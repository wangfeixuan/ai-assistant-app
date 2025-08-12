import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/in_app_notification_service.dart';
import '../../../features/pomodoro/providers/pomodoro_provider.dart';
import '../models/todo_item.dart';
import '../models/todo_settings.dart';
import '../models/delay_diary.dart';
import '../providers/todo_provider.dart';

/// 智能提醒服务
/// 负责任务提醒调度、用户状态感知、通知触达策略等核心功能
class SmartReminderService {
  final NotificationService _notificationService;
  final InAppNotificationService _inAppNotificationService;
  final TodoProvider _todoProvider;
  final PomodoroProvider? _pomodoroProvider;
  
  Timer? _reminderTimer;
  Timer? _rolloverTimer;
  BuildContext? _context;
  
  SmartReminderService({
    required NotificationService notificationService,
    required InAppNotificationService inAppNotificationService,
    required TodoProvider todoProvider,
    PomodoroProvider? pomodoroProvider,
  }) : _notificationService = notificationService,
       _inAppNotificationService = inAppNotificationService,
       _todoProvider = todoProvider,
       _pomodoroProvider = pomodoroProvider;

  /// 初始化提醒服务
  void initialize(BuildContext context) {
    _context = context;
    _startReminderTimer();
    _startRolloverTimer();
    debugPrint('🔔 智能提醒服务已初始化');
  }

  /// 销毁提醒服务
  void dispose() {
    _reminderTimer?.cancel();
    _rolloverTimer?.cancel();
    debugPrint('🔔 智能提醒服务已销毁');
  }

  /// 启动提醒定时器（每分钟检查一次）
  void _startReminderTimer() {
    _reminderTimer?.cancel();
    _reminderTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkAndSendReminders();
    });
  }

  /// 启动跨天任务处理定时器（每小时检查一次）
  void _startRolloverTimer() {
    _rolloverTimer?.cancel();
    _rolloverTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      final now = DateTime.now();
      // 在每天凌晨1点处理跨天任务
      if (now.hour == 1 && now.minute < 5) {
        _handleDailyRollover();
      }
    });
  }

  /// 检查并发送提醒
  Future<void> _checkAndSendReminders() async {
    try {
      final settings = _todoProvider.settings;
      
      // 检查是否启用智能提醒
      if (!settings.enableSmartReminder) return;
      
      // 检查是否在勿扰时段
      if (_isInDoNotDisturbMode()) {
        debugPrint('🔕 当前在勿扰时段，跳过提醒');
        return;
      }
      
      // 检查是否在番茄钟专注模式
      if (_isInPomodoroFocusMode()) {
        debugPrint('🍅 当前在番茄钟专注模式，跳过提醒');
        return;
      }
      
      // 获取需要提醒的任务
      final tasksNeedingReminder = _todoProvider.getTasksNeedingReminder();
      final overdueTasks = _todoProvider.getOverdueTasks();
      final overtimeTasks = _todoProvider.getOvertimeTasks();
      
      // 发送开始时间提醒
      for (final task in tasksNeedingReminder) {
        if (_shouldSendStartTimeReminder(task)) {
          await _sendStartTimeReminder(task);
        }
      }
      
      // 发送过期提醒
      for (final task in overdueTasks) {
        if (_shouldSendOverdueReminder(task)) {
          await _sendOverdueReminder(task);
        }
      }
      
      // 发送进度提醒（超时50%）
      if (settings.enableProgressReminder) {
        for (final task in overtimeTasks) {
          if (_shouldSendProgressReminder(task)) {
            await _sendProgressReminder(task);
          }
        }
      }
      
      // 发送拖延提醒
      if (settings.enableDelayReminder) {
        await _checkAndSendDelayReminders();
      }
      
      // 发送统一提醒（晚上指定时间）
      await _checkAndSendUnifiedReminder();
      
    } catch (e) {
      debugPrint('❌ 检查提醒时出错: $e');
    }
  }

  /// 检查是否在勿扰模式
  bool _isInDoNotDisturbMode() {
    return _todoProvider.isInDoNotDisturbPeriod();
  }

  /// 检查是否在番茄钟专注模式
  bool _isInPomodoroFocusMode() {
    if (_pomodoroProvider == null) return false;
    final settings = _todoProvider.settings;
    if (!settings.respectPomodoroMode) return false;
    
    return _pomodoroProvider!.isRunning && 
           _pomodoroProvider!.currentMode == PomodoroMode.work;
  }

  /// 是否应该发送开始时间提醒
  bool _shouldSendStartTimeReminder(TodoItem task) {
    if (task.startTime == null) return false;
    
    final now = DateTime.now();
    final startTime = task.startTime!;
    
    // 检查是否刚到开始时间（允许5分钟误差）
    final timeDiff = now.difference(startTime).inMinutes;
    if (timeDiff < 0 || timeDiff > 5) return false;
    
    // 检查是否被忽略且还在忽略间隔内
    if (!task.shouldRemindAfterIgnore()) return false;
    
    // 检查是否已经提醒过（避免重复提醒）
    if (task.lastRemindTime != null) {
      final lastRemindDiff = now.difference(task.lastRemindTime!).inMinutes;
      if (lastRemindDiff < 30) return false; // 30分钟内不重复提醒
    }
    
    return true;
  }

  /// 是否应该发送过期提醒
  bool _shouldSendOverdueReminder(TodoItem task) {
    if (!task.isOverdue) return false;
    
    final now = DateTime.now();
    
    // 检查是否被忽略且还在忽略间隔内
    if (!task.shouldRemindAfterIgnore()) return false;
    
    // 检查是否已经提醒过（避免重复提醒）
    if (task.lastRemindTime != null) {
      final lastRemindDiff = now.difference(task.lastRemindTime!).inHours;
      // 根据拖延等级调整提醒频率
      final reminderInterval = _getReminderInterval(task.currentDelayLevel);
      if (lastRemindDiff < reminderInterval) return false;
    }
    
    return true;
  }

  /// 是否应该发送进度提醒
  bool _shouldSendProgressReminder(TodoItem task) {
    if (!task.isOvertime) return false;
    
    final now = DateTime.now();
    
    // 检查是否被忽略且还在忽略间隔内
    if (!task.shouldRemindAfterIgnore()) return false;
    
    // 检查是否已经提醒过
    if (task.lastRemindTime != null) {
      final lastRemindDiff = now.difference(task.lastRemindTime!).inMinutes;
      if (lastRemindDiff < 60) return false; // 1小时内不重复提醒
    }
    
    return true;
  }

  /// 根据拖延等级获取提醒间隔（小时）
  int _getReminderInterval(DelayLevel delayLevel) {
    switch (delayLevel) {
      case DelayLevel.none:
        return 24; // 24小时
      case DelayLevel.light:
        return 12; // 12小时
      case DelayLevel.moderate:
        return 6;  // 6小时
      case DelayLevel.severe:
        return 3;  // 3小时
    }
  }

  /// 发送开始时间提醒
  Future<void> _sendStartTimeReminder(TodoItem task) async {
    final message = _todoProvider.generateReminderMessage(task.text, DelayLevel.none);
    
    await _sendReminder(
      title: '⏰ 任务开始提醒',
      message: message,
      taskId: task.id,
      emoji: '⏰',
    );
    
    debugPrint('⏰ 已发送开始时间提醒: ${task.text}');
  }

  /// 发送过期提醒
  Future<void> _sendOverdueReminder(TodoItem task) async {
    final message = _todoProvider.generateReminderMessage(task.text, task.currentDelayLevel);
    
    await _sendReminder(
      title: '🚨 任务过期提醒',
      message: message,
      taskId: task.id,
      emoji: '🚨',
    );
    
    debugPrint('🚨 已发送过期提醒: ${task.text}');
  }

  /// 发送进度提醒
  Future<void> _sendProgressReminder(TodoItem task) async {
    final settings = _todoProvider.settings;
    final nickname = settings.userNickname.isNotEmpty ? settings.userNickname : '小伙伴';
    final message = '$nickname，任务「${task.text}」已超过预计时间50%，要不要检查一下进度？';
    
    await _sendReminder(
      title: '📊 进度提醒',
      message: message,
      taskId: task.id,
      emoji: '📊',
    );
    
    debugPrint('📊 已发送进度提醒: ${task.text}');
  }

  /// 检查并发送拖延提醒
  Future<void> _checkAndSendDelayReminders() async {
    final allTasks = _todoProvider.todos;
    final delayedTasks = allTasks.where((task) => 
      !task.completed && task.currentDelayLevel != DelayLevel.none
    ).toList();
    
    for (final task in delayedTasks) {
      if (_shouldSendDelayReminder(task)) {
        await _sendDelayReminder(task);
      }
    }
  }

  /// 是否应该发送拖延提醒
  bool _shouldSendDelayReminder(TodoItem task) {
    final now = DateTime.now();
    
    // 检查是否已经提醒过
    if (task.lastRemindTime != null) {
      final lastRemindDiff = now.difference(task.lastRemindTime!).inHours;
      final reminderInterval = _getReminderInterval(task.currentDelayLevel);
      if (lastRemindDiff < reminderInterval) return false;
    }
    
    return true;
  }

  /// 发送拖延提醒
  Future<void> _sendDelayReminder(TodoItem task) async {
    final message = _todoProvider.generateReminderMessage(task.text, task.currentDelayLevel);
    
    String emoji;
    String title;
    switch (task.currentDelayLevel) {
      case DelayLevel.light:
        emoji = '⚠️';
        title = '轻度拖延提醒';
        break;
      case DelayLevel.moderate:
        emoji = '🔶';
        title = '中度拖延提醒';
        break;
      case DelayLevel.severe:
        emoji = '🔴';
        title = '严重拖延提醒';
        break;
      default:
        return;
    }
    
    await _sendReminder(
      title: '$emoji $title',
      message: message,
      taskId: task.id,
      emoji: emoji,
    );
    
    debugPrint('$emoji 已发送拖延提醒: ${task.text} (${task.delayLevelDescription})');
  }

  /// 检查并发送统一提醒
  Future<void> _checkAndSendUnifiedReminder() async {
    final settings = _todoProvider.settings;
    final now = DateTime.now();
    final unifiedTime = settings.unifiedReminderTime;
    
    // 检查是否到了统一提醒时间（允许5分钟误差）
    final currentTime = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    final targetTime = DateTime(now.year, now.month, now.day, unifiedTime.hour, unifiedTime.minute);
    
    final timeDiff = currentTime.difference(targetTime).inMinutes.abs();
    if (timeDiff > 5) return;
    
    // 获取未完成且没有开始时间的任务
    final tasksForUnifiedReminder = _todoProvider.todos.where((task) =>
      !task.completed && 
      task.startTime == null &&
      task.level == 1 // 只提醒主任务
    ).toList();
    
    if (tasksForUnifiedReminder.isEmpty) return;
    
    final nickname = settings.userNickname.isNotEmpty ? settings.userNickname : '小伙伴';
    final taskCount = tasksForUnifiedReminder.length;
    final message = '$nickname，今天还有$taskCount个任务未完成，要不要看看？';
    
    await _sendReminder(
      title: '🌙 今日任务提醒',
      message: message,
      taskId: null,
      emoji: '🌙',
    );
    
    debugPrint('🌙 已发送统一提醒，未完成任务数: $taskCount');
  }

  /// 发送提醒（统一入口）
  Future<void> _sendReminder({
    required String title,
    required String message,
    String? taskId,
    required String emoji,
  }) async {
    try {
      // 更新任务提醒信息
      if (taskId != null) {
        _todoProvider.updateTaskReminder(taskId);
      }
      
      // 根据应用状态选择通知方式
      if (_context != null && _notificationService.isAppInForeground) {
        // 应用在前台，显示应用内通知
        await _inAppNotificationService.showInAppNotification(
          context: _context!,
          title: title,
          message: message,
          emoji: emoji,
          enableVibration: _todoProvider.settings.enableVibration,
          enableSound: _todoProvider.settings.enableSound,
        );
      } else {
        // 应用在后台，发送系统通知
        await _notificationService.showTaskReminderNotification(
          title: title,
          body: message,
          taskId: taskId,
        );
      }
    } catch (e) {
      debugPrint('❌ 发送提醒失败: $e');
    }
  }

  /// 处理每日跨天任务
  Future<void> _handleDailyRollover() async {
    try {
      debugPrint('🔄 开始处理跨天任务...');
      
      // 处理未完成任务延期
      _todoProvider.rolloverIncompleteTasks();
      
      // 生成重复任务的新实例
      await _generateRecurringTaskInstances();
      
      // 检查是否需要显示重新安排对话框
      final tasksNeedingReschedule = _todoProvider.getTasksNeedingReschedule();
      if (tasksNeedingReschedule.isNotEmpty && _todoProvider.settings.showRescheduleDialog) {
        await _showRescheduleDialog(tasksNeedingReschedule);
      }
      
      debugPrint('🔄 跨天任务处理完成');
    } catch (e) {
      debugPrint('❌ 处理跨天任务时出错: $e');
    }
  }

  /// 生成重复任务实例
  Future<void> _generateRecurringTaskInstances() async {
    final allTasks = _todoProvider.todos;
    final recurringTemplates = <String, TodoItem>{};
    
    // 收集重复任务模板
    for (final task in allTasks.where((t) => t.isRecurring)) {
      final templateId = task.templateId!;
      if (!recurringTemplates.containsKey(templateId) || 
          task.recurringIndex > recurringTemplates[templateId]!.recurringIndex) {
        recurringTemplates[templateId] = task;
      }
    }
    
    // 为每个模板生成新实例
    for (final template in recurringTemplates.values) {
      if (_shouldGenerateNextInstance(template)) {
        _todoProvider.generateNextRecurringInstance(template.templateId!);
        debugPrint('🔄 已生成重复任务新实例: ${template.text}');
      }
    }
  }

  /// 是否应该生成下一个重复任务实例
  bool _shouldGenerateNextInstance(TodoItem template) {
    final now = DateTime.now();
    final createdDate = template.createdAt;
    
    switch (template.recurringPattern) {
      case RecurringPattern.daily:
        return now.difference(createdDate).inDays >= 1;
      case RecurringPattern.weekly:
        return now.difference(createdDate).inDays >= 7;
      case RecurringPattern.custom:
        return now.difference(createdDate).inDays >= template.customInterval;
      case RecurringPattern.none:
        return false;
    }
  }

  /// 显示重新安排对话框
  Future<void> _showRescheduleDialog(List<TodoItem> tasksNeedingReschedule) async {
    if (_context == null) return;
    
    final nickname = _todoProvider.settings.userNickname.isNotEmpty 
      ? _todoProvider.settings.userNickname : '小伙伴';
    
    final message = '$nickname，昨天有${tasksNeedingReschedule.length}个任务没有完成，需要重新安排吗？';
    
    await _inAppNotificationService.showInAppNotification(
      context: _context!,
      title: '📅 任务重新安排',
      message: message,
      emoji: '📅',
      duration: const Duration(seconds: 8),
      onTap: () {
        // 这里可以导航到任务重新安排页面
        debugPrint('📅 用户点击了重新安排提醒');
      },
    );
  }

  /// 手动触发提醒检查（用于测试）
  Future<void> triggerReminderCheck() async {
    debugPrint('🔔 手动触发提醒检查');
    await _checkAndSendReminders();
  }

  /// 手动触发跨天处理（用于测试）
  Future<void> triggerDailyRollover() async {
    debugPrint('🔄 手动触发跨天处理');
    await _handleDailyRollover();
  }
}
