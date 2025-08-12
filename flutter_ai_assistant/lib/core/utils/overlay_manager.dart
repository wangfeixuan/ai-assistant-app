import 'package:flutter/material.dart';

/// 全局Overlay管理器
/// 用于统一管理所有Overlay相关组件的GlobalKey，避免重复和冲突
class OverlayManager {
  static final OverlayManager _instance = OverlayManager._internal();
  factory OverlayManager() => _instance;
  OverlayManager._internal();

  // 计数器，用于生成唯一ID
  int _counter = 0;
  
  // 存储已使用的Key，避免重复
  final Set<String> _usedKeys = <String>{};
  
  /// 生成唯一的GlobalKey
  GlobalKey<T> generateUniqueKey<T extends State<StatefulWidget>>({
    String? prefix,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final counterValue = ++_counter;
    final keyString = '${prefix ?? 'overlay'}_${timestamp}_$counterValue';
    
    // 确保Key的唯一性
    String finalKey = keyString;
    int suffix = 0;
    while (_usedKeys.contains(finalKey)) {
      finalKey = '${keyString}_${++suffix}';
    }
    
    _usedKeys.add(finalKey);
    return GlobalKey<T>(debugLabel: finalKey);
  }
  
  /// 生成唯一的ValueKey
  ValueKey<String> generateUniqueValueKey({String? prefix}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final counterValue = ++_counter;
    final keyString = '${prefix ?? 'value'}_${timestamp}_$counterValue';
    
    String finalKey = keyString;
    int suffix = 0;
    while (_usedKeys.contains(finalKey)) {
      finalKey = '${keyString}_${++suffix}';
    }
    
    _usedKeys.add(finalKey);
    return ValueKey<String>(finalKey);
  }
  
  /// 清理已使用的Key（可选，用于内存优化）
  void clearUsedKeys() {
    _usedKeys.clear();
  }
  
  /// 获取已使用Key的数量（用于调试）
  int get usedKeysCount => _usedKeys.length;
}

/// 安全的SnackBar显示器
class SafeSnackBarManager {
  static final SafeSnackBarManager _instance = SafeSnackBarManager._internal();
  factory SafeSnackBarManager() => _instance;
  SafeSnackBarManager._internal();
  
  final OverlayManager _overlayManager = OverlayManager();
  
  /// 安全显示SnackBar
  void showSnackBar(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
    Color? backgroundColor,
    Color? textColor,
    SnackBarBehavior behavior = SnackBarBehavior.floating,
    EdgeInsetsGeometry? margin,
    double? elevation,
    ShapeBorder? shape,
  }) {
    try {
      // 先清除当前的SnackBar，避免冲突
      ScaffoldMessenger.of(context).clearSnackBars();
      
      // 生成唯一Key
      final key = _overlayManager.generateUniqueValueKey(prefix: 'snackbar');
      
      final snackBar = SnackBar(
        key: key,
        content: Text(
          message,
          style: TextStyle(color: textColor),
        ),
        duration: duration,
        action: action,
        backgroundColor: backgroundColor,
        behavior: behavior,
        margin: margin,
        elevation: elevation,
        shape: shape,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } catch (e) {
      debugPrint('❌ SnackBar显示失败: $e');
      // 降级处理：使用简单的print输出
      debugPrint('📢 消息: $message');
    }
  }
  
  /// 清除所有SnackBar
  void clearAllSnackBars(BuildContext context) {
    try {
      ScaffoldMessenger.of(context).clearSnackBars();
    } catch (e) {
      debugPrint('❌ 清除SnackBar失败: $e');
    }
  }
}

/// 安全的对话框管理器
class SafeDialogManager {
  static final SafeDialogManager _instance = SafeDialogManager._internal();
  factory SafeDialogManager() => _instance;
  SafeDialogManager._internal();
  
  final OverlayManager _overlayManager = OverlayManager();
  
  /// 安全显示对话框
  Future<T?> showSafeDialog<T>({
    required BuildContext context,
    required Widget Function(BuildContext) builder,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
    bool useRootNavigator = false,
    RouteSettings? routeSettings,
    String? keyPrefix,
  }) async {
    try {
      final key = _overlayManager.generateUniqueValueKey(
        prefix: keyPrefix ?? 'dialog',
      );
      
      return await showDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        barrierColor: barrierColor,
        barrierLabel: barrierLabel,
        useRootNavigator: useRootNavigator,
        routeSettings: routeSettings,
        builder: (BuildContext dialogContext) {
          return KeyedSubtree(
            key: key,
            child: builder(dialogContext),
          );
        },
      );
    } catch (e) {
      debugPrint('❌ 对话框显示失败: $e');
      return null;
    }
  }
}

/// 扩展BuildContext，提供便捷的安全Overlay方法
extension SafeOverlayExtension on BuildContext {
  /// 安全显示SnackBar
  void showSafeSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
    Color? backgroundColor,
    Color? textColor,
    SnackBarBehavior behavior = SnackBarBehavior.floating,
  }) {
    SafeSnackBarManager().showSnackBar(
      this,
      message: message,
      duration: duration,
      action: action,
      backgroundColor: backgroundColor,
      textColor: textColor,
      behavior: behavior,
    );
  }
  
  /// 安全显示对话框
  Future<T?> showSafeDialog<T>({
    required Widget Function(BuildContext) builder,
    bool barrierDismissible = true,
    String? keyPrefix,
  }) {
    return SafeDialogManager().showSafeDialog<T>(
      context: this,
      builder: builder,
      barrierDismissible: barrierDismissible,
      keyPrefix: keyPrefix,
    );
  }
}
