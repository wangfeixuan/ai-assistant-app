"""
番茄钟API接口
处理番茄钟计时器相关功能
"""

from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models.user import User
from models.pomodoro import PomodoroSession, PomodoroSettings, db
from datetime import datetime, timedelta
import json

pomodoro_bp = Blueprint('pomodoro', __name__)

@pomodoro_bp.route('/settings', methods=['GET'])
@jwt_required()
def get_pomodoro_settings():
    """获取用户番茄钟设置"""
    try:
        current_user_id = get_jwt_identity()
        
        settings = PomodoroSettings.query.filter_by(
            user_id=current_user_id
        ).first()
        
        if not settings:
            # 创建默认设置
            settings = PomodoroSettings(
                user_id=current_user_id,
                work_duration=25,  # 25分钟工作时间
                short_break_duration=5,  # 5分钟短休息
                long_break_duration=15,  # 15分钟长休息
                sessions_until_long_break=4  # 4个番茄钟后长休息
            )
            db.session.add(settings)
            db.session.commit()
        
        return jsonify({
            'success': True,
            'data': settings.to_dict()
        })
        
    except Exception as e:
        return jsonify({'error': f'获取番茄钟设置失败: {str(e)}'}), 500

@pomodoro_bp.route('/settings', methods=['PUT'])
@jwt_required()
def update_pomodoro_settings():
    """更新用户番茄钟设置"""
    try:
        current_user_id = get_jwt_identity()
        data = request.get_json()
        
        if not data:
            return jsonify({'error': '请提供设置数据'}), 400
        
        settings = PomodoroSettings.query.filter_by(
            user_id=current_user_id
        ).first()
        
        if not settings:
            settings = PomodoroSettings(user_id=current_user_id)
            db.session.add(settings)
        
        # 更新设置
        if 'work_duration' in data:
            work_duration = int(data['work_duration'])
            if 1 <= work_duration <= 60:
                settings.work_duration = work_duration
        
        if 'short_break_duration' in data:
            short_break = int(data['short_break_duration'])
            if 1 <= short_break <= 30:
                settings.short_break_duration = short_break
        
        if 'long_break_duration' in data:
            long_break = int(data['long_break_duration'])
            if 1 <= long_break <= 60:
                settings.long_break_duration = long_break
        
        if 'sessions_until_long_break' in data:
            sessions = int(data['sessions_until_long_break'])
            if 2 <= sessions <= 10:
                settings.sessions_until_long_break = sessions
        
        if 'sound_enabled' in data:
            settings.sound_enabled = bool(data['sound_enabled'])
        
        if 'auto_start_breaks' in data:
            settings.auto_start_breaks = bool(data['auto_start_breaks'])
        
        if 'auto_start_pomodoros' in data:
            settings.auto_start_pomodoros = bool(data['auto_start_pomodoros'])
        
        settings.updated_at = datetime.utcnow()
        db.session.commit()
        
        return jsonify({
            'success': True,
            'data': settings.to_dict(),
            'message': '番茄钟设置更新成功'
        })
        
    except Exception as e:
        return jsonify({'error': f'更新番茄钟设置失败: {str(e)}'}), 500

@pomodoro_bp.route('/start', methods=['POST'])
@jwt_required()
def start_pomodoro_session():
    """开始番茄钟会话"""
    try:
        current_user_id = get_jwt_identity()
        data = request.get_json()
        
        session_type = data.get('type', 'work')  # work, short_break, long_break
        if session_type not in ['work', 'short_break', 'long_break']:
            return jsonify({'error': '无效的会话类型'}), 400
        
        # 获取用户设置
        settings = PomodoroSettings.query.filter_by(
            user_id=current_user_id
        ).first()
        
        if not settings:
            return jsonify({'error': '请先配置番茄钟设置'}), 400
        
        # 确定会话时长
        duration_map = {
            'work': settings.work_duration,
            'short_break': settings.short_break_duration,
            'long_break': settings.long_break_duration
        }
        duration = duration_map[session_type]
        
        # 创建新会话
        session = PomodoroSession(
            user_id=current_user_id,
            session_type=session_type,
            planned_duration=duration,
            start_time=datetime.utcnow()
        )
        
        db.session.add(session)
        db.session.commit()
        
        return jsonify({
            'success': True,
            'data': {
                'session_id': session.id,
                'type': session.session_type,
                'duration': session.planned_duration,
                'start_time': session.start_time.isoformat(),
                'end_time': (session.start_time + timedelta(minutes=duration)).isoformat()
            },
            'message': f'番茄钟会话已开始 ({duration}分钟)'
        })
        
    except Exception as e:
        return jsonify({'error': f'开始番茄钟会话失败: {str(e)}'}), 500

@pomodoro_bp.route('/complete/<int:session_id>', methods=['POST'])
@jwt_required()
def complete_pomodoro_session(session_id):
    """完成番茄钟会话"""
    try:
        current_user_id = get_jwt_identity()
        
        session = PomodoroSession.query.filter_by(
            id=session_id,
            user_id=current_user_id
        ).first()
        
        if not session:
            return jsonify({'error': '会话不存在'}), 404
        
        if session.is_completed:
            return jsonify({'error': '会话已完成'}), 400
        
        # 标记会话完成
        session.end_time = datetime.utcnow()
        session.is_completed = True
        session.actual_duration = int((session.end_time - session.start_time).total_seconds() / 60)
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'data': session.to_dict(),
            'message': '番茄钟会话已完成'
        })
        
    except Exception as e:
        return jsonify({'error': f'完成番茄钟会话失败: {str(e)}'}), 500

@pomodoro_bp.route('/pause/<int:session_id>', methods=['POST'])
@jwt_required()
def pause_pomodoro_session(session_id):
    """暂停番茄钟会话"""
    try:
        current_user_id = get_jwt_identity()
        
        session = PomodoroSession.query.filter_by(
            id=session_id,
            user_id=current_user_id
        ).first()
        
        if not session:
            return jsonify({'error': '会话不存在'}), 404
        
        if session.is_completed:
            return jsonify({'error': '已完成的会话无法暂停'}), 400
        
        session.is_paused = True
        session.pause_time = datetime.utcnow()
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'data': session.to_dict(),
            'message': '番茄钟会话已暂停'
        })
        
    except Exception as e:
        return jsonify({'error': f'暂停番茄钟会话失败: {str(e)}'}), 500

@pomodoro_bp.route('/resume/<int:session_id>', methods=['POST'])
@jwt_required()
def resume_pomodoro_session(session_id):
    """恢复番茄钟会话"""
    try:
        current_user_id = get_jwt_identity()
        
        session = PomodoroSession.query.filter_by(
            id=session_id,
            user_id=current_user_id
        ).first()
        
        if not session:
            return jsonify({'error': '会话不存在'}), 404
        
        if not session.is_paused:
            return jsonify({'error': '会话未暂停'}), 400
        
        # 计算暂停时长并调整开始时间
        if session.pause_time:
            pause_duration = datetime.utcnow() - session.pause_time
            session.start_time += pause_duration
        
        session.is_paused = False
        session.pause_time = None
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'data': session.to_dict(),
            'message': '番茄钟会话已恢复'
        })
        
    except Exception as e:
        return jsonify({'error': f'恢复番茄钟会话失败: {str(e)}'}), 500

@pomodoro_bp.route('/stats', methods=['GET'])
@jwt_required()
def get_pomodoro_stats():
    """获取番茄钟统计数据"""
    try:
        current_user_id = get_jwt_identity()
        
        # 获取查询参数
        period = request.args.get('period', 'today')  # today, week, month, all
        
        # 构建查询
        query = PomodoroSession.query.filter_by(
            user_id=current_user_id,
            is_completed=True
        )
        
        # 时间过滤
        now = datetime.utcnow()
        if period == 'today':
            start_date = now.replace(hour=0, minute=0, second=0, microsecond=0)
            query = query.filter(PomodoroSession.start_time >= start_date)
        elif period == 'week':
            start_date = now - timedelta(days=7)
            query = query.filter(PomodoroSession.start_time >= start_date)
        elif period == 'month':
            start_date = now - timedelta(days=30)
            query = query.filter(PomodoroSession.start_time >= start_date)
        
        sessions = query.all()
        
        # 统计数据
        total_sessions = len(sessions)
        work_sessions = len([s for s in sessions if s.session_type == 'work'])
        break_sessions = len([s for s in sessions if s.session_type in ['short_break', 'long_break']])
        total_minutes = sum([s.actual_duration or s.planned_duration for s in sessions])
        
        return jsonify({
            'success': True,
            'data': {
                'period': period,
                'total_sessions': total_sessions,
                'work_sessions': work_sessions,
                'break_sessions': break_sessions,
                'total_minutes': total_minutes,
                'total_hours': round(total_minutes / 60, 1),
                'average_session_length': round(total_minutes / total_sessions, 1) if total_sessions > 0 else 0
            }
        })
        
    except Exception as e:
        return jsonify({'error': f'获取番茄钟统计失败: {str(e)}'}), 500
