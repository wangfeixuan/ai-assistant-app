import 'dart:convert';
import 'package:flutter/material.dart';

/// 拖延等级枚举
enum DelayLevel {
  none,    // 无拖延
  light,   // 轻度拖延
  moderate, // 中度拖延
  severe   // 严重拖延
}

/// 任务类型枚举
enum TaskType {
  today,    // 今日待办
  daily     // 每日待办
}

/// 四象限分类枚举
enum QuadrantType {
  importantUrgent,     // 重要且紧急
  importantNotUrgent,  // 重要不紧急
  notImportantUrgent,  // 不重要但紧急
  notImportantNotUrgent // 不重要不紧急
}

/// 待办事项数据模型
/// 支持多级任务结构：1级任务（用户输入/手动添加）和2级任务（AI拆分的子任务）
/// 包含时间管理、重复任务、拖延记录等完整功能
class TodoItem {
  final String id;
  final String text;
  final bool completed;
  final DateTime createdAt;
  final int level; // 1: 主任务, 2: 子任务
  final String? parentId; // 2级任务的父任务ID
  final List<String> subtaskIds; // 1级任务的子任务ID列表
  final bool isExpanded; // 是否展开显示子任务
  final String source; // 'manual': 手动添加, 'ai_split': AI拆分
  
  // 时间管理相关
  final DateTime? startTime; // 开始时间
  final Duration? estimatedDuration; // 预计完成时长
  final DateTime? deadline; // 截止时间
  final DateTime? completedAt; // 实际完成时间
  
  // 每日待办相关
  final TaskType taskType; // 任务类型：今日待办或每日待办
  final int? dailyDuration; // 每日待办持续天数
  final int? currentOccurrence; // 当前是第几次
  final int? totalOccurrences; // 总共几次
  final String? parentTaskId; // 原始任务ID（用于关联每日待办的各个实例）
  final bool isDelayed; // 是否为拖延任务
  final bool needsProcrastinationDiary; // 是否需要填写拖延日记
  
  // 拖延记录相关
  final bool isPostponed; // 是否已拖延
  final int postponedDays; // 拖延天数
  final String? postponeReason; // 拖延原因
  final DelayLevel delayLevel; // 拖延等级
  final DateTime? lastRemindTime; // 上次提醒时间
  final int remindCount; // 提醒次数
  final int ignoreCount; // 忽略次数
  final DateTime? lastIgnoreTime; // 上次忽略时间
  final bool isPriority; // 是否为优先任务（拖延后标记）
  final bool isUrgent; // 是否为紧急任务
  
  // 跨天任务相关
  final bool isRolledOver; // 是否从前一天延期而来
  final DateTime? originalDate; // 原始计划日期
  final int sortOrder; // 自定义排序序号

  TodoItem({
    required this.id,
    required this.text,
    this.completed = false,
    required this.createdAt,
    this.level = 1,
    this.parentId,
    this.subtaskIds = const [],
    this.isExpanded = false,
    this.source = 'manual',
    // 时间管理
    this.startTime,
    this.estimatedDuration,
    this.deadline,
    this.completedAt,
    // 每日待办
    this.taskType = TaskType.today,
    this.dailyDuration,
    this.currentOccurrence,
    this.totalOccurrences,
    this.parentTaskId,
    this.isDelayed = false,
    this.needsProcrastinationDiary = false,
    // 拖延记录
    this.isPostponed = false,
    this.postponedDays = 0,
    this.postponeReason,
    this.delayLevel = DelayLevel.none,
    this.lastRemindTime,
    this.remindCount = 0,
    this.ignoreCount = 0,
    this.lastIgnoreTime,
    this.isPriority = false,
    this.isUrgent = false,
    // 跨天任务
    this.isRolledOver = false,
    this.originalDate,
    this.sortOrder = 0,
  });

  /// 从JSON创建TodoItem
  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'] as String,
      text: json['text'] as String,
      completed: json['completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      level: int.tryParse(json['level'].toString()) ?? 1,
      parentId: json['parentId'] as String?,
      subtaskIds: (json['subtaskIds'] as List<dynamic>?)?.cast<String>() ?? [],
      isExpanded: json['isExpanded'] as bool? ?? false,
      source: json['source'] as String? ?? 'manual',
      // 时间管理
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime'] as String) : null,
      estimatedDuration: json['estimatedDuration'] != null ? Duration(minutes: int.tryParse(json['estimatedDuration'].toString()) ?? 0) : null,
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline'] as String) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
      // 每日待办
      taskType: TaskType.values.firstWhere(
        (e) => e.toString() == 'TaskType.${json['taskType']}',
        orElse: () => TaskType.today,
      ),
      dailyDuration: json['dailyDuration'] != null ? int.tryParse(json['dailyDuration'].toString()) : null,
      currentOccurrence: json['currentOccurrence'] != null ? int.tryParse(json['currentOccurrence'].toString()) : null,
      totalOccurrences: json['totalOccurrences'] != null ? int.tryParse(json['totalOccurrences'].toString()) : null,
      parentTaskId: json['parentTaskId'] as String?,
      isDelayed: json['isDelayed'] as bool? ?? false,
      needsProcrastinationDiary: json['needsProcrastinationDiary'] as bool? ?? false,
      // 拖延记录
      isPostponed: json['isPostponed'] as bool? ?? false,
      postponedDays: int.tryParse(json['postponedDays'].toString()) ?? 0,
      postponeReason: json['postponeReason'] as String?,
      delayLevel: DelayLevel.values.firstWhere(
        (e) => e.toString() == 'DelayLevel.${json['delayLevel']}',
        orElse: () => DelayLevel.none,
      ),
      lastRemindTime: json['lastRemindTime'] != null ? DateTime.parse(json['lastRemindTime'] as String) : null,
      remindCount: int.tryParse(json['remindCount'].toString()) ?? 0,
      ignoreCount: int.tryParse(json['ignoreCount'].toString()) ?? 0,
      lastIgnoreTime: json['lastIgnoreTime'] != null ? DateTime.parse(json['lastIgnoreTime'] as String) : null,
      isPriority: json['isPriority'] as bool? ?? false,
      isUrgent: json['isUrgent'] as bool? ?? false,
      // 跨天任务
      isRolledOver: json['isRolledOver'] as bool? ?? false,
      originalDate: json['originalDate'] != null ? DateTime.parse(json['originalDate'] as String) : null,
      sortOrder: int.tryParse(json['sortOrder'].toString()) ?? 0,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'completed': completed,
      'createdAt': createdAt.toIso8601String(),
      'level': level,
      'parentId': parentId,
      'subtaskIds': subtaskIds,
      'isExpanded': isExpanded,
      'source': source,
      // 时间管理
      'startTime': startTime?.toIso8601String(),
      'estimatedDuration': estimatedDuration?.inMinutes,
      'deadline': deadline?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      // 每日待办
      'taskType': taskType.toString().split('.').last,
      'dailyDuration': dailyDuration,
      'currentOccurrence': currentOccurrence,
      'totalOccurrences': totalOccurrences,
      'parentTaskId': parentTaskId,
      'isDelayed': isDelayed,
      'needsProcrastinationDiary': needsProcrastinationDiary,
      // 拖延记录
      'isPostponed': isPostponed,
      'postponedDays': postponedDays,
      'postponeReason': postponeReason,
      'delayLevel': delayLevel.toString().split('.').last,
      'lastRemindTime': lastRemindTime?.toIso8601String(),
      'remindCount': remindCount,
      'ignoreCount': ignoreCount,
      'lastIgnoreTime': lastIgnoreTime?.toIso8601String(),
      'isPriority': isPriority,
      'isUrgent': isUrgent,
      // 跨天任务
      'isRolledOver': isRolledOver,
      'originalDate': originalDate?.toIso8601String(),
      'sortOrder': sortOrder,
    };
  }

  /// 创建副本并修改指定属性
  TodoItem copyWith({
    String? id,
    String? text,
    bool? completed,
    DateTime? createdAt,
    int? level,
    String? parentId,
    List<String>? subtaskIds,
    bool? isExpanded,
    String? source,
    // 时间管理
    DateTime? startTime,
    Duration? estimatedDuration,
    DateTime? deadline,
    DateTime? completedAt,
    // 每日待办
    TaskType? taskType,
    int? dailyDuration,
    int? currentOccurrence,
    int? totalOccurrences,
    String? parentTaskId,
    bool? isDelayed,
    bool? needsProcrastinationDiary,
    // 拖延记录
    bool? isPostponed,
    int? postponedDays,
    String? postponeReason,
    DelayLevel? delayLevel,
    DateTime? lastRemindTime,
    int? remindCount,
    int? ignoreCount,
    DateTime? lastIgnoreTime,
    bool? isPriority,
    bool? isUrgent,
    // 跨天任务
    bool? isRolledOver,
    DateTime? originalDate,
    int? sortOrder,
  }) {
    return TodoItem(
      id: id ?? this.id,
      text: text ?? this.text,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      level: level ?? this.level,
      parentId: parentId ?? this.parentId,
      subtaskIds: subtaskIds ?? this.subtaskIds,
      isExpanded: isExpanded ?? this.isExpanded,
      source: source ?? this.source,
      // 时间管理
      startTime: startTime ?? this.startTime,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      deadline: deadline ?? this.deadline,
      completedAt: completedAt ?? this.completedAt,
      // 每日待办
      taskType: taskType ?? this.taskType,
      dailyDuration: dailyDuration ?? this.dailyDuration,
      currentOccurrence: currentOccurrence ?? this.currentOccurrence,
      totalOccurrences: totalOccurrences ?? this.totalOccurrences,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      isDelayed: isDelayed ?? this.isDelayed,
      needsProcrastinationDiary: needsProcrastinationDiary ?? this.needsProcrastinationDiary,
      // 拖延记录
      isPostponed: isPostponed ?? this.isPostponed,
      postponedDays: postponedDays ?? this.postponedDays,
      postponeReason: postponeReason ?? this.postponeReason,
      delayLevel: delayLevel ?? this.delayLevel,
      lastRemindTime: lastRemindTime ?? this.lastRemindTime,
      remindCount: remindCount ?? this.remindCount,
      ignoreCount: ignoreCount ?? this.ignoreCount,
      lastIgnoreTime: lastIgnoreTime ?? this.lastIgnoreTime,
      isPriority: isPriority ?? this.isPriority,
      isUrgent: isUrgent ?? this.isUrgent,
      // 跨天任务
      isRolledOver: isRolledOver ?? this.isRolledOver,
      originalDate: originalDate ?? this.originalDate,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  /// 是否为主任务
  bool get isMainTask => level == 1;

  /// 是否为子任务
  bool get isSubtask => level == 2;

  /// 是否有子任务
  bool get hasSubtasks => subtaskIds.isNotEmpty;
  
  /// 是否已过期（超过截止时间）
  bool get isOverdue {
    if (deadline == null || completed) return false;
    return DateTime.now().isAfter(deadline!);
  }
  
  /// 是否应该开始（到达开始时间）
  bool get shouldStart {
    if (startTime == null || completed) return false;
    return DateTime.now().isAfter(startTime!);
  }
  
  /// 预计结束时间
  DateTime? get estimatedEndTime {
    if (startTime == null || estimatedDuration == null) return null;
    return startTime!.add(estimatedDuration!);
  }
  
  /// 是否超时（超过预计完成时间的50%）
  bool get isOvertime {
    if (estimatedEndTime == null || completed) return false;
    final now = DateTime.now();
    if (!now.isAfter(estimatedEndTime!)) return false;
    
    final overtimeThreshold = estimatedEndTime!.add(
      Duration(milliseconds: (estimatedDuration!.inMilliseconds * 0.5).round())
    );
    return now.isAfter(overtimeThreshold);
  }
  
  /// 获取拖延天数（基于截止时间或预计完成时间）
  int get actualDelayDays {
    if (completed) return 0;
    
    final now = DateTime.now();
    DateTime? referenceTime;
    
    if (deadline != null) {
      referenceTime = deadline;
    } else if (estimatedEndTime != null) {
      referenceTime = estimatedEndTime;
    } else if (startTime != null) {
      // 如果只有开始时间，按开始时间后1天算
      referenceTime = startTime!.add(const Duration(days: 1));
    }
    
    if (referenceTime == null || !now.isAfter(referenceTime)) return 0;
    
    return now.difference(referenceTime).inDays;
  }
  
  /// 计算当前拖延等级
  DelayLevel get currentDelayLevel {
    if (completed) return DelayLevel.none;
    
    final delayDays = actualDelayDays;
    if (delayDays == 0) return DelayLevel.none;
    if (delayDays <= 1) return DelayLevel.light;
    if (delayDays <= 3) return DelayLevel.moderate;
    return DelayLevel.severe;
  }
  
  /// 是否需要提醒
  bool shouldRemind(DateTime unifiedRemindTime) {
    if (completed) return false;
    
    final now = DateTime.now();
    
    // 如果有开始时间且已到开始时间
    if (startTime != null && now.isAfter(startTime!)) {
      return true;
    }
    
    // 如果没有开始时间，在统一提醒时间提醒
    if (startTime == null && now.isAfter(unifiedRemindTime)) {
      return true;
    }
    
    // 如果有开始时间但早于统一提醒时间，且当前时间已过统一提醒时间
    if (startTime != null && 
        startTime!.isBefore(unifiedRemindTime) && 
        now.isAfter(unifiedRemindTime)) {
      return true;
    }
    
    return false;
  }
  
  /// 计算忽略后的提醒间隔（分钟）
  int getIgnoreInterval() {
    if (ignoreCount == 0) return 0;
    
    // 基础间隔：30分钟
    final baseInterval = 30;
    
    // 忽略次数越多，间隔越长
    final multiplier = (ignoreCount * 1.5).clamp(1.0, 8.0);
    
    return (baseInterval * multiplier).round();
  }
  
  /// 检查是否应该在忽略后提醒
  bool shouldRemindAfterIgnore() {
    if (lastIgnoreTime == null) return false;
    
    final now = DateTime.now();
    final ignoreInterval = getIgnoreInterval();
    
    return now.difference(lastIgnoreTime!).inMinutes >= ignoreInterval;
  }
  
  /// 获取拖延等级描述
  String get delayLevelDescription {
    switch (currentDelayLevel) {
      case DelayLevel.none:
        return '正常';
      case DelayLevel.light:
        return '轻度拖延';
      case DelayLevel.moderate:
        return '中度拖延';
      case DelayLevel.severe:
        return '严重拖延';
    }
  }
  
  /// 获取任务类型描述
  String get taskTypeDescription {
    switch (taskType) {
      case TaskType.today:
        return '今日待办';
      case TaskType.daily:
        return '每日待办';
    }
  }

  /// 是否为AI拆分的任务
  bool get isAiGenerated => source == 'ai_split';

  /// 获取任务的四象限分类
  QuadrantType get quadrantType {
    if (isPriority && isUrgent) {
      return QuadrantType.importantUrgent;
    } else if (isPriority && !isUrgent) {
      return QuadrantType.importantNotUrgent;
    } else if (!isPriority && isUrgent) {
      return QuadrantType.notImportantUrgent;
    } else {
      return QuadrantType.notImportantNotUrgent;
    }
  }

  /// 获取四象限标题
  String get quadrantTitle {
    switch (quadrantType) {
      case QuadrantType.importantUrgent:
        return '重要且紧急';
      case QuadrantType.importantNotUrgent:
        return '重要不紧急';
      case QuadrantType.notImportantUrgent:
        return '不重要但紧急';
      case QuadrantType.notImportantNotUrgent:
        return '不重要不紧急';
    }
  }

  /// 获取四象限颜色
  Color get quadrantColor {
    switch (quadrantType) {
      case QuadrantType.importantUrgent:
        return Colors.red.shade100;
      case QuadrantType.importantNotUrgent:
        return Colors.orange.shade100;
      case QuadrantType.notImportantUrgent:
        return Colors.blue.shade100;
      case QuadrantType.notImportantNotUrgent:
        return Colors.green.shade100;
    }
  }

  @override
  String toString() {
    return 'TodoItem(id: $id, text: $text, level: $level, parentId: $parentId, subtasks: ${subtaskIds.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TodoItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
