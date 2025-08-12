import 'package:flutter/material.dart';
import 'todo_item.dart'; // 导入DelayLevel枚举

/// 拖延原因枚举
enum DelayReason {
  lackOfMotivation,    // 缺乏动力
  taskTooComplex,      // 任务太复杂
  lackOfTime,          // 时间不够
  distractions,        // 分心/干扰
  perfectionism,       // 完美主义
  fearOfFailure,       // 害怕失败
  lackOfSkills,        // 技能不足
  poorPlanning,        // 计划不当
  fatigue,             // 疲劳
  moodIssues,          // 情绪问题
  other                // 其他原因
}

/// 拖延日记条目数据模型
class DelayDiaryEntry {
  final String id;
  final String taskId; // 关联的任务ID
  final String taskName; // 任务名称（冗余存储，便于查询）
  final DateTime delayDate; // 拖延日期
  final DelayReason primaryReason; // 主要拖延原因
  final List<DelayReason> secondaryReasons; // 次要拖延原因
  final String? customReason; // 自定义拖延原因
  final String? reflection; // 反思记录
  final int delayDays; // 拖延天数
  final DelayLevel delayLevel; // 拖延等级
  final DateTime createdAt; // 创建时间
  final bool isResolved; // 是否已解决
  final DateTime? resolvedAt; // 解决时间
  final String? resolution; // 解决方案记录

  const DelayDiaryEntry({
    required this.id,
    required this.taskId,
    required this.taskName,
    required this.delayDate,
    required this.primaryReason,
    this.secondaryReasons = const [],
    this.customReason,
    this.reflection,
    required this.delayDays,
    required this.delayLevel,
    required this.createdAt,
    this.isResolved = false,
    this.resolvedAt,
    this.resolution,
  });

  /// 从JSON创建DelayDiaryEntry
  factory DelayDiaryEntry.fromJson(Map<String, dynamic> json) {
    return DelayDiaryEntry(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      taskName: json['taskName'] as String,
      delayDate: DateTime.parse(json['delayDate'] as String),
      primaryReason: DelayReason.values.firstWhere(
        (e) => e.toString() == 'DelayReason.${json['primaryReason']}',
        orElse: () => DelayReason.other,
      ),
      secondaryReasons: (json['secondaryReasons'] as List<dynamic>?)
          ?.map((e) => DelayReason.values.firstWhere(
                (reason) => reason.toString() == 'DelayReason.$e',
                orElse: () => DelayReason.other,
              ))
          .toList() ?? [],
      customReason: json['customReason'] as String?,
      reflection: json['reflection'] as String?,
      delayDays: json['delayDays'] as int,
      delayLevel: DelayLevel.values.firstWhere(
        (e) => e.toString() == 'DelayLevel.${json['delayLevel']}',
        orElse: () => DelayLevel.none,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isResolved: json['isResolved'] as bool? ?? false,
      resolvedAt: json['resolvedAt'] != null 
        ? DateTime.parse(json['resolvedAt'] as String) 
        : null,
      resolution: json['resolution'] as String?,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'taskName': taskName,
      'delayDate': delayDate.toIso8601String(),
      'primaryReason': primaryReason.toString().split('.').last,
      'secondaryReasons': secondaryReasons.map((e) => e.toString().split('.').last).toList(),
      'customReason': customReason,
      'reflection': reflection,
      'delayDays': delayDays,
      'delayLevel': delayLevel.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'isResolved': isResolved,
      'resolvedAt': resolvedAt?.toIso8601String(),
      'resolution': resolution,
    };
  }

  /// 创建副本并修改指定属性
  DelayDiaryEntry copyWith({
    String? id,
    String? taskId,
    String? taskName,
    DateTime? delayDate,
    DelayReason? primaryReason,
    List<DelayReason>? secondaryReasons,
    String? customReason,
    String? reflection,
    int? delayDays,
    DelayLevel? delayLevel,
    DateTime? createdAt,
    bool? isResolved,
    DateTime? resolvedAt,
    String? resolution,
  }) {
    return DelayDiaryEntry(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      taskName: taskName ?? this.taskName,
      delayDate: delayDate ?? this.delayDate,
      primaryReason: primaryReason ?? this.primaryReason,
      secondaryReasons: secondaryReasons ?? this.secondaryReasons,
      customReason: customReason ?? this.customReason,
      reflection: reflection ?? this.reflection,
      delayDays: delayDays ?? this.delayDays,
      delayLevel: delayLevel ?? this.delayLevel,
      createdAt: createdAt ?? this.createdAt,
      isResolved: isResolved ?? this.isResolved,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolution: resolution ?? this.resolution,
    );
  }

  /// 获取拖延原因描述
  String get primaryReasonDescription => _getReasonDescription(primaryReason);
  
  /// 获取所有拖延原因描述
  List<String> get allReasonsDescriptions {
    final reasons = [primaryReason, ...secondaryReasons];
    return reasons.map(_getReasonDescription).toList();
  }

  /// 获取拖延原因的中文描述
  static String _getReasonDescription(DelayReason reason) {
    switch (reason) {
      case DelayReason.lackOfMotivation:
        return '缺乏动力';
      case DelayReason.taskTooComplex:
        return '任务太复杂';
      case DelayReason.lackOfTime:
        return '时间不够';
      case DelayReason.distractions:
        return '分心/干扰';
      case DelayReason.perfectionism:
        return '完美主义';
      case DelayReason.fearOfFailure:
        return '害怕失败';
      case DelayReason.lackOfSkills:
        return '技能不足';
      case DelayReason.poorPlanning:
        return '计划不当';
      case DelayReason.fatigue:
        return '疲劳';
      case DelayReason.moodIssues:
        return '情绪问题';
      case DelayReason.other:
        return '其他原因';
    }
  }

  /// 获取拖延等级颜色
  Color get delayLevelColor {
    switch (delayLevel) {
      case DelayLevel.none:
        return Colors.green;
      case DelayLevel.light:
        return Colors.yellow;
      case DelayLevel.moderate:
        return Colors.orange;
      case DelayLevel.severe:
        return Colors.red;
    }
  }
}

/// 任务类型分析数据
class TaskTypeAnalysis {
  final String taskType; // 任务类型名称
  final int delayCount; // 拖延次数
  final double averageDelayDays; // 平均拖延天数
  final List<DelayReason> commonReasons; // 常见拖延原因
  final double improvementSuggestionScore; // 改进建议评分

  const TaskTypeAnalysis({
    required this.taskType,
    required this.delayCount,
    required this.averageDelayDays,
    required this.commonReasons,
    required this.improvementSuggestionScore,
  });
}

/// 时间分析数据
class TimeAnalysis {
  final int bestHour; // 最佳工作小时
  final int worstHour; // 最容易拖延的小时
  final int bestWeekday; // 最佳工作日
  final int worstWeekday; // 最容易拖延的工作日
  final Map<int, double> hourlyProductivity; // 小时级生产力指数

  const TimeAnalysis({
    required this.bestHour,
    required this.worstHour,
    required this.bestWeekday,
    required this.worstWeekday,
    required this.hourlyProductivity,
  });
}

/// 拖延分析统计数据模型
class DelayAnalytics {
  final int totalDelayDays; // 总拖延天数
  final int totalDelayTasks; // 总拖延任务数
  final Map<DelayReason, int> reasonFrequency; // 拖延原因频率统计
  final Map<DelayLevel, int> levelDistribution; // 拖延等级分布
  final Map<int, int> hourlyDelayPattern; // 小时级拖延模式（0-23小时）
  final Map<int, int> weeklyDelayPattern; // 周级拖延模式（1-7，周一到周日）
  final double averageDelayDays; // 平均拖延天数
  final List<TaskTypeAnalysis> taskTypeAnalysis; // 任务类型分析
  final List<String> improvementSuggestions; // 改进建议
  final TimeAnalysis bestProductiveTime; // 最佳工作时间分析
  final List<DateTime> delayTrend; // 拖延趋势（按日期）
  final Map<String, int> delayTrendData; // 拖延趋势数据（日期 -> 拖延任务数）

  const DelayAnalytics({
    required this.totalDelayDays,
    required this.totalDelayTasks,
    required this.reasonFrequency,
    required this.levelDistribution,
    required this.hourlyDelayPattern,
    required this.weeklyDelayPattern,
    required this.averageDelayDays,
    required this.taskTypeAnalysis,
    required this.improvementSuggestions,
    required this.bestProductiveTime,
    required this.delayTrend,
    required this.delayTrendData,
  });

  /// 从拖延日记条目列表生成分析数据
  factory DelayAnalytics.fromEntries(List<DelayDiaryEntry> entries) {
    if (entries.isEmpty) {
      return DelayAnalytics(
        totalDelayDays: 0,
        totalDelayTasks: 0,
        reasonFrequency: {},
        levelDistribution: {},
        hourlyDelayPattern: {},
        weeklyDelayPattern: {},
        averageDelayDays: 0.0,
        taskTypeAnalysis: [],
        improvementSuggestions: [],
        bestProductiveTime: const TimeAnalysis(
          bestHour: 9, worstHour: 21, bestWeekday: 2, worstWeekday: 1,
          hourlyProductivity: {},
        ),
        delayTrend: [],
        delayTrendData: {},
      );
    }

    // 计算基础统计
    final totalDelayDays = entries.fold<int>(0, (sum, entry) => sum + entry.delayDays);
    final totalDelayTasks = entries.length;
    final averageDelayDays = totalDelayDays / totalDelayTasks;

    // 统计拖延原因频率
    final reasonFrequency = <DelayReason, int>{};
    for (final entry in entries) {
      reasonFrequency[entry.primaryReason] = 
        (reasonFrequency[entry.primaryReason] ?? 0) + 1;
      for (final reason in entry.secondaryReasons) {
        reasonFrequency[reason] = (reasonFrequency[reason] ?? 0) + 1;
      }
    }

    // 统计拖延等级分布
    final levelDistribution = <DelayLevel, int>{};
    for (final entry in entries) {
      levelDistribution[entry.delayLevel] = 
        (levelDistribution[entry.delayLevel] ?? 0) + 1;
    }

    // 统计时间模式
    final hourlyDelayPattern = <int, int>{};
    final weeklyDelayPattern = <int, int>{};
    for (final entry in entries) {
      final hour = entry.delayDate.hour;
      final weekday = entry.delayDate.weekday;
      hourlyDelayPattern[hour] = (hourlyDelayPattern[hour] ?? 0) + 1;
      weeklyDelayPattern[weekday] = (weeklyDelayPattern[weekday] ?? 0) + 1;
    }

    // 分析任务类型
    final taskTypeAnalysis = _analyzeTaskTypes(entries);

    // 分析最佳工作时间
    final bestProductiveTime = _analyzeBestTime(hourlyDelayPattern, weeklyDelayPattern);

    // 生成拖延趋势数据
    final delayTrendData = _generateTrendData(entries);
    final delayTrend = delayTrendData.keys.map((dateStr) => DateTime.parse(dateStr)).toList()
      ..sort();

    // 生成改进建议
    final improvementSuggestions = _generateAdvancedSuggestions(
      reasonFrequency, levelDistribution, averageDelayDays, 
      taskTypeAnalysis, bestProductiveTime
    );

    return DelayAnalytics(
      totalDelayDays: totalDelayDays,
      totalDelayTasks: totalDelayTasks,
      reasonFrequency: reasonFrequency,
      levelDistribution: levelDistribution,
      hourlyDelayPattern: hourlyDelayPattern,
      weeklyDelayPattern: weeklyDelayPattern,
      averageDelayDays: averageDelayDays,
      taskTypeAnalysis: taskTypeAnalysis,
      improvementSuggestions: improvementSuggestions,
      bestProductiveTime: bestProductiveTime,
      delayTrend: delayTrend,
      delayTrendData: delayTrendData,
    );
  }

  /// 生成改进建议
  static List<String> _generateImprovementSuggestions(
    Map<DelayReason, int> reasonFrequency,
    Map<DelayLevel, int> levelDistribution,
    double averageDelayDays,
  ) {
    final suggestions = <String>[];

    // 基于最常见的拖延原因给出建议
    final topReason = reasonFrequency.entries
      .reduce((a, b) => a.value > b.value ? a : b)
      .key;

    switch (topReason) {
      case DelayReason.lackOfMotivation:
        suggestions.add('尝试将大任务拆分成小目标，每完成一个小目标就奖励自己');
        break;
      case DelayReason.taskTooComplex:
        suggestions.add('将复杂任务分解为更小的可执行步骤');
        break;
      case DelayReason.lackOfTime:
        suggestions.add('重新评估时间分配，考虑使用番茄钟技术提高专注度');
        break;
      case DelayReason.distractions:
        suggestions.add('创造专注环境，关闭不必要的通知和干扰源');
        break;
      case DelayReason.perfectionism:
        suggestions.add('设定"足够好"的标准，避免过度追求完美');
        break;
      default:
        suggestions.add('建议记录更详细的拖延原因，以便提供针对性建议');
    }

    // 基于拖延严重程度给出建议
    final severeDelays = levelDistribution[DelayLevel.severe] ?? 0;
    if (severeDelays > 0) {
      suggestions.add('严重拖延任务较多，建议寻求专业帮助或调整任务优先级');
    }

    // 基于平均拖延天数给出建议
    if (averageDelayDays > 3) {
      suggestions.add('平均拖延时间较长，建议设置更频繁的提醒和检查点');
    }

    return suggestions;
  }

  /// 分析任务类型
  static List<TaskTypeAnalysis> _analyzeTaskTypes(List<DelayDiaryEntry> entries) {
    final taskTypes = <String, List<DelayDiaryEntry>>{};
    
    // 按任务类型分组
    for (final entry in entries) {
      final taskName = entry.taskName.toLowerCase();
      String category = '其他';
      
      if (taskName.contains('学习') || taskName.contains('复习') || taskName.contains('读书')) {
        category = '学习类';
      } else if (taskName.contains('工作') || taskName.contains('项目') || taskName.contains('会议')) {
        category = '工作类';
      } else if (taskName.contains('运动') || taskName.contains('健身') || taskName.contains('锻炼')) {
        category = '运动类';
      } else if (taskName.contains('家务') || taskName.contains('购物') || taskName.contains('整理')) {
        category = '生活类';
      } else if (taskName.contains('写作') || taskName.contains('创作') || taskName.contains('设计')) {
        category = '创作类';
      }
      
      taskTypes[category] ??= [];
      taskTypes[category]!.add(entry);
    }
    
    // 分析每个类型
    final analyses = <TaskTypeAnalysis>[];
    for (final entry in taskTypes.entries) {
      final type = entry.key;
      final typeEntries = entry.value;
      
      final delayCount = typeEntries.length;
      final averageDelayDays = typeEntries.fold(0, (sum, e) => sum + e.delayDays) / delayCount;
      
      // 统计常见原因
      final reasonCounts = <DelayReason, int>{};
      for (final e in typeEntries) {
        reasonCounts[e.primaryReason] = (reasonCounts[e.primaryReason] ?? 0) + 1;
        for (final reason in e.secondaryReasons) {
          reasonCounts[reason] = (reasonCounts[reason] ?? 0) + 1;
        }
      }
      
      final commonReasons = reasonCounts.entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      // 计算改进建议评分
      double score = 1.0;
      if (averageDelayDays > 5) score -= 0.3;
      if (delayCount > 5) score -= 0.2;
      if (commonReasons.isNotEmpty && 
          commonReasons.first.key == DelayReason.taskTooComplex) score -= 0.3;
      
      analyses.add(TaskTypeAnalysis(
        taskType: type,
        delayCount: delayCount,
        averageDelayDays: averageDelayDays,
        commonReasons: commonReasons.take(3).map((e) => e.key).toList(),
        improvementSuggestionScore: score.clamp(0.0, 1.0),
      ));
    }
    
    analyses.sort((a, b) => b.delayCount.compareTo(a.delayCount));
    return analyses;
  }

  /// 分析最佳工作时间
  static TimeAnalysis _analyzeBestTime(
    Map<int, int> hourlyDelayPattern, 
    Map<int, int> weeklyDelayPattern
  ) {
    // 计算生产力指数（拖延越少 = 生产力越高）
    final hourlyProductivity = <int, double>{};
    final maxDelayCount = hourlyDelayPattern.values.isNotEmpty 
      ? hourlyDelayPattern.values.reduce((a, b) => a > b ? a : b) : 1;
    
    for (int hour = 0; hour < 24; hour++) {
      final delayCount = hourlyDelayPattern[hour] ?? 0;
      // 生产力 = 1 - (拖延次数 / 最大拖延次数)
      hourlyProductivity[hour] = 1.0 - (delayCount / maxDelayCount);
    }
    
    // 找到最佳和最差时间
    var bestHour = 9;
    var worstHour = 21;
    double maxProductivity = 0;
    double minProductivity = 1;
    
    hourlyProductivity.forEach((hour, productivity) {
      if (productivity > maxProductivity) {
        maxProductivity = productivity;
        bestHour = hour;
      }
      if (productivity < minProductivity) {
        minProductivity = productivity;
        worstHour = hour;
      }
    });
    
    // 分析周级模式
    var bestWeekday = 2; // 默认周二
    var worstWeekday = 1; // 默认周一
    int minWeeklyDelay = 999;
    int maxWeeklyDelay = 0;
    
    weeklyDelayPattern.forEach((weekday, delayCount) {
      if (delayCount < minWeeklyDelay) {
        minWeeklyDelay = delayCount;
        bestWeekday = weekday;
      }
      if (delayCount > maxWeeklyDelay) {
        maxWeeklyDelay = delayCount;
        worstWeekday = weekday;
      }
    });
    
    return TimeAnalysis(
      bestHour: bestHour,
      worstHour: worstHour,
      bestWeekday: bestWeekday,
      worstWeekday: worstWeekday,
      hourlyProductivity: hourlyProductivity,
    );
  }

  /// 生成趋势数据
  static Map<String, int> _generateTrendData(List<DelayDiaryEntry> entries) {
    final trendData = <String, int>{};
    
    for (final entry in entries) {
      final dateStr = '${entry.delayDate.year}-${entry.delayDate.month.toString().padLeft(2, '0')}-${entry.delayDate.day.toString().padLeft(2, '0')}';
      trendData[dateStr] = (trendData[dateStr] ?? 0) + 1;
    }
    
    return trendData;
  }

  /// 生成高级改进建议
  static List<String> _generateAdvancedSuggestions(
    Map<DelayReason, int> reasonFrequency,
    Map<DelayLevel, int> levelDistribution,
    double averageDelayDays,
    List<TaskTypeAnalysis> taskTypeAnalysis,
    TimeAnalysis bestProductiveTime,
  ) {
    final suggestions = <String>[];

    // 基于时间分析的建议
    if (bestProductiveTime.bestHour >= 6 && bestProductiveTime.bestHour <= 10) {
      suggestions.add('您在上午${bestProductiveTime.bestHour}点最有效率，建议将重要任务安排在这个时间段');
    } else if (bestProductiveTime.bestHour >= 14 && bestProductiveTime.bestHour <= 18) {
      suggestions.add('您在下午${bestProductiveTime.bestHour}点效率最高，可以将核心工作安排在此时');
    }

    // 基于任务类型的建议
    if (taskTypeAnalysis.isNotEmpty) {
      final mostProblematicType = taskTypeAnalysis.first;
      switch (mostProblematicType.taskType) {
        case '学习类':
          suggestions.add('学习类任务拖延较多，建议使用番茄钟技术，将学习时间拆分为25分钟的小块');
          break;
        case '工作类':
          suggestions.add('工作任务拖延频繁，考虑在每日最佳时间段处理最重要的工作事项');
          break;
        case '运动类':
          suggestions.add('运动拖延问题突出，建议设定固定的运动时间，或寻找运动伙伴增加动力');
          break;
        case '创作类':
          suggestions.add('创作类任务需要灵感，建议在精神状态最佳时进行，避免强迫自己创作');
          break;
      }
    }

    // 基于拖延原因的深度分析建议
    final topReason = reasonFrequency.entries.isNotEmpty 
      ? reasonFrequency.entries.reduce((a, b) => a.value > b.value ? a : b).key
      : DelayReason.other;

    switch (topReason) {
      case DelayReason.lackOfMotivation:
        suggestions.add('缺乏动力是主要问题，建议设定明确的奖励机制，完成任务后给自己小奖励');
        suggestions.add('尝试与他人分享目标，获得外部监督和支持');
        break;
      case DelayReason.taskTooComplex:
        suggestions.add('任务过于复杂，建议使用"两分钟法则"，先做能在2分钟内完成的部分');
        suggestions.add('将大任务分解为不超过1小时的小任务，降低心理压力');
        break;
      case DelayReason.perfectionism:
        suggestions.add('完美主义倾向明显，尝试设定"足够好"的标准，避免过度修改');
        suggestions.add('为每个任务设定时间上限，到时间就停止，避免无限优化');
        break;
      case DelayReason.distractions:
        suggestions.add('环境干扰严重，建议创建专门的工作空间，关闭所有不必要的通知');
        suggestions.add('使用网站屏蔽工具，在工作时间限制娱乐网站访问');
        break;
      default:
        break;
    }

    // 基于拖延严重程度的建议
    final severeDelays = levelDistribution[DelayLevel.severe] ?? 0;
    final totalDelays = levelDistribution.values.fold(0, (a, b) => a + b);
    
    if (severeDelays > totalDelays * 0.3) {
      suggestions.add('严重拖延比例较高，建议寻求专业的时间管理指导或心理咨询');
      suggestions.add('考虑使用更严格的自我监控系统，如每日打卡和进度跟踪');
    }

    // 基于平均拖延天数的建议
    if (averageDelayDays > 7) {
      suggestions.add('平均拖延时间过长，建议重新评估任务的现实性和优先级');
      suggestions.add('采用"一分钟开始法"，承诺只做一分钟，通常会发现可以继续下去');
    }

    // 智能个性化建议算法
    suggestions.addAll(_generatePersonalizedSuggestions(
      reasonFrequency, 
      levelDistribution, 
      averageDelayDays, 
      taskTypeAnalysis, 
      bestProductiveTime
    ));

    return suggestions;
  }

  /// 生成个性化智能建议
  static List<String> _generatePersonalizedSuggestions(
    Map<DelayReason, int> reasonFrequency,
    Map<DelayLevel, int> levelDistribution,
    double averageDelayDays,
    List<TaskTypeAnalysis> taskTypeAnalysis,
    TimeAnalysis bestProductiveTime,
  ) {
    final personalizedSuggestions = <String>[];

    // 基于拖延模式的智能分析
    final totalReasons = reasonFrequency.values.fold(0, (a, b) => a + b);
    if (totalReasons > 0) {
      // 分析主导拖延原因
      final dominantReasons = reasonFrequency.entries
          .where((e) => e.value > totalReasons * 0.3)
          .map((e) => e.key)
          .toList();

      // 组合拖延原因的智能建议
      if (dominantReasons.contains(DelayReason.lackOfMotivation) &&
          dominantReasons.contains(DelayReason.taskTooComplex)) {
        personalizedSuggestions.add('您同时面临动力不足和任务复杂的问题，建议先将任务简化，再设置小奖励激励自己');
      }

      if (dominantReasons.contains(DelayReason.perfectionism) &&
          dominantReasons.contains(DelayReason.fearOfFailure)) {
        personalizedSuggestions.add('完美主义和害怕失败往往相关，尝试接受"足够好"的结果，并将失败视为学习机会');
      }

      if (dominantReasons.contains(DelayReason.distractions) &&
          dominantReasons.contains(DelayReason.lackOfMotivation)) {
        personalizedSuggestions.add('环境干扰和动力不足的组合很常见，建议创造专注环境并设立明确目标');
      }
    }

    // 基于生产力时间模式的个性化建议
    final hourlyProductivity = bestProductiveTime.hourlyProductivity;
    if (hourlyProductivity.isNotEmpty) {
      final morningProductivity = hourlyProductivity.entries
          .where((e) => e.key >= 6 && e.key <= 12)
          .map((e) => e.value)
          .fold(0.0, (a, b) => a + b) / 7;

      final afternoonProductivity = hourlyProductivity.entries
          .where((e) => e.key >= 13 && e.key <= 18)
          .map((e) => e.value)
          .fold(0.0, (a, b) => a + b) / 6;

      final eveningProductivity = hourlyProductivity.entries
          .where((e) => e.key >= 19 && e.key <= 23)
          .map((e) => e.value)
          .fold(0.0, (a, b) => a + b) / 5;

      if (morningProductivity > afternoonProductivity && morningProductivity > eveningProductivity) {
        personalizedSuggestions.add('您是晨型人，建议在上午安排最重要的任务，下午处理routine工作');
      } else if (eveningProductivity > morningProductivity && eveningProductivity > afternoonProductivity) {
        personalizedSuggestions.add('您在晚上效率较高，可以利用晚间时光处理创造性工作，但注意不要太晚影响睡眠');
      }
    }

    // 基于任务类型组合的智能建议
    if (taskTypeAnalysis.length >= 2) {
      final topTwoTypes = taskTypeAnalysis.take(2).toList();
      final type1 = topTwoTypes[0];
      final type2 = topTwoTypes[1];

      if (type1.taskType == '工作类' && type2.taskType == '学习类') {
        personalizedSuggestions.add('工作和学习任务都容易拖延，建议交替进行，利用不同类型任务间的切换来保持新鲜感');
      } else if (type1.taskType == '运动类') {
        personalizedSuggestions.add('运动拖延最严重，这可能影响整体精力状态，建议从每天10分钟的轻度运动开始');
      }
    }

    // 基于拖延严重度分布的智能建议
    final totalDelays = levelDistribution.values.fold(0, (a, b) => a + b);
    if (totalDelays > 0) {
      final lightDelays = levelDistribution[DelayLevel.light] ?? 0;
      final moderateDelays = levelDistribution[DelayLevel.moderate] ?? 0;
      final severeDelays = levelDistribution[DelayLevel.severe] ?? 0;

      if (lightDelays > totalDelays * 0.6) {
        personalizedSuggestions.add('您的拖延程度主要是轻度，这说明您有很好的自控基础，只需要一些技巧调整');
      } else if (severeDelays > totalDelays * 0.4) {
        personalizedSuggestions.add('严重拖延较多，建议寻求专业帮助，或者使用更强的外部约束机制');
      }
    }

    // 基于拖延频率的时间管理建议
    if (averageDelayDays <= 2) {
      personalizedSuggestions.add('您的平均拖延时间较短，说明执行力不错，可以尝试更有挑战性的目标');
    } else if (averageDelayDays > 5) {
      personalizedSuggestions.add('平均拖延时间较长，建议使用"截止日期前置法"，为自己设置更早的内部截止时间');
    }

    // 基于综合数据的生活方式建议
    if (totalDelays > 20 && averageDelayDays > 3) {
      personalizedSuggestions.add('您的拖延问题较为突出，建议从生活作息、工作环境、目标设定等多个维度进行改善');
    }

    return personalizedSuggestions;
  }
}


