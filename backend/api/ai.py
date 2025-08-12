"""
AI任务拆解API接口
处理AI任务拆解相关功能
"""

from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from services.ai_service import AIService
from models.user import User

ai_bp = Blueprint('ai', __name__)

@ai_bp.route('/decompose', methods=['POST'])
@jwt_required()
def decompose_task():
    """AI任务拆解接口"""
    try:
        current_user_id = get_jwt_identity()
        data = request.get_json()
        
        if not data or 'task' not in data:
            return jsonify({'error': '任务描述为必填项'}), 400
        
        task_description = data['task'].strip()
        if not task_description:
            return jsonify({'error': '任务描述不能为空'}), 400
        
        # 获取用户信息（用于个性化拆解）
        user = User.query.get(current_user_id)
        if not user:
            return jsonify({'error': '用户不存在'}), 404
        
        # 检查付费用户权限（高级拆解功能）
        is_premium = user.is_premium_active()
        
        # 使用AI服务进行任务拆解
        ai_service = AIService()
        steps = ai_service.decompose_task(
            task_description, 
            context=data.get('context', ''),
            user_preferences={
                'theme': user.theme_preference,
                'is_premium': is_premium
            }
        )
        
        if not steps:
            return jsonify({'error': 'AI拆解失败，请重试'}), 500
        
        return jsonify({
            'task': task_description,
            'steps': steps,
            'step_count': len(steps),
            'is_premium_result': is_premium
        }), 200
        
    except Exception as e:
        return jsonify({'error': f'任务拆解失败: {str(e)}'}), 500

@ai_bp.route('/suggest', methods=['POST'])
@jwt_required()
def suggest_improvements():
    """AI建议任务改进"""
    try:
        current_user_id = get_jwt_identity()
        data = request.get_json()
        
        if not data or 'task_id' not in data:
            return jsonify({'error': '任务ID为必填项'}), 400
        
        # 这里可以根据任务完成情况提供改进建议
        # 暂时返回示例响应
        suggestions = [
            "可以将大任务拆分为更小的步骤",
            "建议设置具体的时间节点",
            "考虑添加奖励机制来提高完成动力"
        ]
        
        return jsonify({
            'suggestions': suggestions
        }), 200
        
    except Exception as e:
        return jsonify({'error': f'获取建议失败: {str(e)}'}), 500

@ai_bp.route('/templates', methods=['GET'])
@jwt_required()
def get_task_templates():
    """获取任务模板"""
    try:
        current_user_id = get_jwt_identity()
        user = User.query.get(current_user_id)
        
        # 基础模板
        templates = [
            {
                'id': 1,
                'title': '学习新技能',
                'description': '系统性学习一项新技能的通用模板',
                'example': '学习Python编程',
                'category': 'learning',
                'is_premium': False
            },
            {
                'id': 2,
                'title': '日常生活任务',
                'description': '处理日常生活事务的模板',
                'example': '整理房间',
                'category': 'daily',
                'is_premium': False
            },
            {
                'id': 3,
                'title': '工作项目',
                'description': '完成工作项目的结构化模板',
                'example': '准备项目汇报',
                'category': 'work',
                'is_premium': False
            }
        ]
        
        # 付费用户专享模板
        if user and user.is_premium_active():
            premium_templates = [
                {
                    'id': 4,
                    'title': '深度学习计划',
                    'description': '高级学习计划模板，包含复习和测试环节',
                    'example': '掌握机器学习算法',
                    'category': 'learning',
                    'is_premium': True
                },
                {
                    'id': 5,
                    'title': '创业项目规划',
                    'description': '创业项目的完整规划模板',
                    'example': '开发移动应用',
                    'category': 'business',
                    'is_premium': True
                }
            ]
            templates.extend(premium_templates)
        
        return jsonify({
            'templates': templates
        }), 200
        
    except Exception as e:
        return jsonify({'error': f'获取模板失败: {str(e)}'}), 500

@ai_bp.route('/feedback', methods=['POST'])
@jwt_required()
def submit_feedback():
    """提交AI拆解反馈"""
    try:
        current_user_id = get_jwt_identity()
        data = request.get_json()
        
        if not data or not all(k in data for k in ('task_id', 'rating', 'feedback')):
            return jsonify({'error': '任务ID、评分和反馈内容为必填项'}), 400
        
        task_id = data['task_id']
        rating = data['rating']  # 1-5分
        feedback_text = data['feedback']
        
        if not (1 <= rating <= 5):
            return jsonify({'error': '评分必须在1-5之间'}), 400
        
        # 这里可以将反馈存储到数据库，用于改进AI模型
        # 暂时只返回成功响应
        
        return jsonify({
            'message': '反馈提交成功，感谢您的建议！'
        }), 200
        
    except Exception as e:
        return jsonify({'error': f'提交反馈失败: {str(e)}'}), 500
