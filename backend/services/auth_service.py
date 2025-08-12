"""
认证服务
处理用户认证相关的业务逻辑
"""

import jwt
import hashlib
import secrets
from datetime import datetime, timedelta
from typing import Optional, Dict
from models.user import User, db
from config import Config

class AuthService:
    """认证服务类"""
    
    @staticmethod
    def generate_password_reset_token(user_id: int) -> str:
        """生成密码重置令牌"""
        payload = {
            'user_id': user_id,
            'exp': datetime.utcnow() + timedelta(hours=1),  # 1小时有效期
            'type': 'password_reset'
        }
        return jwt.encode(payload, Config.SECRET_KEY, algorithm='HS256')
    
    @staticmethod
    def verify_password_reset_token(token: str) -> Optional[int]:
        """验证密码重置令牌"""
        try:
            payload = jwt.decode(token, Config.SECRET_KEY, algorithms=['HS256'])
            if payload.get('type') != 'password_reset':
                return None
            return payload.get('user_id')
        except jwt.ExpiredSignatureError:
            return None
        except jwt.InvalidTokenError:
            return None
    
    @staticmethod
    def generate_email_verification_token(user_id: int) -> str:
        """生成邮箱验证令牌"""
        payload = {
            'user_id': user_id,
            'exp': datetime.utcnow() + timedelta(days=1),  # 24小时有效期
            'type': 'email_verification'
        }
        return jwt.encode(payload, Config.SECRET_KEY, algorithm='HS256')
    
    @staticmethod
    def verify_email_verification_token(token: str) -> Optional[int]:
        """验证邮箱验证令牌"""
        try:
            payload = jwt.decode(token, Config.SECRET_KEY, algorithms=['HS256'])
            if payload.get('type') != 'email_verification':
                return None
            return payload.get('user_id')
        except jwt.ExpiredSignatureError:
            return None
        except jwt.InvalidTokenError:
            return None
    
    @staticmethod
    def hash_api_key(api_key: str) -> str:
        """对API密钥进行哈希处理"""
        return hashlib.sha256(api_key.encode()).hexdigest()
    
    @staticmethod
    def generate_api_key() -> str:
        """生成API密钥"""
        return secrets.token_urlsafe(32)
    
    @staticmethod
    def validate_user_permissions(user: User, required_permission: str) -> bool:
        """验证用户权限"""
        # 基础权限检查
        if not user.is_active:
            return False
        
        # 付费功能权限检查
        premium_features = [
            'advanced_ai_decomposition',
            'unlimited_tasks',
            'premium_themes',
            'export_data',
            'priority_support'
        ]
        
        if required_permission in premium_features:
            return user.is_premium_active()
        
        return True
    
    @staticmethod
    def get_user_session_info(user: User) -> Dict:
        """获取用户会话信息"""
        return {
            'user_id': user.id,
            'username': user.username,
            'is_premium': user.is_premium_active(),
            'theme_preference': user.theme_preference,
            'last_login': user.last_login_at.isoformat() if user.last_login_at else None,
            'session_created': datetime.utcnow().isoformat()
        }
    
    @staticmethod
    def update_user_activity(user_id: int):
        """更新用户活动时间"""
        user = User.query.get(user_id)
        if user:
            user.last_login_at = datetime.utcnow()
            db.session.commit()
    
    @staticmethod
    def check_rate_limit(user_id: int, action: str, limit: int = 100, window: int = 3600) -> bool:
        """检查用户操作频率限制"""
        # 这里可以实现基于Redis的频率限制
        # 暂时返回True，表示允许操作
        return True
    
    @staticmethod
    def log_security_event(user_id: int, event_type: str, details: Dict = None):
        """记录安全事件"""
        # 这里可以实现安全事件日志记录
        # 例如：登录失败、密码修改、权限变更等
        security_log = {
            'user_id': user_id,
            'event_type': event_type,
            'details': details or {},
            'timestamp': datetime.utcnow().isoformat(),
            'ip_address': None  # 可以从请求中获取
        }
        
        # 实际应用中应该存储到数据库或日志系统
        print(f"Security Event: {security_log}")
    
    @staticmethod
    def validate_password_strength(password: str) -> Dict:
        """验证密码强度"""
        result = {
            'is_valid': True,
            'score': 0,
            'suggestions': []
        }
        
        # 长度检查
        if len(password) < 6:
            result['is_valid'] = False
            result['suggestions'].append('密码长度至少6个字符')
        elif len(password) >= 8:
            result['score'] += 1
        
        # 复杂度检查
        has_upper = any(c.isupper() for c in password)
        has_lower = any(c.islower() for c in password)
        has_digit = any(c.isdigit() for c in password)
        has_special = any(c in '!@#$%^&*()_+-=[]{}|;:,.<>?' for c in password)
        
        complexity_score = sum([has_upper, has_lower, has_digit, has_special])
        result['score'] += complexity_score
        
        if complexity_score < 2:
            result['suggestions'].append('建议包含大小写字母、数字和特殊字符')
        
        # 常见密码检查
        common_passwords = ['123456', 'password', '123456789', 'qwerty', 'abc123']
        if password.lower() in common_passwords:
            result['is_valid'] = False
            result['suggestions'].append('请避免使用常见密码')
        
        return result
