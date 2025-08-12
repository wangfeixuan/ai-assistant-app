"""
拖延日记模型
记录用户拖延行为和借口的数据结构
"""

from datetime import datetime, date
from enum import Enum
from . import db

class ProcrastinationReason(Enum):
    """拖延借口类型枚举"""
    TOO_TIRED = "too_tired"                    # 太累了
    DONT_KNOW_HOW = "dont_know_how"           # 不知道怎么做
    NOT_IN_MOOD = "not_in_mood"               # 没心情
    TOO_DIFFICULT = "too_difficult"           # 太难了
    NO_TIME = "no_time"                       # 没时间
    DISTRACTED = "distracted"                 # 被打断了
    NOT_IMPORTANT = "not_important"           # 不重要
    PERFECTIONISM = "perfectionism"           # 想做到完美
    FEAR_OF_FAILURE = "fear_of_failure"       # 害怕失败
    PROCRASTINATION_HABIT = "procrastination_habit"  # 习惯性拖延
    CUSTOM = "custom"                         # 自定义原因

class ProcrastinationDiary(db.Model):
    """拖延日记模型"""
    
    __tablename__ = 'procrastination_diaries'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)
    task_id = db.Column(db.Integer, db.ForeignKey('tasks.id'), nullable=True, index=True)  # 关联的任务ID（可选）
    
    # 拖延信息
    task_title = db.Column(db.String(200), nullable=False)  # 拖延的任务标题
    reason_type = db.Column(db.Enum(ProcrastinationReason), nullable=False, index=True)  # 借口类型
    custom_reason = db.Column(db.Text, nullable=True)  # 自定义借口内容
    mood_before = db.Column(db.Integer, nullable=True)  # 拖延前心情(1-5分)
    mood_after = db.Column(db.Integer, nullable=True)   # 记录后心情(1-5分)
    
    # 时间相关
    procrastination_date = db.Column(db.Date, nullable=False, index=True)  # 拖延发生的日期
    created_at = db.Column(db.DateTime, default=datetime.utcnow, index=True)
    
    # 关联关系
    task = db.relationship('Task', backref='procrastination_records', lazy='select')
    
    def __init__(self, user_id, task_title, reason_type, procrastination_date=None, task_id=None, custom_reason=None):
        self.user_id = user_id
        self.task_title = task_title
        self.reason_type = reason_type
        self.procrastination_date = procrastination_date or date.today()
        self.task_id = task_id
        self.custom_reason = custom_reason
    
    def get_reason_display(self):
        """获取借口的显示文本"""
        reason_map = {
            ProcrastinationReason.TOO_TIRED: "太累了",
            ProcrastinationReason.DONT_KNOW_HOW: "不知道怎么做",
            ProcrastinationReason.NOT_IN_MOOD: "没心情",
            ProcrastinationReason.TOO_DIFFICULT: "太难了",
            ProcrastinationReason.NO_TIME: "没时间",
            ProcrastinationReason.DISTRACTED: "被打断了",
            ProcrastinationReason.NOT_IMPORTANT: "不重要",
            ProcrastinationReason.PERFECTIONISM: "想做到完美",
            ProcrastinationReason.FEAR_OF_FAILURE: "害怕失败",
            ProcrastinationReason.PROCRASTINATION_HABIT: "习惯性拖延",
            ProcrastinationReason.CUSTOM: self.custom_reason or "其他原因"
        }
        return reason_map.get(self.reason_type, "未知原因")
    
    def to_dict(self):
        """转换为字典格式"""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'task_id': self.task_id,
            'task_title': self.task_title,
            'reason_type': self.reason_type.value,
            'reason_display': self.get_reason_display(),
            'custom_reason': self.custom_reason,
            'mood_before': self.mood_before,
            'mood_after': self.mood_after,
            'procrastination_date': self.procrastination_date.isoformat(),
            'created_at': self.created_at.isoformat()
        }
    
    @staticmethod
    def get_available_reasons():
        """获取所有可用的拖延借口选项"""
        return [
            {'value': ProcrastinationReason.TOO_TIRED.value, 'label': '太累了'},
            {'value': ProcrastinationReason.DONT_KNOW_HOW.value, 'label': '不知道怎么做'},
            {'value': ProcrastinationReason.NOT_IN_MOOD.value, 'label': '没心情'},
            {'value': ProcrastinationReason.TOO_DIFFICULT.value, 'label': '太难了'},
            {'value': ProcrastinationReason.NO_TIME.value, 'label': '没时间'},
            {'value': ProcrastinationReason.DISTRACTED.value, 'label': '被打断了'},
            {'value': ProcrastinationReason.NOT_IMPORTANT.value, 'label': '不重要'},
            {'value': ProcrastinationReason.PERFECTIONISM.value, 'label': '想做到完美'},
            {'value': ProcrastinationReason.FEAR_OF_FAILURE.value, 'label': '害怕失败'},
            {'value': ProcrastinationReason.PROCRASTINATION_HABIT.value, 'label': '习惯性拖延'},
            {'value': ProcrastinationReason.CUSTOM.value, 'label': '其他原因（自定义）'}
        ]
    
    def __repr__(self):
        return f'<ProcrastinationDiary {self.id}: {self.task_title} - {self.get_reason_display()}>'

class ProcrastinationStats(db.Model):
    """拖延统计模型（用户级别的统计数据）"""
    
    __tablename__ = 'procrastination_stats'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, unique=True, index=True)
    
    # 统计数据
    total_procrastinations = db.Column(db.Integer, default=0)  # 总拖延次数
    most_common_reason = db.Column(db.Enum(ProcrastinationReason), nullable=True)  # 最常用借口
    current_streak = db.Column(db.Integer, default=0)  # 当前连续拖延天数
    longest_streak = db.Column(db.Integer, default=0)  # 最长连续拖延天数
    
    # 时间相关
    last_procrastination_date = db.Column(db.Date, nullable=True)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def __init__(self, user_id):
        self.user_id = user_id
    
    def update_stats(self, procrastination_date, reason_type):
        """更新统计数据"""
        # 确保数值字段不为None
        if self.total_procrastinations is None:
            self.total_procrastinations = 0
        if self.current_streak is None:
            self.current_streak = 0
        if self.longest_streak is None:
            self.longest_streak = 0
            
        self.total_procrastinations += 1
        
        # 更新连续拖延天数
        if (self.last_procrastination_date and 
            (procrastination_date - self.last_procrastination_date).days == 1):
            self.current_streak += 1
        else:
            self.current_streak = 1
        
        if self.current_streak > self.longest_streak:
            self.longest_streak = self.current_streak
        
        # 更新最常用借口（简化版，实际应该查询数据库统计）
        self.most_common_reason = reason_type
        self.last_procrastination_date = procrastination_date
    
    def to_dict(self):
        """转换为字典格式"""
        return {
            'user_id': self.user_id,
            'total_procrastinations': self.total_procrastinations,
            'most_common_reason': self.most_common_reason.value if self.most_common_reason else None,
            'current_streak': self.current_streak,
            'longest_streak': self.longest_streak,
            'last_procrastination_date': self.last_procrastination_date.isoformat() if self.last_procrastination_date else None,
            'updated_at': self.updated_at.isoformat()
        }
    
    def __repr__(self):
        return f'<ProcrastinationStats {self.user_id}: {self.total_procrastinations} total>'