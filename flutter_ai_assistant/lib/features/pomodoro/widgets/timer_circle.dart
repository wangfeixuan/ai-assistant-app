import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 番茄钟圆形计时器组件 - 对应HTML版本的圆形进度条，增加完成特效
class TimerCircle extends StatefulWidget {
  final double progress; // 0.0 - 1.0
  final String timeText;
  final Color primaryColor;
  final Color backgroundColor;
  final double size;
  final bool showCompletionAnimation;

  const TimerCircle({
    super.key,
    required this.progress,
    required this.timeText,
    required this.primaryColor,
    required this.backgroundColor,
    this.size = 200,
    this.showCompletionAnimation = false,
  });

  @override
  State<TimerCircle> createState() => _TimerCircleState();
}

class _TimerCircleState extends State<TimerCircle>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _completionController;
  late Animation<double> _animation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _completionController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _completionController,
      curve: Curves.elasticOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _completionController,
      curve: Curves.easeInOut,
    ));
    
    _colorAnimation = ColorTween(
      begin: widget.primaryColor,
      end: Colors.green,
    ).animate(CurvedAnimation(
      parent: _completionController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }

  @override
  void didUpdateWidget(TimerCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));
      _animationController.forward(from: 0);
    }
    
    // 处理完成动画
    if (!oldWidget.showCompletionAnimation && widget.showCompletionAnimation) {
      _completionController.forward();
    } else if (oldWidget.showCompletionAnimation && !widget.showCompletionAnimation) {
      _completionController.reset();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _completionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_completionController, _animationController]),
      builder: (context, child) {
        return Transform.scale(
          scale: widget.showCompletionAnimation ? _scaleAnimation.value : 1.0,
          child: Transform.rotate(
            angle: widget.showCompletionAnimation ? _rotationAnimation.value * 0.1 : 0.0,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: widget.showCompletionAnimation
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_colorAnimation.value ?? widget.primaryColor).withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    )
                  : null,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  // 圆形进度条
                  CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: TimerCirclePainter(
                      progress: _animation.value,
                      primaryColor: widget.showCompletionAnimation 
                          ? (_colorAnimation.value ?? widget.primaryColor)
                          : widget.primaryColor,
                      backgroundColor: widget.backgroundColor,
                      showCompletion: widget.showCompletionAnimation,
                    ),
                  ),
                  
                  // 时间显示
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      // 完成图标或时间文本
                      widget.showCompletionAnimation
                        ? Icon(
                            Icons.check_circle,
                            size: widget.size * 0.2,
                            color: Colors.green,
                          )
                        : Text(
                            widget.timeText,
                            style: TextStyle(
                              fontSize: widget.size * 0.16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontFamily: 'monospace',
                            ),
                          ),
                      
                      const SizedBox(height: 4),
                      
                      // 完成文本或进度百分比
                      widget.showCompletionAnimation
                        ? Text(
                            '完成！',
                            style: TextStyle(
                              fontSize: widget.size * 0.08,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : Text(
                            '${(widget.progress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: widget.size * 0.08,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 自定义画笔绘制圆形进度条
class TimerCirclePainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color backgroundColor;
  final bool showCompletion;

  TimerCirclePainter({
    required this.progress,
    required this.primaryColor,
    required this.backgroundColor,
    this.showCompletion = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 20) / 2; // 留出边距
    final strokeWidth = showCompletion ? 12.0 : 8.0; // 完成时加粗

    // 背景圆环
    final backgroundPaint = Paint()
      ..color = backgroundColor.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // 进度圆环
    final progressPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // 绘制进度弧
    const startAngle = -math.pi / 2; // 从顶部开始
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );

    // 添加阴影效果
    if (progress > 0) {
      final shadowPaint = Paint()
        ..color = primaryColor.withOpacity(showCompletion ? 0.5 : 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 2
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, showCompletion ? 8 : 4);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        shadowPaint,
      );
    }
    
    // 完成时的额外装饰
    if (showCompletion && progress >= 1.0) {
      // 绘制闪烁效果
      final sparkles = <Offset>[
        Offset(center.dx + radius * 0.7, center.dy - radius * 0.7),
        Offset(center.dx - radius * 0.7, center.dy - radius * 0.7),
        Offset(center.dx + radius * 0.9, center.dy),
        Offset(center.dx - radius * 0.9, center.dy),
      ];
      
      final sparklePaint = Paint()
        ..color = primaryColor
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      
      for (final sparkle in sparkles) {
        canvas.drawLine(
          Offset(sparkle.dx - 3, sparkle.dy - 3),
          Offset(sparkle.dx + 3, sparkle.dy + 3),
          sparklePaint,
        );
        canvas.drawLine(
          Offset(sparkle.dx + 3, sparkle.dy - 3),
          Offset(sparkle.dx - 3, sparkle.dy + 3),
          sparklePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(TimerCirclePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.showCompletion != showCompletion;
  }
}
