import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/chat_provider.dart';
import '../../daily_quote/providers/quote_provider.dart';
import '../../../core/services/personalization_service.dart';
import '../../../core/utils/keyboard_utils.dart';
import '../../../widgets/instant_keyboard_text_field.dart';

/// AI助手聊天页面
class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _aiAssistantName = '小AI';

  @override
  void initState() {
    super.initState();
    _loadAiAssistantName();
  }

  /// 加载AI助手名字
  void _loadAiAssistantName() async {
    final personalizationService = PersonalizationService.instance;
    final aiName = await personalizationService.getAiAssistantName();
    if (mounted) {
      setState(() {
        _aiAssistantName = aiName;
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final chatProvider = context.read<ChatProvider>();
    chatProvider.sendMessage(message);
    _messageController.clear();

    // 滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () {
        // 点击空白区域收起键盘
        print('💆 点击空白区域，收起键盘');
        FocusScope.of(context).unfocus();
        KeyboardUtils.hideKeyboard(context);
      },
      behavior: HitTestBehavior.opaque, // 确保能捕获到点击事件
      child: Scaffold(
      appBar: AppBar(
        title: Text(_aiAssistantName),
        elevation: 0,
      ),
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // 每日鼓励语录
          Consumer<QuoteProvider>(
            builder: (context, quoteProvider, child) {
              return GestureDetector(
                onTap: () {
                  // 点击鼓励区域收起键盘
                  print('✨ 点击鼓励区域，收起键盘');
                  FocusScope.of(context).unfocus();
                  KeyboardUtils.hideKeyboard(context);
                },
                child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '今日鼓励',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          quoteProvider.currentDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      quoteProvider.currentQuote,
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.colorScheme.onSurface,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          // 聊天消息列表
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                return GestureDetector(
                  onTap: () {
                    // 点击聊天区域收起键盘
                    print('🎯 点击聊天区域，收起键盘');
                    FocusScope.of(context).unfocus();
                    KeyboardUtils.hideKeyboard(context);
                  },
                  behavior: HitTestBehavior.translucent,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: chatProvider.messages.length,
                    itemBuilder: (context, index) {
                    final message = chatProvider.messages[index];
                    final isUser = message['isUser'] as bool;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisAlignment: isUser 
                          ? MainAxisAlignment.end 
                          : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isUser) ...[
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: theme.colorScheme.primary,
                              child: const Icon(
                                Icons.smart_toy,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isUser 
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: isUser 
                                  ? null 
                                  : Border.all(
                                      color: theme.colorScheme.outline.withOpacity(0.2),
                                    ),
                              ),
                              child: Text(
                                message['content'] as String,
                                style: TextStyle(
                                  color: isUser 
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurface,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ),
                          if (isUser) ...[
                            const SizedBox(width: 8),
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: theme.colorScheme.secondary,
                              child: const Icon(
                                Icons.person,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                    },
                  ),
                );
              },
            ),
          ),
          
          // 输入框
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InstantKeyboardTextField(
                      controller: _messageController,
                      hintText: '输入消息...',
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.send,
                      maxLines: 1,
                      suffixIcon: IconButton(
                        onPressed: () {
                          // 点击完成按钮收起键盘
                          KeyboardUtils.hideKeyboard(context);
                        },
                        icon: const Icon(Icons.keyboard_hide),
                        tooltip: '收起键盘',
                      ),
                      onSubmitted: (_) {
                        // 发送消息
                        _sendMessage();
                        // 收起键盘
                        KeyboardUtils.hideKeyboard(context);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Consumer<ChatProvider>(
                  builder: (context, chatProvider, child) {
                    return IconButton(
                      onPressed: chatProvider.isLoading ? null : _sendMessage,
                      icon: chatProvider.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
