import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 个人资料功能提供者
class ProfileProvider extends ChangeNotifier {
  static const String _userNameKey = 'user_name';
  static const String _userAvatarKey = 'user_avatar';
  static const String _notificationEnabledKey = 'notification_enabled';
  
  String _userName = '小AI用户';
  String _userAvatar = '';
  bool _notificationEnabled = true;

  String get userName => _userName;
  String get userAvatar => _userAvatar;
  bool get notificationEnabled => _notificationEnabled;

  ProfileProvider() {
    _loadProfile();
  }

  /// 更新用户名
  Future<void> updateUserName(String name) async {
    _userName = name;
    await _saveProfile();
    notifyListeners();
  }

  /// 更新用户头像
  Future<void> updateUserAvatar(String avatarPath) async {
    _userAvatar = avatarPath;
    await _saveProfile();
    notifyListeners();
  }

  /// 切换通知设置
  Future<void> toggleNotification() async {
    _notificationEnabled = !_notificationEnabled;
    await _saveProfile();
    notifyListeners();
  }

  /// 获取用户统计信息
  Map<String, dynamic> getUserStats() {
    // 这里可以集成其他Provider的数据
    return {
      'joinDate': '2024-01-01', // 可以从本地存储获取
      'totalTasks': 0, // 可以从TodoProvider获取
      'completedTasks': 0, // 可以从TodoProvider获取
      'focusTime': 0, // 可以从PomodoroProvider获取（分钟）
    };
  }

  /// 从本地存储加载个人资料
  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _userName = prefs.getString(_userNameKey) ?? '小AI用户';
      _userAvatar = prefs.getString(_userAvatarKey) ?? '';
      _notificationEnabled = prefs.getBool(_notificationEnabledKey) ?? true;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  /// 保存个人资料到本地存储
  Future<void> _saveProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString(_userNameKey, _userName);
      await prefs.setString(_userAvatarKey, _userAvatar);
      await prefs.setBool(_notificationEnabledKey, _notificationEnabled);
    } catch (e) {
      debugPrint('Error saving profile: $e');
    }
  }

  /// 重置个人资料
  Future<void> resetProfile() async {
    _userName = '小AI用户';
    _userAvatar = '';
    _notificationEnabled = true;
    
    await _saveProfile();
    notifyListeners();
  }
}
