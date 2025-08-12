"""
每日语录数据模型
"""

from datetime import datetime, date
from models import db

class DailyQuote(db.Model):
    """每日语录模型"""
    __tablename__ = 'daily_quotes'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    quote_text = db.Column(db.Text, nullable=False)
    quote_date = db.Column(db.Date, nullable=False, default=date.today)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # 关系
    user = db.relationship('User', backref=db.backref('daily_quotes', lazy=True))
    
    # 索引
    __table_args__ = (
        db.Index('idx_user_date', 'user_id', 'quote_date'),
    )
    
    def __repr__(self):
        return f'<DailyQuote {self.user_id}-{self.quote_date}>'
    
    def to_dict(self):
        """转换为字典格式"""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'quote': self.quote_text,
            'date': self.quote_date.isoformat(),
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
            'is_today': self.quote_date == date.today()
        }

class CustomQuote(db.Model):
    """用户自定义语录模型"""
    __tablename__ = 'custom_quotes'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    quote_text = db.Column(db.Text, nullable=False)
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # 关系
    user = db.relationship('User', backref=db.backref('custom_quotes', lazy=True))
    
    def __repr__(self):
        return f'<CustomQuote {self.user_id}-{self.id}>'
    
    def to_dict(self):
        """转换为字典格式"""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'quote': self.quote_text,
            'is_active': self.is_active,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }
