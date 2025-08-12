import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ai_task.dart';
import '../core/config.dart';
import 'auth_service.dart';
import 'ai_connection_manager.dart';

class AIService {
  static const String _baseUrl = AppConfig.baseUrl;
  final AuthService _authService = AuthService();

  // 测试AI连接
  Future<Map<String, dynamic>> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/ai-simple/test'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('AI服务连接失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('AI服务连接错误: $e');
    }
  }

  // AI任务拆分 - 使用简单接口（无需JWT）
  Future<AITaskBreakdown> breakdownTaskSimple(String task) async {
    try {
      final request = AITaskRequest(task: task);
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/ai-simple/breakdown'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          return AITaskBreakdown.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['error'] ?? 'AI任务拆分失败');
        }
      } else {
        throw Exception('AI任务拆分请求失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('AI任务拆分错误: $e');
    }
  }

  // AI任务拆分 - 使用JWT认证接口
  Future<AITaskBreakdown> breakdownTask(String task) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        throw Exception('用户未登录');
      }

      final request = AITaskRequest(task: task);
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/ai/breakdown'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          return AITaskBreakdown.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['error'] ?? 'AI任务拆分失败');
        }
      } else if (response.statusCode == 401) {
        // Token过期，尝试刷新
        await _authService.logout();
        throw Exception('登录已过期，请重新登录');
      } else {
        throw Exception('AI任务拆分请求失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('AI任务拆分错误: $e');
    }
  }

  // 添加选中的子任务到待办列表
  Future<bool> addSubTasksToTodo(List<SubTask> selectedTasks) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        throw Exception('用户未登录');
      }

      // 批量添加任务
      for (final task in selectedTasks) {
        final response = await http.post(
          Uri.parse('$_baseUrl/api/tasks'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode(task.toTodoTask()),
        );

        if (response.statusCode != 201) {
          throw Exception('添加任务失败: ${task.title}');
        }
      }

      return true;
    } catch (e) {
      throw Exception('添加任务到待办列表失败: $e');
    }
  }

  // 获取AI服务状态（使用连接管理器）
  Future<Map<String, dynamic>> getAIStatus({bool forceRefresh = false}) async {
    return await AIConnectionManager.instance.getConnectionStatus(forceRefresh: forceRefresh);
  }
}
