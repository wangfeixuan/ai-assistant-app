"""
任务模型
定义任务和任务步骤的数据结构
"""

from datetime import datetime, date
from enum import Enum
from . import db

class TaskStatus(Enum):
    """任务状态枚举"""
    PENDING = "pending"      # 待完成
    IN_PROGRESS = "in_progress"  # 进行中
    COMPLETED = "completed"  # 已完成
    CANCELLED = "cancelled"  # 已取消

class TaskPriority(Enum):
    """任务优先级枚举"""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    URGENT = "urgent"

class Task(db.Model):
    """任务模型"""
    
    __tablename__ = 'tasks'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)
    
    # 任务基本信息
    title = db.Column(db.String(200), nullable=False)  # 原始任务描述
    description = db.Column(db.Text, nullable=True)    # 详细描述
    ai_generated_steps = db.Column(db.Text, nullable=True)  # AI生成的步骤（JSON格式）
    
    # 任务状态和优先级
    status = db.Column(db.Enum(TaskStatus), default=TaskStatus.PENDING, index=True)
    priority = db.Column(db.Enum(TaskPriority), default=TaskPriority.MEDIUM)
    
    # 时间相关
    created_at = db.Column(db.DateTime, default=datetime.utcnow, index=True)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    completed_at = db.Column(db.DateTime, nullable=True)
    due_date = db.Column(db.Date, nullable=True)
    
    # 任务统计
    total_steps = db.Column(db.Integer, default=0)
    completed_steps = db.Column(db.Integer, default=0)
    
    # 关联关系
    steps = db.relationship('TaskStep', backref='task', lazy='dynamic', 
                           cascade='all, delete-orphan', order_by='TaskStep.order')
    
    def __init__(self, user_id, title, description=None):
        self.user_id = user_id
        self.title = title
        self.description = description
    
    def add_steps(self, steps_data):
        """添加AI生成的任务步骤"""
        import json
        
        # 保存原始AI生成的步骤数据
        self.ai_generated_steps = json.dumps(steps_data, ensure_ascii=False)
        
        # 创建TaskStep对象
        for i, step_text in enumerate(steps_data):
            step = TaskStep(
                task_id=self.id,
                content=step_text,
                order=i + 1
            )
            db.session.add(step)
        
        self.total_steps = len(steps_data)
        db.session.commit()
    
    def mark_step_completed(self, step_id):
        """标记某个步骤为完成"""
        step = TaskStep.query.filter_by(id=step_id, task_id=self.id).first()
        if step and not step.is_completed:
            step.is_completed = True
            step.completed_at = datetime.utcnow()
            self.completed_steps += 1
            
            # 检查是否所有步骤都完成
            if self.completed_steps >= self.total_steps:
                self.status = TaskStatus.COMPLETED
                self.completed_at = datetime.utcnow()
            else:
                self.status = TaskStatus.IN_PROGRESS
            
            db.session.commit()
            return True
        return False
    
    def get_progress_percentage(self):
        """获取任务完成百分比"""
        if self.total_steps == 0:
            return 0
        return round((self.completed_steps / self.total_steps) * 100, 1)
    
    def is_overdue(self):
        """检查任务是否过期"""
        if not self.due_date:
            return False
        return self.due_date < date.today() and self.status != TaskStatus.COMPLETED
    
    def to_dict(self, include_steps=False):
        """转换为字典格式"""
        data = {
            'id': self.id,
            'user_id': self.user_id,
            'title': self.title,
            'description': self.description,
            'status': self.status.value,
            'priority': self.priority.value,
            'total_steps': self.total_steps,
            'completed_steps': self.completed_steps,
            'progress_percentage': self.get_progress_percentage(),
            'is_overdue': self.is_overdue(),
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat(),
            'completed_at': self.completed_at.isoformat() if self.completed_at else None,
            'due_date': self.due_date.isoformat() if self.due_date else None
        }
        
        if include_steps:
            data['steps'] = [step.to_dict() for step in self.steps.order_by(TaskStep.order)]
        
        return data
    
    def __repr__(self):
        return f'<Task {self.id}: {self.title[:50]}>'

class TaskStep(db.Model):
    """任务步骤模型"""
    
    __tablename__ = 'task_steps'
    
    id = db.Column(db.Integer, primary_key=True)
    task_id = db.Column(db.Integer, db.ForeignKey('tasks.id'), nullable=False, index=True)
    
    # 步骤内容
    content = db.Column(db.Text, nullable=False)  # 步骤描述
    order = db.Column(db.Integer, nullable=False)  # 步骤顺序
    
    # 完成状态
    is_completed = db.Column(db.Boolean, default=False, index=True)
    completed_at = db.Column(db.DateTime, nullable=True)
    
    # 时间戳
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def __init__(self, task_id, content, order):
        self.task_id = task_id
        self.content = content
        self.order = order
    
    def mark_completed(self):
        """标记步骤为完成"""
        if not self.is_completed:
            self.is_completed = True
            self.completed_at = datetime.utcnow()
            return True
        return False
    
    def mark_uncompleted(self):
        """标记步骤为未完成"""
        if self.is_completed:
            self.is_completed = False
            self.completed_at = None
            return True
        return False
    
    def to_dict(self):
        """转换为字典格式"""
        return {
            'id': self.id,
            'task_id': self.task_id,
            'content': self.content,
            'order': self.order,
            'is_completed': self.is_completed,
            'completed_at': self.completed_at.isoformat() if self.completed_at else None,
            'created_at': self.created_at.isoformat()
        }
    
    def __repr__(self):
        return f'<TaskStep {self.id}: {self.content[:30]}>'
