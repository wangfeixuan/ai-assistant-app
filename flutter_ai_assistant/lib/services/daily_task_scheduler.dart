import 'dart:async';
import 'package:flutter/material.dart';
import '../features/todo/providers/todo_provider.dart';

/// 每日待办任务调度服务
/// 负责在每天0点自动生成新的每日待办任务实例
class DailyTaskScheduler {
  static final DailyTaskScheduler _instance = DailyTaskScheduler._internal();
  factory DailyTaskScheduler() => _instance;
  DailyTaskScheduler._internal();

  Timer? _timer;
  TodoProvider? _todoProvider;

  /// 初始化调度器
  void initialize(TodoProvider todoProvider) {
    _todoProvider = todoProvider;
    _scheduleNextMidnight();
  }

  /// 停止调度器
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _todoProvider = null;
  }

  /// 计算到下一个午夜的时间间隔
  Duration _timeUntilNextMidnight() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    return nextMidnight.difference(now);
  }

  /// 安排下一个午夜的任务生成
  void _scheduleNextMidnight() {
    _timer?.cancel();
    
    final timeUntilMidnight = _timeUntilNextMidnight();
    
    debugPrint('📅 每日待办调度器: ${timeUntilMidnight.inHours}小时${timeUntilMidnight.inMinutes % 60}分钟后执行');
    
    _timer = Timer(timeUntilMidnight, () {
      _generateDailyTasks();
      _scheduleNextMidnight(); // 安排下一次执行
    });
  }

  /// 生成每日待办任务
  void _generateDailyTasks() {
    if (_todoProvider == null) return;
    
    debugPrint('🌅 开始生成今日的每日待办任务');
    
    try {
      _todoProvider!.generateTodayDailyTasks();
      debugPrint('✅ 每日待办任务生成完成');
    } catch (e) {
      debugPrint('❌ 每日待办任务生成失败: $e');
    }
  }

  /// 手动触发任务生成（用于测试）
  void manualTrigger() {
    debugPrint('🔧 手动触发每日待办任务生成');
    _generateDailyTasks();
  }

  /// 获取下次执行时间
  DateTime? getNextExecutionTime() {
    if (_timer == null) return null;
    
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }

  /// 检查调度器是否运行中
  bool get isRunning => _timer != null && _timer!.isActive;
}
