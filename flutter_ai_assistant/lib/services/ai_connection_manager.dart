import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../core/config.dart';

/// AI连接管理器 - 单例模式，管理应用内AI连接状态
class AIConnectionManager extends ChangeNotifier {
  static AIConnectionManager? _instance;
  static AIConnectionManager get instance {
    _instance ??= AIConnectionManager._internal();
    return _instance!;
  }

  AIConnectionManager._internal();

  // 连接状态
  bool _isConnected = false;
  String _connectionMessage = '未连接';
  String _aiModel = 'unknown';
  DateTime? _lastCheckTime;
  Timer? _heartbeatTimer;

  // 连接状态getter
  bool get isConnected => _isConnected;
  String get connectionMessage => _connectionMessage;
  String get aiModel => _aiModel;
  DateTime? get lastCheckTime => _lastCheckTime;

  static const String _baseUrl = AppConfig.baseUrl;
  static const Duration _heartbeatInterval = Duration(minutes: 5); // 5分钟心跳检查
  static const Duration _cacheTimeout = Duration(minutes: 2); // 2分钟缓存有效期

  /// 初始化连接管理器（应用启动时调用）
  Future<void> initialize() async {
    debugPrint('🔌 初始化AI连接管理器');
    await _checkConnection();
    _startHeartbeat();
  }

  /// 获取连接状态（带缓存）
  Future<Map<String, dynamic>> getConnectionStatus({bool forceRefresh = false}) async {
    // 如果有缓存且未过期，直接返回缓存结果
    if (!forceRefresh && 
        _lastCheckTime != null && 
        DateTime.now().difference(_lastCheckTime!) < _cacheTimeout) {
      debugPrint('📋 使用缓存的AI连接状态: $_isConnected');
      return {
        'isConnected': _isConnected,
        'model': _aiModel,
        'message': _connectionMessage,
        'fromCache': true,
      };
    }

    // 否则检查连接状态
    await _checkConnection();
    return {
      'isConnected': _isConnected,
      'model': _aiModel,
      'message': _connectionMessage,
      'fromCache': false,
    };
  }

  /// 检查AI连接状态
  Future<void> _checkConnection() async {
    try {
      debugPrint('🔍 检查AI连接状态...');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/api/ai-simple/test'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final wasConnected = _isConnected;
        
        _isConnected = data['success'] == true;
        _aiModel = data['model'] ?? 'unknown';
        _connectionMessage = data['message'] ?? data['response'] ?? 'AI服务已连接';
        _lastCheckTime = DateTime.now();

        // 只有状态真正改变时才通知监听器
        if (wasConnected != _isConnected) {
          debugPrint('🔄 AI连接状态变化: $wasConnected -> $_isConnected');
          notifyListeners();
        }
        
        debugPrint('✅ AI连接检查完成: $_isConnected (模型: $_aiModel)');
      } else {
        _updateConnectionStatus(false, 'AI服务连接失败 (${response.statusCode})');
      }
    } catch (e) {
      _updateConnectionStatus(false, 'AI服务连接错误: $e');
    }
  }

  /// 更新连接状态
  void _updateConnectionStatus(bool connected, String message) {
    final wasConnected = _isConnected;
    _isConnected = connected;
    _connectionMessage = message;
    _lastCheckTime = DateTime.now();
    
    if (wasConnected != _isConnected) {
      debugPrint('🔄 AI连接状态更新: $wasConnected -> $_isConnected');
      notifyListeners();
    }
  }

  /// 启动心跳检查
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      debugPrint('💓 AI连接心跳检查');
      _checkConnection();
    });
    debugPrint('💓 AI连接心跳已启动 (间隔: ${_heartbeatInterval.inMinutes}分钟)');
  }

  /// 停止心跳检查
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    debugPrint('💓 AI连接心跳已停止');
  }

  /// 手动刷新连接状态
  Future<void> refresh() async {
    debugPrint('🔄 手动刷新AI连接状态');
    await _checkConnection();
  }

  /// 重置连接状态
  void reset() {
    debugPrint('🔄 重置AI连接状态');
    _isConnected = false;
    _connectionMessage = '未连接';
    _aiModel = 'unknown';
    _lastCheckTime = null;
    notifyListeners();
  }

  /// 应用进入后台时暂停心跳
  void pauseHeartbeat() {
    debugPrint('⏸️ 应用进入后台，暂停AI心跳检查');
    _stopHeartbeat();
  }

  /// 应用回到前台时恢复心跳
  void resumeHeartbeat() {
    debugPrint('▶️ 应用回到前台，恢复AI心跳检查');
    _startHeartbeat();
    // 立即检查一次连接状态
    _checkConnection();
  }

  @override
  void dispose() {
    _stopHeartbeat();
    super.dispose();
  }
}
