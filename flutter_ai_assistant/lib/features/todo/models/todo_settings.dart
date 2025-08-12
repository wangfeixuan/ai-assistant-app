import 'todo_item.dart';

/// 通知频率枚举
enum NotificationFrequency {
  low,
  normal,
  high,
}

/// 提醒风格枚举
enum ReminderStyle {
  gentle,
  strict,
  encouraging,
}

/// 拖延容忍度枚举
enum DelayTolerance {
  strict,
  normal,
  lenient,
}

/// 时间输入样式枚举
enum TimeInputStyle {
  scroll,      // 上下滚动（默认）
  dial,        // 拨动指针
  manual,      // 手动填写
}

/// 自动清除周期枚举
enum AutoCleanupPeriod {
  disabled,    // 禁用自动清除
  daily,       // 每日清除（1天前的已完成任务）
  weekly,      // 每周清除（7天前的已完成任务）
  monthly,     // 每月清除（30天前的已完成任务）
  custom,      // 自定义天数
}

/// 待办系统设置数据模型
/// 包含提醒时间、勿扰时段、个性化设置等配置
class TodoSettings {
  // 提醒设置
  final DateTime unifiedReminderTime; // 统一提醒时间（默认22:00）
  final bool enableVibration; // 是否启用震动
  final bool enableSound; // 是否启用声音
  final NotificationFrequency notificationFrequency; // 通知频率
  
  // 勿扰时段设置
  final bool enableDoNotDisturb; // 是否启用勿扰模式
  final DateTime doNotDisturbStart; // 勿扰开始时间
  final DateTime doNotDisturbEnd; // 勿扰结束时间
  final List<int> doNotDisturbDays; // 勿扰日期（1-7，周一到周日）
  
  // 个性化设置
  final ReminderStyle reminderStyle; // 提醒语言风格
  final DelayTolerance delayTolerance; // 拖延容忍度
  final TimeInputStyle timeInputStyle; // 时间输入样式
  
  // 智能提醒设置
  final bool enableSmartReminder; // 是否启用智能提醒
  final bool respectPomodoroFocus; // 是否在番茄钟专注时避免提醒
  final bool enableProgressReminder; // 是否启用进度提醒（超时50%）
  final bool enableDelayReminder; // 是否启用拖延提醒
  
  // 跨天任务设置
  final bool enableCrossDayRollover; // 是否自动延期未完成任务
  final bool showRescheduleDialog; // 是否显示次日重新安排对话框
  
  // 重复任务设置（习惯追踪默认启用，目标天数在每个任务中单独设置）
  final bool enableHabitTracking; // 是否启用习惯追踪
  final int streakGoal; // 连续完成目标天数
  
  // 自动清除设置
  final bool enableAutoCleanup; // 是否启用自动清除
  final AutoCleanupPeriod autoCleanupPeriod; // 自动清除周期
  final int customCleanupDays; // 自定义清除天数（当周期为custom时使用）
  final bool excludePriorityTasks; // 是否排除优先任务
  final bool excludeRecurringTasks; // 是否排除每日待办任务
  final bool enableCleanupNotification; // 是否在清除后显示通知
  final DateTime? lastCleanupTime; // 上次清除时间
  
  TodoSettings({
    // 提醒设置默认值
    DateTime? unifiedReminderTime,
    this.enableVibration = true,
    this.enableSound = true,
    this.notificationFrequency = NotificationFrequency.normal,
    
    // 勿扰时段默认值
    this.enableDoNotDisturb = false,
    DateTime? doNotDisturbStart,
    DateTime? doNotDisturbEnd,
    this.doNotDisturbDays = const [],
    
    // 个性化设置默认值
    this.reminderStyle = ReminderStyle.gentle,
    this.delayTolerance = DelayTolerance.normal,
    this.timeInputStyle = TimeInputStyle.scroll,
    
    // 智能提醒默认值
    this.enableSmartReminder = true,
    this.respectPomodoroFocus = true,
    this.enableProgressReminder = true,
    this.enableDelayReminder = true,
    
    // 跨天任务默认值
    this.enableCrossDayRollover = true,
    this.showRescheduleDialog = true,
    
    // 重复任务默认值
    this.enableHabitTracking = true,
    this.streakGoal = 30,
    
    // 自动清除默认值
    this.enableAutoCleanup = false, // 默认禁用，由用户手动开启
    this.autoCleanupPeriod = AutoCleanupPeriod.weekly, // 默认每周清除
    this.customCleanupDays = 7, // 默认自定义7天
    this.excludePriorityTasks = true, // 默认排除优先任务
    this.excludeRecurringTasks = true, // 默认排除每日待办
    this.enableCleanupNotification = true, // 默认显示清除通知
    this.lastCleanupTime,
  }) : unifiedReminderTime = unifiedReminderTime ?? 
         DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 22, 0),
       doNotDisturbStart = doNotDisturbStart ?? 
         DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 23, 0),
       doNotDisturbEnd = doNotDisturbEnd ?? 
         DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 7, 0);

  /// 从JSON创建TodoSettings
  factory TodoSettings.fromJson(Map<String, dynamic> json) {
    return TodoSettings(
      // 提醒设置
      unifiedReminderTime: json['unifiedReminderTime'] != null 
        ? DateTime.parse(json['unifiedReminderTime'] as String)
        : null,
      enableVibration: json['enableVibration'] as bool? ?? true,
      enableSound: json['enableSound'] as bool? ?? true,
      notificationFrequency: json['notificationFrequency'] != null 
        ? NotificationFrequency.values[json['notificationFrequency'] as int]
        : NotificationFrequency.normal,
      
      // 勿扰时段
      enableDoNotDisturb: json['enableDoNotDisturb'] as bool? ?? false,
      doNotDisturbStart: json['doNotDisturbStart'] != null 
        ? DateTime.parse(json['doNotDisturbStart'] as String)
        : null,
      doNotDisturbEnd: json['doNotDisturbEnd'] != null 
        ? DateTime.parse(json['doNotDisturbEnd'] as String)
        : null,
      doNotDisturbDays: (json['doNotDisturbDays'] as List<dynamic>?)?.cast<int>() ?? [],
      
      // 个性化设置
      reminderStyle: json['reminderStyle'] != null 
        ? ReminderStyle.values[json['reminderStyle'] as int]
        : ReminderStyle.gentle,
      delayTolerance: json['delayTolerance'] != null 
        ? DelayTolerance.values[json['delayTolerance'] as int]
        : DelayTolerance.normal,
      timeInputStyle: json['timeInputStyle'] != null 
        ? TimeInputStyle.values[json['timeInputStyle'] as int]
        : TimeInputStyle.scroll,
      
      // 智能提醒
      enableSmartReminder: json['enableSmartReminder'] as bool? ?? true,
      respectPomodoroFocus: json['respectPomodoroFocus'] as bool? ?? true,
      enableProgressReminder: json['enableProgressReminder'] as bool? ?? true,
      enableDelayReminder: json['enableDelayReminder'] as bool? ?? true,
      
      // 跨天任务
      enableCrossDayRollover: json['enableCrossDayRollover'] as bool? ?? true,
      showRescheduleDialog: json['showRescheduleDialog'] as bool? ?? true,
      
      // 重复任务
      enableHabitTracking: json['enableHabitTracking'] as bool? ?? true,
      streakGoal: json['streakGoal'] as int? ?? 30,
      
      // 自动清除
      enableAutoCleanup: json['enableAutoCleanup'] as bool? ?? false,
      autoCleanupPeriod: json['autoCleanupPeriod'] != null 
        ? AutoCleanupPeriod.values[json['autoCleanupPeriod'] as int]
        : AutoCleanupPeriod.weekly,
      customCleanupDays: json['customCleanupDays'] as int? ?? 7,
      excludePriorityTasks: json['excludePriorityTasks'] as bool? ?? true,
      excludeRecurringTasks: json['excludeRecurringTasks'] as bool? ?? true,
      enableCleanupNotification: json['enableCleanupNotification'] as bool? ?? true,
      lastCleanupTime: json['lastCleanupTime'] != null 
        ? DateTime.parse(json['lastCleanupTime'] as String)
        : null,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      // 提醒设置
      'unifiedReminderTime': unifiedReminderTime.toIso8601String(),
      'enableVibration': enableVibration,
      'enableSound': enableSound,
      'notificationFrequency': notificationFrequency.index,
      
      // 勿扰时段
      'enableDoNotDisturb': enableDoNotDisturb,
      'doNotDisturbStart': doNotDisturbStart.toIso8601String(),
      'doNotDisturbEnd': doNotDisturbEnd.toIso8601String(),
      'doNotDisturbDays': doNotDisturbDays,
      
      // 个性化设置
      'reminderStyle': reminderStyle.index,
      'delayTolerance': delayTolerance.index,
      'timeInputStyle': timeInputStyle.index,
      
      // 智能提醒
      'enableSmartReminder': enableSmartReminder,
      'respectPomodoroFocus': respectPomodoroFocus,
      'enableProgressReminder': enableProgressReminder,
      'enableDelayReminder': enableDelayReminder,
      
      // 跨天任务
      'enableCrossDayRollover': enableCrossDayRollover,
      'showRescheduleDialog': showRescheduleDialog,
      
      // 重复任务
      'enableHabitTracking': enableHabitTracking,
      'streakGoal': streakGoal,
      
      // 自动清除
      'enableAutoCleanup': enableAutoCleanup,
      'autoCleanupPeriod': autoCleanupPeriod.index,
      'customCleanupDays': customCleanupDays,
      'excludePriorityTasks': excludePriorityTasks,
      'excludeRecurringTasks': excludeRecurringTasks,
      'enableCleanupNotification': enableCleanupNotification,
      'lastCleanupTime': lastCleanupTime?.toIso8601String(),
    };
  }

  /// 创建副本并修改指定属性
  TodoSettings copyWith({
    DateTime? unifiedReminderTime,
    bool? enableVibration,
    bool? enableSound,
    NotificationFrequency? notificationFrequency,
    bool? enableDoNotDisturb,
    DateTime? doNotDisturbStart,
    DateTime? doNotDisturbEnd,
    List<int>? doNotDisturbDays,
    ReminderStyle? reminderStyle,
    DelayTolerance? delayTolerance,
    TimeInputStyle? timeInputStyle,
    bool? enableSmartReminder,
    bool? respectPomodoroFocus,
    bool? enableProgressReminder,
    bool? enableDelayReminder,
    bool? enableCrossDayRollover,
    bool? showRescheduleDialog,
    bool? enableHabitTracking,
    int? streakGoal,
  }) {
    return TodoSettings(
      unifiedReminderTime: unifiedReminderTime ?? this.unifiedReminderTime,
      enableVibration: enableVibration ?? this.enableVibration,
      enableSound: enableSound ?? this.enableSound,
      notificationFrequency: notificationFrequency ?? this.notificationFrequency,
      enableDoNotDisturb: enableDoNotDisturb ?? this.enableDoNotDisturb,
      doNotDisturbStart: doNotDisturbStart ?? this.doNotDisturbStart,
      doNotDisturbEnd: doNotDisturbEnd ?? this.doNotDisturbEnd,
      doNotDisturbDays: doNotDisturbDays ?? this.doNotDisturbDays,

      reminderStyle: reminderStyle ?? this.reminderStyle,
      delayTolerance: delayTolerance ?? this.delayTolerance,
      timeInputStyle: timeInputStyle ?? this.timeInputStyle,
      enableSmartReminder: enableSmartReminder ?? this.enableSmartReminder,
      respectPomodoroFocus: respectPomodoroFocus ?? this.respectPomodoroFocus,
      enableProgressReminder: enableProgressReminder ?? this.enableProgressReminder,
      enableDelayReminder: enableDelayReminder ?? this.enableDelayReminder,
      enableCrossDayRollover: enableCrossDayRollover ?? this.enableCrossDayRollover,
      showRescheduleDialog: showRescheduleDialog ?? this.showRescheduleDialog,
      enableHabitTracking: enableHabitTracking ?? this.enableHabitTracking,
      streakGoal: streakGoal ?? this.streakGoal,
    );
  }

  /// 检查当前时间是否在勿扰时段
  bool isInDoNotDisturbPeriod([DateTime? checkTime]) {
    if (!enableDoNotDisturb) return false;
    
    final now = checkTime ?? DateTime.now();
    final currentWeekday = now.weekday;
    
    // 检查是否在勿扰日期内
    if (doNotDisturbDays.isNotEmpty && !doNotDisturbDays.contains(currentWeekday)) {
      return false;
    }
    
    // 获取今天的勿扰时间段
    final todayStart = DateTime(now.year, now.month, now.day, 
      doNotDisturbStart.hour, doNotDisturbStart.minute);
    final todayEnd = DateTime(now.year, now.month, now.day, 
      doNotDisturbEnd.hour, doNotDisturbEnd.minute);
    
    // 处理跨天的情况（如23:00-07:00）
    if (todayEnd.isBefore(todayStart)) {
      // 跨天情况：检查是否在今天晚上的开始时间之后，或明天早上的结束时间之前
      final tomorrowEnd = todayEnd.add(const Duration(days: 1));
      return now.isAfter(todayStart) || now.isBefore(tomorrowEnd);
    } else {
      // 同一天情况：检查是否在时间段内
      return now.isAfter(todayStart) && now.isBefore(todayEnd);
    }
  }
  
  /// 获取提醒语言风格描述
  String get reminderStyleDescription {
    switch (reminderStyle) {
      case ReminderStyle.gentle:
        return '温和';
      case ReminderStyle.strict:
        return '严格';
      case ReminderStyle.encouraging:
        return '鼓励';
    }
  }
  
  /// 根据拖延等级和语言风格生成提醒消息
  String generateReminderMessage(String taskName, DelayLevel delayLevel, [String? userNickname]) {
    final nickname = (userNickname != null && userNickname.isNotEmpty) ? userNickname : '小伙伴';
    
    switch (reminderStyle) {
      case ReminderStyle.gentle:
        return _generateGentleMessage(nickname, taskName, delayLevel);
      case ReminderStyle.strict:
        return _generateStrictMessage(nickname, taskName, delayLevel);
      case ReminderStyle.encouraging:
        return _generateEncouragingMessage(nickname, taskName, delayLevel);
    }
  }
  
  String _generateGentleMessage(String nickname, String taskName, DelayLevel delayLevel) {
    switch (delayLevel) {
      case DelayLevel.none:
        return '$nickname，该开始「$taskName」了哦～';
      case DelayLevel.light:
        return '$nickname，「$taskName」稍微延迟了一点，不如现在开始吧？';
      case DelayLevel.moderate:
        return '$nickname，「$taskName」已经拖延几天了，要不要先做一小部分？';
      case DelayLevel.severe:
        return '$nickname，「$taskName」拖延有点久了，我们一起想想怎么解决吧？';
    }
  }
  
  String _generateStrictMessage(String nickname, String taskName, DelayLevel delayLevel) {
    switch (delayLevel) {
      case DelayLevel.none:
        return '$nickname，「$taskName」到时间了，请立即开始！';
      case DelayLevel.light:
        return '$nickname，「$taskName」已经延迟，必须马上处理！';
      case DelayLevel.moderate:
        return '$nickname，「$taskName」严重拖延，这样下去不行！';
      case DelayLevel.severe:
        return '$nickname，「$taskName」拖延太久，必须立即行动！';
    }
  }
  
  String _generateEncouragingMessage(String nickname, String taskName, DelayLevel delayLevel) {
    switch (delayLevel) {
      case DelayLevel.none:
        return '$nickname，开始「$taskName」的时候到了，你一定可以的！';
      case DelayLevel.light:
        return '$nickname，「$taskName」稍有延迟，但现在开始还来得及！';
      case DelayLevel.moderate:
        return '$nickname，虽然「$taskName」拖延了几天，但每一步都是进步！';
      case DelayLevel.severe:
        return '$nickname，「$taskName」拖延很久了，但现在开始永远不晚！';
    }
  }
}
