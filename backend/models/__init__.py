"""
数据模型包初始化文件
"""

from flask_sqlalchemy import SQLAlchemy

# 创建db对象
db = SQLAlchemy()

# 延迟导入模型，避免循环导入
def init_models():
    """初始化所有模型"""
    from .user import User
    from .task import Task, TaskStep
    from .theme import Theme, UserTheme, ThemeColor
    from .procrastination_diary import ProcrastinationDiary, ProcrastinationStats
    
    # 返回模型类
    return {
        'User': User,
        'Task': Task,
        'TaskStep': TaskStep,
        'UserTheme': UserTheme,
        'ThemeColor': ThemeColor,
        'ProcrastinationDiary': ProcrastinationDiary,
        'ProcrastinationStats': ProcrastinationStats
    }

__all__ = ['db', 'init_models']
