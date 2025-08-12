import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/utils/keyboard_utils.dart';

/// 即时键盘响应文本输入框 - 专门解决键盘弹出慢的问题
class InstantKeyboardTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final Function(String)? onSubmitted;
  final Function()? onTap;
  final int maxLines;
  final bool autofocus;

  const InstantKeyboardTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.suffixIcon,
    this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
    this.onTap,
    this.maxLines = 1,
    this.autofocus = false,
  });

  @override
  State<InstantKeyboardTextField> createState() => _InstantKeyboardTextFieldState();
}

class _InstantKeyboardTextFieldState extends State<InstantKeyboardTextField> {
  late FocusNode _focusNode;
  bool _isKeyboardReady = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    
    // 预备键盘状态
    _prepareKeyboard();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  /// 超级键盘预备 - 利用全局预热机制
  void _prepareKeyboard() async {
    try {
      final stopwatch = Stopwatch()..start();
      
      // 等待全局键盘预热完成
      await _waitForGlobalPrewarm();
      
      // 立即建立专用连接
      await _establishDedicatedConnection();
      
      // 预激活键盘状态
      await _preActivateKeyboard();
      
      setState(() {
        _isKeyboardReady = true;
      });
      
      stopwatch.stop();
      debugPrint('🎹 输入框超级预备完成: ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      debugPrint('🎹 输入框键盘预备失败: $e');
      // 即使失败也标记为准备好，避免阻塞用户操作
      setState(() {
        _isKeyboardReady = true;
      });
    }
  }
  
  /// 等待全局键盘预热完成
  Future<void> _waitForGlobalPrewarm() async {
    int attempts = 0;
    while (attempts < 10) { // 最多等待1秒
      if (KeyboardUtils.isKeyboardPrewarmed) {
        break;
      }
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
  }
  
  /// 建立专用连接
  Future<void> _establishDedicatedConnection() async {
    await SystemChannels.textInput.invokeMethod('TextInput.setClient', [
      hashCode, // 使用组件hash作为唯一ID
      {
        'inputType': {'name': widget.keyboardType.toString()},
        'inputAction': widget.textInputAction.toString(),
        'autocorrect': false,
        'enableSuggestions': false,
        'enableInteractiveSelection': true,
      }
    ]);
  }
  
  /// 预激活键盘状态
  Future<void> _preActivateKeyboard() async {
    // 设置初始编辑状态
    await SystemChannels.textInput.invokeMethod('TextInput.setEditingState', {
      'text': widget.controller.text,
      'selectionBase': widget.controller.selection.baseOffset,
      'selectionExtent': widget.controller.selection.extentOffset,
    });
    
    // 预热一次显示/隐藏循环
    await SystemChannels.textInput.invokeMethod('TextInput.show');
    await Future.delayed(const Duration(milliseconds: 10));
    await SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  /// 超快速键盘弹出处理
  void _handleTap() {
    if (widget.onTap != null) {
      widget.onTap!();
    }
    
    // 立即激活键盘
    _activateKeyboardInstantly();
  }

  /// 闪电激活键盘 - 零延迟响应
  void _activateKeyboardInstantly() {
    final stopwatch = Stopwatch()..start();
    
    // 机制1: 同步请求焦点（最快）
    _focusNode.requestFocus();
    FocusScope.of(context).requestFocus(_focusNode);
    
    // 机制2: 立即显示键盘（无等待）
    SystemChannels.textInput.invokeMethod('TextInput.show');
    
    // 机制3: 如果已预备，立即同步状态
    if (_isKeyboardReady) {
      SystemChannels.textInput.invokeMethod('TextInput.setEditingState', {
        'text': widget.controller.text,
        'selectionBase': widget.controller.selection.baseOffset,
        'selectionExtent': widget.controller.selection.extentOffset,
      });
    }
    
    // 机制4: 强制连接到预热的客户端
    SystemChannels.textInput.invokeMethod('TextInput.setClient', [
      hashCode,
      {
        'inputType': {'name': widget.keyboardType.toString()},
        'inputAction': widget.textInputAction.toString(),
        'autocorrect': false,
        'enableSuggestions': false,
        'enableInteractiveSelection': true,
      }
    ]);
    
    // 机制5: 后备确保机制（异步，不阻塞）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_focusNode.hasFocus) {
        _focusNode.requestFocus();
        SystemChannels.textInput.invokeMethod('TextInput.show');
      }
    });
    
    stopwatch.stop();
    debugPrint('⚡ 键盘闪电激活: ${stopwatch.elapsedMilliseconds}ms');
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      maxLines: widget.maxLines,
      autofocus: widget.autofocus,
      
      // 关键优化配置
      autocorrect: false,
      enableSuggestions: false,
      enableInteractiveSelection: true,
      
      // 即时响应点击
      onTap: _handleTap,
      onSubmitted: widget.onSubmitted,
      
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: const TextStyle(
          color: Colors.grey,  // 固定为浅灰色，不跟随主题
          fontSize: 16,  // 与语录内容字体大小一致
        ),
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.suffixIcon,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        // 减少动画延迟
        floatingLabelBehavior: FloatingLabelBehavior.never,
      ),
      
      // 移除onTapOutside，让外层GestureDetector处理
    );
  }
}
