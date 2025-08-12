import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'in_app_notification_service.dart';
import 'personalization_service.dart';

/// 本地通知服务 - App Store友好的推送方案
/// 支持番茄钟提醒、任务通知、每日打卡等功能
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final InAppNotificationService _inAppService = InAppNotificationService();
  bool _initialized = false;
  BuildContext? _context;

  /// 初始化通知服务
  Future<void> initialize() async {
    if (_initialized) return;

    // 初始化时区数据
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));

    // Android初始化设置
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS初始化设置
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: null,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
    if (kDebugMode) {
      print('✅ 本地通知服务初始化成功');
    }
  }

  /// 设置应用上下文（用于应用内通知）
  void setContext(BuildContext context) {
    _context = context;
  }

  /// 处理通知点击事件
  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      print('📱 通知被点击: ${response.payload}');
    }
    // TODO: 根据payload跳转到对应页面
  }

  /// 检查应用是否在前台
  bool get isAppInForeground {
    return _isAppInForeground;
  }

  bool get _isAppInForeground {
    final hasContext = _context != null;
    final lifecycleState = WidgetsBinding.instance.lifecycleState;
    final isResumed = lifecycleState == AppLifecycleState.resumed;
    
    if (kDebugMode) {
      print('🔍 应用状态检查: hasContext=$hasContext, lifecycleState=$lifecycleState, isResumed=$isResumed');
    }
    
    // 检查上下文是否有效
    if (!hasContext) {
      if (kDebugMode) {
        print('❌ 没有有效的BuildContext，无法显示应用内通知');
      }
      return false;
    }
    
    // 检查上下文是否仍然mounted
    try {
      final overlay = Overlay.of(_context!);
      if (overlay == null) {
        if (kDebugMode) {
          print('❌ Overlay不可用，无法显示应用内通知');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 上下文已失效: $e');
      }
      return false;
    }
    
    return true;
  }

  /// 格式化个性化通知内容
  /// 格式："昵称，通知内容"
  Future<String> _formatPersonalizedContent(String content) async {
    try {
      final nickname = await PersonalizationService.instance.getUserNickname();
      if (nickname != null && nickname.isNotEmpty) {
        return '$nickname，$content';
      }
      return content;
    } catch (e) {
      if (kDebugMode) {
        print('获取用户昵称失败: $e');
      }
      return content;
    }
  }

  /// 请求通知权限
  Future<bool> requestPermissions() async {
    final result = await _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    return result ?? false;
  }

  /// 检查通知权限状态
  Future<bool> checkPermissions() async {
    final result = await _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.checkPermissions();
    return result?.isAlertEnabled ?? false;
  }

  /// 引导用户开启通知权限
  Future<bool> requestPermissionsWithDialog(BuildContext context) async {
    final hasPermission = await checkPermissions();
    if (hasPermission) return true;

    final shouldRequest = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔔 开启通知权限'),
        content: const Text('为了及时提醒您完成任务，请允许应用发送通知。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('稍后'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('开启'),
          ),
        ],
      ),
    );

    if (shouldRequest == true) {
      return await requestPermissions();
    }

    return false;
  }

  /// 显示即时通知
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationDetails? notificationDetails,
  }) async {
    await _notifications.show(
      id,
      title,
      body,
      notificationDetails ?? _getDefaultNotificationDetails(),
      payload: payload,
    );
  }

  /// 番茄钟完成通知（智能选择系统通知或应用内通知）
  Future<void> showPomodoroCompleteNotification({
    required String type, // 'work', 'shortBreak', 'longBreak'
    required int sessionCount,
  }) async {
    if (kDebugMode) {
      print('🔔 开始显示番茄钟完成通知: type=$type, sessionCount=$sessionCount');
    }
    
    // 如果应用在前台，显示应用内通知
    if (_isAppInForeground && _context != null) {
      if (kDebugMode) {
        print('📱 应用在前台，显示应用内通知');
      }
      try {
        await _inAppService.showPomodoroInAppNotification(
          context: _context!,
          type: type,
          sessionCount: sessionCount,
        );
        if (kDebugMode) {
          print('✅ 应用内通知显示成功');
        }
        return;
      } catch (e) {
        if (kDebugMode) {
          print('❌ 应用内通知显示失败: $e');
        }
        // 如果应用内通知失败，继续显示系统通知
      }
    } else {
      if (kDebugMode) {
        print('📱 应用不在前台或无上下文，显示系统通知');
      }
    }

    // 否则显示系统通知
    String title, baseBody;
    
    switch (type) {
      case 'work':
        title = '🍅 专注时间结束！';
        baseBody = '恭喜完成第${sessionCount}个番茄钟，该休息一下了～';
        break;
      case 'shortBreak':
        title = '⏰ 短休息结束！';
        baseBody = '休息完毕，准备开始下一个专注时段吧！';
        break;
      case 'longBreak':
        title = '🎉 长休息结束！';
        baseBody = '充分休息后，让我们继续高效工作吧！';
        break;
      default:
        title = '⏰ 番茄钟提醒';
        baseBody = '时间到了！';
    }

    // 格式化个性化内容
    final body = await _formatPersonalizedContent(baseBody);

    await showNotification(
      id: 1001,
      title: title,
      body: body,
      payload: 'pomodoro_$type',
      notificationDetails: _getPomodoroNotificationDetails(),
    );
  }

  /// 任务截止提醒
  Future<void> showTaskDeadlineNotification({
    required String taskTitle,
    required DateTime deadline,
  }) async {
    final now = DateTime.now();
    final difference = deadline.difference(now);
    
    String urgencyText;
    if (difference.inHours < 1) {
      urgencyText = '⚠️ 即将截止';
    } else if (difference.inHours < 24) {
      urgencyText = '🔔 今日截止';
    } else {
      urgencyText = '📅 即将到期';
    }

    // 格式化个性化内容
    final baseBody = '任务「$taskTitle」将在${_formatDeadline(deadline)}截止，记得及时完成哦！';
    final personalizedBody = await _formatPersonalizedContent(baseBody);

    await showNotification(
      id: 2001,
      title: '$urgencyText',
      body: personalizedBody,
      payload: 'task_deadline',
      notificationDetails: _getTaskNotificationDetails(),
    );
  }

  /// 学习打卡提醒
  Future<void> showStudyReminderNotification() async {
    // 格式化个性化内容
    final baseBody = '今天还没有学习记录哦，快来开始你的学习之旅吧！';
    final personalizedBody = await _formatPersonalizedContent(baseBody);

    await showNotification(
      id: 4001,
      title: '📚 学习打卡提醒',
      body: personalizedBody,
      payload: 'study_reminder',
    );
  }

  /// 任务提醒通知（智能选择系统通知或应用内通知）
  Future<void> showTaskReminderNotification({
    required String title,
    required String body,
    String? taskId,
  }) async {
    if (kDebugMode) {
      print('🔔 开始显示任务提醒通知: title=$title, taskId=$taskId');
    }
    
    // 如果应用在前台，不显示系统通知（由SmartReminderService处理应用内通知）
    if (isAppInForeground) {
      if (kDebugMode) {
        print('📱 应用在前台，跳过系统通知');
      }
      return;
    }

    // 应用在后台，显示系统通知
    if (kDebugMode) {
      print('📱 应用在后台，显示系统通知');
    }

    final personalizedBody = await _formatPersonalizedContent(body);

    await showNotification(
      id: taskId?.hashCode ?? 3001,
      title: title,
      body: personalizedBody,
      payload: 'task_reminder${taskId != null ? '_$taskId' : ''}',
      notificationDetails: _getTaskNotificationDetails(),
    );
  }

  /// 任务开始时间提醒
  Future<void> showTaskStartNotification({
    required String taskTitle,
    String? taskId,
  }) async {
    final baseBody = '任务「$taskTitle」该开始了，现在就动手吧！';
    await showTaskReminderNotification(
      title: '⏰ 任务开始提醒',
      body: baseBody,
      taskId: taskId,
    );
  }

  /// 任务进度提醒（超时50%）
  Future<void> showTaskProgressNotification({
    required String taskTitle,
    String? taskId,
  }) async {
    final baseBody = '任务「$taskTitle」已超过预计时间50%，要不要检查一下进度？';
    await showTaskReminderNotification(
      title: '📊 进度提醒',
      body: baseBody,
      taskId: taskId,
    );
  }

  /// 拖延提醒（分级别）
  Future<void> showDelayReminderNotification({
    required String title,
    required String message,
    String? taskId,
  }) async {
    await showTaskReminderNotification(
      title: title,
      body: message,
      taskId: taskId,
    );
  }

  /// 统一提醒（每日汇总）
  Future<void> showUnifiedReminderNotification({
    required int taskCount,
    required String nickname,
  }) async {
    final baseBody = '今天还有$taskCount个任务未完成，要不要看看？';
    await showTaskReminderNotification(
      title: '🌙 今日任务提醒',
      body: baseBody,
    );
  }

  /// 任务重新安排提醒
  Future<void> showRescheduleNotification({
    required int taskCount,
    required String nickname,
  }) async {
    final baseBody = '昨天有$taskCount个任务没有完成，需要重新安排吗？';
    await showTaskReminderNotification(
      title: '📅 任务重新安排',
      body: baseBody,
    );
  }

  /// 安排定时通知
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      _getDefaultNotificationDetails(),
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// 安排每日重复通知
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      _getDefaultNotificationDetails(),
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// 取消指定通知
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// 取消所有通知
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// 获取默认通知样式
  NotificationDetails _getDefaultNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'default_channel',
        '默认通知',
        channelDescription: '应用默认通知渠道',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  /// 番茄钟通知样式
  NotificationDetails _getPomodoroNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'pomodoro_channel',
        '番茄钟提醒',
        channelDescription: '番茄钟工作和休息提醒',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        sound: RawResourceAndroidNotificationSound('notification_sound'),
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'notification_sound.wav',
        interruptionLevel: InterruptionLevel.active,
      ),
    );
  }

  /// 任务通知样式
  NotificationDetails _getTaskNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'task_channel',
        '任务提醒',
        channelDescription: '任务截止和完成提醒',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }



  /// 计算下一个指定时间
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  /// 格式化截止时间
  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}天后';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时后';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟后';
    } else {
      return '即将截止';
    }
  }
}
