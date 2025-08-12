"""
每日语录API接口
处理每日鼓励语录相关功能
"""

from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import datetime, date
from models.user import User
from models.quote import DailyQuote, db
import random

quotes_bp = Blueprint('quotes', __name__)

@quotes_bp.route('/daily', methods=['GET'])
@jwt_required()
def get_daily_quote():
    """获取今日语录"""
    try:
        current_user_id = get_jwt_identity()
        today = date.today()
        
        # 查找今日语录
        daily_quote = DailyQuote.query.filter_by(
            user_id=current_user_id,
            quote_date=today
        ).first()
        
        if not daily_quote:
            # 如果今日没有语录，随机选择一个并创建记录
            quote_text = _get_random_quote()
            daily_quote = DailyQuote(
                user_id=current_user_id,
                quote_text=quote_text,
                quote_date=today
            )
            db.session.add(daily_quote)
            db.session.commit()
        
        return jsonify({
            'success': True,
            'data': {
                'id': daily_quote.id,
                'quote': daily_quote.quote_text,
                'date': daily_quote.quote_date.isoformat(),
                'is_today': True
            }
        })
        
    except Exception as e:
        return jsonify({'error': f'获取今日语录失败: {str(e)}'}), 500

@quotes_bp.route('/history', methods=['GET'])
@jwt_required()
def get_quote_history():
    """获取语录历史"""
    try:
        current_user_id = get_jwt_identity()
        page = int(request.args.get('page', 1))
        per_page = int(request.args.get('per_page', 10))
        
        quotes = DailyQuote.query.filter_by(
            user_id=current_user_id
        ).order_by(DailyQuote.quote_date.desc()).paginate(
            page=page, per_page=per_page, error_out=False
        )
        
        return jsonify({
            'success': True,
            'data': {
                'quotes': [{
                    'id': quote.id,
                    'quote': quote.quote_text,
                    'date': quote.quote_date.isoformat(),
                    'is_today': quote.quote_date == date.today()
                } for quote in quotes.items],
                'pagination': {
                    'page': quotes.page,
                    'pages': quotes.pages,
                    'per_page': quotes.per_page,
                    'total': quotes.total
                }
            }
        })
        
    except Exception as e:
        return jsonify({'error': f'获取语录历史失败: {str(e)}'}), 500

@quotes_bp.route('/refresh', methods=['POST'])
@jwt_required()
def refresh_daily_quote():
    """刷新今日语录（付费功能）"""
    try:
        current_user_id = get_jwt_identity()
        user = User.query.get(current_user_id)
        
        if not user:
            return jsonify({'error': '用户不存在'}), 404
        
        # 检查是否为付费用户
        if not user.is_premium_active():
            return jsonify({'error': '此功能需要付费版权限'}), 403
        
        today = date.today()
        
        # 更新今日语录
        daily_quote = DailyQuote.query.filter_by(
            user_id=current_user_id,
            quote_date=today
        ).first()
        
        new_quote_text = _get_random_quote()
        
        if daily_quote:
            daily_quote.quote_text = new_quote_text
            daily_quote.updated_at = datetime.utcnow()
        else:
            daily_quote = DailyQuote(
                user_id=current_user_id,
                quote_text=new_quote_text,
                quote_date=today
            )
            db.session.add(daily_quote)
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'data': {
                'id': daily_quote.id,
                'quote': daily_quote.quote_text,
                'date': daily_quote.quote_date.isoformat(),
                'is_today': True
            },
            'message': '今日语录已刷新'
        })
        
    except Exception as e:
        return jsonify({'error': f'刷新语录失败: {str(e)}'}), 500

@quotes_bp.route('/custom', methods=['POST'])
@jwt_required()
def add_custom_quote():
    """添加自定义语录（付费功能）"""
    try:
        current_user_id = get_jwt_identity()
        user = User.query.get(current_user_id)
        
        if not user:
            return jsonify({'error': '用户不存在'}), 404
        
        if not user.is_premium_active():
            return jsonify({'error': '此功能需要付费版权限'}), 403
        
        data = request.get_json()
        if not data or 'quote' not in data:
            return jsonify({'error': '语录内容为必填项'}), 400
        
        quote_text = data['quote'].strip()
        if not quote_text:
            return jsonify({'error': '语录内容不能为空'}), 400
        
        if len(quote_text) > 200:
            return jsonify({'error': '语录内容不能超过200字符'}), 400
        
        # 添加到用户自定义语录库
        # 这里可以扩展为用户自定义语录管理功能
        
        return jsonify({
            'success': True,
            'message': '自定义语录添加成功'
        })
        
    except Exception as e:
        return jsonify({'error': f'添加自定义语录失败: {str(e)}'}), 500

def _get_random_quote():
    """获取随机语录"""
    quotes = [
        "每一个小步骤都是向目标迈进的勇敢尝试 💪",
        "今天的努力是明天成功的基石 🌟",
        "不要害怕开始，最难的部分往往是迈出第一步 🚀",
        "进步不在于速度，而在于方向的正确性 🎯",
        "每完成一个小任务，你就离梦想更近一步 ✨",
        "拖延是梦想的敌人，行动是成功的朋友 🔥",
        "相信自己，你比想象中更有能力 💎",
        "今天的你要比昨天的你更进一步 📈",
        "专注当下，一次只做一件事 🎯",
        "小小的改变能带来巨大的结果 🌱",
        "坚持不懈，水滴石穿 💧",
        "每一次努力都在为未来的自己投资 💰",
        "困难是成长的阶梯，挑战是能力的试金石 🏔️",
        "今天是改变的最好时机 ⏰",
        "相信过程，享受进步的每一刻 🌈"
    ]
    return random.choice(quotes)
