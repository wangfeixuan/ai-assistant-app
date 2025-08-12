import 'package:flutter/material.dart';

/// 5种颜色主题定义 - 治愈风格配色
/// 奶盐小方、荔枝轻牛乳、百香气泡水、马蹄爹珠椰、莫埃老紫
class ColorThemes {
  // 奶盐小方 - 天空蓝系
  static const Map<String, Color> blue = {
    'primary': Color(0xFF87CEEB),        // 晴空蓝
    'primaryDark': Color(0xFF4682B4),    // 钢蓝
    'primaryLight': Color(0xFFB0E0E6),   // 云朵蓝
    'secondary': Color(0xFF2F4F4F),      // 深石板蓝
    'accent': Color(0xFFF0F8FF),         // 爱丽丝蓝
    'background': Color(0xFFF0F8FF),     // 晨雾白
    'surface': Color(0xFFFFFFFF),
    'onPrimary': Color(0xFFFFFFFF),
    'onSecondary': Color(0xFFFFFFFF),
    'onBackground': Color(0xFF2F4F4F),   // 深海蓝
    'onSurface': Color(0xFF2F4F4F),
    'textLight': Color(0xFF708090),      // 石板灰
    'border': Color(0xFFE6F3FF),
  };

  // 荔枝轻牛乳 - 樱花粉系
  static const Map<String, Color> pink = {
    'primary': Color(0xFFF8BBD9),        // 荔枝粉
    'primaryDark': Color(0xFFDC143C),    // 深红
    'primaryLight': Color(0xFFFFB6C1),   // 樱花粉
    'secondary': Color(0xFF8B1538),      // 玫瑰红
    'accent': Color(0xFFFFF0F5),         // 淡紫红
    'background': Color(0xFFFFF0F5),     // 奶霜白
    'surface': Color(0xFFFFFFFF),
    'onPrimary': Color(0xFFFFFFFF),
    'onSecondary': Color(0xFFFFFFFF),
    'onBackground': Color(0xFF8B1538),   // 玫瑰红
    'onSurface': Color(0xFF8B1538),
    'textLight': Color(0xFFCD919E),      // 玫瑰灰
    'border': Color(0xFFFFE4E1),
  };

  // 莫埃老紫 - 薰衣草紫系
  static const Map<String, Color> purple = {
    'primary': Color(0xFFDDA0DD),        // 梦幻紫
    'primaryDark': Color(0xFF8A2BE2),    // 蓝紫
    'primaryLight': Color(0xFFE6E6FA),   // 薰衣草
    'secondary': Color(0xFF483D8B),      // 深紫蓝
    'accent': Color(0xFFF8F8FF),         // 幽灵白
    'background': Color(0xFFF8F8FF),     // 云朵白
    'surface': Color(0xFFFFFFFF),
    'onPrimary': Color(0xFFFFFFFF),
    'onSecondary': Color(0xFFFFFFFF),
    'onBackground': Color(0xFF483D8B),   // 深紫蓝
    'onSurface': Color(0xFF483D8B),
    'textLight': Color(0xFF9370DB),      // 中紫
    'border': Color(0xFFE6E6FA),
  };

  // 马蹄爹珠椰 - 抹茶绿系
  static const Map<String, Color> green = {
    'primary': Color(0xFF90EE90),        // 清新绿
    'primaryDark': Color(0xFF228B22),    // 森林绿
    'primaryLight': Color(0xFF98FB98),   // 淡绿
    'secondary': Color(0xFF2E8B57),      // 海绿
    'accent': Color(0xFFF0FFF0),         // 蜂蜜露
    'background': Color(0xFFF0FFF0),     // 晨露白
    'surface': Color(0xFFFFFFFF),
    'onPrimary': Color(0xFFFFFFFF),
    'onSecondary': Color(0xFFFFFFFF),
    'onBackground': Color(0xFF2E8B57),   // 森林绿
    'onSurface': Color(0xFF2E8B57),
    'textLight': Color(0xFF8FBC8F),      // 深海绿
    'border': Color(0xFFE0FFE0),
  };

  // 百香气泡水 - 柠檬黄系
  static const Map<String, Color> yellow = {
    'primary': Color(0xFFF0E68C),        // 蜂蜜黄
    'primaryDark': Color(0xFFDAA520),    // 金黄
    'primaryLight': Color(0xFFFFFACD),   // 柠檬绸
    'secondary': Color(0xFF556B2F),      // 橄榄绿
    'accent': Color(0xFFF5FFFA),         // 薄荷奶油
    'background': Color(0xFFFFFFF0),     // 柠檬白
    'surface': Color(0xFFFFFFFF),
    'onPrimary': Color(0xFF556B2F),      // 橄榄绿
    'onSecondary': Color(0xFFFFFFFF),
    'onBackground': Color(0xFF556B2F),   // 橄榄绿
    'onSurface': Color(0xFF556B2F),
    'textLight': Color(0xFFBDB76B),      // 深卡其
    'border': Color(0xFFFFF8DC),
  };

  /// 获取所有可用的主题颜色
  static Map<String, Map<String, Color>> getAllThemes() {
    return {
      'blue': blue,
      'pink': pink,
      'purple': purple,
      'green': green,
      'yellow': yellow,
    };
  }

  /// 根据主题名称创建ThemeData
  static ThemeData createTheme(String themeName) {
    final colors = getAllThemes()[themeName] ?? blue;
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: colors['primary']!,
        primaryContainer: colors['primaryLight']!,
        secondary: colors['secondary']!,
        secondaryContainer: colors['accent']!,
        surface: colors['surface']!,
        onPrimary: colors['onPrimary']!,
        onSecondary: colors['onSecondary']!,
        onSurface: colors['onSurface']!,
        outline: colors['border']!,
      ),
      
      // 字体配置 - 使用系统默认字体
      // fontFamily: 'Inter',
      
      // AppBar主题
      appBarTheme: AppBarTheme(
        backgroundColor: colors['primary'],
        foregroundColor: colors['onPrimary'],
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: colors['onPrimary'],
        ),
      ),
      
      // 卡片主题
      cardTheme: CardThemeData(
        color: colors['surface'],
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // 按钮主题
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors['primary'],
          foregroundColor: colors['onPrimary'],
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      
      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors['surface'],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors['border']!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors['border']!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors['primary']!, width: 2),
        ),
      ),
      
      // 底部导航栏主题
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors['surface'],
        selectedItemColor: colors['primary'],
        unselectedItemColor: colors['textLight'],
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  /// 获取主题显示名称
  static String getThemeDisplayName(String themeName) {
    const names = {
      'blue': '蓝色',
      'pink': '粉色',
      'purple': '紫色',
      'green': '绿色',
      'yellow': '黄色',
    };
    return names[themeName] ?? '蓝色';
  }

  /// 获取主题图标
  static IconData getThemeIcon(String themeName) {
    const icons = {
      'blue': Icons.water_drop,
      'pink': Icons.favorite,
      'purple': Icons.auto_awesome,
      'green': Icons.eco,
      'yellow': Icons.wb_sunny,
    };
    return icons[themeName] ?? Icons.water_drop;
  }
}
