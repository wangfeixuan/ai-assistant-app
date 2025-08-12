import 'pomodoro_mode.dart';

/// 严格模式违规记录
class StrictModeViolation {
  final DateTime timestamp;
  final Duration plannedDuration;
  final Duration actualDuration;
  final PomodoroMode mode;
  final String reason;

  StrictModeViolation({
    required this.timestamp,
    required this.plannedDuration,
    required this.actualDuration,
    required this.mode,
    this.reason = '离开应用',
  });

  /// 计算完成率
  double get completionRate {
    if (plannedDuration.inSeconds == 0) return 0.0;
    return actualDuration.inSeconds / plannedDuration.inSeconds;
  }

  /// 获取模式名称
  String get modeName {
    switch (mode) {
      case PomodoroMode.pomodoro:
        return '专注';
      case PomodoroMode.shortBreak:
        return '短休息';
      case PomodoroMode.longBreak:
        return '长休息';
    }
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'plannedDuration': plannedDuration.inSeconds,
    'actualDuration': actualDuration.inSeconds,
    'mode': mode.index,
    'reason': reason,
  };

  /// 从JSON创建对象
  factory StrictModeViolation.fromJson(Map<String, dynamic> json) {
    return StrictModeViolation(
      timestamp: DateTime.parse(json['timestamp']),
      plannedDuration: Duration(seconds: json['plannedDuration']),
      actualDuration: Duration(seconds: json['actualDuration']),
      mode: PomodoroMode.values[json['mode']],
      reason: json['reason'] ?? '离开应用',
    );
  }

  @override
  String toString() {
    return 'StrictModeViolation(timestamp: $timestamp, mode: $modeName, '
           'completion: ${(completionRate * 100).toInt()}%)';
  }
}
