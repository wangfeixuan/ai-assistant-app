import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/procrastination_diary.dart';

class ProcrastinationService {
  static const String baseUrl = 'http://172.20.10.6:5001/api/procrastination';
  static const Duration timeoutDuration = Duration(seconds: 5);

  /// 获取认证头部
  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };
  }

  /// 获取所有可用的拖延借口选项
  Future<List<ReasonOption>> getReasons() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/reasons'),
        headers: headers,
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> reasonsData = data['data'];
          return reasonsData.map((item) => ReasonOption.fromJson(item)).toList();
        }
      }
      throw Exception('获取拖延借口失败');
    } catch (e) {
      throw Exception('网络错误: $e');
    }
  }

  /// 记录拖延原因，返回记录和AI分析
  Future<Map<String, dynamic>> recordProcrastination({
    required String taskTitle,
    required String reasonType,
    int? taskId,
    String? customReason,
    int? moodBefore,
    int? moodAfter,
    String? procrastinationDate,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = {
        'task_title': taskTitle,
        'reason_type': reasonType,
        if (taskId != null) 'task_id': taskId,
        if (customReason != null) 'custom_reason': customReason,
        if (moodBefore != null) 'mood_before': moodBefore,
        if (moodAfter != null) 'mood_after': moodAfter,
        if (procrastinationDate != null) 'procrastination_date': procrastinationDate,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/record'),
        headers: headers,
        body: json.encode(body),
      ).timeout(timeoutDuration);

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'diary': ProcrastinationDiary.fromJson(data['data']['diary']),
            'analysis': SingleProcrastinationAnalysis.fromJson(data['data']['analysis']),
          };
        }
      }
      
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? '记录拖延失败');
    } catch (e) {
      throw Exception('网络错误: $e');
    }
  }

  /// 获取拖延日记列表
  Future<List<ProcrastinationDiary>> getDiary({
    int page = 1,
    int perPage = 10,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = {
        'page': page.toString(),
        'per_page': perPage.toString(),
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
      };

      final uri = Uri.parse('$baseUrl/diary').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> entriesData = data['data']['entries'];
          return entriesData.map((item) => ProcrastinationDiary.fromJson(item)).toList();
        }
      }
      throw Exception('获取拖延日记失败');
    } catch (e) {
      throw Exception('网络错误: $e');
    }
  }

  /// 添加拖延日记
  Future<void> addDiary({
    required String trigger,
    required String emotion,
    required String situation,
    required String thought,
    required String behavior,
    required String consequence,
    required String improvement,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = json.encode({
        'trigger': trigger,
        'emotion': emotion,
        'situation': situation,
        'thought': thought,
        'behavior': behavior,
        'consequence': consequence,
        'improvement': improvement,
      });
      
      final response = await http.post(
        Uri.parse('$baseUrl/diary'),
        headers: headers,
        body: body,
      ).timeout(timeoutDuration);

      if (response.statusCode != 201) {
        throw Exception('添加拖延日记失败');
      }
    } catch (e) {
      throw Exception('网络错误: $e');
    }
  }

  /// 获取拖延统计数据
  Future<ProcrastinationStatsResponse> getStats() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/stats'),
        headers: headers,
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return ProcrastinationStatsResponse.fromJson(data['data']);
        }
      }
      throw Exception('获取统计数据失败');
    } catch (e) {
      throw Exception('网络错误: $e');
    }
  }

  /// 获取AI智能分析
  Future<ProcrastinationAnalysis> getAIAnalysis() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/ai-analysis'),
        headers: headers,
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return ProcrastinationAnalysis.fromJson(data['data']);
        }
      }
      throw Exception('获取AI分析失败');
    } catch (e) {
      throw Exception('网络错误: $e');
    }
  }

  /// 检查超时任务
  Future<Map<String, dynamic>> checkOverdueTasks() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/check-overdue-tasks'),
        headers: headers,
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
      throw Exception('检查超时任务失败');
    } catch (e) {
      throw Exception('网络错误: $e');
    }
  }
}
