import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pomodoro_provider.dart';
import '../models/pomodoro_mode.dart';

/// 番茄钟沉浸模式页面
/// 提供简洁美观的专注界面，只显示计时器和返回按钮
class PomodoroImmersiveScreen extends StatefulWidget {
  const PomodoroImmersiveScreen({Key? key}) : super(key: key);

  @override
  State<PomodoroImmersiveScreen> createState() => _PomodoroImmersiveScreenState();
}

class _PomodoroImmersiveScreenState extends State<PomodoroImmersiveScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // 创建脉冲动画
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // 开始脉冲动画
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PomodoroProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: _getBackgroundColor(provider.currentMode),
          body: SafeArea(
            child: Stack(
              children: [
                // 背景装饰
                _buildBackgroundDecoration(),
                
                // 主要内容
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 模式标题
                      _buildModeTitle(provider.currentMode),
                      
                      const SizedBox(height: 60),
                      
                      // 计时器圆环
                      _buildTimerCircle(provider),
                      
                      const SizedBox(height: 60),
                      
                      // 状态信息
                      _buildStatusInfo(provider),
                    ],
                  ),
                ),
                
                // 返回按钮
                Positioned(
                  top: 16,
                  left: 16,
                  child: _buildBackButton(),
                ),
                
                // 翻转状态指示器（如果启用）
                if (provider.flipModeEnabled)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: _buildFlipStatusIndicator(provider),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 获取背景颜色
  Color _getBackgroundColor(PomodoroMode mode) {
    switch (mode) {
      case PomodoroMode.pomodoro:
        return const Color(0xFF1A1A2E); // 深蓝色
      case PomodoroMode.shortBreak:
        return const Color(0xFF16213E); // 深青色
      case PomodoroMode.longBreak:
        return const Color(0xFF0F3460); // 深紫蓝色
    }
  }

  /// 构建背景装饰
  Widget _buildBackgroundDecoration() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            _getBackgroundColor(context.read<PomodoroProvider>().currentMode).withOpacity(0.8),
            _getBackgroundColor(context.read<PomodoroProvider>().currentMode),
          ],
        ),
      ),
      child: CustomPaint(
        painter: _BackgroundPatternPainter(),
        size: Size.infinite,
      ),
    );
  }

  /// 构建模式标题
  Widget _buildModeTitle(PomodoroMode mode) {
    String title;
    IconData icon;
    Color color;
    
    switch (mode) {
      case PomodoroMode.pomodoro:
        title = '专注时间';
        icon = Icons.psychology;
        color = Colors.white;
        break;
      case PomodoroMode.shortBreak:
        title = '短休息';
        icon = Icons.coffee;
        color = Colors.white70;
        break;
      case PomodoroMode.longBreak:
        title = '长休息';
        icon = Icons.spa;
        color = Colors.white70;
        break;
    }
    
    return Column(
      children: [
        Icon(
          icon,
          size: 48,
          color: color,
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w300,
            color: color,
            letterSpacing: 2.0,
          ),
        ),
      ],
    );
  }

  /// 构建计时器圆环
  Widget _buildTimerCircle(PomodoroProvider provider) {
    final progress = provider.progress;
    final timeLeft = provider.timeLeft;
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: provider.isRunning ? _pulseAnimation.value : 1.0,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 背景圆环
                SizedBox(
                  width: 280,
                  height: 280,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 8,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                
                // 进度圆环
                SizedBox(
                  width: 280,
                  height: 280,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withOpacity(0.8),
                    ),
                  ),
                ),
                
                // 时间显示
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatTime(timeLeft),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w200,
                        color: Colors.white,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建状态信息
  Widget _buildStatusInfo(PomodoroProvider provider) {
    return Column(
      children: [
        // 运行状态
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: provider.isRunning ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                provider.isRunning ? '专注中' : '已暂停',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // 今日统计
        Text(
          '今日已完成 ${provider.getTodayCompletedCount()} 个番茄钟',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w300,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  /// 构建返回按钮
  Widget _buildBackButton() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.1),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: Colors.white,
          size: 20,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  /// 构建翻转状态指示器
  Widget _buildFlipStatusIndicator(PomodoroProvider provider) {
    final isFlipped = provider.isFlipModeActive;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFlipped ? Icons.screen_rotation : Icons.stay_current_portrait,
            size: 16,
            color: Colors.white.withOpacity(0.8),
          ),
          const SizedBox(width: 6),
          Text(
            isFlipped ? '翻转中' : '正常',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  /// 格式化时间显示
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

/// 背景图案绘制器
class _BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // 绘制几何图案
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // 绘制同心圆
    for (int i = 1; i <= 5; i++) {
      canvas.drawCircle(
        Offset(centerX, centerY),
        i * 60.0,
        paint,
      );
    }
    
    // 绘制放射线
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * (3.14159 / 180);
      final startX = centerX + 100 * cos(angle);
      final startY = centerY + 100 * sin(angle);
      final endX = centerX + 300 * cos(angle);
      final endY = centerY + 300 * sin(angle);
      
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
