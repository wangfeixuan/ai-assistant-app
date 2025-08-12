"""
推送通知API接口
管理用户推送token和通知设置
"""

from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from models.push_token import UserPushToken, PlatformType
from models import db
from services.notification_service import notification_service

push_notifications_bp = Blueprint('push_notifications', __name__)

@push_notifications_bp.route('/register-token', methods=['POST'])
@jwt_required()
def register_push_token():
    """注册或更新推送token"""
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        
        # 验证必需字段
        required_fields = ['token', 'platform']
        for field in required_fields:
            if field not in data:
                return jsonify({
                    'success': False,
                    'message': f'缺少必需字段: {field}'
                }), 400
        
        # 验证平台类型
        try:
            platform = PlatformType(data['platform'])
        except ValueError:
            return jsonify({
                'success': False,
                'message': '无效的平台类型，支持: ios, android, web'
            }), 400
        
        # 注册或更新token
        push_token = UserPushToken.register_or_update_token(
            user_id=user_id,
            token=data['token'],
            platform=platform,
            device_id=data.get('device_id'),
            device_name=data.get('device_name')
        )
        
        return jsonify({
            'success': True,
            'message': '推送token注册成功',
            'data': push_token.to_dict()
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({
            'success': False,
            'message': f'注册推送token失败: {str(e)}'
        }), 500

@push_notifications_bp.route('/tokens', methods=['GET'])
@jwt_required()
def get_user_push_tokens():
    """获取用户的推送token列表"""
    try:
        user_id = get_jwt_identity()
        
        tokens = UserPushToken.query.filter_by(user_id=user_id).order_by(
            UserPushToken.created_at.desc()
        ).all()
        
        return jsonify({
            'success': True,
            'data': [token.to_dict() for token in tokens]
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'获取推送token失败: {str(e)}'
        }), 500

@push_notifications_bp.route('/settings', methods=['PUT'])
@jwt_required()
def update_notification_settings():
    """更新通知设置"""
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        
        token_id = data.get('token_id')
        if not token_id:
            return jsonify({
                'success': False,
                'message': '缺少token_id参数'
            }), 400
        
        # 查找token记录
        push_token = UserPushToken.query.filter_by(
            id=token_id,
            user_id=user_id
        ).first()
        
        if not push_token:
            return jsonify({
                'success': False,
                'message': '推送token不存在'
            }), 404
        
        # 更新通知设置
        push_token.update_notification_settings(
            evening_reminder=data.get('enable_evening_reminder'),
            procrastination_reminder=data.get('enable_procrastination_reminder')
        )
        
        return jsonify({
            'success': True,
            'message': '通知设置更新成功',
            'data': push_token.to_dict()
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({
            'success': False,
            'message': f'更新通知设置失败: {str(e)}'
        }), 500

@push_notifications_bp.route('/deactivate-token', methods=['POST'])
@jwt_required()
def deactivate_push_token():
    """停用推送token"""
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        
        token_id = data.get('token_id')
        if not token_id:
            return jsonify({
                'success': False,
                'message': '缺少token_id参数'
            }), 400
        
        # 查找token记录
        push_token = UserPushToken.query.filter_by(
            id=token_id,
            user_id=user_id
        ).first()
        
        if not push_token:
            return jsonify({
                'success': False,
                'message': '推送token不存在'
            }), 404
        
        # 停用token
        push_token.deactivate()
        
        return jsonify({
            'success': True,
            'message': '推送token已停用'
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({
            'success': False,
            'message': f'停用推送token失败: {str(e)}'
        }), 500

@push_notifications_bp.route('/test-notification', methods=['POST'])
@jwt_required()
def test_notification():
    """测试推送通知（开发用）"""
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        
        notification_type = data.get('type', 'evening')  # evening 或 procrastination
        
        if notification_type == 'evening':
            success = notification_service.send_evening_reminder(user_id, 3)
            message = '晚间提醒测试'
        elif notification_type == 'procrastination':
            task_title = data.get('task_title', '测试任务')
            success = notification_service.send_procrastination_reminder(user_id, task_title)
            message = '拖延提醒测试'
        else:
            return jsonify({
                'success': False,
                'message': '无效的通知类型，支持: evening, procrastination'
            }), 400
        
        return jsonify({
            'success': success,
            'message': f'{message}{"成功" if success else "失败"}'
        }), 200 if success else 500
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'测试通知失败: {str(e)}'
        }), 500
