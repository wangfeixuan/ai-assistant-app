#!/usr/bin/env python3
"""
简单数据库初始化脚本
直接使用SQL创建必要的用户表
"""

import sqlite3
import os

def init_simple_database():
    """直接使用sqlite3创建数据库"""
    db_path = 'procrastination_ai.db'
    
    # 删除现有数据库文件
    if os.path.exists(db_path):
        os.remove(db_path)
        print(f"已删除现有数据库文件: {db_path}")
    
    # 创建新的数据库连接
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    print("开始创建数据库表...")
    
    # 创建用户表
    cursor.execute("""
        CREATE TABLE users (
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
    print("✅ 用户表创建成功")
    
    # 创建任务表
    cursor.execute("""
        CREATE TABLE tasks (
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
    print("✅ 任务表创建成功")
    
    # 创建主题表
    cursor.execute("""
        CREATE TABLE themes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name VARCHAR(50) UNIQUE NOT NULL,
            display_name VARCHAR(100) NOT NULL,
            description TEXT,
            is_default BOOLEAN DEFAULT 0,
            is_active BOOLEAN DEFAULT 1,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    """)
    print("✅ 主题表创建成功")
    
    # 插入默认主题数据
    cursor.execute("""
        INSERT INTO themes (name, display_name, description, is_default, is_active)
        VALUES 
        ('business', '商务风格', '专业简洁的商务风格主题', 1, 1),
        ('cute', '可爱风格', '温馨可爱的粉色系主题', 0, 1)
    """)
    print("✅ 默认主题数据插入成功")
    
    # 创建索引
    cursor.execute("CREATE INDEX idx_users_username ON users (username)")
    cursor.execute("CREATE INDEX idx_users_email ON users (email)")
    cursor.execute("CREATE INDEX idx_tasks_user_id ON tasks (user_id)")
    print("✅ 索引创建成功")
    
    # 提交更改并关闭连接
    conn.commit()
    conn.close()
    
    print(f"\n✅ 数据库初始化完成！数据库文件: {db_path}")
    
    # 验证数据库
    verify_database(db_path)

def verify_database(db_path):
    """验证数据库是否创建成功"""
    print("\n验证数据库...")
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # 检查表是否存在
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
    tables = cursor.fetchall()
    print(f"数据库中的表: {[table[0] for table in tables]}")
    
    # 检查主题数据
    cursor.execute("SELECT name, display_name FROM themes")
    themes = cursor.fetchall()
    print(f"默认主题: {themes}")
    
    conn.close()
    print("✅ 数据库验证完成")

if __name__ == '__main__':
    try:
        init_simple_database()
        print("\n🎉 数据库初始化成功！现在您可以正常使用登录和注册功能了。")
    except Exception as e:
        print(f"\n❌ 数据库初始化失败: {str(e)}")
        import traceback
        traceback.print_exc()
