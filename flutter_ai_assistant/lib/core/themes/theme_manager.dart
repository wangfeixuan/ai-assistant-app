import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'color_themes.dart';

/// 主题管理器 - 管理5种颜色主题的切换和持久化
class ThemeManager extends ChangeNotifier {
  static const String _themeKey = 'selected_color_theme';
  
  String _currentThemeName = 'blue';
  late ThemeData _currentTheme;
  bool _isInitialized = false;
  bool _isLoading = false;
  
  ThemeManager() {
    _currentTheme = ColorThemes.createTheme(_currentThemeName);
    _initializeAsync();
  }
  
  /// 异步初始化（避免在构造函数中进行异步操作）
  Future<void> _initializeAsync() async {
    if (_isLoading) return;
    _isLoading = true;
    
    try {
      await _loadSavedTheme();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Theme initialization error: $e');
      // 使用默认主题继续运行
      _currentThemeName = 'blue';
      _currentTheme = ColorThemes.createTheme('blue');
    } finally {
      _isLoading = false;
      if (!_isInitialized) {
        _isInitialized = true;
        notifyListeners();
      }
    }
  }
  
  /// 是否已初始化
  bool get isInitialized => _isInitialized;
  
  /// 当前主题名称
  String get currentThemeName => _currentThemeName;
  
  /// 当前主题数据
  ThemeData get currentTheme => _currentTheme;
  
  /// 获取所有可用主题
  List<String> get availableThemes => ['blue', 'pink', 'purple', 'green', 'yellow'];
  
  /// 切换主题
  Future<void> switchTheme(String themeName) async {
    debugPrint('🔧 ThemeManager.switchTheme 被调用: $themeName');
    debugPrint('🔧 当前主题: $_currentThemeName');
    debugPrint('🔧 可用主题: $availableThemes');
    debugPrint('🔧 是否已初始化: $_isInitialized');
    
    if (!availableThemes.contains(themeName)) {
      debugPrint('❌ 无效的主题名称: $themeName');
      return;
    }
    
    if (_currentThemeName == themeName) {
      debugPrint('⚠️ 主题已经是选中状态: $themeName');
      return;
    }
    
    try {
      debugPrint('🔧 开始应用新主题: $themeName');
      final oldTheme = _currentThemeName;
      _currentThemeName = themeName;
      _currentTheme = ColorThemes.createTheme(themeName);
      
      debugPrint('🔧 主题对象创建成功，准备通知监听者');
      
      // 先通知UI更新（确保界面立即响应）
      notifyListeners();
      debugPrint('🔧 已通知监听者，UI应该更新了');
      
      // 然后异步保存到本地存储
      try {
        await _saveTheme(themeName);
        debugPrint('🔧 主题保存到本地存储成功');
      } catch (saveError) {
        debugPrint('⚠️ 保存主题到本地存储失败: $saveError');
        // 即使保存失败，主题切换仍然有效
      }
      
      debugPrint('✅ 主题切换完成: $oldTheme -> $themeName');
    } catch (e) {
      debugPrint('❌ 主题切换过程中发生错误: $e');
      // 如果切换失败，回滚到之前的主题
      // 注意：这里不应该再次调用notifyListeners，因为状态没有改变
      rethrow; // 重新抛出异常让调用者知道
    }
  }
  
  /// 从本地存储加载保存的主题
  Future<void> _loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);
      
      if (savedTheme != null && availableThemes.contains(savedTheme)) {
        if (_currentThemeName != savedTheme) {
          _currentThemeName = savedTheme;
          _currentTheme = ColorThemes.createTheme(savedTheme);
          
          // 只有在主题确实改变时才通知监听者
          if (_isInitialized) {
            notifyListeners();
          }
        }
        debugPrint('Loaded saved theme: $savedTheme');
      } else {
        debugPrint('No valid saved theme found, using default: $_currentThemeName');
      }
    } catch (e) {
      debugPrint('Error loading saved theme: $e');
    }
  }
  
  /// 保存主题到本地存储
  Future<void> _saveTheme(String themeName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, themeName);
      debugPrint('Theme saved: $themeName');
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }
  
  /// 获取主题显示名称
  String getThemeDisplayName(String themeName) {
    return ColorThemes.getThemeDisplayName(themeName);
  }
  
  /// 获取主题图标
  IconData getThemeIcon(String themeName) {
    return ColorThemes.getThemeIcon(themeName);
  }
  
  /// 获取主题颜色（用于颜色选择器显示）
  Color getThemeColor(String themeName) {
    final colors = ColorThemes.getAllThemes()[themeName];
    return colors?['primary'] ?? Colors.blue;
  }
}
