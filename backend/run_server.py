"""
后端服务启动脚本
包含开发和生产环境配置
"""

import os
import sys
from app import create_app
from models import db
from flask_migrate import Migrate

def create_development_app():
    """创建开发环境应用"""
    app = create_app()
    
    # 配置开发环境
    app.config['DEBUG'] = True
    app.config['TESTING'] = False
    
    # 数据库迁移
    migrate = Migrate(app, db)
    
    return app

def init_database(app):
    """初始化数据库"""
    with app.app_context():
        try:
            # 导入所有模型确保它们被注册
            from models import init_models
            init_models()
            
            # 创建所有表
            db.create_all()
            print("✅ 数据库表创建成功")
            
            # 运行迁移脚本
            from migrations.add_new_features import init_theme_colors
            init_theme_colors()
            print("✅ 数据库初始化完成")
            
        except Exception as e:
            print(f"❌ 数据库初始化失败: {e}")

def main():
    """主函数"""
    print("🚀 启动拖延症AI助手后端服务...")
    
    # 创建应用
    app = create_development_app()
    
    # 检查是否需要初始化数据库
    if '--init-db' in sys.argv:
        print("🔧 初始化数据库...")
        init_database(app)
        return
    
    # 启动服务
    host = os.getenv('HOST', '0.0.0.0')
    port = int(os.getenv('PORT', 8000))
    
    print(f"📡 服务地址: http://{host}:{port}")
    print("📋 API端点:")
    print("   - 健康检查: /health")
    print("   - 用户认证: /api/auth")
    print("   - 任务管理: /api/tasks")
    print("   - AI助手: /api/ai")
    print("   - 每日语录: /api/quotes")
    print("   - 主题系统: /api/themes")
    print("   - 番茄钟: /api/pomodoro")
    print("\n🎯 按 Ctrl+C 停止服务")
    
    try:
        app.run(
            host=host,
            port=port,
            debug=True,
            threaded=True
        )
    except KeyboardInterrupt:
        print("\n👋 服务已停止")

if __name__ == '__main__':
    main()
