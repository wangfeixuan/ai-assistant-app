import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Widget修复工具类
/// 用于解决运行时的GlobalKey重复和构建作用域问题
class WidgetFixUtils {
  /// 创建唯一的GlobalKey
  static GlobalKey<T> createUniqueKey<T extends State<StatefulWidget>>() {
    return GlobalKey<T>(debugLabel: 'unique_${DateTime.now().millisecondsSinceEpoch}_${T.toString()}');
  }
  
  /// 安全的Provider访问
  static T? safeProviderOf<T>(BuildContext context, {bool listen = true}) {
    try {
      return Provider.of<T>(context, listen: listen);
    } catch (e) {
      debugPrint('❌ Provider访问失败: $e');
      return null;
    }
  }
  
  /// 安全的Widget构建
  static Widget safeBuild(BuildContext context, Widget Function() builder) {
    try {
      return builder();
    } catch (e) {
      debugPrint('❌ Widget构建失败: $e');
      return Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 8),
              Text(
                '组件加载失败',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '请稍后重试',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
  
  /// 延迟执行，避免构建冲突
  static void safePostFrame(VoidCallback callback) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        callback();
      } catch (e) {
        debugPrint('❌ PostFrame回调执行失败: $e');
      }
    });
  }
  
  /// 安全的状态更新
  static void safeSetState(State state, VoidCallback callback) {
    if (state.mounted) {
      try {
        state.setState(callback);
      } catch (e) {
        debugPrint('❌ setState执行失败: $e');
      }
    }
  }
}

/// 安全的Consumer Widget包装器
class SafeConsumer<T extends ChangeNotifier> extends StatelessWidget {
  final Widget Function(BuildContext context, T value, Widget? child) builder;
  final Widget? child;
  final Widget Function(BuildContext context)? errorBuilder;

  const SafeConsumer({
    super.key,
    required this.builder,
    this.child,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<T>(
      builder: (context, value, child) {
        try {
          return builder(context, value, child);
        } catch (e) {
          debugPrint('❌ SafeConsumer构建失败: $e');
          if (errorBuilder != null) {
            return errorBuilder!(context);
          }
          return WidgetFixUtils.safeBuild(context, () => Container());
        }
      },
      child: child,
    );
  }
}

/// 安全的Stateful Widget基类
abstract class SafeStatefulWidget extends StatefulWidget {
  const SafeStatefulWidget({super.key});
}

abstract class SafeState<T extends SafeStatefulWidget> extends State<T> {
  bool _isDisposed = false;
  
  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
  
  /// 安全的setState调用
  void safeSetState(VoidCallback callback) {
    if (!_isDisposed && mounted) {
      WidgetFixUtils.safeSetState(this, callback);
    }
  }
  
  /// 安全的异步操作
  Future<void> safeAsync(Future<void> Function() operation) async {
    if (!_isDisposed && mounted) {
      try {
        await operation();
      } catch (e) {
        debugPrint('❌ 异步操作失败: $e');
      }
    }
  }
}
