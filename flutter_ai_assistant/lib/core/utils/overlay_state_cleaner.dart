import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Overlay状态清理器
/// 用于解决GlobalKey重复和Widget构建作用域问题
class OverlayStateCleaner {
  static final OverlayStateCleaner _instance = OverlayStateCleaner._internal();
  factory OverlayStateCleaner() => _instance;
  OverlayStateCleaner._internal();

  // 跟踪活跃的Overlay
  final Set<OverlayEntry> _activeOverlays = <OverlayEntry>{};
  
  // 跟踪活跃的GlobalKey
  final Map<String, GlobalKey> _activeKeys = <String, GlobalKey>{};

  /// 注册Overlay
  void registerOverlay(OverlayEntry overlay, {String? keyId}) {
    _activeOverlays.add(overlay);
    if (keyId != null && overlay.builder != null) {
      // 这里可以添加更多的跟踪逻辑
    }
  }

  /// 注销Overlay
  void unregisterOverlay(OverlayEntry overlay) {
    _activeOverlays.remove(overlay);
  }

  /// 清理所有活跃的Overlay
  void clearAllOverlays() {
    for (final overlay in List.from(_activeOverlays)) {
      try {
        if (overlay.mounted) {
          overlay.remove();
        }
      } catch (e) {
        debugPrint('❌ 清理Overlay失败: $e');
      }
    }
    _activeOverlays.clear();
  }

  /// 安全清理指定context的所有SnackBar
  void clearSnackBars(BuildContext context) {
    try {
      ScaffoldMessenger.of(context).clearSnackBars();
    } catch (e) {
      debugPrint('❌ 清理SnackBar失败: $e');
    }
  }

  /// 强制清理Widget树中的脏状态
  void forceCleanWidgetTree() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      try {
        // 强制触发一次完整的重建
        WidgetsBinding.instance.reassembleApplication();
      } catch (e) {
        debugPrint('❌ 强制清理Widget树失败: $e');
      }
    });
  }

  /// 获取活跃Overlay数量
  int get activeOverlayCount => _activeOverlays.length;
}

/// 安全的Overlay入口点
class SafeOverlayEntry extends OverlayEntry {
  final String _uniqueId;
  final OverlayStateCleaner _cleaner = OverlayStateCleaner();

  SafeOverlayEntry({
    required WidgetBuilder builder,
    bool opaque = false,
    bool maintainState = false,
    String? uniqueId,
  }) : _uniqueId = uniqueId ?? 'overlay_${DateTime.now().millisecondsSinceEpoch}',
       super(
         builder: builder,
         opaque: opaque,
         maintainState: maintainState,
       ) {
    _cleaner.registerOverlay(this, keyId: _uniqueId);
  }

  @override
  void remove() {
    _cleaner.unregisterOverlay(this);
    super.remove();
  }

  String get uniqueId => _uniqueId;
}

/// 混入类，为StatefulWidget提供安全的Overlay管理
mixin SafeOverlayMixin<T extends StatefulWidget> on State<T> {
  final OverlayStateCleaner _cleaner = OverlayStateCleaner();
  final List<OverlayEntry> _ownedOverlays = [];

  /// 安全显示Overlay
  void showSafeOverlay(OverlayEntry overlay) {
    try {
      Overlay.of(context).insert(overlay);
      _ownedOverlays.add(overlay);
      _cleaner.registerOverlay(overlay);
    } catch (e) {
      debugPrint('❌ 显示Overlay失败: $e');
    }
  }

  /// 安全移除Overlay
  void removeSafeOverlay(OverlayEntry overlay) {
    try {
      if (overlay.mounted) {
        overlay.remove();
      }
      _ownedOverlays.remove(overlay);
      _cleaner.unregisterOverlay(overlay);
    } catch (e) {
      debugPrint('❌ 移除Overlay失败: $e');
    }
  }

  /// 清理所有拥有的Overlay
  void clearAllOwnedOverlays() {
    for (final overlay in List.from(_ownedOverlays)) {
      removeSafeOverlay(overlay);
    }
  }

  @override
  void dispose() {
    // 在dispose时清理所有拥有的Overlay
    clearAllOwnedOverlays();
    super.dispose();
  }
}

/// 全局Overlay状态监控器
class OverlayStateMonitor extends StatefulWidget {
  final Widget child;

  const OverlayStateMonitor({
    super.key,
    required this.child,
  });

  @override
  State<OverlayStateMonitor> createState() => _OverlayStateMonitorState();
}

class _OverlayStateMonitorState extends State<OverlayStateMonitor>
    with WidgetsBindingObserver {
  final OverlayStateCleaner _cleaner = OverlayStateCleaner();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // 在应用生命周期变化时清理Overlay状态
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _cleaner.clearAllOverlays();
      _cleaner.forceCleanWidgetTree();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
