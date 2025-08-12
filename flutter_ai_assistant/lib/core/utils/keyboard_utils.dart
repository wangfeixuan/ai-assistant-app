import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 键盘管理工具类 - 优化键盘响应速度
class KeyboardUtils {
  static bool _isKeyboardPrewarmed = false;
  
  /// 检查键盘是否已预热
  static bool get isKeyboardPrewarmed => _isKeyboardPrewarmed;
  
  /// 超级激进的键盘预热 - 解决10秒响应问题
  static Future<void> prewarmKeyboard() async {
    if (_isKeyboardPrewarmed) return;
    
    try {
      debugPrint('🎹 开始超级键盘预热...');
      final stopwatch = Stopwatch()..start();
      
      // 阶段1: 强制唤醒文本输入服务
      await _forceWakeupTextInputService();
      
      // 阶段2: 预热多种键盘类型
      await _prewarmMultipleKeyboardTypes();
      
      // 阶段3: 建立持久连接
      await _establishPersistentConnection();
      
      // 阶段4: 验证键盘响应速度
      await _validateKeyboardResponse();
      
      _isKeyboardPrewarmed = true;
      stopwatch.stop();
      debugPrint('🎹 超级键盘预热完成！耗时: ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      debugPrint('🎹 键盘预热失败: $e');
    }
  }
  
  /// 强制唤醒文本输入服务
  static Future<void> _forceWakeupTextInputService() async {
    // 连续快速调用，强制系统启动键盘服务
    for (int i = 0; i < 5; i++) {
      await SystemChannels.textInput.invokeMethod('TextInput.show');
      await SystemChannels.textInput.invokeMethod('TextInput.hide');
      // 不等待，立即下一轮
    }
    
    // 短暂等待让系统处理
    await Future.delayed(const Duration(milliseconds: 50));
  }
  
  /// 预热多种键盘类型
  static Future<void> _prewarmMultipleKeyboardTypes() async {
    final keyboardTypes = [
      {'name': 'TextInputType.text'},
      {'name': 'TextInputType.multiline'},
      {'name': 'TextInputType.number'},
    ];
    
    for (int i = 0; i < keyboardTypes.length; i++) {
      await SystemChannels.textInput.invokeMethod('TextInput.setClient', [
        i + 100, // 使用不同的客户端ID
        {
          'inputType': keyboardTypes[i],
          'inputAction': 'TextInputAction.done',
          'autocorrect': false,
          'enableSuggestions': false,
        }
      ]);
      
      // 激活每个客户端
      await SystemChannels.textInput.invokeMethod('TextInput.show');
      await Future.delayed(const Duration(milliseconds: 20));
      await SystemChannels.textInput.invokeMethod('TextInput.hide');
    }
  }
  
  /// 建立持久连接
  static Future<void> _establishPersistentConnection() async {
    // 创建一个持久的文本输入客户端
    await SystemChannels.textInput.invokeMethod('TextInput.setClient', [
      999, // 持久客户端ID
      {
        'inputType': {'name': 'TextInputType.text'},
        'inputAction': 'TextInputAction.done',
        'autocorrect': false,
        'enableSuggestions': false,
        'enableInteractiveSelection': true,
      }
    ]);
    
    // 设置初始编辑状态
    await SystemChannels.textInput.invokeMethod('TextInput.setEditingState', {
      'text': '',
      'selectionBase': 0,
      'selectionExtent': 0,
    });
  }
  
  /// 验证键盘响应速度
  static Future<void> _validateKeyboardResponse() async {
    final testStopwatch = Stopwatch()..start();
    
    // 测试键盘显示速度
    await SystemChannels.textInput.invokeMethod('TextInput.show');
    await SystemChannels.textInput.invokeMethod('TextInput.hide');
    
    testStopwatch.stop();
    debugPrint('🎹 键盘响应测试: ${testStopwatch.elapsedMilliseconds}ms');
    
    if (testStopwatch.elapsedMilliseconds > 100) {
      debugPrint('⚠️ 键盘响应仍然较慢，可能需要设备重启');
    }
  }
  
  /// 维护优化 - 应用启动后进行深度优化
  static Future<void> performMaintenanceOptimization() async {
    if (!_isKeyboardPrewarmed) {
      await prewarmKeyboard();
      return;
    }
    
    try {
      debugPrint('🔧 开始键盘维护优化...');
      
      // 清理可能的僵死连接
      await SystemChannels.textInput.invokeMethod('TextInput.clearClient');
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 重新建立优化连接
      await _establishPersistentConnection();
      
      // 验证优化效果
      await _validateKeyboardResponse();
      
      debugPrint('🔧 键盘维护优化完成');
    } catch (e) {
      debugPrint('🔧 键盘维护优化失败: $e');
    }
  }
  
  /// 轻量级优化 - 定期保持键盘活跃状态
  static Future<void> performLightweightOptimization() async {
    if (!_isKeyboardPrewarmed) return;
    
    try {
      // 轻量级心跳，保持键盘服务活跃
      await SystemChannels.textInput.invokeMethod('TextInput.show');
      await Future.delayed(const Duration(milliseconds: 10));
      await SystemChannels.textInput.invokeMethod('TextInput.hide');
    } catch (e) {
      // 静默失败，不打印错误日志
    }
  }
  
  /// 超级快速显示键盘 - 多重保障立即响应
  static void showKeyboardFast(BuildContext context, FocusNode focusNode) {
    // 立即请求焦点 - 方法1
    focusNode.requestFocus();
    
    // 强制显示键盘 - 方法2
    SystemChannels.textInput.invokeMethod('TextInput.show');
    
    // 强制设置焦点 - 方法3
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(focusNode);
    });
    
    // 立即激活文本输入 - 方法4
    SystemChannels.textInput.invokeMethod('TextInput.setClient', [
      1,
      {
        'inputType': {'name': 'TextInputType.text'},
        'inputAction': 'TextInputAction.done',
      }
    ]);
  }
  
  /// 强制隐藏键盘 - 使用多种方法确保键盘收起
  static void hideKeyboard(BuildContext context) {
    // 方法1：取消焦点
    FocusScope.of(context).unfocus();
    
    // 方法2：请求一个新的空焦点节点
    FocusScope.of(context).requestFocus(FocusNode());
    
    // 方法3：使用系统方法隐藏键盘
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  /// 创建一个包装器，点击空白区域时隐藏键盘
  static Widget dismissKeyboardWrapper({
    required BuildContext context,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: () => hideKeyboard(context),
      behavior: HitTestBehavior.opaque, // 确保能捕获到点击事件
      child: child,
    );
  }
  
  /// 创建优化的输入框配置
  static InputDecoration getOptimizedInputDecoration({
    String? hintText,
    Widget? suffixIcon,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Colors.grey,  // 固定为浅灰色，不跟随主题
        fontSize: 16,  // 与语录内容字体大小一致
      ),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      // 减少动画延迟
      floatingLabelBehavior: FloatingLabelBehavior.never,
    );
  }
}

/// 扩展方法，方便使用
extension KeyboardDismiss on Widget {
  /// 包装widget，使其支持点击空白区域收起键盘
  Widget dismissKeyboard(BuildContext context) {
    return KeyboardUtils.dismissKeyboardWrapper(
      context: context,
      child: this,
    );
  }
}