#!/usr/bin/env python3
"""
数据库初始化脚本
用于创建所有必要的数据库表和初始数据
"""

import os
import sys
from datetime import datetime

# 添加项目根目录到路径
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app import create_app
from models import db, init_models

def init_database():
    """初始化数据库"""
    print("开始初始化数据库...")
    
    # 创建应用实例
    app = create_app()
    
    with app.app_context():
        # 导入所有模型
        models = init_models()
        print(f"已导入 {len(models)} 个数据模型")
        
        try:
            # 删除所有表（如果存在）
            print("删除现有表...")
            db.drop_all()
            
            # 创建所有表
            print("创建数据库表...")
            db.create_all()
            
            # 创建默认主题数据
            create_default_themes()
            
            # 提交更改
            db.session.commit()
            print("数据库初始化完成！")
            
        except Exception as e:
            print(f"创建表时出错: {str(e)}")
            # 如果出错，尝试手动创建基本表
            create_basic_tables()
            db.session.commit()
            print("使用基本表结构初始化完成！")

def create_default_themes():
    """创建默认主题数据"""
    from models.theme import Theme, ThemeColor
    
    print("创建默认主题...")
    
    # 商务主题
    business_theme = Theme(
        name='business',
        display_name='商务风格',
        description='专业简洁的商务风格主题',
        is_default=True,
        is_active=True
    )
    db.session.add(business_theme)
    db.session.flush()  # 获取ID
    
    # 商务主题颜色
    business_colors = [
        ThemeColor(theme_id=business_theme.id, color_name='primary', color_value='#2563eb'),
        ThemeColor(theme_id=business_theme.id, color_name='secondary', color_value='#64748b'),
        ThemeColor(theme_id=business_theme.id, color_name='accent', color_value='#0ea5e9'),
        ThemeColor(theme_id=business_theme.id, color_name='background', color_value='#ffffff'),
        ThemeColor(theme_id=business_theme.id, color_name='surface', color_value='#f8fafc'),
        ThemeColor(theme_id=business_theme.id, color_name='text_primary', color_value='#1e293b'),
        ThemeColor(theme_id=business_theme.id, color_name='text_secondary', color_value='#64748b'),
    ]
    
    for color in business_colors:
        db.session.add(color)
    
    # 可爱主题
    cute_theme = Theme(
        name='cute',
        display_name='可爱风格',
        description='温馨可爱的粉色系主题',
        is_default=False,
        is_active=True
    )
    db.session.add(cute_theme)
    db.session.flush()  # 获取ID
    
    # 可爱主题颜色
    cute_colors = [
        ThemeColor(theme_id=cute_theme.id, color_name='primary', color_value='#ec4899'),
        ThemeColor(theme_id=cute_theme.id, color_name='secondary', color_value='#f472b6'),
        ThemeColor(theme_id=cute_theme.id, color_name='accent', color_value='#fb7185'),
        ThemeColor(theme_id=cute_theme.id, color_name='background', color_value='#fdf2f8'),
        ThemeColor(theme_id=cute_theme.id, color_name='surface', color_value='#ffffff'),
        ThemeColor(theme_id=cute_theme.id, color_name='text_primary', color_value='#881337'),
        ThemeColor(theme_id=cute_theme.id, color_name='text_secondary', color_value='#be185d'),
    ]
    
    for color in cute_colors:
        db.session.add(color)
    
    print(f"已创建 {len([business_theme, cute_theme])} 个默认主题")

def create_basic_tables():
    """手动创建基本表结构（备用方案）"""
    print("使用手动方式创建基本表...")
    
    # 使用SQLAlchemy 2.x兼容的方法
    from sqlalchemy import text
    
    # 手动创建用户表
    with db.engine.connect() as conn:
        conn.execute(text("""
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
        """))
        
        # 创建用户名和邮箱索引
        try:
            conn.execute(text("CREATE INDEX IF NOT EXISTS idx_users_username ON users (username)"))
            conn.execute(text("CREATE INDEX IF NOT EXISTS idx_users_email ON users (email)"))
        except:
            pass  # 索引可能已存在
        
        conn.commit()
    
    print("基本表创建完成")

if __name__ == '__main__':
    try:
        init_database()
        print("\n✅ 数据库初始化成功！")
        print("现在您可以正常使用登录和注册功能了。")
    except Exception as e:
        print(f"\n❌ 数据库初始化失败: {str(e)}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
