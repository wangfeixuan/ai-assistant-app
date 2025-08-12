import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../core/services/in_app_notification_service.dart';

/// 本地通知服务
/// 专注于本地通知功能，支持任务提醒、番茄钟通知等
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FlutterLocalNotificationsPlugin? _localNotifications;
  InAppNotificationService? _inAppService;
  BuildContext? _context;
  
  bool _isInitialized = false;
  bool _isAppInForeground = true;

  /// 初始化本地通知服务
  Future<void> initialize(BuildContext? context) async {
    if (_isInitialized) return;

    try {
      _context = context;
      
      // 初始化本地通知
      _localNotifications = FlutterLocalNotificationsPlugin();
      
      // 初始化应用内通知服务
      _inAppService = InAppNotificationService();
      
      // 配置本地通知
      await _configureLocalNotifications();
      
      // 请求通知权限
      await _requestPermissions();
      
      _isInitialized = true;
      debugPrint('🔔 本地通知服务初始化成功');
      
    } catch (e) {
      debugPrint('❌ 本地通知服务初始化失败: $e');
    }
  }

  /// 请求通知权限
  Future<void> _requestPermissions() async {
    if (_localNotifications == null) return;

    try {
      // 请求Android通知权限
      final androidPlugin = _localNotifications!.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
      }
      
      // 请求iOS通知权限
      final iosPlugin = _localNotifications!.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
      
      debugPrint('🔔 通知权限请求完成');
    } catch (e) {
      debugPrint('❌ 请求通知权限失败: $e');
    }
  }

  /// 配置本地通知
  Future<void> _configureLocalNotifications() async {
    if (_localNotifications == null) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications!.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    debugPrint('🔔 本地通知配置完成');
  }

  /// 设置应用前后台状态
  void setAppLifecycleState(bool isInForeground) {
    _isAppInForeground = isInForeground;
    debugPrint('📱 应用状态更新: ${isInForeground ? "前台" : "后台"}');
  }
  
  /// 获取应用是否在前台
  bool get isAppInForeground => _isAppInForeground;
  
  /// 显示番茄钟完成通知
  Future<void> showPomodoroCompleteNotification({
    required String type,
    required int sessionCount,
  }) async {
    if (_isAppInForeground && _context != null && _inAppService != null) {
      // 应用在前台，显示应用内通知
      await _inAppService!.showPomodoroInAppNotification(
        context: _context!,
        type: type,
        sessionCount: sessionCount,
      );
      return;
    }
    
    // 应用在后台，显示系统通知
    String title;
    String body;
    
    switch (type) {
      case 'work':
        title = '🍅 专注时间结束！';
        body = '恭喜完成第${sessionCount}个番茄钟，该休息一下了～';
        break;
      case 'shortBreak':
        title = '☕ 短休息结束！';
        body = '休息时间到，准备开始下一个番茄钟吧！';
        break;
      case 'longBreak':
        title = '🌴 长休息结束！';
        body = '充分休息后，让我们继续保持专注！';
        break;
      default:
        title = '🍅 番茄钟提醒';
        body = '时间到！';
    }
    
    await _showSystemNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: title,
      body: body,
      payload: json.encode({
        'type': 'pomodoro',
        'pomodoroType': type,
        'sessionCount': sessionCount,
      }),
    );
  }
  
  /// 显示任务提醒通知
  Future<void> showTaskReminderNotification({
    required String title,
    required String body,
    String? taskId,
  }) async {
    if (_isAppInForeground && _context != null && _inAppService != null) {
      // 应用在前台，显示应用内通知
      await _inAppService!.showInAppNotification(
        context: _context!,
        title: title,
        message: body,
        emoji: '⏰',
      );
      return;
    }
    
    // 应用在后台，显示系统通知
    await _showSystemNotification(
      id: taskId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      title: title,
      body: body,
      payload: json.encode({
        'type': 'task_reminder',
        'taskId': taskId,
      }),
    );
  }
  
  /// 显示系统通知
  Future<void> _showSystemNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (_localNotifications == null) return;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'todo_reminders',
      '任务提醒',
      channelDescription: '待办任务和番茄钟提醒',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _localNotifications!.show(
        id,
        title,
        body,
        platformDetails,
        payload: payload,
      );
      debugPrint('🔔 系统通知已发送: $title');
    } catch (e) {
      debugPrint('❌ 发送系统通知失败: $e');
    }
  }

  /// 处理通知点击
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = json.decode(response.payload!);
        _handleNotificationTap(data);
      } catch (e) {
        debugPrint('❌ 解析通知数据失败: $e');
      }
    }
  }

  /// 处理通知点击事件
  void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    debugPrint('🔔 处理通知点击: type=$type');
    
    // 根据通知类型处理点击事件
    switch (type) {
      case 'pomodoro':
        // 番茄钟通知点击，可以跳转到番茄钟页面
        debugPrint('🍅 番茄钟通知被点击');
        break;
      case 'task_reminder':
        // 任务提醒通知点击，可以跳转到待办页面
        final taskId = data['taskId'] as String?;
        debugPrint('📝 任务提醒通知被点击: taskId=$taskId');
        break;
      default:
        debugPrint('🔔 未知类型通知被点击');
    }
  }
  
  /// 取消指定ID的通知
  Future<void> cancelNotification(int id) async {
    if (_localNotifications == null) return;
    
    try {
      await _localNotifications!.cancel(id);
      debugPrint('🔕 已取消通知: $id');
    } catch (e) {
      debugPrint('❌ 取消通知失败: $e');
    }
  }
  
  /// 取消所有通知
  Future<void> cancelAllNotifications() async {
    if (_localNotifications == null) return;
    
    try {
      await _localNotifications!.cancelAll();
      debugPrint('🔕 已取消所有通知');
    } catch (e) {
      debugPrint('❌ 取消所有通知失败: $e');
    }
  }
  
  /// 检查是否已初始化
  bool get isInitialized => _isInitialized;
}
