/// 拖延日记相关的数据模型

class ProcrastinationReason {
  static const String tooTired = 'too_tired';
  static const String dontKnowHow = 'dont_know_how';
  static const String notInMood = 'not_in_mood';
  static const String tooDifficult = 'too_difficult';
  static const String noTime = 'no_time';
  static const String distracted = 'distracted';
  static const String notImportant = 'not_important';
  static const String perfectionism = 'perfectionism';
  static const String fearOfFailure = 'fear_of_failure';
  static const String procrastinationHabit = 'procrastination_habit';
  static const String custom = 'custom';

  static const Map<String, String> reasonLabels = {
    tooTired: '太累了',
    dontKnowHow: '不知道怎么做',
    notInMood: '没心情',
    tooDifficult: '太难了',
    noTime: '没时间',
    distracted: '被打断了',
    notImportant: '不重要',
    perfectionism: '想做到完美',
    fearOfFailure: '害怕失败',
    procrastinationHabit: '习惯性拖延',
    custom: '其他原因（自定义）',
  };

  static String getLabel(String reason) {
    return reasonLabels[reason] ?? '未知原因';
  }

  static List<ReasonOption> getAllReasons() {
    return reasonLabels.entries
        .map((entry) => ReasonOption(value: entry.key, label: entry.value))
        .toList();
  }
}

class ReasonOption {
  final String value;
  final String label;

  ReasonOption({required this.value, required this.label});

  factory ReasonOption.fromJson(Map<String, dynamic> json) {
    return ReasonOption(
      value: json['value'] ?? '',
      label: json['label'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'label': label,
    };
  }
}

class ProcrastinationDiary {
  final int? id;
  final int userId;
  final int? taskId;
  final String taskTitle;
  final String reasonType;
  final String reasonDisplay;
  final String? customReason;
  final int? moodBefore;
  final int? moodAfter;
  final DateTime procrastinationDate;
  final DateTime createdAt;

  ProcrastinationDiary({
    this.id,
    required this.userId,
    this.taskId,
    required this.taskTitle,
    required this.reasonType,
    required this.reasonDisplay,
    this.customReason,
    this.moodBefore,
    this.moodAfter,
    required this.procrastinationDate,
    required this.createdAt,
  });

  factory ProcrastinationDiary.fromJson(Map<String, dynamic> json) {
    return ProcrastinationDiary(
      id: json['id'],
      userId: json['user_id'],
      taskId: json['task_id'],
      taskTitle: json['task_title'] ?? '',
      reasonType: json['reason_type'] ?? '',
      reasonDisplay: json['reason_display'] ?? '',
      customReason: json['custom_reason'],
      moodBefore: json['mood_before'],
      moodAfter: json['mood_after'],
      procrastinationDate: DateTime.parse(json['procrastination_date']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'task_id': taskId,
      'task_title': taskTitle,
      'reason_type': reasonType,
      'reason_display': reasonDisplay,
      'custom_reason': customReason,
      'mood_before': moodBefore,
      'mood_after': moodAfter,
      'procrastination_date': procrastinationDate.toIso8601String().split('T')[0],
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ProcrastinationStats {
  final int userId;
  final int totalProcrastinations;
  final String? mostCommonReason;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastProcrastinationDate;
  final DateTime updatedAt;

  ProcrastinationStats({
    required this.userId,
    required this.totalProcrastinations,
    this.mostCommonReason,
    required this.currentStreak,
    required this.longestStreak,
    this.lastProcrastinationDate,
    required this.updatedAt,
  });

  factory ProcrastinationStats.fromJson(Map<String, dynamic> json) {
    return ProcrastinationStats(
      userId: json['user_id'],
      totalProcrastinations: json['total_procrastinations'] ?? 0,
      mostCommonReason: json['most_common_reason'],
      currentStreak: json['current_streak'] ?? 0,
      longestStreak: json['longest_streak'] ?? 0,
      lastProcrastinationDate: json['last_procrastination_date'] != null
          ? DateTime.parse(json['last_procrastination_date'])
          : null,
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class TopReason {
  final String reasonType;
  final String reasonDisplay;
  final int count;

  TopReason({
    required this.reasonType,
    required this.reasonDisplay,
    required this.count,
  });

  factory TopReason.fromJson(Map<String, dynamic> json) {
    return TopReason(
      reasonType: json['reason_type'] ?? '',
      reasonDisplay: json['reason_display'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class ProcrastinationAnalysis {
  final String analysis;
  final List<String> suggestions;
  final String moodAdvice;

  ProcrastinationAnalysis({
    required this.analysis,
    required this.suggestions,
    required this.moodAdvice,
  });

  factory ProcrastinationAnalysis.fromJson(Map<String, dynamic> json) {
    return ProcrastinationAnalysis(
      analysis: json['analysis'] ?? '',
      suggestions: List<String>.from(json['suggestions'] ?? []),
      moodAdvice: json['mood_advice'] ?? '',
    );
  }
}

class SingleProcrastinationAnalysis {
  final String analysis;
  final List<String> suggestions;
  final String moodAdvice;

  SingleProcrastinationAnalysis({
    required this.analysis,
    required this.suggestions,
    required this.moodAdvice,
  });

  factory SingleProcrastinationAnalysis.fromJson(Map<String, dynamic> json) {
    return SingleProcrastinationAnalysis(
      analysis: json['analysis'] ?? '',
      suggestions: List<String>.from(json['suggestions'] ?? []),
      moodAdvice: json['mood_advice'] ?? '',
    );
  }
}

class ProcrastinationStatsResponse {
  final ProcrastinationStats basicStats;
  final List<TopReason> topReasons;
  final Map<String, int> dailyTrend;

  ProcrastinationStatsResponse({
    required this.basicStats,
    required this.topReasons,
    required this.dailyTrend,
  });

  factory ProcrastinationStatsResponse.fromJson(Map<String, dynamic> json) {
    return ProcrastinationStatsResponse(
      basicStats: ProcrastinationStats.fromJson(json['basic_stats']),
      topReasons: (json['top_reasons'] as List)
          .map((item) => TopReason.fromJson(item))
          .toList(),
      dailyTrend: Map<String, int>.from(json['daily_trend'] ?? {}),
    );
  }
}
