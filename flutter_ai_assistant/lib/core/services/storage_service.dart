import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 存储服务 - 管理本地数据存储
class StorageService {
  static late SharedPreferences _prefs;
  static late Box _todoBox;
  static late Box _chatBox;
  static late Box _pomodoroBox;
  
  /// 初始化存储服务
  static Future<void> init() async {
    // 初始化SharedPreferences
    _prefs = await SharedPreferences.getInstance();
    
    // 初始化Hive数据库
    _todoBox = await Hive.openBox('todos');
    _chatBox = await Hive.openBox('chats');
    _pomodoroBox = await Hive.openBox('pomodoro');
  }
  
  /// SharedPreferences实例
  static SharedPreferences get prefs => _prefs;
  
  /// 待办事项数据库
  static Box get todoBox => _todoBox;
  
  /// 聊天记录数据库
  static Box get chatBox => _chatBox;
  
  /// 番茄钟数据库
  static Box get pomodoroBox => _pomodoroBox;
  
  /// 保存字符串值
  static Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }
  
  /// 获取字符串值
  static String? getString(String key) {
    return _prefs.getString(key);
  }
  
  /// 保存整数值
  static Future<void> setInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }
  
  /// 获取整数值
  static int? getInt(String key) {
    return _prefs.getInt(key);
  }
  
  /// 保存布尔值
  static Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }
  
  /// 获取布尔值
  static bool? getBool(String key) {
    return _prefs.getBool(key);
  }
  
  /// 保存字符串列表
  static Future<void> setStringList(String key, List<String> value) async {
    await _prefs.setStringList(key, value);
  }
  
  /// 获取字符串列表
  static List<String>? getStringList(String key) {
    return _prefs.getStringList(key);
  }
  
  /// 删除键值
  static Future<void> remove(String key) async {
    await _prefs.remove(key);
  }
  
  /// 清除所有数据
  static Future<void> clear() async {
    await _prefs.clear();
    await _todoBox.clear();
    await _chatBox.clear();
    await _pomodoroBox.clear();
  }
}
