"""
拖延症AI助手 - 主应用入口
Flask应用的主要配置和启动文件
"""

import os
from dotenv import load_dotenv
from flask import Flask, jsonify, request
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from config import Config
from models import db

# 加载根目录下的环境变量文件
load_dotenv(os.path.join(os.path.dirname(os.path.dirname(__file__)), '.env'))

def create_app():
    """创建Flask应用实例"""
    app = Flask(__name__)
    app.config.from_object(Config)
    
    # 初始化数据库
    db.init_app(app)
    
    # 初始化JWT管理器
    jwt = JWTManager(app)
    
    # 启用CORS支持前端跨域请求
    CORS(app)
    
    # 注册蓝图（路由）
    from api.auth import auth_bp
    from api.tasks import tasks_bp
    from api.ai_assistant import ai_bp
    from api.ai_simple import ai_simple_bp
    from api.quotes import quotes_bp
    from api.themes import themes_bp
    from api.pomodoro import pomodoro_bp
    from api.procrastination_diary import procrastination_bp
    from api.push_notifications import push_notifications_bp
    
    app.register_blueprint(auth_bp, url_prefix='/api/auth')
    app.register_blueprint(tasks_bp, url_prefix='/api/tasks')
    app.register_blueprint(ai_bp, url_prefix='/api/ai')
    app.register_blueprint(ai_simple_bp, url_prefix='/api/ai-simple')
    app.register_blueprint(quotes_bp, url_prefix='/api/quotes')
    app.register_blueprint(themes_bp, url_prefix='/api/themes')
    app.register_blueprint(pomodoro_bp, url_prefix='/api/pomodoro')
    app.register_blueprint(procrastination_bp, url_prefix='/api/procrastination')
    app.register_blueprint(push_notifications_bp, url_prefix='/api/notifications')

    
    # 健康检查端点
    @app.route('/health')
    def health_check():
        return jsonify({
            'status': 'healthy',
            'message': '拖延症AI助手服务运行正常'
        })
    
    # 根路径
    @app.route('/')
    def index():
        return jsonify({
            'message': '欢迎使用拖延症AI助手',
            'version': '1.0.0',
            'endpoints': {
                'auth': '/api/auth',
                'tasks': '/api/tasks',
                'ai': '/api/ai',
                'quotes': '/api/quotes',
                'themes': '/api/themes',
                'pomodoro': '/api/pomodoro'
            }
        })
    
    return app

if __name__ == '__main__':
    app = create_app()
    
    # 启动定时任务调度器（暂时禁用，避免依赖问题）
    # from scheduler import init_scheduler
    # init_scheduler(app)
    
    app.run(debug=True, host='0.0.0.0', port=5001)
