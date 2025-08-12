import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';

/// 安全的待办组件包装器
/// 用于解决运行时的GlobalKey重复和构建作用域问题
class SafeTodoWidget extends StatelessWidget {
  final Widget Function(BuildContext context, TodoProvider provider) builder;
  final Widget? fallback;

  const SafeTodoWidget({
    super.key,
    required this.builder,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, todoProvider, child) {
        try {
          return builder(context, todoProvider);
        } catch (e) {
          debugPrint('❌ SafeTodoWidget构建失败: $e');
          return fallback ?? _buildErrorWidget();
        }
      },
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
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
              '请重新加载页面',
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

/// 安全的对话框包装器
class SafeDialog extends StatelessWidget {
  final Widget child;
  final String? title;

  const SafeDialog({
    super.key,
    required this.child,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: ValueKey('safe_dialog_${DateTime.now().millisecondsSinceEpoch}'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: child,
    );
  }
}

/// 安全的页面包装器
class SafePage extends StatefulWidget {
  final Widget child;
  final String? title;
  final List<Widget>? actions;

  const SafePage({
    super.key,
    required this.child,
    this.title,
    this.actions,
  });

  @override
  State<SafePage> createState() => _SafePageState();
}

class _SafePageState extends State<SafePage> {
  bool _hasError = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title ?? '页面'),
          backgroundColor: Colors.red.shade50,
          foregroundColor: Colors.red.shade700,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                '页面加载失败',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade700,
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _errorMessage = null;
                  });
                },
                child: const Text('重新加载'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: widget.title != null
          ? AppBar(
              title: Text(widget.title!),
              actions: widget.actions,
            )
          : null,
      body: Builder(
        builder: (context) {
          try {
            return widget.child;
          } catch (e) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _hasError = true;
                  _errorMessage = e.toString();
                });
              }
            });
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }
}
