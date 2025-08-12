"""
用户认证API接口
处理用户注册、登录、登出等认证相关功能
"""

from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, create_refresh_token, jwt_required, get_jwt_identity
from werkzeug.exceptions import BadRequest
from models.user import User, db
from services.auth_service import AuthService
import re

auth_bp = Blueprint('auth', __name__)

@auth_bp.route('/register', methods=['POST'])
def register():
    """用户注册"""
    try:
        data = request.get_json()
        
        # 验证必填字段
        if not data or not all(k in data for k in ('username', 'email', 'password')):
            return jsonify({'error': '用户名、邮箱和密码为必填项'}), 400
        
        username = data['username'].strip()
        email = data['email'].strip().lower()
        password = data['password']
        
        # 基本验证
        if len(username) < 3 or len(username) > 20:
            return jsonify({'error': '用户名长度应在3-20个字符之间'}), 400
        
        # 支持中文、英文字母、数字和下划线
        if not re.match(r'^[\u4e00-\u9fa5a-zA-Z0-9_]+$', username):
            return jsonify({'error': '用户名只能包含中文、英文字母、数字和下划线'}), 400
        
        if not re.match(r'^[^\s@]+@[^\s@]+\.[^\s@]+$', email):
            return jsonify({'error': '邮箱格式不正确'}), 400
        
        if len(password) < 6:
            return jsonify({'error': '密码长度不能少于6个字符'}), 400
        
        # 检查用户是否已存在
        if User.query.filter_by(username=username).first():
            return jsonify({'error': '用户名已存在'}), 409
        
        if User.query.filter_by(email=email).first():
            return jsonify({'error': '邮箱已被注册'}), 409
        
        # 创建新用户
        user = User(username=username, email=email, password=password)
        user.nickname = data.get('nickname', username)
        
        db.session.add(user)
        db.session.commit()
        
        # 生成JWT token
        access_token = create_access_token(identity=user.id)
        refresh_token = create_refresh_token(identity=user.id)
        
        return jsonify({
            'message': '注册成功',
            'user': user.to_dict(),
            'access_token': access_token,
            'refresh_token': refresh_token
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'注册失败: {str(e)}'}), 500

@auth_bp.route('/login', methods=['POST'])
def login():
    """用户登录"""
    try:
        data = request.get_json()
        
        if not data or not all(k in data for k in ('login', 'password')):
            return jsonify({'error': '登录名和密码为必填项'}), 400
        
        login_field = data['login'].strip()
        password = data['password']
        
        # 支持用户名或邮箱登录
        user = User.query.filter(
            (User.username == login_field) | (User.email == login_field.lower())
        ).first()
        
        if not user or not user.check_password(password):
            return jsonify({'error': '用户名/邮箱或密码错误'}), 401
        
        if not user.is_active:
            return jsonify({'error': '账户已被禁用'}), 403
        
        # 更新最后登录时间
        user.update_last_login()
        
        # 生成JWT token
        access_token = create_access_token(identity=user.id)
        refresh_token = create_refresh_token(identity=user.id)
        
        return jsonify({
            'message': '登录成功',
            'user': user.to_dict(),
            'access_token': access_token,
            'refresh_token': refresh_token
        }), 200
        
    except Exception as e:
        return jsonify({'error': f'登录失败: {str(e)}'}), 500

@auth_bp.route('/refresh', methods=['POST'])
@jwt_required(refresh=True)
def refresh():
    """刷新访问令牌"""
    try:
        current_user_id = get_jwt_identity()
        user = User.query.get(current_user_id)
        
        if not user or not user.is_active:
            return jsonify({'error': '用户不存在或已被禁用'}), 404
        
        new_access_token = create_access_token(identity=current_user_id)
        
        return jsonify({
            'access_token': new_access_token
        }), 200
        
    except Exception as e:
        return jsonify({'error': f'令牌刷新失败: {str(e)}'}), 500

@auth_bp.route('/profile', methods=['GET'])
@jwt_required()
def get_profile():
    """获取用户资料"""
    try:
        current_user_id = get_jwt_identity()
        user = User.query.get(current_user_id)
        
        if not user:
            return jsonify({'error': '用户不存在'}), 404
        
        return jsonify({
            'user': user.to_dict(include_sensitive=True)
        }), 200
        
    except Exception as e:
        return jsonify({'error': f'获取用户资料失败: {str(e)}'}), 500

@auth_bp.route('/profile', methods=['PUT'])
@jwt_required()
def update_profile():
    """更新用户资料"""
    try:
        current_user_id = get_jwt_identity()
        user = User.query.get(current_user_id)
        
        if not user:
            return jsonify({'error': '用户不存在'}), 404
        
        data = request.get_json()
        if not data:
            return jsonify({'error': '请提供要更新的数据'}), 400
        
        # 可更新的字段
        updatable_fields = ['nickname', 'theme_preference', 'timezone', 'language']
        
        for field in updatable_fields:
            if field in data:
                setattr(user, field, data[field])
        
        # 验证主题偏好
        if 'theme_preference' in data:
            if data['theme_preference'] not in ['business', 'cute']:
                return jsonify({'error': '主题偏好只能是business或cute'}), 400
        
        db.session.commit()
        
        return jsonify({
            'message': '资料更新成功',
            'user': user.to_dict(include_sensitive=True)
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'更新资料失败: {str(e)}'}), 500

@auth_bp.route('/change-password', methods=['PUT'])
@jwt_required()
def change_password():
    """修改密码"""
    try:
        current_user_id = get_jwt_identity()
        user = User.query.get(current_user_id)
        
        if not user:
            return jsonify({'error': '用户不存在'}), 404
        
        data = request.get_json()
        if not data or not all(k in data for k in ('current_password', 'new_password')):
            return jsonify({'error': '当前密码和新密码为必填项'}), 400
        
        current_password = data['current_password']
        new_password = data['new_password']
        
        # 验证当前密码
        if not user.check_password(current_password):
            return jsonify({'error': '当前密码错误'}), 401
        
        # 验证新密码
        if len(new_password) < 6:
            return jsonify({'error': '新密码长度不能少于6个字符'}), 400
        
        # 更新密码
        user.set_password(new_password)
        db.session.commit()
        
        return jsonify({'message': '密码修改成功'}), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'修改密码失败: {str(e)}'}), 500

@auth_bp.route('/logout', methods=['POST'])
@jwt_required()
def logout():
    """用户登出"""
    # 在实际应用中，可以将token加入黑名单
    # 这里简单返回成功消息
    return jsonify({'message': '登出成功'}), 200
