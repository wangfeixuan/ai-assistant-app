import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

import '../models/pomodoro_mode.dart';
import '../models/pomodoro_session.dart';
import '../models/achievement.dart';
import '../models/strict_mode_violation.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../services/flip_detection_service.dart';
import '../../../services/procrastination_service.dart';

/// 番茄钟状态管理器 - 对应HTML版本的PomodoroTimer类
class PomodoroProvider extends ChangeNotifier {
  // 番茄钟模式默认时长定义
  final Map<PomodoroMode, int> _defaultDurations = {
    PomodoroMode.pomodoro: 25 * 60,      // 25分钟专注时间
    PomodoroMode.shortBreak: 5 * 60,     // 5分钟短休息
    PomodoroMode.longBreak: 15 * 60,     // 15分钟长休息
  };
  
  // 用户自定义时长
  Map<PomodoroMode, int> _customDurations = {};
  
  // 计时模式：true为正计时，false为倒计时
  bool _isCountUp = false;
  
  // 正计时时的已用时间
  int _elapsedTime = 0;
  
  // 严格模式相关
  bool _strictModeEnabled = false;
  List<StrictModeViolation> _violations = [];
  DateTime? _sessionStartTime;
  
  // 翻转开始模式相关
  bool _flipModeEnabled = false;
  bool _isFlipModeActive = false;
  bool _hasStartedInFlipMode = false; // 记录是否在翻转模式下手动开始过
  int _forceExitAttempts = 0;
  final FlipDetectionService _flipService = FlipDetectionService();
  final ProcrastinationService _procrastinationService = ProcrastinationService();
  
  // 沉浸模式相关
  bool _immersiveModeEnabled = false;

  PomodoroMode _currentMode = PomodoroMode.pomodoro;
  int _timeLeft = 25 * 60;
  bool _isRunning = false;
  bool _showCompletionAnimation = false;
  Timer? _timer;
  int _completedPomodoros = 0;
  int _totalSessions = 0;
  int _streakDays = 0;
  int _dailyGoal = 8; // 默认每日目标8个番茄钟
  List<PomodoroSession> _sessions = [];
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Getters
  PomodoroMode get currentMode => _currentMode;
  int get timeLeft => _timeLeft;
  bool get isRunning => _isRunning;
  bool get showCompletionAnimation => _showCompletionAnimation;
  int get completedPomodoros => _completedPomodoros;
  int get totalSessions => _totalSessions;
  int get streakDays => _streakDays;
  int get maxStreakDays => _streakDays; // 当前实现中最大连续天数就是当前连续天数
  int get dailyGoal => _dailyGoal;
  List<PomodoroSession> get sessions => _sessions;
  bool get isCountUp => _isCountUp;
  int get elapsedTime => _elapsedTime;
  bool get strictModeEnabled => _strictModeEnabled;
  List<StrictModeViolation> get violations => _violations;
  
  // 翻转模式相关getter
  bool get flipModeEnabled => _flipModeEnabled;
  bool get isFlipModeActive => _isFlipModeActive;
  int get forceExitAttempts => _forceExitAttempts;
  bool get canForceExit => _forceExitAttempts >= 3;
  
  // 沉浸模式相关getter
  bool get immersiveModeEnabled => _immersiveModeEnabled;
  
  /// 获取当前模式的总时长
  int get totalTime => _getModeDuration(_currentMode);
  
  /// 获取指定模式的时长（优先使用自定义时长）
  int _getModeDuration(PomodoroMode mode) {
    return _customDurations[mode] ?? _defaultDurations[mode] ?? 25 * 60;
  }
  
  /// 获取进度百分比 (0.0 - 1.0)
  double get progress {
    if (_isCountUp) {
      return _elapsedTime / totalTime;
    } else {
      return (totalTime - _timeLeft) / totalTime;
    }
  }
  
  /// 格式化时间显示 (MM:SS)
  String get formattedTime {
    int displayTime;
    if (_isCountUp) {
      displayTime = _elapsedTime;
    } else {
      displayTime = _timeLeft;
    }
    
    final minutes = displayTime ~/ 60;
    final seconds = displayTime % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  /// 获取模式显示名称
  String get modeDisplayName {
    switch (_currentMode) {
      case PomodoroMode.pomodoro:
        return '专注时间';
      case PomodoroMode.shortBreak:
        return '短休息';
      case PomodoroMode.longBreak:
        return '长休息';
    }
  }

  PomodoroProvider() {
    _loadAllData();
    _initAchievements();
    
    // 监听应用生命周期变化
    WidgetsBinding.instance.addObserver(_AppLifecycleObserver(this));
  }

  /// 初始化成就系统
  Future<void> _initAchievements() async {
    // 成就系统初始化逻辑（如果需要的话）
    debugPrint('🏆 成就系统初始化完成');
  }

  /// 检查并解锁新成就
  Future<List<Achievement>> _checkAndUnlockAchievements() async {
    final newlyUnlocked = <Achievement>[];
    final now = DateTime.now();
    
    // 检查里程碑成就
    if (_completedPomodoros == 1) {
      final achievement = Achievement(
        id: 'milestone_1',
        title: '初次体验',
        description: '完成第1个番茄钟',
        icon: Icons.play_circle,
        unlockedAt: now,
        isUnlocked: true,
      );
      newlyUnlocked.add(achievement);
      debugPrint('🏆 解锁新成就: ${achievement.title}');
    }
    
    if (_completedPomodoros == 10) {
      final achievement = Achievement(
        id: 'milestone_10',
        title: '小试牛刀',
        description: '完成10个番茄钟',
        icon: Icons.star,
        unlockedAt: now,
        isUnlocked: true,
      );
      newlyUnlocked.add(achievement);
      debugPrint('🏆 解锁新成就: ${achievement.title}');
    }
    
    // 检查连续打卡成就
    if (_streakDays == 3) {
      final achievement = Achievement(
        id: 'streak_3',
        title: '初显坚持',
        description: '连续打卡3天',
        icon: Icons.local_fire_department,
        unlockedAt: now,
        isUnlocked: true,
      );
      newlyUnlocked.add(achievement);
      debugPrint('🏆 解锁新成就: ${achievement.title}');
    }
    
    return newlyUnlocked;
  }

  /// 显示成就解锁动画
  void _showAchievementUnlockAnimation(List<Achievement> achievements) {
    // 成就解锁动画逻辑（可以在UI层实现）
    debugPrint('🎉 显示成就解锁动画: ${achievements.map((a) => a.title).join(', ')}');
    
    // 触发震动反馈
    HapticFeedback.heavyImpact();
    
    // 通知监听者更新UI
    notifyListeners();
  }

  /// 设置每日目标
  void setDailyGoal(int goal) {
    if (goal > 0 && goal <= 50) { // 限制在合理范围内
      _dailyGoal = goal;
      _saveAllDataSync();
      notifyListeners();
    }
  }
  
  /// 设置自定义时长（分钟）
  void setCustomDuration(PomodoroMode mode, int minutes) {
    if (minutes > 0 && minutes <= 120) { // 限制在1-120分钟内
      _customDurations[mode] = minutes * 60;
      
      // 如果当前模式就是要设置的模式，需要重置计时器
      if (_currentMode == mode) {
        resetTimer();
      }
      
      _saveAllDataSync();
      notifyListeners();
    }
  }

  /// 获取指定模式的自定义时长（分钟）
  int getCustomDurationMinutes(PomodoroMode mode) {
    final seconds = _customDurations[mode];
    if (seconds != null) {
      return seconds ~/ 60;
    }
    return _defaultDurations[mode]! ~/ 60;
  }
  
  /// 重置指定模式为默认时长
  void resetToDefaultDuration(PomodoroMode mode) {
    _customDurations.remove(mode);
    
    // 如果当前模式就是要重置的模式，需要重置计时器
    if (_currentMode == mode) {
      resetTimer();
    }
    
    _saveAllDataSync();
    notifyListeners();
  }
  
  /// 切换计时模式（正计时/倒计时）
  void toggleCountMode() {
    _isCountUp = !_isCountUp;
    _elapsedTime = 0; // 重置已用时间
    _saveAllDataSync();
    notifyListeners();
  }

  /// 切换模式
  void switchMode(PomodoroMode mode) {
    pauseTimer();
    _currentMode = mode;
    final duration = _getModeDuration(mode);
    _timeLeft = duration;
    _elapsedTime = 0;
    
    debugPrint('🍅 切换模式: ${mode.name}, 时长: ${duration}秒 (${(duration/60).toStringAsFixed(1)}分钟)');
    notifyListeners();
  }

  /// 开始/暂停计时器
  void toggleTimer() {
    debugPrint('🍅 切换计时器状态: ${_isRunning ? "暂停" : "开始"}');
    
    // 翻转模式下的防捡漏逻辑
    if (_flipModeEnabled) {
      debugPrint('🔄 翻转模式已启用，检查是否允许手动控制');
      
      // 如果还没有手动开始过，允许第一次启动
      if (!_hasStartedInFlipMode && !_isRunning) {
        debugPrint('🔄 翻转模式下首次启动，允许手动开始');
        startTimer();
        return;
      }
      
      // 如果已经开始过，禁止手动控制
      debugPrint('🔄 翻转模式下禁止手动暂停/恢复，请使用翻转控制');
      return;
    }
    
    if (_isRunning) {
      pauseTimer();
    } else {
      startTimer();
    }
  }

  /// 开始计时
  void startTimer() {
    debugPrint('🎯 startTimer() 被调用，翻转模式: $_flipModeEnabled, 当前运行: $_isRunning');
    
    // 翻转模式下的特殊处理
    if (_flipModeEnabled) {
      debugPrint('🔄 翻转模式处理开始');
      debugPrint('🔄 翻转服务监听状态: ${_flipService.isListening}');
      
      // 确保翻转服务正在监听
      if (!_flipService.isListening) {
        debugPrint('🔄 翻转服务未监听，重新启动');
        _flipService.startListening();
      }
      
      debugPrint('🔄 当前翻转状态: ${_flipService.isFlipped}');
      debugPrint('🔄 内部翻转状态: $_isFlipModeActive');
      debugPrint('🔄 已手动开始标记: $_hasStartedInFlipMode');
      
      _hasStartedInFlipMode = true;
      _isFlipModeActive = _flipService.isFlipped; // 同步翻转状态
      
      debugPrint('🔄 翻转模式下手动开始，当前翻转状态: ${_isFlipModeActive ? "翻转" : "正常"}');
      
      // 如果用户已经处于翻转状态，立即开始计时
      if (_isFlipModeActive) {
        debugPrint('🔄 用户已翻转，立即开始计时');
        _startTimerInternal();
      } else {
        debugPrint('🔄 等待翻转手机开始计时');
      }
      
      notifyListeners();
      return;
    }
    
    debugPrint('🎯 普通模式开始计时');
    _startTimerInternal();
  }
  
  /// 内部开始计时方法（绕过翻转模式检查）
  void _startTimerInternal() {
    _isRunning = true;
    
    // 记录会话开始时间（用于严格模式）
    _sessionStartTime = DateTime.now();
    
    // 如果启用严格模式，开始监听应用生命周期
    if (_strictModeEnabled) {
      WidgetsBinding.instance.addObserver(_AppLifecycleObserver(this));
    }
    
    debugPrint('🍅 开始计时: ${_currentMode.name}, 模式: ${_isCountUp ? "正计时" : "倒计时"}, 总时长: ${totalTime}秒');
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isCountUp) {
        // 正计时模式
        _elapsedTime++;
        if (_elapsedTime >= totalTime) {
          timer.cancel();
          _timerComplete();
          return;
        }
      } else {
        // 倒计时模式
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          timer.cancel();
          _timerComplete();
          return;
        }
      }
      notifyListeners();
    });
    notifyListeners();
  }

  /// 暂停计时
  void pauseTimer() {
    // 翻转模式下禁止手动暂停
    if (_flipModeEnabled && _hasStartedInFlipMode) {
      debugPrint('🔄 翻转模式下禁止手动暂停，请翻转手机暂停计时');
      return;
    }
    
    _pauseTimerInternal();
  }
  
  /// 内部暂停计时方法（绕过翻转模式检查）
  void _pauseTimerInternal() {
    _isRunning = false;
    _timer?.cancel();
    debugPrint('🍅 计时器已暂停');
    notifyListeners();
  }

  /// 重置计时器
  void resetTimer() {
    _timer?.cancel();
    _isRunning = false;
    _timeLeft = _getModeDuration(_currentMode);
    _elapsedTime = 0;
    notifyListeners();
  }

  /// 手动结束计时器（用于正计时模式）
  Future<void> stopTimer() async {
    if (!_isRunning) return;
    
    _timer?.cancel();
    _isRunning = false;
    
    debugPrint('🍅 手动结束计时: ${_currentMode.name}, 已用时间: ${_elapsedTime}秒');
    
    // 对于正计时模式，将已用时间作为完成时间
    if (_isCountUp) {
      // 保存会话记录（使用实际已用时间）
      _saveSession();
      
      // 更新统计（仅对番茄钟模式）
      if (_currentMode == PomodoroMode.pomodoro) {
        _completedPomodoros++;
        debugPrint('🍅 完成番茄钟数量更新: $_completedPomodoros');
      }
      _totalSessions++;
      _updateStreakDays();
      
      // 确保数据保存完成
      await _saveAllData();
      
      // 检查并解锁新成就
      final newAchievements = await _checkAndUnlockAchievements();
      if (newAchievements.isNotEmpty) {
        // 显示成就解锁动画
        _showAchievementUnlockAnimation(newAchievements);
      }
      
      // 播放完成音效（可选，比正常完成轻一些）
      try {
        await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
      } catch (e) {
        debugPrint('播放音效失败: $e');
      }
      
      // 发送完成通知
      _sendCompletionNotification();
    }
    
    // 重置计时器状态
    _timeLeft = _getModeDuration(_currentMode);
    _elapsedTime = 0;
    
    notifyListeners();
  }

  /// 计时完成处理
  Future<void> _timerComplete() async {
    _isRunning = false;
    _timer?.cancel(); // 确保计时器停止
    _showCompletionAnimation = true;
    
    debugPrint('🍅 计时完成: ${_currentMode.name}');
    
    // 播放完成音效
    try {
      await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
    } catch (e) {
      debugPrint('播放音效失败: $e');
    }
    
    // 触发强震动提醒
    await _triggerStrongVibration();
    
    // 发送本地通知
    _sendCompletionNotification();
    
    // 保存会话记录（在更新统计之前）
    _saveSession();
    
    // 更新统计（仅对番茄钟模式）
    if (_currentMode == PomodoroMode.pomodoro) {
      _completedPomodoros++;
      debugPrint('🍅 完成番茄钟数量更新: $_completedPomodoros');
    }
    _totalSessions++;
    _updateStreakDays();
    
    // 确保数据保存完成
    await _saveAllData();
    
    // 检查并解锁新成就
    final newAchievements = await _checkAndUnlockAchievements();
    if (newAchievements.isNotEmpty) {
      // 显示成就解锁动画
      _showAchievementUnlockAnimation(newAchievements);
    }
    
    // 自动跳转逻辑：根据番茄钟设计原则
    _autoSwitchToNextMode();
    
    // 延迟隐藏动画
    Timer(const Duration(seconds: 3), () {
      _showCompletionAnimation = false;
      notifyListeners();
    });
    
    notifyListeners();
  }

  /// 手动切换到下一个模式（移除自动切换）
  void switchToNextMode() {
    switch (_currentMode) {
      case PomodoroMode.pomodoro:
        _currentMode = PomodoroMode.shortBreak;
        break;
      case PomodoroMode.shortBreak:
        _currentMode = PomodoroMode.pomodoro;
        break;
      case PomodoroMode.longBreak:
        _currentMode = PomodoroMode.pomodoro;
        break;
    }
    
    _timeLeft = _getModeDuration(_currentMode);
    _elapsedTime = 0;
    _isRunning = false;
    
    debugPrint('🔄 手动切换到: ${_currentMode.displayName}');
    notifyListeners();
  }
  
  /// 自动跳转到下一个模式（番茄钟设计原则）
  void _autoSwitchToNextMode() {
    switch (_currentMode) {
      case PomodoroMode.pomodoro:
        // 完成番茄钟后，检查是否需要长休息
        final todayCompletedCount = getTodayCompletedCount();
        if (todayCompletedCount > 0 && todayCompletedCount % 4 == 0) {
          // 每完成4个番茄钟后进入长休息
          _currentMode = PomodoroMode.longBreak;
          debugPrint('🛌 自动跳转到长休息（已完成${todayCompletedCount}个番茄钟）');
        } else {
          // 否则进入短休息
          _currentMode = PomodoroMode.shortBreak;
          debugPrint('☕ 自动跳转到短休息');
        }
        break;
      case PomodoroMode.shortBreak:
      case PomodoroMode.longBreak:
        // 休息结束后回到番茄钟模式
        _currentMode = PomodoroMode.pomodoro;
        debugPrint('🍅 自动跳转到番茄钟模式');
        break;
    }
    
    // 重置计时器状态
    _timeLeft = _getModeDuration(_currentMode);
    _elapsedTime = 0;
    _isRunning = false;
    
    notifyListeners();
  }

  /// 播放提示音
  Future<void> _playNotificationSound() async {
    try {
      // 这里可以播放本地音频文件或生成简单的提示音
      // await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
      debugPrint('Playing notification sound');
    } catch (e) {
      debugPrint('Error playing notification sound: $e');
    }
  }
  
  /// 强震动提醒 - 番茄钟完成时的强烈震动反馈
  Future<void> _triggerStrongVibration() async {
    try {
      // 检查设备是否支持震动
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator != true) {
        debugPrint('设备不支持震动功能');
        // 降级使用系统震动反馈
        HapticFeedback.heavyImpact();
        return;
      }
      
      // 检查是否支持自定义震动模式
      bool? hasCustomVibrationsSupport = await Vibration.hasCustomVibrationsSupport();
      
      if (hasCustomVibrationsSupport == true) {
        // 使用快乐的“庆祝”震动模式：短促有力的节奏，像鸣彩一样
        await Vibration.vibrate(
          pattern: [0, 150, 100, 150, 100, 150, 200, 300, 150, 150, 100, 150, 100, 300],
          intensities: [0, 255, 0, 200, 0, 255, 0, 180, 0, 255, 0, 200, 0, 255],
        );
        debugPrint('🎉 执行快乐庆祝震动模式');
      } else {
        // 降级使用快乐的短促震动
        await Vibration.vibrate(duration: 150); // 短促有力
        await Future.delayed(const Duration(milliseconds: 100));
        await Vibration.vibrate(duration: 150); // 短促有力
        await Future.delayed(const Duration(milliseconds: 100));
        await Vibration.vibrate(duration: 150); // 短促有力
        await Future.delayed(const Duration(milliseconds: 200));
        await Vibration.vibrate(duration: 300); // 稍长一点
        await Future.delayed(const Duration(milliseconds: 150));
        await Vibration.vibrate(duration: 150); // 结束的短促
        await Future.delayed(const Duration(milliseconds: 100));
        await Vibration.vibrate(duration: 150); // 结束的短促
        debugPrint('🎉 执行快乐短促震动模式');
      }
      
      // 额外的系统震动反馈
      HapticFeedback.heavyImpact();
      
    } catch (e) {
      debugPrint('震动提醒失败: $e');
      // 降级使用系统震动反馈
      HapticFeedback.heavyImpact();
    }
  }

  /// 显示模式切换通知
  void _showModeChangeNotification(PomodoroMode nextMode) {
    debugPrint('Auto switching to: ${nextMode.displayName}');
  }

  /// 保存会话记录
  void _saveSession() {
    // 使用实际的计时时长，而不是默认时长
    int actualDuration;
    DateTime sessionStartTime;
    
    if (_isCountUp) {
      // 正计时模式：使用已用时间
      actualDuration = _elapsedTime;
      sessionStartTime = DateTime.now().subtract(Duration(seconds: _elapsedTime));
    } else {
      // 倒计时模式：使用总时长减去剩余时长
      final totalDuration = _getModeDuration(_currentMode);
      actualDuration = totalDuration - _timeLeft;
      sessionStartTime = DateTime.now().subtract(Duration(seconds: actualDuration));
    }
    
    final session = PomodoroSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      mode: _currentMode,
      startTime: sessionStartTime,
      endTime: DateTime.now(),
      duration: actualDuration, // 使用实际时长
      completed: true,
    );
    
    _sessions.add(session);
    if (_sessions.length > 1000) {
      _sessions.removeRange(0, _sessions.length - 1000); // 保留最近1000条记录
    }
    
    debugPrint('🍅 保存会话记录: ${_currentMode.name}, 实际时长: ${actualDuration}秒 (${(actualDuration/60).toStringAsFixed(1)}分钟)');
  }

  /// 更新连续打卡天数（以0点为一天开始）
  void _updateStreakDays() {
    // 获取所有已完成的番茄钟会话，按日期分组
    final completedPomodoroSessions = _sessions
        .where((s) => s.mode == PomodoroMode.pomodoro && s.completed)
        .toList();
    
    if (completedPomodoroSessions.isEmpty) {
      _streakDays = 0;
      return;
    }
    
    // 按日期分组（以0点为一天开始）
    final Map<String, List<PomodoroSession>> sessionsByDate = {};
    for (final session in completedPomodoroSessions) {
      final dateKey = _getDateKey(session.endTime!);
      sessionsByDate[dateKey] ??= [];
      sessionsByDate[dateKey]!.add(session);
    }
    
    // 获取有番茄钟记录的日期列表，按时间倒序排列
    final sortedDates = sessionsByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // 倒序：最新日期在前
    
    if (sortedDates.isEmpty) {
      _streakDays = 0;
      return;
    }
    
    // 检查今天是否有记录
    final todayKey = _getDateKey(DateTime.now());
    if (!sortedDates.contains(todayKey)) {
      _streakDays = 0;
      return;
    }
    
    // 从今天开始计算连续天数
    int streakCount = 0;
    DateTime currentDate = DateTime.now();
    
    while (true) {
      final currentDateKey = _getDateKey(currentDate);
      if (sessionsByDate.containsKey(currentDateKey)) {
        streakCount++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    
    _streakDays = streakCount;
    debugPrint('📅 连续打卡天数更新: $_streakDays 天');
  }

  /// 检查是否为同一天
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }

  /// 获取日期的键（格式：yyyy-MM-dd）
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  /// 格式化日期用于调试输出
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 加载所有数据
  void _loadAllData() {
    _completedPomodoros = StorageService.getInt('completed_pomodoros') ?? 0;
    _totalSessions = StorageService.getInt('total_sessions') ?? 0;
    _streakDays = StorageService.getInt('streak_days') ?? 0;
    _dailyGoal = StorageService.getInt('daily_goal') ?? 8; // 加载每日目标设置
    _isCountUp = StorageService.getBool('is_count_up') ?? false; // 加载计时模式
    
    // 加载自定义时长设置
    final customDurationsData = StorageService.getStringList('custom_durations') ?? [];
    _customDurations.clear();
    for (final data in customDurationsData) {
      try {
        final parts = data.split(':');
        if (parts.length == 2) {
          final modeIndex = int.parse(parts[0]);
          final duration = int.parse(parts[1]);
          if (modeIndex >= 0 && modeIndex < PomodoroMode.values.length) {
            _customDurations[PomodoroMode.values[modeIndex]] = duration;
          }
        }
      } catch (e) {
        debugPrint('Error loading custom duration: $e');
      }
    }
    
    // 加载会话记录
    final sessionsData = StorageService.getStringList('pomodoro_sessions') ?? [];
    _sessions = sessionsData.map((data) {
      try {
        final map = Map<String, dynamic>.from(Uri.parse(data).queryParameters);
        return PomodoroSession.fromMap(map);
      } catch (e) {
        debugPrint('Error loading session: $e');
        return null;
      }
    }).where((session) => session != null).cast<PomodoroSession>().toList();
    
    // 加载严格模式设置
    _strictModeEnabled = StorageService.getBool('strict_mode_enabled') ?? false;
    
    // 加载违规记录
    final violationsData = StorageService.getStringList('strict_mode_violations') ?? [];
    _violations = violationsData.map((data) {
      try {
        final map = jsonDecode(data) as Map<String, dynamic>;
        return StrictModeViolation.fromJson(map);
      } catch (e) {
        debugPrint('Error loading violation: $e');
        return null;
      }
    }).where((violation) => violation != null).cast<StrictModeViolation>().toList();
    
    // 初始化计时器状态
    final duration = _getModeDuration(_currentMode);
    _timeLeft = duration;
    _elapsedTime = 0;
    
    notifyListeners();
  }

  /// 保存所有数据（异步版本）
  Future<void> _saveAllData() async {
    try {
      await StorageService.setInt('completed_pomodoros', _completedPomodoros);
      await StorageService.setInt('total_sessions', _totalSessions);
      await StorageService.setInt('streak_days', _streakDays);
      await StorageService.setInt('daily_goal', _dailyGoal); // 保存每日目标设置
      await StorageService.setBool('is_count_up', _isCountUp); // 保存计时模式
      
      // 保存自定义时长设置
      final customDurationsData = <String>[];
      _customDurations.forEach((mode, duration) {
        customDurationsData.add('${mode.index}:$duration');
      });
      await StorageService.setStringList('custom_durations', customDurationsData);
      
      // 保存严格模式设置
      await StorageService.setBool('strict_mode_enabled', _strictModeEnabled);
      
      // 保存违规记录
      final violationsData = _violations.map((violation) => jsonEncode(violation.toJson())).toList();
      await StorageService.setStringList('strict_mode_violations', violationsData);
      
      // 保存会话记录（简化版本）
      final sessionsData = _sessions.map((session) {
        return Uri(queryParameters: {
          'id': session.id,
          'mode': session.mode.index.toString(),
          'startTime': session.startTime.millisecondsSinceEpoch.toString(),
          'endTime': session.endTime?.millisecondsSinceEpoch.toString() ?? '',
          'duration': session.duration.toString(),
          'completed': session.completed.toString(),
        }).toString();
      }).toList();
      
      await StorageService.setStringList('pomodoro_sessions', sessionsData);
      
      debugPrint('✅ 番茄钟数据保存成功');
    } catch (e) {
      debugPrint('❌ 番茄钟数据保存失败: $e');
    }
  }

  /// 立即保存数据（同步调用异步方法）
  void _saveAllDataSync() {
    _saveAllData().catchError((e) {
      debugPrint('❌ 同步保存数据失败: $e');
    });
  }

  /// 设置沉浸模式
  Future<void> setImmersiveMode(bool enabled) async {
    _immersiveModeEnabled = enabled;
    
    // 确保数据保存完成
    await _saveAllData();
    notifyListeners();
  }

  /// 获取今日违规次数
  int getTodayViolationCount() {
    final today = DateTime.now();
    return _violations.where((violation) {
      return violation.timestamp.year == today.year &&
             violation.timestamp.month == today.month &&
             violation.timestamp.day == today.day;
    }).length;
  }
  
  /// 获取本周违规次数
  int getWeekViolationCount() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return _violations.where((violation) {
      return violation.timestamp.isAfter(weekStart);
    }).length;
  }
  
  /// 清除违规记录
  Future<void> clearViolations() async {
    _violations.clear();
    await _saveAllData();
    notifyListeners();
  }
  
  /// 切换翻转模式
  Future<void> toggleFlipMode() async {
    _flipModeEnabled = !_flipModeEnabled;
    
    if (_flipModeEnabled) {
      // 翻转模式启用时，停止当前计时器
      if (_isRunning) {
        pauseTimer();
      }
      
      // 重置翻转模式相关状态
      _isFlipModeActive = false;
      _hasStartedInFlipMode = false;
      _forceExitAttempts = 0;
      
      // 先停止之前的监听，确保状态清洁
      _flipService.stopListening();
      
      // 重新设置回调函数
      _flipService.setFlipStateCallback((isFlipped) {
        debugPrint('🔄 ===== 翻转回调被触发 =====');
        debugPrint('🔄 回调参数 isFlipped: $isFlipped');
        debugPrint('🔄 当前 _flipModeEnabled: $_flipModeEnabled');
        debugPrint('🔄 当前 _hasStartedInFlipMode: $_hasStartedInFlipMode');
        debugPrint('🔄 当前 _isFlipModeActive: $_isFlipModeActive');
        debugPrint('🔄 当前 _isRunning: $_isRunning');
        
        if (_flipModeEnabled) {
          debugPrint('🔄 翻转状态变化: ${isFlipped ? "翻转" : "正常"}, 已开始: $_hasStartedInFlipMode');
          
          if (_hasStartedInFlipMode) {
            debugPrint('🔄 用户已手动开始，处理翻转控制');
            // 已经手动开始过，可以通过翻转控制
            if (isFlipped && !_isFlipModeActive) {
              debugPrint('🔄 检测到翻转，准备开始计时');
              _isFlipModeActive = true;
              if (!_isRunning) {
                debugPrint('🔄 翻转开始计时');
                _startTimerInternal();
              } else {
                debugPrint('🔄 计时器已在运行，无需重复启动');
              }
            } else if (!isFlipped && _isFlipModeActive) {
              debugPrint('🔄 检测到恢复正常，准备暂停计时');
              _isFlipModeActive = false;
              if (_isRunning) {
                debugPrint('🔄 翻转暂停计时');
                _pauseTimerInternal();
              } else {
                debugPrint('🔄 计时器已暂停，无需重复暂停');
              }
            } else {
              debugPrint('🔄 翻转状态无变化或重复触发');
            }
          } else {
            debugPrint('🔄 用户还未手动开始，只更新翻转状态');
            // 还没有手动开始，只更新翻转状态
            _isFlipModeActive = isFlipped;
            debugPrint('🔄 等待手动开始，当前翻转状态: ${isFlipped ? "翻转" : "正常"}');
          }
          debugPrint('🔄 通知监听器更新UI');
          notifyListeners();
        } else {
          debugPrint('🔄 翻转模式已禁用，忽略回调');
        }
        debugPrint('🔄 ===== 翻转回调处理完成 =====');
      });
      
      // 重新开始监听
      await _flipService.startListening();
      
      debugPrint('🔄 翻转模式已启用，状态已重置，请先点击开始按钮，然后翻转手机开始计时');
    } else {
      _flipService.stopListening();
      _flipService.clearCallback();
      _isFlipModeActive = false;
      _hasStartedInFlipMode = false;
      _forceExitAttempts = 0;
      debugPrint('🔄 翻转模式已关闭');
    }
    
    await _saveAllData();
    notifyListeners();
  }

  /// 切换沉浸模式
  Future<void> toggleImmersiveMode() async {
    _immersiveModeEnabled = !_immersiveModeEnabled;
    await _saveAllData();
    notifyListeners();
    debugPrint('🎯 沉浸模式已${_immersiveModeEnabled ? "启用" : "禁用"}');
  }

  /// 获取今日完成的番茄钟数量（以0点为一天开始）
  int getTodayCompletedCount() {
    final todayKey = _getDateKey(DateTime.now());
    return _sessions
        .where((s) => 
            s.mode == PomodoroMode.pomodoro && 
            s.completed &&
            _getDateKey(s.endTime!) == todayKey)
        .length;
  }
  
  /// 获取今日实际专注时长（秒）
  int getTodayActualFocusTime() {
    final todayKey = _getDateKey(DateTime.now());
    return _sessions
        .where((s) => 
            s.mode == PomodoroMode.pomodoro && 
            s.completed &&
            _getDateKey(s.endTime!) == todayKey)
        .fold<int>(0, (total, session) => total + session.duration);
  }
  
  /// 获取今日实际专注时长（格式化字符串）
  String getTodayActualFocusTimeFormatted() {
    final totalSeconds = getTodayActualFocusTime();
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    
    if (hours > 0) {
      return '${hours}小时${minutes}分钟';
    } else {
      return '${minutes}分钟';
    }
  }

  /// 获取本周完成的番茄钟数量（以0点为一天开始）
  int getWeekCompletedCount() {
    final now = DateTime.now();
    // 计算本周一的0点
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    return _sessions
        .where((s) => 
            s.mode == PomodoroMode.pomodoro && 
            s.completed &&
            s.endTime != null &&
            s.endTime!.isAfter(weekStart))
        .length;
  }

  /// 获取本月完成的番茄钟数量（以0点为一天开始）
  int getMonthCompletedCount() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    return _sessions
        .where((s) => 
            s.mode == PomodoroMode.pomodoro && 
            s.completed &&
            s.endTime != null &&
            s.endTime!.isAfter(monthStart))
        .length;
  }
  
  /// 获取实际使用天数（用于计算平均值）
  int getActualUsageDays() {
    if (_sessions.isEmpty) return 1; // 避免除以零
    
    final completedPomodoroSessions = _sessions
        .where((s) => s.mode == PomodoroMode.pomodoro && s.completed)
        .toList();
    
    if (completedPomodoroSessions.isEmpty) return 1;
    
    final Map<String, List<PomodoroSession>> sessionsByDate = {};
    for (final session in completedPomodoroSessions) {
      final dateKey = _getDateKey(session.endTime!);
      sessionsByDate[dateKey] ??= [];
      sessionsByDate[dateKey]!.add(session);
    }
    
    return sessionsByDate.keys.length;
  }
  
  /// 获取平均每日完成数量
  double getAverageDailyCount() {
    final actualDays = getActualUsageDays();
    final totalCompleted = _sessions
        .where((s) => s.mode == PomodoroMode.pomodoro && s.completed)
        .length;
    return totalCompleted / actualDays;
  }
  
  /// 获取最长连续天数（历史最高记录）
  int getMaxStreakDays() {
    final completedPomodoroSessions = _sessions
        .where((s) => s.mode == PomodoroMode.pomodoro && s.completed)
        .toList();
    
    if (completedPomodoroSessions.isEmpty) return 0;
    
    final Map<String, List<PomodoroSession>> sessionsByDate = {};
    for (final session in completedPomodoroSessions) {
      final dateKey = _getDateKey(session.endTime!);
      sessionsByDate[dateKey] ??= [];
      sessionsByDate[dateKey]!.add(session);
    }
    
    final sortedDates = sessionsByDate.keys.toList()
      ..sort((a, b) => a.compareTo(b));
    
    if (sortedDates.isEmpty) return 0;
    
    int maxStreak = 1;
    int currentStreak = 1;
    
    for (int i = 1; i < sortedDates.length; i++) {
      final prevDate = DateTime.parse(sortedDates[i - 1]);
      final currentDate = DateTime.parse(sortedDates[i]);
      
      if (currentDate.difference(prevDate).inDays == 1) {
        currentStreak++;
        maxStreak = math.max(maxStreak, currentStreak);
      } else {
        currentStreak = 1;
      }
    }
    
    return maxStreak;
  }
  
  /// 获取本周每日的数据（用于趋势图）
  List<int> getWeeklyTrendData() {
    final now = DateTime.now();
    // 修正：使用当前日期的开始时间（0点）计算周一
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    
    debugPrint('📈 本周趋势数据计算: 周一=${_formatDate(weekStart)}, 周日=${_formatDate(weekEnd.subtract(const Duration(days: 1)))}');
    
    final weeklyData = List<int>.filled(7, 0);
    
    for (final session in _sessions) {
      if (session.mode == PomodoroMode.pomodoro && 
          session.completed && 
          session.endTime != null) {
        
        // 使用结束时间的日期部分进行比较
        final sessionDate = DateTime(session.endTime!.year, session.endTime!.month, session.endTime!.day);
        
        // 检查是否在本周范围内
        if (sessionDate.isAtSameMomentAs(weekStart) || 
            (sessionDate.isAfter(weekStart) && sessionDate.isBefore(weekEnd))) {
          
          final daysDiff = sessionDate.difference(weekStart).inDays;
          if (daysDiff >= 0 && daysDiff < 7) {
            weeklyData[daysDiff]++;
            debugPrint('📈 添加数据: 日期=${_formatDate(sessionDate)}, 索引=$daysDiff, 当前计数=${weeklyData[daysDiff]}');
          }
        }
      }
    }
    
    debugPrint('📈 本周趋势数据: $weeklyData');
    return weeklyData;
  }
  
  /// 获取本月每天的数据（用于月度统计）
  Map<int, int> getMonthlyData() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    
    final monthlyData = <int, int>{};
    for (int i = 1; i <= daysInMonth; i++) {
      monthlyData[i] = 0;
    }
    
    for (final session in _sessions) {
      if (session.mode == PomodoroMode.pomodoro && 
          session.completed && 
          session.endTime != null &&
          session.endTime!.isAfter(monthStart) &&
          session.endTime!.month == now.month &&
          session.endTime!.year == now.year) {
        
        final day = session.endTime!.day;
        monthlyData[day] = (monthlyData[day] ?? 0) + 1;
      }
    }
    
    return monthlyData;
  }
  
  /// 获取本周实际专注时长
  int getWeekActualFocusTime() {
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    
    return _sessions
        .where((s) => 
            s.mode == PomodoroMode.pomodoro && 
            s.completed &&
            s.endTime != null &&
            s.endTime!.isAfter(weekStart))
        .fold<int>(0, (total, session) => total + session.duration);
  }
  
  /// 获取本月实际专注时长
  int getMonthActualFocusTime() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    
    return _sessions
        .where((s) => 
            s.mode == PomodoroMode.pomodoro && 
            s.completed &&
            s.endTime != null &&
            s.endTime!.isAfter(monthStart))
        .fold<int>(0, (total, session) => total + session.duration);
  }

  /// 获取时间段效率数据（24小时热力图）
  Map<int, int> getHourlyEfficiencyData() {
    final hourlyData = <int, int>{};
    for (int i = 0; i < 24; i++) {
      hourlyData[i] = 0;
    }
    
    for (final session in _sessions) {
      if (session.mode == PomodoroMode.pomodoro && session.completed) {
        final hour = session.startTime.hour;
        hourlyData[hour] = (hourlyData[hour] ?? 0) + 1;
      }
    }
    
    return hourlyData;
  }

  /// 发送完成通知
  void _sendCompletionNotification() {
    final notificationService = NotificationService();
    
    switch (_currentMode) {
      case PomodoroMode.pomodoro:
        notificationService.showPomodoroCompleteNotification(
          type: 'work',
          sessionCount: _completedPomodoros + 1,
        );
        break;
      case PomodoroMode.shortBreak:
        notificationService.showPomodoroCompleteNotification(
          type: 'shortBreak',
          sessionCount: _completedPomodoros,
        );
        break;
      case PomodoroMode.longBreak:
        notificationService.showPomodoroCompleteNotification(
          type: 'longBreak',
          sessionCount: _completedPomodoros,
        );
        break;
    }
  }

  /// 重置统计数据
  Future<void> resetStats() async {
    _completedPomodoros = 0;
    _totalSessions = 0;
    _streakDays = 0;
    _sessions.clear();
    await _saveAllData();
    notifyListeners();
  }

  /// 切换严格模式
  Future<void> toggleStrictMode() async {
    _strictModeEnabled = !_strictModeEnabled;
    await _saveAllData();
    notifyListeners();
  }

  /// 获取上午时间段完成的番茄钟数量
  int getMorningCount() {
    final today = DateTime.now();
    final todaySessions = _sessions.where((session) => 
      session.startTime.year == today.year &&
      session.startTime.month == today.month &&
      session.startTime.day == today.day &&
      session.startTime.hour >= 6 && session.startTime.hour < 12
    ).length;
    return todaySessions;
  }
  
  /// 获取下午时间段完成的番茄钟数量
  int getAfternoonCount() {
    final today = DateTime.now();
    final todaySessions = _sessions.where((session) => 
      session.startTime.year == today.year &&
      session.startTime.month == today.month &&
      session.startTime.day == today.day &&
      session.startTime.hour >= 12 && session.startTime.hour < 18
    ).length;
    return todaySessions;
  }
  
  /// 获取晚上时间段完成的番茄钟数量
  int getEveningCount() {
    final today = DateTime.now();
    final todaySessions = _sessions.where((session) => 
      session.startTime.year == today.year &&
      session.startTime.month == today.month &&
      session.startTime.day == today.day &&
      session.startTime.hour >= 18 && session.startTime.hour < 24
    ).length;
    return todaySessions;
  }

  /// 获取所有成就（包括已解锁和未解锁）
  List<Achievement> getAllAchievements() {
    final now = DateTime.now();
    final allAchievements = <Achievement>[
      // 连续打卡成就
      Achievement(
        id: 'streak_3',
        title: '初显坚持',
        description: '连续打卡3天',
        icon: Icons.local_fire_department,
        unlockedAt: now,
        isUnlocked: _streakDays >= 3,
      ),
      Achievement(
        id: 'streak_7',
        title: '坚持不懈',
        description: '连续打卡7天',
        icon: Icons.local_fire_department,
        unlockedAt: now,
        isUnlocked: _streakDays >= 7,
      ),
      Achievement(
        id: 'streak_30',
        title: '专注大师',
        description: '连续打卡30天',
        icon: Icons.emoji_events,
        unlockedAt: now,
        isUnlocked: _streakDays >= 30,
      ),
      
      // 里程碑成就
      Achievement(
        id: 'milestone_1',
        title: '初次体验',
        description: '完成第1个番茄钟',
        icon: Icons.play_circle,
        unlockedAt: now,
        isUnlocked: _completedPomodoros >= 1,
      ),
      Achievement(
        id: 'milestone_10',
        title: '小试牛刀',
        description: '完成10个番茄钟',
        icon: Icons.star,
        unlockedAt: now,
        isUnlocked: _completedPomodoros >= 10,
      ),
      Achievement(
        id: 'milestone_50',
        title: '专注者',
        description: '完成50个番茄钟',
        icon: Icons.star_half,
        unlockedAt: now,
        isUnlocked: _completedPomodoros >= 50,
      ),
      Achievement(
        id: 'milestone_100',
        title: '百里挑一',
        description: '完成100个番茄钟',
        icon: Icons.military_tech,
        unlockedAt: now,
        isUnlocked: _completedPomodoros >= 100,
      ),
      Achievement(
        id: 'milestone_500',
        title: '专注大神',
        description: '完成500个番茄钟',
        icon: Icons.workspace_premium,
        unlockedAt: now,
        isUnlocked: _completedPomodoros >= 500,
      ),
      
      // 时间段成就
      Achievement(
        id: 'daily_8',
        title: '一日之计',
        description: '单日完成8个番茄钟',
        icon: Icons.today,
        unlockedAt: now,
        isUnlocked: getTodayCompletedCount() >= 8,
      ),
      Achievement(
        id: 'weekly_30',
        title: '周度冠军',
        description: '单周完成30个番茄钟',
        icon: Icons.date_range,
        unlockedAt: now,
        isUnlocked: getWeekCompletedCount() >= 30,
      ),
    ];
    
    return allAchievements;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    
    // 移除生命周期观察者
    WidgetsBinding.instance.removeObserver(_AppLifecycleObserver(this));
    
    super.dispose();
  }
}

/// 应用生命周期观察者
class _AppLifecycleObserver extends WidgetsBindingObserver {
  final PomodoroProvider _provider;
  
  _AppLifecycleObserver(this._provider);
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // 应用进入后台时保存数据
        _provider._saveAllDataSync();
        debugPrint('📱 应用进入后台，保存番茄钟数据');
        break;
      case AppLifecycleState.resumed:
        // 应用回到前台时可以进行数据同步检查（如果需要）
        debugPrint('📱 应用回到前台');
        break;
      case AppLifecycleState.detached:
        // 应用即将被销毁时保存数据
        _provider._saveAllDataSync();
        debugPrint('📱 应用即将销毁，保存番茄钟数据');
        break;
      case AppLifecycleState.inactive:
        // 应用失去焦点（如来电、通知栏下拉等）
        // 这种情况通常是临时的，可以选择不保存数据
        break;
      case AppLifecycleState.hidden:
        // 应用被隐藏时保存数据
        _provider._saveAllDataSync();
        debugPrint('📱 应用被隐藏，保存番茄钟数据');
        break;
    }
  }
}
