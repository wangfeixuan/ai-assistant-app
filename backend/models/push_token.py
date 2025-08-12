"""
用户推送token管理模型
用于存储用户设备的推送通知token
"""

from datetime import datetime
from enum import Enum
from . import db

class PlatformType(Enum):
    """设备平台类型"""
    IOS = "ios"
    ANDROID = "android"
    WEB = "web"

class UserPushToken(db.Model):
    """用户推送token模型"""
    
    __tablename__ = 'user_push_tokens'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)
    
    # 推送token信息
    token = db.Column(db.String(500), nullable=False, index=True)  # FCM/APNs token
    platform = db.Column(db.Enum(PlatformType), nullable=False, index=True)  # 平台类型
    device_id = db.Column(db.String(100), nullable=True)  # 设备唯一标识
    device_name = db.Column(db.String(100), nullable=True)  # 设备名称（如"iPhone 15"）
    
    # 状态管理
    is_active = db.Column(db.Boolean, default=True, index=True)  # 是否激活
    last_used_at = db.Column(db.DateTime, default=datetime.utcnow)  # 最后使用时间
    
    # 通知设置
    enable_evening_reminder = db.Column(db.Boolean, default=True)  # 启用晚间提醒
    enable_procrastination_reminder = db.Column(db.Boolean, default=True)  # 启用拖延提醒
    
    # 时间戳
    created_at = db.Column(db.DateTime, default=datetime.utcnow, index=True)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # 关联关系
    user = db.relationship('User', backref='push_tokens', lazy='select')
    
    def __init__(self, user_id, token, platform, device_id=None, device_name=None):
        self.user_id = user_id
        self.token = token
        self.platform = platform
        self.device_id = device_id
        self.device_name = device_name
    
    def update_token(self, new_token):
        """更新推送token"""
        self.token = new_token
        self.last_used_at = datetime.utcnow()
        self.is_active = True
        db.session.commit()
    
    def deactivate(self):
        """停用token（设备卸载应用或token失效时）"""
        self.is_active = False
        db.session.commit()
    
    def update_notification_settings(self, evening_reminder=None, procrastination_reminder=None):
        """更新通知设置"""
        if evening_reminder is not None:
            self.enable_evening_reminder = evening_reminder
        if procrastination_reminder is not None:
            self.enable_procrastination_reminder = procrastination_reminder
        db.session.commit()
    
    def to_dict(self):
        """转换为字典格式"""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'token': self.token[:20] + '...' if len(self.token) > 20 else self.token,  # 隐藏完整token
            'platform': self.platform.value,
            'device_id': self.device_id,
            'device_name': self.device_name,
            'is_active': self.is_active,
            'enable_evening_reminder': self.enable_evening_reminder,
            'enable_procrastination_reminder': self.enable_procrastination_reminder,
            'last_used_at': self.last_used_at.isoformat(),
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat()
        }
    
    @staticmethod
    def get_active_tokens_for_user(user_id, notification_type='all'):
        """
        获取用户的活跃推送token
        
        Args:
            user_id: 用户ID
            notification_type: 通知类型 ('evening', 'procrastination', 'all')
        
        Returns:
            List[UserPushToken]: 活跃的推送token列表
        """
        query = UserPushToken.query.filter_by(user_id=user_id, is_active=True)
        
        if notification_type == 'evening':
            query = query.filter_by(enable_evening_reminder=True)
        elif notification_type == 'procrastination':
            query = query.filter_by(enable_procrastination_reminder=True)
        
        return query.all()
    
    @staticmethod
    def register_or_update_token(user_id, token, platform, device_id=None, device_name=None):
        """
        注册或更新推送token
        
        Args:
            user_id: 用户ID
            token: 推送token
            platform: 平台类型
            device_id: 设备ID
            device_name: 设备名称
        
        Returns:
            UserPushToken: 推送token记录
        """
        # 查找现有token
        existing_token = UserPushToken.query.filter_by(
            user_id=user_id,
            device_id=device_id
        ).first() if device_id else None
        
        if existing_token:
            # 更新现有token
            existing_token.update_token(token)
            existing_token.platform = platform
            existing_token.device_name = device_name or existing_token.device_name
            return existing_token
        else:
            # 创建新token记录
            new_token = UserPushToken(
                user_id=user_id,
                token=token,
                platform=platform,
                device_id=device_id,
                device_name=device_name
            )
            db.session.add(new_token)
            db.session.commit()
            return new_token
    
    def __repr__(self):
        return f'<UserPushToken {self.id}: {self.platform.value} - {self.token[:20]}...>'
