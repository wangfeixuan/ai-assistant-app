import 'pomodoro_mode.dart';

/// 番茄钟会话模型
class PomodoroSession {
  final String id;
  final PomodoroMode mode;
  final DateTime startTime;
  final DateTime? endTime;
  final int duration; // 秒
  final bool completed;

  const PomodoroSession({
    required this.id,
    required this.mode,
    required this.startTime,
    this.endTime,
    required this.duration,
    required this.completed,
  });

  /// 从Map创建PomodoroSession
  factory PomodoroSession.fromMap(Map<String, dynamic> map) {
    return PomodoroSession(
      id: map['id']?.toString() ?? '',
      mode: PomodoroMode.values[_parseToInt(map['mode']) ?? 0],
      startTime: DateTime.fromMillisecondsSinceEpoch(_parseToInt(map['startTime']) ?? 0),
      endTime: map['endTime'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(_parseToInt(map['endTime']) ?? 0)
          : null,
      duration: _parseToInt(map['duration']) ?? 0,
      completed: _parseToBool(map['completed']) ?? false,
    );
  }
  
  /// 安全地将动态类型转换为int
  static int? _parseToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
  
  /// 安全地将动态类型转换为bool
  static bool? _parseToBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return null;
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mode': mode.index,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'duration': duration,
      'completed': completed,
    };
  }

  /// 创建副本
  PomodoroSession copyWith({
    String? id,
    PomodoroMode? mode,
    DateTime? startTime,
    DateTime? endTime,
    int? duration,
    bool? completed,
  }) {
    return PomodoroSession(
      id: id ?? this.id,
      mode: mode ?? this.mode,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      completed: completed ?? this.completed,
    );
  }

  @override
  String toString() {
    return 'PomodoroSession(id: $id, mode: $mode, startTime: $startTime, endTime: $endTime, duration: $duration, completed: $completed)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PomodoroSession && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}
