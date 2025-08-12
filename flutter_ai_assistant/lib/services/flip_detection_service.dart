import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// 翻转检测服务
/// 检测手机翻转状态，用于翻转开始番茄钟功能
class FlipDetectionService {
  static final FlipDetectionService _instance = FlipDetectionService._internal();
  factory FlipDetectionService() => _instance;
  FlipDetectionService._internal();

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  bool _isFlipped = false;
  bool _isListening = false;
  
  // 翻转状态变化回调
  Function(bool isFlipped)? onFlipStateChanged;
  
  // 翻转阈值（Z轴负值阈值，更宽松的检测）
  static const double _flipThreshold = 5.0;
  
  // 优化检测参数（平衡响应速度和资源消耗）
  static const int _stabilityCheckCount = 3;
  static const Duration _stabilityCheckInterval = Duration(milliseconds: 500); // 降低检测频率
  
  // 数据采样控制
  static const int _sampleSkipCount = 5; // 每5次数据采样1次
  int _sampleCounter = 0;
  
  List<bool> _recentFlipStates = [];
  Timer? _stabilityTimer;
  Timer? _idleTimer; // 空闲检测定时器
  
  // 智能监听控制
  static const Duration _idleTimeout = Duration(minutes: 5); // 5分钟无变化后暂停监听
  DateTime _lastStateChange = DateTime.now();

  /// 获取当前翻转状态
  bool get isFlipped => _isFlipped;
  
  /// 是否正在监听
  bool get isListening => _isListening;

  /// 开始监听翻转状态
  Future<void> startListening() async {
    if (_isListening) return;
    
    try {
      _isListening = true;
      _recentFlipStates.clear();
      
      debugPrint('🔄 开始监听手机翻转状态');
      
      _accelerometerSubscription = accelerometerEvents.listen(
        _handleAccelerometerEvent,
        onError: (error) {
          debugPrint('❌ 加速度计监听错误: $error');
          stopListening();
        },
      );
      
    } catch (e) {
      debugPrint('❌ 启动翻转检测失败: $e');
      _isListening = false;
    }
  }

  /// 停止监听翻转状态
  void stopListening() {
    if (!_isListening) return;
    
    debugPrint('⏹️ 停止监听手机翻转状态');
    
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _stabilityTimer?.cancel();
    _stabilityTimer = null;
    _isListening = false;
    _recentFlipStates.clear();
    
    // 重置翻转状态
    if (_isFlipped) {
      _isFlipped = false;
      onFlipStateChanged?.call(false);
    }
  }

  /// 处理加速度计事件
  void _handleAccelerometerEvent(AccelerometerEvent event) {
    // 数据采样控制：减少处理频率，节省资源
    _sampleCounter++;
    if (_sampleCounter < _sampleSkipCount) {
      return; // 跳过这次数据
    }
    _sampleCounter = 0; // 重置计数器
    
    // 简化翻转棆测：主要检测Z轴方向
    bool currentFlipState = event.z < -_flipThreshold;
    
    // 只在debug模式下输出日志，减少性能影响
    if (kDebugMode) {
      debugPrint('📱 传感器数据: z=${event.z.toStringAsFixed(2)}, 翻转状态: $currentFlipState');
    }
    
    // 添加到稳定性检测队列
    _recentFlipStates.add(currentFlipState);
    if (_recentFlipStates.length > _stabilityCheckCount) {
      _recentFlipStates.removeAt(0);
    }
    
    // 重启稳定性检测定时器
    _stabilityTimer?.cancel();
    _stabilityTimer = Timer(_stabilityCheckInterval, _checkStability);
  }

  /// 检查翻转状态稳定性
  void _checkStability() {
    if (_recentFlipStates.length < _stabilityCheckCount) return;
    
    // 计算最近状态的一致性（降低阈值，提高敏感度）
    int flipCount = _recentFlipStates.where((state) => state).length;
    bool stableFlipped = flipCount >= (_stabilityCheckCount * 0.6); // 60%一致性
    bool stableNormal = flipCount <= (_stabilityCheckCount * 0.4); // 40%一致性
    
    debugPrint('🔍 稳定性检查: 翻转次数=$flipCount/总数=$_stabilityCheckCount, 稳定翻转=$stableFlipped, 稳定正常=$stableNormal');
    
    bool newFlipState;
    if (stableFlipped) {
      newFlipState = true;
    } else if (stableNormal) {
      newFlipState = false;
    } else {
      return; // 状态不稳定，继续等待
    }
    
    // 状态发生变化时触发回调
    if (newFlipState != _isFlipped) {
      _isFlipped = newFlipState;
      debugPrint('📱 手机翻转状态变化: ${_isFlipped ? "翻转" : "正常"}');
      onFlipStateChanged?.call(_isFlipped);
    }
  }

  /// 设置翻转状态变化回调
  void setFlipStateCallback(Function(bool isFlipped) callback) {
    onFlipStateChanged = callback;
  }

  /// 清除回调
  void clearCallback() {
    onFlipStateChanged = null;
  }

  /// 释放资源
  void dispose() {
    stopListening();
    clearCallback();
  }
}
