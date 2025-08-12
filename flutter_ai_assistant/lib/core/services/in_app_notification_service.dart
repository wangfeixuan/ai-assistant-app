import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'personalization_service.dart';

/// 应用内通知服务
/// 当应用在前台时显示自定义弹窗和震动提醒
class InAppNotificationService {
  static final InAppNotificationService _instance = InAppNotificationService._internal();
  factory InAppNotificationService() => _instance;
  InAppNotificationService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  OverlayEntry? _currentOverlay;

  /// 格式化个性化通知内容
  /// 格式："昵称，通知内容"
  Future<String> _formatPersonalizedContent(String content) async {
    try {
      final nickname = await PersonalizationService.instance.getUserNickname();
      if (nickname != null && nickname.isNotEmpty) {
        return '$nickname，$content';
      }
      return content;
    } catch (e) {
      return content;
    }
  }

  /// 显示应用内通知弹窗
  Future<void> showInAppNotification({
    required BuildContext context,
    required String title,
    required String message,
    String? emoji,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 4),
    bool enableVibration = true,
    bool enableSound = true,
    VoidCallback? onTap,
  }) async {
    print('🔔 开始显示应用内通知: $title - $message');
    
    // 移除之前的通知
    _removeCurrentOverlay();

    // 震动反馈
    if (enableVibration) {
      await HapticFeedback.mediumImpact();
    }

    // 播放提示音
    if (enableSound) {
      await _playNotificationSound();
    }

    print('🔧 开始创建覆盖层通知');
    
    try {
      // 检查Overlay是否可用
      final overlay = Overlay.of(context);
      if (overlay == null) {
        print('❌ Overlay不可用，无法显示应用内通知');
        return;
      }
      print('✅ Overlay检查通过');
      
      // 创建覆盖层通知
      _currentOverlay = _createNotificationOverlay(
        context: context,
        title: title,
        message: message,
        emoji: emoji,
        backgroundColor: backgroundColor,
        onTap: onTap,
      );
      print('✅ 覆盖层创建成功');

      print('📱 插入覆盖层通知到Overlay');
      // 显示通知
      overlay.insert(_currentOverlay!);
      print('✅ 应用内通知已显示');
    } catch (e, stackTrace) {
      print('❌ 应用内通知显示失败: $e');
      print('📋 错误堆栈: $stackTrace');
      return;
    }

    // 自动隐藏
    Future.delayed(duration, () {
      print('⏰ 自动隐藏应用内通知');
      _removeCurrentOverlay();
    });
  }

  /// 番茄钟完成应用内通知
  Future<void> showPomodoroInAppNotification({
    required BuildContext context,
    required String type,
    required int sessionCount,
  }) async {
    String title, baseMessage, emoji;
    Color backgroundColor;

    switch (type) {
      case 'work':
        title = '专注时间结束！';
        baseMessage = '恭喜完成第${sessionCount}个番茄钟，该休息一下了～';
        emoji = '🍅';
        backgroundColor = const Color(0xFF4CAF50); // 柔和的绿色
        break;
      case 'shortBreak':
        title = '短休息结束！';
        baseMessage = '休息完毕，准备开始下一个专注时段吧！';
        emoji = '⏰';
        backgroundColor = const Color(0xFF2196F3); // 柔和的蓝色
        break;
      case 'longBreak':
        title = '长休息结束！';
        baseMessage = '充分休息后，让我们继续高效工作吧！';
        emoji = '🎉';
        backgroundColor = const Color(0xFF9C27B0); // 柔和的紫色
        break;
      default:
        title = '番茄钟提醒';
        baseMessage = '时间到了！';
        emoji = '⏰';
        backgroundColor = const Color(0xFF607D8B); // 柔和的灰蓝色
    }

    // 格式化个性化内容
    final message = await _formatPersonalizedContent(baseMessage);

    await showInAppNotification(
      context: context,
      title: title,
      message: message,
      emoji: emoji,
      backgroundColor: Colors.white, // 使用白色背景
      duration: const Duration(seconds: 5),
    );
  }

  /// 任务提醒应用内通知
  Future<void> showTaskInAppNotification({
    required BuildContext context,
    required String taskTitle,
    required DateTime deadline,
  }) async {
    final now = DateTime.now();
    final difference = deadline.difference(now);
    
    String urgencyText, emoji;
    Color backgroundColor;
    
    if (difference.inHours < 1) {
      urgencyText = '即将截止';
      emoji = '⚠️';
      backgroundColor = Colors.red;
    } else if (difference.inHours < 24) {
      urgencyText = '今日截止';
      emoji = '🔔';
      backgroundColor = Colors.orange;
    } else {
      urgencyText = '即将到期';
      emoji = '📅';
      backgroundColor = Colors.blue;
    }

    // 格式化个性化内容
    final baseMessage = '任务「$taskTitle」将在${_formatDeadline(deadline)}截止，记得及时完成哦！';
    final message = await _formatPersonalizedContent(baseMessage);

    await showInAppNotification(
      context: context,
      title: urgencyText,
      message: message,
      emoji: emoji,
      backgroundColor: backgroundColor,
      duration: const Duration(seconds: 4),
    );
  }

  /// 学习提醒应用内通知
  Future<void> showStudyReminderInAppNotification({
    required BuildContext context,
  }) async {
    // 格式化个性化内容
    final baseMessage = '今天还没有学习记录哦，快来开始你的学习之旅吧！';
    final message = await _formatPersonalizedContent(baseMessage);

    await showInAppNotification(
      context: context,
      title: '学习打卡提醒',
      message: message,
      emoji: '📚',
      backgroundColor: Colors.indigo,
      duration: const Duration(seconds: 4),
    );
  }

  /// 创建通知覆盖层
  OverlayEntry _createNotificationOverlay({
    required BuildContext context,
    required String title,
    required String message,
    String? emoji,
    Color? backgroundColor,
    VoidCallback? onTap,
  }) {
    return OverlayEntry(
      builder: (context) => _InAppNotificationWidget(
        title: title,
        message: message,
        emoji: emoji,
        backgroundColor: backgroundColor ?? Colors.blue,
        onTap: onTap,
        onDismiss: _removeCurrentOverlay,
      ),
    );
  }

  /// 移除当前覆盖层
  void _removeCurrentOverlay() {
    try {
      if (_currentOverlay != null) {
        print('🗑️ 移除当前覆盖层');
        _currentOverlay!.remove();
        _currentOverlay = null;
        print('✅ 覆盖层移除成功');
      }
    } catch (e) {
      print('❌ 移除覆盖层失败: $e');
      _currentOverlay = null; // 强制清空引用
    }
  }

  /// 播放通知声音
  Future<void> _playNotificationSound() async {
    try {
      // 播放系统通知声音
      await HapticFeedback.selectionClick();
      
      // 可以添加自定义音效
      // await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
    } catch (e) {
      // 忽略音频播放错误
    }
  }

  /// 格式化截止时间
  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}天后';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时后';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟后';
    } else {
      return '即将截止';
    }
  }

  /// 清理资源
  void dispose() {
    _removeCurrentOverlay();
    _audioPlayer.dispose();
  }
}

/// 应用内通知弹窗组件
class _InAppNotificationWidget extends StatefulWidget {
  final String title;
  final String message;
  final String? emoji;
  final Color backgroundColor;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const _InAppNotificationWidget({
    required this.title,
    required this.message,
    this.emoji,
    required this.backgroundColor,
    this.onTap,
    this.onDismiss,
  });

  @override
  State<_InAppNotificationWidget> createState() => _InAppNotificationWidgetState();
}

class _InAppNotificationWidgetState extends State<_InAppNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleDismiss() {
    _animationController.reverse().then((_) {
      widget.onDismiss?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            elevation: 0,
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Emoji图标
                      if (widget.emoji != null) ...[
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Center(
                            child: Text(
                              widget.emoji!,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      
                      // 文本内容
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                color: Color(0xFF1A1A1A),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.message,
                              style: const TextStyle(
                                color: Color(0xFF666666),
                                fontSize: 14,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      
                      // 关闭按钮
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: IconButton(
                          onPressed: _handleDismiss,
                          icon: const Icon(
                            Icons.close,
                            color: Color(0xFF999999),
                            size: 18,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
