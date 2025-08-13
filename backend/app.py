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

def auto_init_database():
    """应用启动时自动初始化数据库"""
    import sqlite3
    
    # 使用绝对路径确保数据库文件位置
    db_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'procrastination_ai.db')
    print(f"💾 数据库路径: {db_path}")
    
    # 检查数据库是否存在且有内容
    db_exists = os.path.exists(db_path)
    db_size = os.path.getsize(db_path) if db_exists else 0
    print(f"🔍 数据库检查: 存在={db_exists}, 大小={db_size}字节")
    
    if not db_exists or db_size == 0:
        print("🚀 检测到数据库未初始化，开始自动初始化...")
        
        try:
            # 创建数据库连接
            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()
            
            # 创建用户表
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS users (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    username VARCHAR(80) UNIQUE NOT NULL,
                    email VARCHAR(120) UNIQUE NOT NULL,
                    password_hash VARCHAR(255) NOT NULL,
                    nickname VARCHAR(50),
                    avatar_url VARCHAR(255),
                    theme_preference VARCHAR(20) DEFAULT 'business',
                    timezone VARCHAR(50) DEFAULT 'Asia/Shanghai',
                    language VARCHAR(10) DEFAULT 'zh-CN',
                    is_active BOOLEAN DEFAULT 1,
                    is_premium BOOLEAN DEFAULT 0,
                    premium_expires_at DATETIME,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    last_login_at DATETIME
                )
            """)
            
            # 创建任务表
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS tasks (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id INTEGER NOT NULL,
                    title VARCHAR(200) NOT NULL,
                    description TEXT,
                    status VARCHAR(20) DEFAULT 'pending',
                    priority INTEGER DEFAULT 1,
                    due_date DATETIME,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (user_id) REFERENCES users (id)
                )
            """)
            
            # 创建主题表
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS themes (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name VARCHAR(50) UNIQUE NOT NULL,
                    display_name VARCHAR(100) NOT NULL,
                    description TEXT,
                    is_default BOOLEAN DEFAULT 0,
                    is_active BOOLEAN DEFAULT 1,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            # 插入默认主题数据
            cursor.execute("""
                INSERT OR IGNORE INTO themes (name, display_name, description, is_default, is_active)
                VALUES 
                ('business', '商务风格', '专业简洁的商务风格主题', 1, 1),
                ('cute', '可爱风格', '温馨可爱的粉色系主题', 0, 1)
            """)
            
            # 创建索引
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_users_username ON users (username)")
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_users_email ON users (email)")
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_tasks_user_id ON tasks (user_id)")
            
            # 提交更改并关闭连接
            conn.commit()
            conn.close()
            
            print("✅ 数据库自动初始化完成！")
            
            # 验证数据库初始化结果
            conn_verify = sqlite3.connect(db_path)
            cursor_verify = conn_verify.cursor()
            cursor_verify.execute("SELECT name FROM sqlite_master WHERE type='table'")
            tables = cursor_verify.fetchall()
            print(f"📋 已创建的表: {[table[0] for table in tables]}")
            conn_verify.close()
            
        except Exception as e:
            print(f"❌ 数据库初始化失败: {str(e)}")
            import traceback
            print(f"🔍 详细错误信息: {traceback.format_exc()}")
    else:
        print("📋 数据库已存在，跳过初始化")
        
        # 验证现有数据库的表结构
        try:
            conn_check = sqlite3.connect(db_path)
            cursor_check = conn_check.cursor()
            cursor_check.execute("SELECT name FROM sqlite_master WHERE type='table'")
            tables = cursor_check.fetchall()
            print(f"📋 现有表: {[table[0] for table in tables]}")
            conn_check.close()
        except Exception as e:
            print(f"⚠️ 无法验证数据库表结构: {str(e)}")

if __name__ == '__main__':
    app = create_app()
    
    # 自动初始化数据库
    auto_init_database()
    
    # 启动定时任务调度器（暂时禁用，避免依赖问题）
    # from scheduler import init_scheduler
    # init_scheduler(app)
    
    # Railway部署时使用PORT环境变量，本地开发使用5001
    port = int(os.environ.get('PORT', 5001))
    app.run(debug=False, host='0.0.0.0', port=port)
