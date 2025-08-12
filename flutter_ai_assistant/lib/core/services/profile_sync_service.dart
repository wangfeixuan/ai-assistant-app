import 'dart:async';

/// 个人资料同步服务
/// 用于在个人资料修改后通知其他页面实时更新
class ProfileSyncService {
  static final ProfileSyncService _instance = ProfileSyncService._internal();
  factory ProfileSyncService() => _instance;
  ProfileSyncService._internal();

  // AI助手名称变化的流控制器
  final StreamController<String> _aiNameController = StreamController<String>.broadcast();
  
  // 用户昵称变化的流控制器
  final StreamController<String> _userNicknameController = StreamController<String>.broadcast();

  /// AI助手名称变化流
  Stream<String> get aiNameStream => _aiNameController.stream;
  
  /// 用户昵称变化流
  Stream<String> get userNicknameStream => _userNicknameController.stream;

  /// 通知AI助手名称已更新
  void notifyAINameChanged(String newName) {
    _aiNameController.add(newName);
  }

  /// 通知用户昵称已更新
  void notifyUserNicknameChanged(String newNickname) {
    _userNicknameController.add(newNickname);
  }

  /// 释放资源
  void dispose() {
    _aiNameController.close();
    _userNicknameController.close();
  }
}
