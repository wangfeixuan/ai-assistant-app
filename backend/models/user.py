"""
用户模型
定义用户数据结构和相关方法
"""

from datetime import datetime
from werkzeug.security import generate_password_hash, check_password_hash
from flask_login import UserMixin
from . import db

class User(UserMixin, db.Model):
    """用户模型"""
    
    __tablename__ = 'users'
    
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False, index=True)
    email = db.Column(db.String(120), unique=True, nullable=False, index=True)
    password_hash = db.Column(db.String(255), nullable=False)
    
    # 用户基本信息
    nickname = db.Column(db.String(50), nullable=True)
    avatar_url = db.Column(db.String(255), nullable=True)
    
    # 用户偏好设置
    theme_preference = db.Column(db.String(20), default='business')  # business/cute
    timezone = db.Column(db.String(50), default='Asia/Shanghai')
    language = db.Column(db.String(10), default='zh-CN')
    
    # 账户状态
    is_active = db.Column(db.Boolean, default=True)
    is_premium = db.Column(db.Boolean, default=False)  # 付费用户标识
    premium_expires_at = db.Column(db.DateTime, nullable=True)
    
    # 时间戳
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    last_login_at = db.Column(db.DateTime, nullable=True)
    
    # 关联关系
    tasks = db.relationship('Task', backref='user', lazy='dynamic', cascade='all, delete-orphan')
    
    def __init__(self, username, email, password):
        self.username = username
        self.email = email
        self.set_password(password)
    
    def set_password(self, password):
        """设置密码哈希"""
        self.password_hash = generate_password_hash(password)
    
    def check_password(self, password):
        """验证密码"""
        return check_password_hash(self.password_hash, password)
    
    def update_last_login(self):
        """更新最后登录时间"""
        self.last_login_at = datetime.utcnow()
        db.session.commit()
    
    def is_premium_active(self):
        """检查付费会员是否有效"""
        if not self.is_premium:
            return False
        if self.premium_expires_at and self.premium_expires_at < datetime.utcnow():
            return False
        return True
    
    def get_task_count_today(self):
        """获取今日任务数量"""
        from datetime import date
        today = date.today()
        return self.tasks.filter(
            db.func.date(Task.created_at) == today
        ).count()
    
    def to_dict(self, include_sensitive=False):
        """转换为字典格式"""
        data = {
            'id': self.id,
            'username': self.username,
            'email': self.email if include_sensitive else None,
            'nickname': self.nickname,
            'avatar_url': self.avatar_url,
            'theme_preference': self.theme_preference,
            'timezone': self.timezone,
            'language': self.language,
            'is_premium': self.is_premium,
            'premium_expires_at': self.premium_expires_at.isoformat() if self.premium_expires_at else None,
            'created_at': self.created_at.isoformat(),
            'last_login_at': self.last_login_at.isoformat() if self.last_login_at else None
        }
        return data
    
    def __repr__(self):
        return f'<User {self.username}>'
