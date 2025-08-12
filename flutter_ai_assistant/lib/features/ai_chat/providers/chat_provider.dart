import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/services/personalization_service.dart';

/// AI聊天功能提供者
class ChatProvider extends ChangeNotifier {
  // 后端API基础URL - 使用Mac的LAN IP
  static const String _baseUrl = 'http://172.20.10.6:5001';
  
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;

  /// 发送消息
  void sendMessage(String message) {
    // 添加用户消息
    _messages.add({
      'content': message,
      'isUser': true,
      'timestamp': DateTime.now(),
    });
    notifyListeners();

    // 模拟AI回复
    _simulateAIResponse(message);
  }

  /// 调用真实AI API获取回复
  void _simulateAIResponse(String userMessage) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 调用后端AI聊天API
      String aiResponse = await _callAIAPI(userMessage);
      
      _messages.add({
        'content': aiResponse,
        'isUser': false,
        'timestamp': DateTime.now(),
      });
    } catch (e) {
      // 如果API调用失败，使用本地回复
      print('AI API调用失败: $e');
      String fallbackResponse = await _generateLocalResponse(userMessage);
      
      _messages.add({
        'content': fallbackResponse,
        'isUser': false,
        'timestamp': DateTime.now(),
      });
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 调用后端AI API
  Future<String> _callAIAPI(String userMessage) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/ai-simple/chat'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'message': userMessage,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['response'] ?? '抱歉，我现在无法回复。';
        } else {
          throw Exception(data['error'] ?? 'API调用失败');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('AI API调用异常: $e');
      rethrow;
    }
  }

  /// 生成本地备用回复
  Future<String> _generateLocalResponse(String userMessage) async {
    final message = userMessage.toLowerCase();
    final personalizationService = PersonalizationService.instance;
    final aiName = await personalizationService.getAiAssistantName();
    final userNickname = await personalizationService.getUserNickname();
    
    // 生成个性化回复前缀
    String responsePrefix = '';
    if (userNickname != null && userNickname.isNotEmpty) {
      responsePrefix = '$userNickname，';
    }
    
    if (message.contains('你好') || message.contains('hi') || message.contains('hello')) {
      return '$responsePrefix你好！我是$aiName，很高兴为你服务！有什么可以帮助你的吗？';
    } else if (message.contains('拖延') || message.contains('专注')) {
      return '$responsePrefix我理解你的困扰。建议你试试番茄钟技术：专注25分钟，然后休息5分钟。这样可以有效提升专注力，克服拖延症！';
    } else if (message.contains('任务') || message.contains('待办')) {
      return '$responsePrefix管理任务很重要！建议你：\n1. 把大任务分解成小任务\n2. 设定优先级\n3. 使用番茄钟专注完成\n4. 及时记录完成情况';
    } else if (message.contains('时间') || message.contains('效率')) {
      return '$responsePrefix时间管理的关键是：\n• 制定明确的目标\n• 避免多任务处理\n• 定期休息保持精力\n• 使用工具辅助管理\n\n试试我们的番茄钟功能吧！';
    } else if (message.contains('谢谢') || message.contains('感谢')) {
      return '$responsePrefix不客气！能帮助到你我很开心。记住，克服拖延症需要坚持，你一定可以做到的！💪';
    } else {
      return '$responsePrefix我明白了！作为你的专注助手，我建议你可以：\n\n1. 🍅 使用番茄钟专注工作\n2. 📝 记录待办事项\n3. 🎯 设定明确目标\n4. ⏰ 合理安排休息\n\n有什么具体问题可以继续问我哦！';
    }
  }

  /// 清空聊天记录
  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }
}
