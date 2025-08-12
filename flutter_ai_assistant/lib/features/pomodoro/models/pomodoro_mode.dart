/// 番茄钟模式枚举
enum PomodoroMode {
  /// 专注时间 (25分钟)
  pomodoro,
  
  /// 短休息 (5分钟)
  shortBreak,
  
  /// 长休息 (15分钟)
  longBreak,
}

/// 番茄钟模式扩展方法
extension PomodoroModeExtension on PomodoroMode {
  /// 获取模式显示名称
  String get displayName {
    switch (this) {
      case PomodoroMode.pomodoro:
        return '专注';
      case PomodoroMode.shortBreak:
        return '短休息';
      case PomodoroMode.longBreak:
        return '长休息';
    }
  }
  
  /// 获取模式图标
  String get icon {
    switch (this) {
      case PomodoroMode.pomodoro:
        return '🍅';
      case PomodoroMode.shortBreak:
        return '☕';
      case PomodoroMode.longBreak:
        return '🛋️';
    }
  }
  
  /// 获取默认时长（秒）
  int get defaultDuration {
    switch (this) {
      case PomodoroMode.pomodoro:
        return 25 * 60;
      case PomodoroMode.shortBreak:
        return 5 * 60;
      case PomodoroMode.longBreak:
        return 15 * 60;
    }
  }
}
