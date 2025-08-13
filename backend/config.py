"""
拖延症AI助手 - 配置文件
包含数据库连接、AI服务、认证等配置
"""

import os
from datetime import timedelta

class Config:
    """基础配置类"""
    
    # Flask基础配置
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'dev-secret-key-change-in-production'
    
    # 数据库配置 - Railway部署时使用环境变量，本地开发使用SQLite
    DATABASE_URL = os.environ.get('DATABASE_URL') or os.environ.get('SQLALCHEMY_DATABASE_URI')
    if DATABASE_URL:
        # 生产环境（Railway）使用PostgreSQL
        SQLALCHEMY_DATABASE_URI = DATABASE_URL
        SQLALCHEMY_ENGINE_OPTIONS = {
            'pool_pre_ping': True,
            'pool_recycle': 300,
        }
    else:
        # 本地开发使用SQLite
        SQLALCHEMY_DATABASE_URI = 'sqlite:///procrastination_ai.db'
        SQLALCHEMY_ENGINE_OPTIONS = {}
    
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    
    # JWT认证配置
    JWT_SECRET_KEY = os.environ.get('JWT_SECRET_KEY') or 'jwt-secret-change-in-production'
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(hours=24)
    JWT_REFRESH_TOKEN_EXPIRES = timedelta(days=30)
    
    # AI服务配置 - 通义千问
    DASHSCOPE_API_KEY = os.environ.get('DASHSCOPE_API_KEY')
    AI_MODEL = os.environ.get('AI_MODEL') or 'qwen-max'
    AI_PROVIDER = os.environ.get('AI_PROVIDER') or 'dashscope'
    
    # 任务拆解配置
    MAX_TASK_STEPS = 20  # 最大拆解步骤数
    TASK_HISTORY_DAYS = 90  # 保留任务历史天数
    
    # 文件上传配置
    MAX_CONTENT_LENGTH = 16 * 1024 * 1024  # 16MB
    
    # 缓存配置
    CACHE_TYPE = 'simple'
    CACHE_DEFAULT_TIMEOUT = 300  # 5分钟
    
    # 邮件配置（用于用户验证）
    MAIL_SERVER = os.environ.get('MAIL_SERVER')
    MAIL_PORT = int(os.environ.get('MAIL_PORT') or 587)
    MAIL_USE_TLS = os.environ.get('MAIL_USE_TLS', 'true').lower() in ['true', 'on', '1']
    MAIL_USERNAME = os.environ.get('MAIL_USERNAME')
    MAIL_PASSWORD = os.environ.get('MAIL_PASSWORD')
    
    # 支付配置（后续商业化功能）
    STRIPE_PUBLISHABLE_KEY = os.environ.get('STRIPE_PUBLISHABLE_KEY')
    STRIPE_SECRET_KEY = os.environ.get('STRIPE_SECRET_KEY')
    
    # Firebase推送通知配置
    FCM_SERVER_KEY = os.environ.get('FCM_SERVER_KEY', 'YOUR_FCM_SERVER_KEY_HERE')
    FCM_URL = "https://fcm.googleapis.com/fcm/send"
    
    # APNs配置（iOS推送）
    APNS_KEY_ID = os.environ.get('APNS_KEY_ID', 'YOUR_APNS_KEY_ID')
    APNS_TEAM_ID = os.environ.get('APNS_TEAM_ID', 'YOUR_TEAM_ID')
    APNS_BUNDLE_ID = os.environ.get('APNS_BUNDLE_ID', 'com.example.flutterAiAssistant')
    
    # 推送通知模板
    NOTIFICATION_TEMPLATES = {
        'evening_reminder': {
            'title': '📝 任务提醒',
            'body_template': '你还有{task_count}个任务未完成，记得及时处理哦！',
            'icon': 'ic_notification',
            'sound': 'default',
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'route': '/todo'
        },
        'procrastination_reminder': {
            'title': '🤔 拖延提醒',
            'body_template': '任务「{task_title}」已超时，要不要记录一下拖延原因？',
            'icon': 'ic_notification',
            'sound': 'default',
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'route': '/procrastination/record'
        },
        'task_completed': {
            'title': '🎉 任务完成',
            'body_template': '恭喜完成任务「{task_title}」！继续保持！',
            'icon': 'ic_notification',
            'sound': 'default',
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'route': '/todo'
        }
    }
    
    @classmethod
    def is_firebase_configured(cls):
        """检查Firebase是否已正确配置"""
        return (cls.FCM_SERVER_KEY and 
                cls.FCM_SERVER_KEY != 'YOUR_FCM_SERVER_KEY_HERE' and
                len(cls.FCM_SERVER_KEY) > 10)
    
    @classmethod
    def get_notification_template(cls, notification_type):
        """获取通知模板"""
        return cls.NOTIFICATION_TEMPLATES.get(notification_type, {
            'title': '拖延症AI助手',
            'body_template': '{message}',
            'icon': 'ic_notification',
            'sound': 'default',
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'route': '/'
        })

class DevelopmentConfig(Config):
    """开发环境配置"""
    DEBUG = True
    SQLALCHEMY_DATABASE_URI = 'postgresql://localhost/procrastination_ai_dev'

class ProductionConfig(Config):
    """生产环境配置"""
    DEBUG = False
    
class TestingConfig(Config):
    """测试环境配置"""
    TESTING = True
    SQLALCHEMY_DATABASE_URI = 'postgresql://localhost/procrastination_ai_test'

# 配置字典
config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'testing': TestingConfig,
    'default': DevelopmentConfig
}
