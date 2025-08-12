import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/todo_item.dart';
import '../providers/todo_provider.dart';

/// 自动清除策略枚举
enum AutoCleanupStrategy {
  disabled,     // 禁用自动清除
  daily,        // 每日清除
  weekly,       // 每周清除
  monthly,      // 每月清除
  custom,       // 自定义天数
}

/// 自动清除设置
class AutoCleanupSettings {
  final bool enabled;
  final AutoCleanupStrategy strategy;
  final int customDays;
  final bool keepImportantTasks;
  final bool keepRecurringTasks;
  final bool createBackup;
  final TimeOfDay cleanupTime;
  final DateTime? lastCleanupTime;

  const AutoCleanupSettings({
    this.enabled = false,
    this.strategy = AutoCleanupStrategy.weekly,
    this.customDays = 7,
    this.keepImportantTasks = true,
    this.keepRecurringTasks = true,
    this.createBackup = true,
    this.cleanupTime = const TimeOfDay(hour: 2, minute: 0), // 凌晨2点
    this.lastCleanupTime,
  });

  factory AutoCleanupSettings.fromJson(Map<String, dynamic> json) {
    return AutoCleanupSettings(
      enabled: json['enabled'] as bool? ?? false,
      strategy: AutoCleanupStrategy.values.firstWhere(
        (e) => e.toString() == 'AutoCleanupStrategy.${json['strategy']}',
        orElse: () => AutoCleanupStrategy.weekly,
      ),
      customDays: json['customDays'] as int? ?? 7,
      keepImportantTasks: json['keepImportantTasks'] as bool? ?? true,
      keepRecurringTasks: json['keepRecurringTasks'] as bool? ?? true,
      createBackup: json['createBackup'] as bool? ?? true,
      cleanupTime: TimeOfDay(
        hour: json['cleanupHour'] as int? ?? 2,
        minute: json['cleanupMinute'] as int? ?? 0,
      ),
      lastCleanupTime: json['lastCleanupTime'] != null 
          ? DateTime.parse(json['lastCleanupTime'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'strategy': strategy.toString().split('.').last,
      'customDays': customDays,
      'keepImportantTasks': keepImportantTasks,
      'keepRecurringTasks': keepRecurringTasks,
      'createBackup': createBackup,
      'cleanupHour': cleanupTime.hour,
      'cleanupMinute': cleanupTime.minute,
      'lastCleanupTime': lastCleanupTime?.toIso8601String(),
    };
  }

  AutoCleanupSettings copyWith({
    bool? enabled,
    AutoCleanupStrategy? strategy,
    int? customDays,
    bool? keepImportantTasks,
    bool? keepRecurringTasks,
    bool? createBackup,
    TimeOfDay? cleanupTime,
    DateTime? lastCleanupTime,
  }) {
    return AutoCleanupSettings(
      enabled: enabled ?? this.enabled,
      strategy: strategy ?? this.strategy,
      customDays: customDays ?? this.customDays,
      keepImportantTasks: keepImportantTasks ?? this.keepImportantTasks,
      keepRecurringTasks: keepRecurringTasks ?? this.keepRecurringTasks,
      createBackup: createBackup ?? this.createBackup,
      cleanupTime: cleanupTime ?? this.cleanupTime,
      lastCleanupTime: lastCleanupTime ?? this.lastCleanupTime,
    );
  }

  /// 获取清除间隔天数
  int get cleanupIntervalDays {
    switch (strategy) {
      case AutoCleanupStrategy.disabled:
        return 0;
      case AutoCleanupStrategy.daily:
        return 1;
      case AutoCleanupStrategy.weekly:
        return 7;
      case AutoCleanupStrategy.monthly:
        return 30;
      case AutoCleanupStrategy.custom:
        return customDays;
    }
  }

  /// 获取策略显示名称
  String get strategyDisplayName {
    switch (strategy) {
      case AutoCleanupStrategy.disabled:
        return '禁用';
      case AutoCleanupStrategy.daily:
        return '每日';
      case AutoCleanupStrategy.weekly:
        return '每周';
      case AutoCleanupStrategy.monthly:
        return '每月';
      case AutoCleanupStrategy.custom:
        return '自定义($customDays天)';
    }
  }
}

/// 自动清除服务
class AutoCleanupService {
  static const String _settingsKey = 'auto_cleanup_settings';
  static const String _backupPrefix = 'cleanup_backup_';
  
  final TodoProvider _todoProvider;
  AutoCleanupSettings _settings = const AutoCleanupSettings();
  Timer? _cleanupTimer;

  AutoCleanupService(this._todoProvider) {
    _initializeService();
  }
  
  /// 初始化服务
  Future<void> _initializeService() async {
    await _loadSettings();
    _scheduleNextCleanup();
    debugPrint('🧹 自动清除服务初始化完成，启用状态: ${_settings.enabled}');
  }

  /// 获取当前设置
  AutoCleanupSettings get settings => _settings;
  
  /// 确保设置已加载
  Future<void> ensureSettingsLoaded() async {
    await _loadSettings();
  }

  /// 更新设置
  Future<void> updateSettings(AutoCleanupSettings newSettings) async {
    _settings = newSettings;
    await _saveSettings();
    _scheduleNextCleanup();
  }

  /// 加载设置
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);
      if (settingsJson != null) {
        final Map<String, dynamic> json = jsonDecode(settingsJson);
        _settings = AutoCleanupSettings.fromJson(json);
      }
    } catch (e) {
      debugPrint('❌ 加载自动清除设置失败: $e');
    }
  }

  /// 保存设置
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(_settings.toJson());
      await prefs.setString(_settingsKey, settingsJson);
    } catch (e) {
      debugPrint('❌ 保存自动清除设置失败: $e');
    }
  }

  /// 安排下次清除
  void _scheduleNextCleanup() {
    _cleanupTimer?.cancel();
    
    debugPrint('🔧 正在安排下次清除，当前设置: enabled=${_settings.enabled}, strategy=${_settings.strategy}');
    
    if (!_settings.enabled || _settings.strategy == AutoCleanupStrategy.disabled) {
      debugPrint('⏸️ 自动清除已禁用，跳过安排');
      return;
    }

    final nextCleanupTime = _calculateNextCleanupTime();
    final now = DateTime.now();
    
    debugPrint('⏰ 当前时间: ${now.toString()}');
    debugPrint('⏰ 计算的下次清除时间: ${nextCleanupTime.toString()}');
    
    if (nextCleanupTime.isAfter(now)) {
      final duration = nextCleanupTime.difference(now);
      debugPrint('✅ 下次自动清除安排成功，将在 ${duration.inMinutes} 分钟后执行');
      debugPrint('🕐 下次自动清除时间: ${nextCleanupTime.toString()}');
      
      _cleanupTimer = Timer(duration, () {
        debugPrint('⏰ 定时器触发，开始执行自动清除');
        _performCleanup();
        _scheduleNextCleanup(); // 安排下一次清除
      });
    } else {
      debugPrint('❌ 计算的清除时间已过期，重新计算');
      // 如果计算的时间已经过期，立即执行一次清除
      _performCleanup();
      _scheduleNextCleanup();
    }
  }

  /// 计算下次清除时间
  DateTime _calculateNextCleanupTime() {
    final now = DateTime.now();
    final intervalDays = _settings.cleanupIntervalDays;
    
    // 如果禁用或间隔为0，返回很久以后的时间
    if (!_settings.enabled || intervalDays <= 0) {
      return now.add(const Duration(days: 365));
    }
    
    final todayCleanupTime = DateTime(
      now.year,
      now.month,
      now.day,
      _settings.cleanupTime.hour,
      _settings.cleanupTime.minute,
    );

    // 如果今天的清除时间还没过，就安排今天
    if (todayCleanupTime.isAfter(now)) {
      return todayCleanupTime;
    }

    // 否则安排到下一个清除周期
    // 根据策略计算下次清除时间
    DateTime nextCleanupTime;
    switch (_settings.strategy) {
      case AutoCleanupStrategy.daily:
        nextCleanupTime = todayCleanupTime.add(const Duration(days: 1));
        break;
      case AutoCleanupStrategy.weekly:
        nextCleanupTime = todayCleanupTime.add(const Duration(days: 7));
        break;
      case AutoCleanupStrategy.monthly:
        nextCleanupTime = todayCleanupTime.add(const Duration(days: 30));
        break;
      case AutoCleanupStrategy.custom:
        nextCleanupTime = todayCleanupTime.add(Duration(days: _settings.customDays));
        break;
      case AutoCleanupStrategy.disabled:
      default:
        nextCleanupTime = now.add(const Duration(days: 365));
        break;
    }
    
    return nextCleanupTime;
  }

  /// 执行清除
  Future<void> _performCleanup() async {
    try {
      debugPrint('🧹 开始执行自动清除...');
      
      final completedTasks = _getTasksToCleanup();
      
      if (completedTasks.isEmpty) {
        debugPrint('✅ 没有需要清除的任务');
        await _updateLastCleanupTime();
        return;
      }

      // 创建备份
      if (_settings.createBackup) {
        await _createBackup(completedTasks);
      }

      // 执行清除
      int cleanedCount = 0;
      for (final task in completedTasks) {
        _todoProvider.deleteTodo(task.id);
        cleanedCount++;
      }

      await _updateLastCleanupTime();
      
      debugPrint('✅ 自动清除完成，共清除 $cleanedCount 个已完成任务');
      
      // 可以在这里发送通知给用户
      _notifyCleanupCompleted(cleanedCount);
      
    } catch (e) {
      debugPrint('❌ 自动清除失败: $e');
    }
  }

  /// 获取需要清除的任务
  List<TodoItem> _getTasksToCleanup({bool isManual = false}) {
    final now = DateTime.now();
    final cutoffTime = now.subtract(Duration(days: _settings.cleanupIntervalDays));
    
    return _todoProvider.todos.where((task) {
      // 只清除已完成的任务
      if (!task.completed || task.completedAt == null) {
        return false;
      }
      
      // 保留重要任务
      if (_settings.keepImportantTasks && task.isPriority) {
        return false;
      }
      
      // 保留每日待办任务
      if (_settings.keepRecurringTasks && task.taskType == TaskType.daily) {
        return false;
      }
      
      // 手动清除模式：清除所有已完成任务
      if (isManual) {
        return true;
      }
      
      // 自动清除模式：检查完成时间是否超过清除期限
      return task.completedAt!.isBefore(cutoffTime);
    }).toList();
  }

  /// 创建备份
  Future<void> _createBackup(List<TodoItem> tasksToCleanup) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupKey = '$_backupPrefix${DateTime.now().millisecondsSinceEpoch}';
      
      final backupData = {
        'timestamp': DateTime.now().toIso8601String(),
        'tasks': tasksToCleanup.map((task) => task.toJson()).toList(),
        'count': tasksToCleanup.length,
      };
      
      await prefs.setString(backupKey, jsonEncode(backupData));
      
      // 清理旧备份（保留最近10个）
      await _cleanupOldBackups();
      
      debugPrint('💾 已创建备份: $backupKey (${tasksToCleanup.length}个任务)');
    } catch (e) {
      debugPrint('❌ 创建备份失败: $e');
    }
  }

  /// 清理旧备份
  Future<void> _cleanupOldBackups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final backupKeys = allKeys
          .where((key) => key.startsWith(_backupPrefix))
          .toList()
        ..sort((a, b) => b.compareTo(a)); // 按时间戳降序排列

      // 保留最近10个备份，删除其余的
      if (backupKeys.length > 10) {
        for (int i = 10; i < backupKeys.length; i++) {
          await prefs.remove(backupKeys[i]);
        }
        debugPrint('🗑️ 已清理 ${backupKeys.length - 10} 个旧备份');
      }
    } catch (e) {
      debugPrint('❌ 清理旧备份失败: $e');
    }
  }

  /// 更新最后清除时间
  Future<void> _updateLastCleanupTime() async {
    _settings = _settings.copyWith(lastCleanupTime: DateTime.now());
    await _saveSettings();
  }

  /// 通知清除完成
  void _notifyCleanupCompleted(int count) {
    // 这里可以发送应用内通知或推送通知
    // 暂时只打印日志
    debugPrint('📱 通知：已自动清除 $count 个已完成任务');
  }

  /// 手动执行清除
  Future<int> performManualCleanup() async {
    debugPrint('🔧 手动执行清除被调用');
    final tasksToCleanup = _getTasksToCleanup(isManual: true);
    
    debugPrint('📋 找到 ${tasksToCleanup.length} 个需要清除的任务');
    
    if (tasksToCleanup.isEmpty) {
      debugPrint('✅ 没有需要清除的任务');
      return 0;
    }

    if (_settings.createBackup) {
      await _createBackup(tasksToCleanup);
    }

    for (final task in tasksToCleanup) {
      debugPrint('🗑️ 删除任务: ${task.text}');
      _todoProvider.deleteTodo(task.id);
    }

    await _updateLastCleanupTime();
    debugPrint('✅ 手动清除完成，共清除 ${tasksToCleanup.length} 个任务');
    return tasksToCleanup.length;
  }
  
  /// 测试自动清除功能（立即执行一次）
  Future<void> testAutoCleanup() async {
    debugPrint('🧪 测试自动清除功能');
    debugPrint('🧪 当前设置: enabled=${_settings.enabled}, strategy=${_settings.strategy}');
    
    // 临时启用自动清除进行测试
    final originalSettings = _settings;
    _settings = _settings.copyWith(
      enabled: true,
      strategy: AutoCleanupStrategy.daily,
    );
    
    await _performCleanup();
    
    // 恢复原始设置
    _settings = originalSettings;
    debugPrint('🧪 测试完成，已恢复原始设置');
  }

  /// 获取备份列表
  Future<List<Map<String, dynamic>>> getBackupList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final backupKeys = allKeys
          .where((key) => key.startsWith(_backupPrefix))
          .toList()
        ..sort((a, b) => b.compareTo(a));

      final backups = <Map<String, dynamic>>[];
      for (final key in backupKeys) {
        final backupJson = prefs.getString(key);
        if (backupJson != null) {
          final backupData = jsonDecode(backupJson);
          backups.add({
            'key': key,
            'timestamp': DateTime.parse(backupData['timestamp']),
            'count': backupData['count'],
          });
        }
      }
      
      return backups;
    } catch (e) {
      debugPrint('❌ 获取备份列表失败: $e');
      return [];
    }
  }

  /// 恢复备份
  Future<bool> restoreBackup(String backupKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupJson = prefs.getString(backupKey);
      
      if (backupJson == null) {
        return false;
      }

      final backupData = jsonDecode(backupJson);
      final tasks = (backupData['tasks'] as List)
          .map((taskJson) => TodoItem.fromJson(taskJson))
          .toList();

      for (final task in tasks) {
        _todoProvider.addTodoFromBackup(task);
      }

      debugPrint('♻️ 已恢复备份: $backupKey (${tasks.length}个任务)');
      return true;
    } catch (e) {
      debugPrint('❌ 恢复备份失败: $e');
      return false;
    }
  }

  /// 释放资源
  void dispose() {
    _cleanupTimer?.cancel();
  }
}
