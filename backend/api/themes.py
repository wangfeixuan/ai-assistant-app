"""
主题管理API接口
处理5色主题系统相关功能
"""

from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models.user import User
from models.theme import UserTheme, ThemeColor, db
from datetime import datetime

themes_bp = Blueprint('themes', __name__)

@themes_bp.route('/colors', methods=['GET'])
def get_available_colors():
    """获取可用的主题颜色列表"""
    try:
        colors = [
            {
                'id': 'pink',
                'name': '粉色',
                'primary': '#FF6B9D',
                'secondary': '#FFB3D1',
                'accent': '#FF8FA3',
                'background': '#FFF5F8',
                'surface': '#FFFFFF',
                'description': '温柔浪漫的粉色主题'
            },
            {
                'id': 'blue',
                'name': '蓝色',
                'primary': '#2196F3',
                'secondary': '#64B5F6',
                'accent': '#42A5F5',
                'background': '#F3F9FF',
                'surface': '#FFFFFF',
                'description': '专业稳重的蓝色主题'
            },
            {
                'id': 'purple',
                'name': '紫色',
                'primary': '#9C27B0',
                'secondary': '#BA68C8',
                'accent': '#AB47BC',
                'background': '#F8F5FF',
                'surface': '#FFFFFF',
                'description': '神秘优雅的紫色主题'
            },
            {
                'id': 'green',
                'name': '绿色',
                'primary': '#4CAF50',
                'secondary': '#81C784',
                'accent': '#66BB6A',
                'background': '#F5FFF5',
                'surface': '#FFFFFF',
                'description': '清新自然的绿色主题'
            },
            {
                'id': 'yellow',
                'name': '黄色',
                'primary': '#FF9800',
                'secondary': '#FFB74D',
                'accent': '#FFA726',
                'background': '#FFFBF0',
                'surface': '#FFFFFF',
                'description': '活力阳光的黄色主题'
            }
        ]
        
        return jsonify({
            'success': True,
            'data': {
                'colors': colors,
                'total': len(colors)
            }
        })
        
    except Exception as e:
        return jsonify({'error': f'获取主题颜色失败: {str(e)}'}), 500

@themes_bp.route('/current', methods=['GET'])
@jwt_required()
def get_current_theme():
    """获取用户当前主题设置"""
    try:
        current_user_id = get_jwt_identity()
        
        user_theme = UserTheme.query.filter_by(
            user_id=current_user_id
        ).first()
        
        if not user_theme:
            # 如果用户没有主题设置，创建默认主题
            user_theme = UserTheme(
                user_id=current_user_id,
                color_scheme='blue',  # 默认蓝色主题
                is_dark_mode=False
            )
            db.session.add(user_theme)
            db.session.commit()
        
        # 获取主题颜色详情
        color_details = _get_color_details(user_theme.color_scheme)
        
        return jsonify({
            'success': True,
            'data': {
                'id': user_theme.id,
                'color_scheme': user_theme.color_scheme,
                'is_dark_mode': user_theme.is_dark_mode,
                'custom_settings': user_theme.custom_settings or {},
                'color_details': color_details,
                'last_updated': user_theme.updated_at.isoformat() if user_theme.updated_at else None
            }
        })
        
    except Exception as e:
        return jsonify({'error': f'获取当前主题失败: {str(e)}'}), 500

@themes_bp.route('/update', methods=['PUT'])
@jwt_required()
def update_theme():
    """更新用户主题设置"""
    try:
        current_user_id = get_jwt_identity()
        data = request.get_json()
        
        if not data:
            return jsonify({'error': '请提供主题设置数据'}), 400
        
        # 验证颜色方案
        color_scheme = data.get('color_scheme')
        if color_scheme:
            valid_colors = ['pink', 'blue', 'purple', 'green', 'yellow']
            if color_scheme not in valid_colors:
                return jsonify({'error': '无效的颜色方案'}), 400
        
        # 获取或创建用户主题设置
        user_theme = UserTheme.query.filter_by(
            user_id=current_user_id
        ).first()
        
        if not user_theme:
            user_theme = UserTheme(user_id=current_user_id)
            db.session.add(user_theme)
        
        # 更新设置
        if color_scheme:
            user_theme.color_scheme = color_scheme
        
        if 'is_dark_mode' in data:
            user_theme.is_dark_mode = bool(data['is_dark_mode'])
        
        if 'custom_settings' in data:
            user_theme.custom_settings = data['custom_settings']
        
        user_theme.updated_at = datetime.utcnow()
        db.session.commit()
        
        # 获取更新后的主题详情
        color_details = _get_color_details(user_theme.color_scheme)
        
        return jsonify({
            'success': True,
            'data': {
                'id': user_theme.id,
                'color_scheme': user_theme.color_scheme,
                'is_dark_mode': user_theme.is_dark_mode,
                'custom_settings': user_theme.custom_settings or {},
                'color_details': color_details,
                'last_updated': user_theme.updated_at.isoformat()
            },
            'message': '主题设置更新成功'
        })
        
    except Exception as e:
        return jsonify({'error': f'更新主题设置失败: {str(e)}'}), 500

@themes_bp.route('/preview', methods=['POST'])
@jwt_required()
def preview_theme():
    """预览主题效果（不保存）"""
    try:
        data = request.get_json()
        
        if not data or 'color_scheme' not in data:
            return jsonify({'error': '请提供要预览的颜色方案'}), 400
        
        color_scheme = data['color_scheme']
        valid_colors = ['pink', 'blue', 'purple', 'green', 'yellow']
        
        if color_scheme not in valid_colors:
            return jsonify({'error': '无效的颜色方案'}), 400
        
        # 获取主题颜色详情
        color_details = _get_color_details(color_scheme)
        is_dark_mode = data.get('is_dark_mode', False)
        
        return jsonify({
            'success': True,
            'data': {
                'color_scheme': color_scheme,
                'is_dark_mode': is_dark_mode,
                'color_details': color_details,
                'preview_mode': True
            }
        })
        
    except Exception as e:
        return jsonify({'error': f'预览主题失败: {str(e)}'}), 500

def _get_color_details(color_scheme):
    """获取颜色方案详情"""
    color_map = {
        'pink': {
            'id': 'pink',
            'name': '粉色',
            'primary': '#FF6B9D',
            'secondary': '#FFB3D1',
            'accent': '#FF8FA3',
            'background': '#FFF5F8',
            'surface': '#FFFFFF',
            'description': '温柔浪漫的粉色主题'
        },
        'blue': {
            'id': 'blue',
            'name': '蓝色',
            'primary': '#2196F3',
            'secondary': '#64B5F6',
            'accent': '#42A5F5',
            'background': '#F3F9FF',
            'surface': '#FFFFFF',
            'description': '专业稳重的蓝色主题'
        },
        'purple': {
            'id': 'purple',
            'name': '紫色',
            'primary': '#9C27B0',
            'secondary': '#BA68C8',
            'accent': '#AB47BC',
            'background': '#F8F5FF',
            'surface': '#FFFFFF',
            'description': '神秘优雅的紫色主题'
        },
        'green': {
            'id': 'green',
            'name': '绿色',
            'primary': '#4CAF50',
            'secondary': '#81C784',
            'accent': '#66BB6A',
            'background': '#F5FFF5',
            'surface': '#FFFFFF',
            'description': '清新自然的绿色主题'
        },
        'yellow': {
            'id': 'yellow',
            'name': '黄色',
            'primary': '#FF9800',
            'secondary': '#FFB74D',
            'accent': '#FFA726',
            'background': '#FFFBF0',
            'surface': '#FFFFFF',
            'description': '活力阳光的黄色主题'
        }
    }
    
    return color_map.get(color_scheme, color_map['blue'])
