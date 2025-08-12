import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
// import 'package:firebase_core/firebase_core.dart';  // 暂时注释解决iOS构建问题

import 'app.dart';
import 'core/themes/theme_manager.dart';
import 'core/services/storage_service.dart';
import 'core/services/notification_service.dart';
import 'core/utils/keyboard_utils.dart';
import 'features/daily_quote/providers/quote_provider.dart';
import 'features/ai_chat/providers/chat_provider.dart';
import 'features/todo/providers/todo_provider.dart';
import 'features/pomodoro/providers/pomodoro_provider.dart';
import 'features/profile/providers/profile_provider.dart';
import 'providers/auth_provider.dart';
import 'services/daily_task_scheduler.dart';
import 'features/todo/services/auto_cleanup_service.dart';
import 'services/ai_connection_manager.dart';
// import 'services/firebase_messaging_service.dart';  // 暂时禁用解决iOS构建问题

// 全局服务实例，防止被垃圾回收
AutoCleanupService? _globalAutoCleanupService;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // 🚀 立即开始键盘预热（最高优先级）
    final keyboardPrewarmFuture = KeyboardUtils.prewarmKeyboard();
    
    // 并行初始化其他服务
    final initFutures = [
      // Firebase.initializeApp(), // Firebase初始化 - 暂时注释解决iOS构建问题
      Hive.initFlutter(),
      StorageService.init(),
      NotificationService().initialize(), // 本地通知服务初始化
    ];
    
    // 等待所有初始化完成
    await Future.wait([
      keyboardPrewarmFuture,
      ...initFutures,
    ]);
    
    // Firebase初始化完成后，初始化消息推送服务
    // await FirebaseMessagingService.initialize();  // 暂时禁用解决iOS构建问题
    
    // 🎹 启动后台键盘优化任务
    _startBackgroundKeyboardOptimization();
    
    debugPrint('🚀 应用初始化完成，键盘已预热');
  } catch (e) {
    debugPrint('Initialization failed: $e');
    // 即使初始化失败，也继续运行应用
    // 启动降级键盘优化
    _startBackgroundKeyboardOptimization();
  }
  
  // 创建 AuthProvider 实例
  final authProvider = AuthProvider();
  
  runApp(
    MultiProvider(
      providers: [
        // 主题管理
        ChangeNotifierProvider(create: (_) => ThemeManager()),
        
        // 功能模块提供者
        ChangeNotifierProvider(create: (_) => QuoteProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => TodoProvider()),
        ChangeNotifierProvider(create: (_) => PomodoroProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider.value(value: authProvider),
      ],
      child: const MyApp(),
    ),
  );
  
  // 在应用启动后异步初始化 AuthProvider 和每日待办调度器
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await authProvider.initializeAuth();
    
    // 初始化每日待办调度器和自动清除服务
    final context = MyApp.navigatorKey.currentContext;
    if (context != null) {
      final todoProvider = context.read<TodoProvider>();
      DailyTaskScheduler().initialize(todoProvider);
      debugPrint('📅 每日待办调度器已初始化');
      
      // 初始化自动清除服务
      _globalAutoCleanupService = AutoCleanupService(todoProvider);
      debugPrint('🧹 自动清除服务已初始化');
      
      // 初始化AI连接管理器
      await AIConnectionManager.instance.initialize();
      debugPrint('🤖 AI连接管理器已初始化');
    }
  });
}

/// 启动后台键盘优化任务
void _startBackgroundKeyboardOptimization() {
  // 延迟3秒后进行二次优化，确保键盘服务完全就绪
  Timer(const Duration(seconds: 3), () async {
    try {
      await KeyboardUtils.performMaintenanceOptimization();
      debugPrint('🔧 键盘维护优化完成');
    } catch (e) {
      debugPrint('🔧 键盘维护优化失败: $e');
    }
  });
  
  // 每30秒进行一次轻量级优化，保持键盘响应速度
  Timer.periodic(const Duration(seconds: 30), (timer) async {
    try {
      await KeyboardUtils.performLightweightOptimization();
    } catch (e) {
      debugPrint('🔧 轻量级键盘优化失败: $e');
    }
  });
}
