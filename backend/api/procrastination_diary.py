"""
拖延日记API接口
处理拖延记录、统计和AI分析功能
"""

from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import datetime, date, timedelta
from sqlalchemy import func, desc
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from models.procrastination_diary import ProcrastinationDiary, ProcrastinationStats, ProcrastinationReason
from models.task import Task
from models import db
from services.ai_service import AIService
import requests
import json

procrastination_bp = Blueprint('procrastination', __name__)

@procrastination_bp.route('/reasons', methods=['GET'])
def get_procrastination_reasons():
    """获取所有可用的拖延借口选项"""
    try:
        reasons = ProcrastinationDiary.get_available_reasons()
        return jsonify({
            'success': True,
            'data': reasons
        }), 200
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'获取拖延借口失败: {str(e)}'
        }), 500

@procrastination_bp.route('/record', methods=['POST'])
def record_procrastination():
    """记录拖延原因"""
    try:
        # 尝试获取JWT用户ID，如果没有则使用默认用户ID 1
        try:
            user_id = get_jwt_identity() if request.headers.get('Authorization') else 1
        except:
            user_id = 1
        
        data = request.get_json()
        
        # 验证必需字段
        required_fields = ['task_title', 'reason_type']
        for field in required_fields:
            if field not in data:
                return jsonify({
                    'success': False,
                    'message': f'缺少必需字段: {field}'
                }), 400
        
        # 验证reason_type是否有效
        try:
            reason_type = ProcrastinationReason(data['reason_type'])
        except ValueError:
            return jsonify({
                'success': False,
                'message': '无效的拖延原因类型'
            }), 400
        
        # 如果是自定义原因，检查是否提供了custom_reason
        if reason_type == ProcrastinationReason.CUSTOM and not data.get('custom_reason'):
            return jsonify({
                'success': False,
                'message': '自定义原因不能为空'
            }), 400
        
        # 创建拖延记录
        diary_entry = ProcrastinationDiary(
            user_id=user_id,
            task_title=data['task_title'],
            reason_type=reason_type,
            task_id=data.get('task_id'),
            custom_reason=data.get('custom_reason'),
            procrastination_date=datetime.strptime(data.get('procrastination_date', date.today().isoformat()), '%Y-%m-%d').date()
        )
        
        # 设置心情评分
        if 'mood_before' in data:
            diary_entry.mood_before = data['mood_before']
        if 'mood_after' in data:
            diary_entry.mood_after = data['mood_after']
        
        db.session.add(diary_entry)
        
        # 更新或创建统计数据
        stats = ProcrastinationStats.query.filter_by(user_id=user_id).first()
        if not stats:
            stats = ProcrastinationStats(user_id=user_id)
            db.session.add(stats)
        
        stats.update_stats(diary_entry.procrastination_date, reason_type)
        
        db.session.commit()
        
        # 生成单次拖延分析
        ai_service = AIService()
        analysis = ai_service.analyze_single_procrastination(
            task_title=data['task_title'],
            reason_type=reason_type.value,
            custom_reason=data.get('custom_reason'),
            mood_before=data.get('mood_before'),
            mood_after=data.get('mood_after')
        )
        
        return jsonify({
            'success': True,
            'message': '拖延记录已保存',
            'data': {
                'diary': diary_entry.to_dict(),
                'analysis': analysis
            }
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({
            'success': False,
            'message': f'记录拖延失败: {str(e)}'
        }), 500

@procrastination_bp.route('/diary', methods=['GET'])
def get_procrastination_diary():
    """获取用户的拖延日记列表"""
    try:
        # 尝试获取JWT用户ID，如果没有则使用默认用户ID 1
        try:
            user_id = get_jwt_identity() if request.headers.get('Authorization') else 1
        except:
            user_id = 1
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 10, type=int)
        
        # 获取日期范围参数
        start_date = request.args.get('start_date')
        end_date = request.args.get('end_date')
        
        query = ProcrastinationDiary.query.filter_by(user_id=user_id)
        
        # 添加日期过滤
        if start_date:
            query = query.filter(ProcrastinationDiary.procrastination_date >= datetime.strptime(start_date, '%Y-%m-%d').date())
        if end_date:
            query = query.filter(ProcrastinationDiary.procrastination_date <= datetime.strptime(end_date, '%Y-%m-%d').date())
        
        # 按日期倒序排列
        query = query.order_by(desc(ProcrastinationDiary.procrastination_date), desc(ProcrastinationDiary.created_at))
        
        # 分页
        pagination = query.paginate(page=page, per_page=per_page, error_out=False)
        
        return jsonify({
            'success': True,
            'data': {
                'entries': [entry.to_dict() for entry in pagination.items],
                'total': pagination.total,
                'pages': pagination.pages,
                'current_page': page,
                'per_page': per_page
            }
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'获取拖延日记失败: {str(e)}'
        }), 500

@procrastination_bp.route('/stats', methods=['GET'])
def get_procrastination_stats():
    """获取拖延统计数据"""
    try:
        # 尝试获取JWT用户ID，如果没有则使用默认用户ID 1
        try:
            user_id = get_jwt_identity() if request.headers.get('Authorization') else 1
        except:
            user_id = 1
        
        # 获取基础统计
        stats = ProcrastinationStats.query.filter_by(user_id=user_id).first()
        if not stats:
            stats = ProcrastinationStats(user_id=user_id)
            db.session.add(stats)
            db.session.commit()
        
        # 获取借口排行榜（前3名）
        reason_stats = db.session.query(
            ProcrastinationDiary.reason_type,
            func.count(ProcrastinationDiary.id).label('count')
        ).filter_by(user_id=user_id).group_by(
            ProcrastinationDiary.reason_type
        ).order_by(desc('count')).limit(3).all()
        
        # 转换借口统计为可读格式
        top_reasons = []
        for reason, count in reason_stats:
            reason_display = {
                ProcrastinationReason.TOO_TIRED: "太累了",
                ProcrastinationReason.DONT_KNOW_HOW: "不知道怎么做",
                ProcrastinationReason.NOT_IN_MOOD: "没心情",
                ProcrastinationReason.TOO_DIFFICULT: "太难了",
                ProcrastinationReason.NO_TIME: "没时间",
                ProcrastinationReason.DISTRACTED: "被打断了",
                ProcrastinationReason.NOT_IMPORTANT: "不重要",
                ProcrastinationReason.PERFECTIONISM: "想做到完美",
                ProcrastinationReason.FEAR_OF_FAILURE: "害怕失败",
                ProcrastinationReason.PROCRASTINATION_HABIT: "习惯性拖延",
                ProcrastinationReason.CUSTOM: "其他原因"
            }.get(reason, "未知原因")
            
            top_reasons.append({
                'reason_type': reason.value,
                'reason_display': reason_display,
                'count': count
            })
        
        # 获取最近7天的拖延趋势
        seven_days_ago = date.today() - timedelta(days=7)
        recent_entries = ProcrastinationDiary.query.filter(
            ProcrastinationDiary.user_id == user_id,
            ProcrastinationDiary.procrastination_date >= seven_days_ago
        ).order_by(ProcrastinationDiary.procrastination_date).all()
        
        # 按日期分组统计
        daily_stats = {}
        for entry in recent_entries:
            date_str = entry.procrastination_date.isoformat()
            if date_str not in daily_stats:
                daily_stats[date_str] = 0
            daily_stats[date_str] += 1
        
        return jsonify({
            'success': True,
            'data': {
                'basic_stats': stats.to_dict(),
                'top_reasons': top_reasons,
                'daily_trend': daily_stats
            }
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'获取统计数据失败: {str(e)}'
        }), 500

@procrastination_bp.route('/ai-analysis', methods=['GET'])
def get_ai_analysis():
    """获取AI智能分析"""
    try:
        # 尝试获取JWT用户ID，如果没有则使用默认用户ID 1
        try:
            user_id = get_jwt_identity() if request.headers.get('Authorization') else 1
        except:
            user_id = 1
        
        # 获取前3名借口
        reason_stats = db.session.query(
            ProcrastinationDiary.reason_type,
            func.count(ProcrastinationDiary.id).label('count')
        ).filter_by(user_id=user_id).group_by(
            ProcrastinationDiary.reason_type
        ).order_by(desc('count')).limit(3).all()
        
        if not reason_stats:
            return jsonify({
                'success': True,
                'data': {
                    'analysis': '暂无拖延记录，无法进行分析。保持良好的习惯！',
                    'suggestions': ['继续保持高效的工作状态', '制定合理的任务计划', '适当休息，保持身心健康'],
                    'mood_advice': '你的自律能力很棒，继续加油！'
                }
            }), 200
        
        # 构建分析提示词
        top_reasons_text = []
        for reason, count in reason_stats:
            reason_display = {
                ProcrastinationReason.TOO_TIRED: "太累了",
                ProcrastinationReason.DONT_KNOW_HOW: "不知道怎么做",
                ProcrastinationReason.NOT_IN_MOOD: "没心情",
                ProcrastinationReason.TOO_DIFFICULT: "太难了",
                ProcrastinationReason.NO_TIME: "没时间",
                ProcrastinationReason.DISTRACTED: "被打断了",
                ProcrastinationReason.NOT_IMPORTANT: "不重要",
                ProcrastinationReason.PERFECTIONISM: "想做到完美",
                ProcrastinationReason.FEAR_OF_FAILURE: "害怕失败",
                ProcrastinationReason.PROCRASTINATION_HABIT: "习惯性拖延",
                ProcrastinationReason.CUSTOM: "其他原因"
            }.get(reason, "未知原因")
            top_reasons_text.append(f"{reason_display}({count}次)")
        
        # 获取最近7天的拖延记录用于模式分析
        seven_days_ago = date.today() - timedelta(days=7)
        recent_records = ProcrastinationDiary.query.filter(
            ProcrastinationDiary.user_id == user_id,
            ProcrastinationDiary.procrastination_date >= seven_days_ago
        ).order_by(desc(ProcrastinationDiary.procrastination_date)).all()
        
        # 分析任务重复性
        task_repetition = {}
        for record in recent_records:
            task_title = record.task_title
            task_repetition[task_title] = task_repetition.get(task_title, 0) + 1
        
        # 转换记录格式
        records_data = [record.to_dict() for record in recent_records]
        
        # 使用AI服务生成深度分析
        ai_service = AIService()
        analysis_result = ai_service.analyze_procrastination_patterns(records_data, task_repetition)
        
        return jsonify({
            'success': True,
            'data': analysis_result
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'AI分析失败: {str(e)}'
        }), 500

def generate_mock_analysis(top_reasons):
    """生成模拟的AI分析结果"""
    # 这是临时的模拟分析，后续会替换为真实的AI API调用
    
    if not top_reasons:
        return {
            'analysis': '暂无拖延记录，无法进行分析。',
            'suggestions': ['制定合理的任务计划', '保持良好的作息习惯'],
            'mood_advice': '继续保持良好状态！'
        }
    
    # 根据最常见的借口类型生成建议
    main_reason = top_reasons[0]
    
    analysis_templates = {
        '太累了': {
            'analysis': f'你最常用的借口是"{main_reason}"，这通常反映了时间管理和精力分配的问题。过度疲劳可能是因为任务安排过于密集，或者休息不充分。',
            'suggestions': [
                '制定更合理的作息时间表，确保充足睡眠',
                '学会任务优先级排序，避免同时处理过多任务',
                '适当安排休息时间，劳逸结合',
                '考虑使用番茄工作法，提高工作效率'
            ],
            'mood_advice': '疲劳是正常的生理反应，不要过分自责。重要的是找到适合自己的节奏，循序渐进地改善。'
        },
        '没心情': {
            'analysis': f'你最常用的借口是"{main_reason}"，这可能与情绪管理和动机激发有关。情绪波动会直接影响执行力。',
            'suggestions': [
                '建立情绪觉察习惯，记录每日心情变化',
                '寻找任务的内在意义和价值',
                '创造积极的工作环境',
                '学习简单的情绪调节技巧'
            ],
            'mood_advice': '情绪起伏是人之常情，关键是学会与情绪和谐相处，而不是被情绪控制。'
        },
        '太难了': {
            'analysis': f'你最常用的借口是"{main_reason}"，这表明你可能习惯性高估任务难度，或者缺乏分解复杂任务的技巧。',
            'suggestions': [
                '学会将大任务分解为小步骤',
                '从最简单的部分开始着手',
                '寻求帮助和资源，不要独自承担',
                '培养"先做再说"的行动思维'
            ],
            'mood_advice': '每个人都会遇到挑战，困难并不可怕，可怕的是不敢开始。相信自己的学习能力！'
        }
    }
    
    # 默认分析
    default_analysis = {
        'analysis': f'根据你的拖延记录，最常见的借口是{", ".join(top_reasons[:3])}。这些借口背后往往隐藏着更深层的原因，比如完美主义、恐惧心理或时间管理问题。',
        'suggestions': [
            '识别并接受自己的拖延模式',
            '制定具体可行的行动计划',
            '建立奖励机制，庆祝小进步',
            '寻找合适的工作环境和时间'
        ],
        'mood_advice': '拖延是很多人都会遇到的问题，不要过分自责。重要的是保持耐心，一步步改善。'
    }
    
    # 查找匹配的分析模板
    for reason_key, template in analysis_templates.items():
        if reason_key in main_reason:
            return template
    
    return default_analysis

@procrastination_bp.route('/check-overdue-tasks', methods=['POST'])
def check_overdue_tasks():
    """检查并标记超时未完成的任务为拖延任务"""
    try:
        # 尝试获取JWT用户ID，如果没有则使用默认用户ID 1
        try:
            user_id = get_jwt_identity() if request.headers.get('Authorization') else 1
        except:
            user_id = 1
        current_time = datetime.now()
        
        # 查找昨天24点之前应该完成但未完成的任务
        yesterday = (current_time - timedelta(days=1)).date()
        
        overdue_tasks = Task.query.filter(
            Task.user_id == user_id,
            Task.completed == False,
            func.date(Task.created_at) <= yesterday
        ).all()
        
        procrastination_records = []
        
        for task in overdue_tasks:
            # 检查是否已经有拖延记录
            existing_record = ProcrastinationDiary.query.filter(
                ProcrastinationDiary.user_id == user_id,
                ProcrastinationDiary.task_id == task.id,
                ProcrastinationDiary.procrastination_date == yesterday
            ).first()
            
            if not existing_record:
                # 创建拖延记录，等待用户输入原因
                diary_entry = ProcrastinationDiary(
                    user_id=user_id,
                    task_id=task.id,
                    task_title=task.title,
                    reason_type=ProcrastinationReason.CUSTOM,  # 临时设置，等待用户选择
                    procrastination_date=yesterday
                )
                
                db.session.add(diary_entry)
                procrastination_records.append(diary_entry.to_dict())
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': f'检查完成，发现{len(procrastination_records)}个拖延任务',
            'data': {
                'overdue_count': len(procrastination_records),
                'records': procrastination_records
            }
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({
            'success': False,
            'message': f'检查超时任务失败: {str(e)}'
        }), 500
