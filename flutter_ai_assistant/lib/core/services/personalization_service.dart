import 'package:shared_preferences/shared_preferences.dart';

/// 用户个性化设置服务
/// 管理AI助手名字、用户昵称等个性化配置
class PersonalizationService {
  static const String _aiAssistantNameKey = 'ai_assistant_name';
  static const String _userNicknameKey = 'user_nickname';
  
  static PersonalizationService? _instance;
  static PersonalizationService get instance {
    return _instance ??= PersonalizationService._();
  }
  
  PersonalizationService._();

  /// 获取AI助手名字
  Future<String> getAiAssistantName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_aiAssistantNameKey) ?? '小AI';
  }

  /// 设置AI助手名字
  Future<void> setAiAssistantName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_aiAssistantNameKey, name);
  }

  /// 获取用户昵称
  Future<String?> getUserNickname() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNicknameKey);
  }

  /// 设置用户昵称
  Future<void> setUserNickname(String? nickname) async {
    final prefs = await SharedPreferences.getInstance();
    if (nickname != null && nickname.isNotEmpty) {
      await prefs.setString(_userNicknameKey, nickname);
    } else {
      await prefs.remove(_userNicknameKey);
    }
  }

  /// 清除所有个性化设置
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_aiAssistantNameKey);
    await prefs.remove(_userNicknameKey);
  }

  /// 生成个性化问候语
  /// 根据用户昵称和AI助手名字生成合适的问候语
  Future<String> generateGreeting({String? userNickname}) async {
    final aiName = await getAiAssistantName();
    final nickname = userNickname ?? await getUserNickname();
    
    if (nickname != null && nickname.isNotEmpty) {
      return '$aiName：你好，$nickname！有什么我可以帮助你的吗？';
    } else {
      return '$aiName：你好！有什么我可以帮助你的吗？';
    }
  }

  /// 生成个性化回复前缀
  /// 用于AI助手回复时的个性化称呼
  Future<String> generateReplyPrefix({String? userNickname}) async {
    final aiName = await getAiAssistantName();
    final nickname = userNickname ?? await getUserNickname();
    
    if (nickname != null && nickname.isNotEmpty) {
      return '$aiName：$nickname，';
    } else {
      return '$aiName：';
    }
  }
}