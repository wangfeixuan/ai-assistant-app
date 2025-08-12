"""
API接口包初始化文件
"""

from .auth import auth_bp
from .tasks import tasks_bp
from .ai import ai_bp

__all__ = ['auth_bp', 'tasks_bp', 'ai_bp']
