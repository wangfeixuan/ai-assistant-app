import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../../features/todo/providers/todo_provider.dart';
import '../../features/todo/models/todo_item.dart';

/// 应用包装器 - 用于设置全局服务的上下文
class AppWrapper extends StatefulWidget {
  final Widget child;

  const AppWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> with WidgetsBindingObserver {
  DateTime? _lastActiveDate;
  DateTime? _lastBackgroundTime;
  AppLifecycleState? _previousState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastActiveDate = DateTime.now();
    
    // 设置通知服务的上下文
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().setContext(context);
      _checkForRolloverTasks();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    final now = DateTime.now();
    
    debugPrint('🔄 应用生命周期状态变更: $_previousState -> $state');
    
    switch (state) {
      case AppLifecycleState.resumed:
        if (mounted) {
          NotificationService().setContext(context);
          _checkForRolloverTasks();
          
          // 如果从后台返回前台，检查后台时长
          if (_lastBackgroundTime != null) {
            final backgroundDuration = now.difference(_lastBackgroundTime!);
            debugPrint('📱 应用从后台返回，后台时长: ${backgroundDuration.inMinutes}分钟');
            
            // 如果后台超过5分钟，触发提醒检查
            if (backgroundDuration.inMinutes > 5) {
              _triggerReminderCheck();
            }
          }
        }
        break;
        
      case AppLifecycleState.paused:
        _lastActiveDate = now;
        _lastBackgroundTime = now;
        debugPrint('📱 应用进入后台');
        break;
        
      case AppLifecycleState.detached:
        debugPrint('📱 应用被分离');
        break;
        
      case AppLifecycleState.inactive:
        debugPrint('📱 应用变为非活跃状态');
        break;
        
      case AppLifecycleState.hidden:
        debugPrint('📱 应用被隐藏');
        break;
    }
    
    _previousState = state;
  }

  /// 检查是否需要处理跨天任务
  void _checkForRolloverTasks() {
    try {
      final todoProvider = context.read<TodoProvider>();
      final now = DateTime.now();
      
      // 如果是新的一天，执行跨天任务处理
      if (_lastActiveDate != null) {
        final lastActiveDay = DateTime(_lastActiveDate!.year, _lastActiveDate!.month, _lastActiveDate!.day);
        final currentDay = DateTime(now.year, now.month, now.day);
        
        if (currentDay.isAfter(lastActiveDay)) {
          debugPrint('🌅 检测到新的一天，开始处理跨天任务...');
          todoProvider.rolloverIncompleteTasks();
          
          // 检查并生成重复任务的新实例
          _checkAndGenerateRecurringTasks(todoProvider);
          
          debugPrint('✅ 跨天任务处理完成');
        }
      }
      
      _lastActiveDate = now;
    } catch (e) {
      debugPrint('❌ 跨天任务处理失败: $e');
    }
  }
  
  /// 触发提醒检查（用于从后台返回时）
  void _triggerReminderCheck() {
    try {
      // 这里可以触发SmartReminderService的检查
      debugPrint('🔔 触发提醒检查 - 应用从长时间后台返回');
      // 注意：实际实现中需要获取SmartReminderService实例
      // 可以通过Provider或单例模式访问
    } catch (e) {
      debugPrint('❌ 触发提醒检查失败: $e');
    }
  }

  /// 检查并生成每日待办任务（已由DailyTaskScheduler处理）
  void _checkAndGenerateRecurringTasks(TodoProvider todoProvider) {
    // 每日待办任务的生成已由DailyTaskScheduler自动处理
    // 这里不再需要手动检查，保留方法以保持兼容性
    debugPrint('📅 每日待办任务由DailyTaskScheduler自动管理');
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
