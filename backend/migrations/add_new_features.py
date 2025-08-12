"""
数据库迁移脚本 - 添加新功能支持
包括：每日语录、5色主题系统、番茄钟功能、拖延日记功能
"""

from flask_migrate import Migrate
from models import db
from models.quote import DailyQuote, CustomQuote
from models.theme import UserTheme, ThemeColor, ColorScheme
from models.pomodoro import PomodoroSettings, PomodoroSession, PomodoroStats
from models.procrastination_diary import ProcrastinationDiary, ProcrastinationStats

def upgrade():
    """升级数据库结构"""
    
    # 创建每日语录相关表
    db.create_all()
    
    # 初始化主题颜色数据
    init_theme_colors()
    
    print("数据库迁移完成：新功能表已创建")

def init_theme_colors():
    """初始化主题颜色配置"""
    
    # 检查是否已经初始化
    if ThemeColor.query.first():
        print("主题颜色已初始化，跳过")
        return
    
    # 5色主题配置
    theme_colors = [
        {
            'color_scheme': ColorScheme.PINK,
            'name': '粉色',
            'primary_color': '#FF6B9D',
            'secondary_color': '#FFB3D1',
            'accent_color': '#FF8FA3',
            'background_color': '#FFF5F8',
            'surface_color': '#FFFFFF',
            'description': '温柔浪漫的粉色主题'
        },
        {
            'color_scheme': ColorScheme.BLUE,
            'name': '蓝色',
            'primary_color': '#2196F3',
            'secondary_color': '#64B5F6',
            'accent_color': '#42A5F5',
            'background_color': '#F3F9FF',
            'surface_color': '#FFFFFF',
            'description': '专业稳重的蓝色主题'
        },
        {
            'color_scheme': ColorScheme.PURPLE,
            'name': '紫色',
            'primary_color': '#9C27B0',
            'secondary_color': '#BA68C8',
            'accent_color': '#AB47BC',
            'background_color': '#F8F5FF',
            'surface_color': '#FFFFFF',
            'description': '神秘优雅的紫色主题'
        },
        {
            'color_scheme': ColorScheme.GREEN,
            'name': '绿色',
            'primary_color': '#4CAF50',
            'secondary_color': '#81C784',
            'accent_color': '#66BB6A',
            'background_color': '#F5FFF5',
            'surface_color': '#FFFFFF',
            'description': '清新自然的绿色主题'
        },
        {
            'color_scheme': ColorScheme.YELLOW,
            'name': '黄色',
            'primary_color': '#FF9800',
            'secondary_color': '#FFB74D',
            'accent_color': '#FFA726',
            'background_color': '#FFFBF0',
            'surface_color': '#FFFFFF',
            'description': '活力阳光的黄色主题'
        }
    ]
    
    # 添加主题颜色配置
    for color_config in theme_colors:
        # 创建ThemeColor对象，确保使用枚举对象而不是字符串
        theme_color = ThemeColor(
            color_scheme=color_config['color_scheme'],
            name=color_config['name'],
            primary_color=color_config['primary_color'],
            secondary_color=color_config['secondary_color'],
            accent_color=color_config['accent_color'],
            background_color=color_config['background_color'],
            surface_color=color_config['surface_color'],
            description=color_config['description']
        )
        db.session.add(theme_color)
    
    try:
        db.session.commit()
        print("主题颜色配置初始化完成")
    except Exception as e:
        db.session.rollback()
        print(f"主题颜色初始化失败: {e}")

def downgrade():
    """降级数据库结构"""
    
    # 删除新增的表
    tables_to_drop = [
        'daily_quotes',
        'custom_quotes', 
        'user_themes',
        'theme_colors',
        'pomodoro_settings',
        'pomodoro_sessions',
        'pomodoro_stats'
    ]
    
    for table_name in tables_to_drop:
        try:
            db.engine.execute(f'DROP TABLE IF EXISTS {table_name}')
            print(f"已删除表: {table_name}")
        except Exception as e:
            print(f"删除表 {table_name} 失败: {e}")
    
    print("数据库降级完成")

if __name__ == '__main__':
    # 直接运行此脚本进行迁移
    from app import create_app
    
    app = create_app()
    with app.app_context():
        upgrade()
