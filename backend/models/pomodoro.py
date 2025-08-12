"""
番茄钟数据模型
"""

from datetime import datetime
from models import db

class PomodoroSettings(db.Model):
    """番茄钟设置模型"""
    __tablename__ = 'pomodoro_settings'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    
    # 时间设置（分钟）
    work_duration = db.Column(db.Integer, default=25)  # 工作时间
    short_break_duration = db.Column(db.Integer, default=5)  # 短休息时间
    long_break_duration = db.Column(db.Integer, default=15)  # 长休息时间
    sessions_until_long_break = db.Column(db.Integer, default=4)  # 几个番茄钟后长休息
    
    # 功能设置
    sound_enabled = db.Column(db.Boolean, default=True)  # 声音提醒
    auto_start_breaks = db.Column(db.Boolean, default=False)  # 自动开始休息
    auto_start_pomodoros = db.Column(db.Boolean, default=False)  # 自动开始番茄钟
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # 关系
    user = db.relationship('User', backref=db.backref('pomodoro_settings', uselist=False))
    
    def __repr__(self):
        return f'<PomodoroSettings {self.user_id}>'
    
    def to_dict(self):
        """转换为字典格式"""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'work_duration': self.work_duration,
            'short_break_duration': self.short_break_duration,
            'long_break_duration': self.long_break_duration,
            'sessions_until_long_break': self.sessions_until_long_break,
            'sound_enabled': self.sound_enabled,
            'auto_start_breaks': self.auto_start_breaks,
            'auto_start_pomodoros': self.auto_start_pomodoros,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }

class PomodoroSession(db.Model):
    """番茄钟会话模型"""
    __tablename__ = 'pomodoro_sessions'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    
    # 会话信息
    session_type = db.Column(db.String(20), nullable=False)  # work, short_break, long_break
    planned_duration = db.Column(db.Integer, nullable=False)  # 计划时长（分钟）
    actual_duration = db.Column(db.Integer, nullable=True)  # 实际时长（分钟）
    
    # 时间记录
    start_time = db.Column(db.DateTime, nullable=False)
    end_time = db.Column(db.DateTime, nullable=True)
    pause_time = db.Column(db.DateTime, nullable=True)
    
    # 状态
    is_completed = db.Column(db.Boolean, default=False)
    is_paused = db.Column(db.Boolean, default=False)
    
    # 关联任务（可选）
    task_id = db.Column(db.Integer, db.ForeignKey('tasks.id'), nullable=True)
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # 关系
    user = db.relationship('User', backref=db.backref('pomodoro_sessions', lazy=True))
    task = db.relationship('Task', backref=db.backref('pomodoro_sessions', lazy=True))
    
    # 索引
    __table_args__ = (
        db.Index('idx_user_session', 'user_id', 'start_time'),
        db.Index('idx_session_type', 'session_type'),
    )
    
    def __repr__(self):
        return f'<PomodoroSession {self.user_id}-{self.session_type}-{self.start_time}>'
    
    def to_dict(self):
        """转换为字典格式"""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'session_type': self.session_type,
            'planned_duration': self.planned_duration,
            'actual_duration': self.actual_duration,
            'start_time': self.start_time.isoformat(),
            'end_time': self.end_time.isoformat() if self.end_time else None,
            'pause_time': self.pause_time.isoformat() if self.pause_time else None,
            'is_completed': self.is_completed,
            'is_paused': self.is_paused,
            'task_id': self.task_id,
            'created_at': self.created_at.isoformat()
        }

class PomodoroStats(db.Model):
    """番茄钟统计模型（每日汇总）"""
    __tablename__ = 'pomodoro_stats'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    date = db.Column(db.Date, nullable=False)
    
    # 统计数据
    total_sessions = db.Column(db.Integer, default=0)
    work_sessions = db.Column(db.Integer, default=0)
    break_sessions = db.Column(db.Integer, default=0)
    total_minutes = db.Column(db.Integer, default=0)
    completed_sessions = db.Column(db.Integer, default=0)
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # 关系
    user = db.relationship('User', backref=db.backref('pomodoro_stats', lazy=True))
    
    # 索引
    __table_args__ = (
        db.Index('idx_user_date', 'user_id', 'date'),
        db.UniqueConstraint('user_id', 'date', name='uq_user_date'),
    )
    
    def __repr__(self):
        return f'<PomodoroStats {self.user_id}-{self.date}>'
    
    def to_dict(self):
        """转换为字典格式"""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'date': self.date.isoformat(),
            'total_sessions': self.total_sessions,
            'work_sessions': self.work_sessions,
            'break_sessions': self.break_sessions,
            'total_minutes': self.total_minutes,
            'completed_sessions': self.completed_sessions,
            'completion_rate': round(self.completed_sessions / self.total_sessions * 100, 1) if self.total_sessions > 0 else 0,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }
