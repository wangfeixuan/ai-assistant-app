"""
主题配置模型
定义用户界面主题相关的数据结构
"""

from datetime import datetime
from flask_sqlalchemy import SQLAlchemy
from enum import Enum
from . import db

class ThemeType(Enum):
    """主题类型枚举"""
    BUSINESS = "business"  # 商务风
    CUTE = "cute"         # 可爱风

class ColorScheme(Enum):
    """颜色方案枚举"""
    PINK = "pink"       # 粉色
    BLUE = "blue"       # 蓝色
    PURPLE = "purple"   # 紫色
    GREEN = "green"     # 绿色
    YELLOW = "yellow"   # 黄色

class Theme(db.Model):
    """主题配置模型"""
    
    __tablename__ = 'themes'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(50), unique=True, nullable=False)
    theme_type = db.Column(db.Enum(ThemeType), nullable=False)
    
    # 主题配置（JSON格式存储）
    color_config = db.Column(db.JSON, nullable=False)  # 颜色配置
    font_config = db.Column(db.JSON, nullable=True)    # 字体配置
    icon_config = db.Column(db.JSON, nullable=True)    # 图标配置
    animation_config = db.Column(db.JSON, nullable=True)  # 动画配置
    
    # 主题描述
    description = db.Column(db.Text, nullable=True)
    preview_image_url = db.Column(db.String(255), nullable=True)
    
    # 状态
    is_active = db.Column(db.Boolean, default=True)
    is_premium = db.Column(db.Boolean, default=False)  # 是否为付费主题
    
    # 时间戳
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def __init__(self, name, theme_type, color_config, description=None):
        self.name = name
        self.theme_type = theme_type
        self.color_config = color_config
        self.description = description
    
    @classmethod
    def get_default_themes(cls):
        """获取默认主题配置"""
        return [
            {
                'name': 'business_default',
                'theme_type': ThemeType.BUSINESS,
                'description': '商务风格 - 专业简洁的蓝色主题',
                'color_config': {
                    'primary': '#2563EB',      # 主色调 - 蓝色
                    'secondary': '#1E40AF',    # 次要色 - 深蓝
                    'accent': '#3B82F6',       # 强调色 - 亮蓝
                    'background': '#FFFFFF',   # 背景色 - 白色
                    'surface': '#F8FAFC',      # 表面色 - 浅灰
                    'text_primary': '#1F2937', # 主要文字 - 深灰
                    'text_secondary': '#6B7280', # 次要文字 - 中灰
                    'border': '#E5E7EB',       # 边框色 - 浅灰
                    'success': '#10B981',      # 成功色 - 绿色
                    'warning': '#F59E0B',      # 警告色 - 橙色
                    'error': '#EF4444'         # 错误色 - 红色
                },
                'font_config': {
                    'primary_font': 'Inter, -apple-system, BlinkMacSystemFont, sans-serif',
                    'heading_font': 'Inter, -apple-system, BlinkMacSystemFont, sans-serif',
                    'mono_font': 'SF Mono, Monaco, monospace'
                },
                'animation_config': {
                    'transition_duration': '200ms',
                    'easing': 'cubic-bezier(0.4, 0, 0.2, 1)',
                    'hover_scale': '1.02'
                }
            },
            {
                'name': 'cute_default',
                'theme_type': ThemeType.CUTE,
                'description': '可爱风格 - 温馨的马卡龙色系主题',
                'color_config': {
                    'primary': '#F472B6',      # 主色调 - 粉色
                    'secondary': '#A78BFA',    # 次要色 - 紫色
                    'accent': '#34D399',       # 强调色 - 薄荷绿
                    'background': '#FEF7FF',   # 背景色 - 淡粉
                    'surface': '#FDF2F8',      # 表面色 - 浅粉
                    'text_primary': '#831843', # 主要文字 - 深粉
                    'text_secondary': '#BE185D', # 次要文字 - 中粉
                    'border': '#F9A8D4',       # 边框色 - 粉色
                    'success': '#6EE7B7',      # 成功色 - 浅绿
                    'warning': '#FCD34D',      # 警告色 - 柠檬黄
                    'error': '#FB7185'         # 错误色 - 浅红
                },
                'font_config': {
                    'primary_font': 'Nunito, -apple-system, BlinkMacSystemFont, sans-serif',
                    'heading_font': 'Nunito, -apple-system, BlinkMacSystemFont, sans-serif',
                    'mono_font': 'SF Mono, Monaco, monospace'
                },
                'icon_config': {
                    'style': 'rounded',
                    'cat_elements': True,
                    'dog_elements': True,
                    'sparkle_effects': True
                },
                'animation_config': {
                    'transition_duration': '300ms',
                    'easing': 'cubic-bezier(0.68, -0.55, 0.265, 1.55)',
                    'hover_scale': '1.05',
                    'bounce_effect': True
                }
            }
        ]
    
    @classmethod
    def create_default_themes(cls):
        """创建默认主题"""
        default_themes = cls.get_default_themes()
        
        for theme_data in default_themes:
            existing_theme = cls.query.filter_by(name=theme_data['name']).first()
            if not existing_theme:
                theme = cls(
                    name=theme_data['name'],
                    theme_type=theme_data['theme_type'],
                    color_config=theme_data['color_config'],
                    description=theme_data['description']
                )
                theme.font_config = theme_data.get('font_config')
                theme.icon_config = theme_data.get('icon_config')
                theme.animation_config = theme_data.get('animation_config')
                
                db.session.add(theme)
        
        db.session.commit()
    
    def to_dict(self):
        """转换为字典格式"""
        return {
            'id': self.id,
            'name': self.name,
            'theme_type': self.theme_type.value,
            'color_config': self.color_config,
            'font_config': self.font_config,
            'icon_config': self.icon_config,
            'animation_config': self.animation_config,
            'description': self.description,
            'preview_image_url': self.preview_image_url,
            'is_active': self.is_active,
            'is_premium': self.is_premium,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }
    
    def __repr__(self):
        return f'<Theme {self.name} ({self.theme_type.value})>'

class UserTheme(db.Model):
    """用户主题设置模型"""
    __tablename__ = 'user_themes'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    color_scheme = db.Column(db.Enum(ColorScheme), nullable=False, default=ColorScheme.BLUE)
    is_dark_mode = db.Column(db.Boolean, default=False)
    custom_settings = db.Column(db.JSON, nullable=True)  # 自定义设置
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # 关系 - 使用字符串形式避免循环导入
    
    # 索引
    __table_args__ = (
        db.Index('idx_user_theme', 'user_id'),
    )
    
    def __repr__(self):
        return f'<UserTheme {self.user_id}-{self.color_scheme.value}>'
    
    def to_dict(self):
        """转换为字典格式"""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'color_scheme': self.color_scheme.value,
            'is_dark_mode': self.is_dark_mode,
            'custom_settings': self.custom_settings or {},
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }

class ThemeColor(db.Model):
    """主题颜色配置模型"""
    __tablename__ = 'theme_colors'
    
    id = db.Column(db.Integer, primary_key=True)
    color_scheme = db.Column(db.Enum(ColorScheme), nullable=False, unique=True)
    name = db.Column(db.String(50), nullable=False)
    primary_color = db.Column(db.String(7), nullable=False)  # #RRGGBB
    secondary_color = db.Column(db.String(7), nullable=False)
    accent_color = db.Column(db.String(7), nullable=False)
    background_color = db.Column(db.String(7), nullable=False)
    surface_color = db.Column(db.String(7), nullable=False)
    description = db.Column(db.Text, nullable=True)
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def __repr__(self):
        return f'<ThemeColor {self.color_scheme.value}>'
    
    def to_dict(self):
        """转换为字典格式"""
        return {
            'id': self.id,
            'color_scheme': self.color_scheme.value,
            'name': self.name,
            'primary': self.primary_color,
            'secondary': self.secondary_color,
            'accent': self.accent_color,
            'background': self.background_color,
            'surface': self.surface_color,
            'description': self.description,
            'is_active': self.is_active,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }
