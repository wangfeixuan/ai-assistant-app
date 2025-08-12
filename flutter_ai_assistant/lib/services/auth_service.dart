import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../core/config.dart';

/// 认证服务异常
class AuthException implements Exception {
  final String message;
  final int? statusCode;

  const AuthException(this.message, [this.statusCode]);

  @override
  String toString() => 'AuthException: $message';
}

/// 认证服务
class AuthService {
  static const String _baseUrl = '${AppConfig.baseUrl}/api';
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';

  final http.Client _httpClient;

  AuthService({http.Client? httpClient}) 
      : _httpClient = httpClient ?? _createHttpClient();

  /// 创建配置好的HTTP客户端
  static http.Client _createHttpClient() {
    final client = http.Client();
    return client;
  }

  /// 获取存储的访问令牌
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// 获取存储的刷新令牌
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  /// 获取存储的用户数据
  Future<User?> getStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      try {
        return User.fromJson(jsonDecode(userJson));
      } catch (e) {
        // 如果解析失败，清除存储的数据
        await clearStoredAuth();
        return null;
      }
    }
    return null;
  }

  /// 存储认证数据
  Future<void> _storeAuthData(AuthResponse authResponse) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, authResponse.accessToken);
    await prefs.setString(_refreshTokenKey, authResponse.refreshToken);
    await prefs.setString(_userKey, jsonEncode(authResponse.user.toJson()));
  }

  /// 清除存储的认证数据
  Future<void> clearStoredAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userKey);
  }

  /// 检查是否已登录
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    final user = await getStoredUser();
    return token != null && user != null;
  }

  /// 网络连接测试
  Future<Map<String, dynamic>> testNetworkConnection() async {
    try {
      print('🔍 开始网络连接诊断...');
      print('🎯 目标服务器: $_baseUrl');
      
      final stopwatch = Stopwatch()..start();
      
      // 测试基本连接
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/'),
        headers: {
          'User-Agent': 'Flutter/iOS-NetworkTest',
          'Accept': '*/*',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('连接超时');
        },
      );
      
      stopwatch.stop();
      final responseTime = stopwatch.elapsedMilliseconds;
      
      print('✅ 网络连接成功!');
      print('⏱️ 响应时间: ${responseTime}ms');
      print('📊 状态码: ${response.statusCode}');
      print('🌐 服务器: ${response.headers['server'] ?? 'Unknown'}');
      
      return {
        'success': true,
        'responseTime': responseTime,
        'statusCode': response.statusCode,
        'server': response.headers['server'] ?? 'Unknown',
        'message': '网络连接正常',
      };
    } catch (e) {
      print('❌ 网络连接失败: $e');
      
      String errorMessage = '网络连接失败';
      String errorType = 'unknown';
      
      if (e.toString().contains('Connection refused')) {
        errorMessage = '服务器拒绝连接，请检查服务器是否运行';
        errorType = 'connection_refused';
      } else if (e.toString().contains('timeout') || e.toString().contains('连接超时')) {
        errorMessage = '连接超时，请检查网络连接';
        errorType = 'timeout';
      } else if (e.toString().contains('No address associated with hostname')) {
        errorMessage = '无法解析服务器地址';
        errorType = 'dns_error';
      } else if (e.toString().contains('Network is unreachable')) {
        errorMessage = '网络不可达，请检查WiFi连接';
        errorType = 'network_unreachable';
      } else if (e.toString().contains('Connection interrupted')) {
        errorMessage = '网络连接被中断';
        errorType = 'connection_interrupted';
      }
      
      return {
        'success': false,
        'errorType': errorType,
        'errorMessage': errorMessage,
        'originalError': e.toString(),
      };
    }
  }

  /// 用户登录
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      print('🔗 尝试连接到: $_baseUrl/auth/login');
      print('📤 发送数据: ${jsonEncode(request.toJson())}');
      print('🌐 网络状态检查: 准备发送HTTP请求...');
      
      // 添加网络连接测试
      print('🧪 开始网络连接测试...');
      
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'Flutter/iOS',
          'Connection': 'keep-alive',
        },
        body: jsonEncode(request.toJson()),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⏰ 登录请求超时 - 网络连接可能存在问题');
          throw AuthException('网络请求超时，请检查网络连接或稍后重试', 408);
        },
      );

      print('📥 登录响应状态码: ${response.statusCode}');
      print('📥 登录响应体: ${response.body}');

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
        await _storeAuthData(authResponse);
        return authResponse;
      } else {
        final errorData = jsonDecode(response.body);
        throw AuthException(
          errorData['message'] ?? '登录失败',
          response.statusCode,
        );
      }
    } catch (e) {
      print('❌ 登录请求异常: $e');
      if (e is AuthException) rethrow;
      
      // 更详细的错误信息
      String errorMessage = '网络连接失败，请检查网络设置';
      if (e.toString().contains('Connection refused')) {
        errorMessage = '无法连接到服务器，请检查服务器是否运行';
      } else if (e.toString().contains('timeout')) {
        errorMessage = '请求超时，请检查网络连接';
      } else if (e.toString().contains('No address associated with hostname')) {
        errorMessage = '网络地址解析失败，请检查设备网络';
      } else if (e.toString().contains('Connection interrupted')) {
        errorMessage = '网络连接被中断，请重试';
      } else if (e.toString().contains('Network is unreachable')) {
        errorMessage = '网络不可达，请检查网络连接';
      }
      
      throw AuthException(errorMessage);
    }
  }

  /// 用户注册
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      print('🔗 尝试连接到: $_baseUrl/auth/register');
      print('📤 发送数据: ${jsonEncode(request.toJson())}');
      print('🌐 网络状态检查: 准备发送注册请求...');
      
      // 添加网络连接测试
      print('🧪 开始注册网络连接测试...');
      
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'Flutter/iOS',
          'Connection': 'keep-alive',
        },
        body: jsonEncode(request.toJson()),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⏰ 注册请求超时 - 网络连接可能存在问题');
          throw AuthException('网络请求超时，请检查网络连接或稍后重试', 408);
        },
      );

      print('📥 响应状态码: ${response.statusCode}');
      print('📥 响应体: ${response.body}');

      if (response.statusCode == 201) {
        final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
        await _storeAuthData(authResponse);
        return authResponse;
      } else {
        final errorData = jsonDecode(response.body);
        throw AuthException(
          errorData['message'] ?? '注册失败',
          response.statusCode,
        );
      }
    } catch (e) {
      print('❌ 注册请求异常: $e');
      if (e is AuthException) rethrow;
      
      // 更详细的错误信息
      String errorMessage = '网络连接失败，请检查网络设置';
      if (e.toString().contains('Connection refused')) {
        errorMessage = '无法连接到服务器，请检查服务器是否运行';
      } else if (e.toString().contains('timeout')) {
        errorMessage = '请求超时，请检查网络连接';
      } else if (e.toString().contains('No address associated with hostname')) {
        errorMessage = '网络地址解析失败，请检查设备网络';
      }
      
      throw AuthException(errorMessage);
    }
  }

  /// 刷新访问令牌
  Future<AuthResponse> refreshToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) {
      throw const AuthException('未找到刷新令牌');
    }

    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
        await _storeAuthData(authResponse);
        return authResponse;
      } else {
        // 刷新失败，清除存储的认证数据
        await clearStoredAuth();
        throw const AuthException('登录已过期，请重新登录');
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      await clearStoredAuth();
      throw const AuthException('网络连接失败，请重新登录');
    }
  }

  /// 用户登出
  Future<void> logout() async {
    final token = await getAccessToken();
    
    if (token != null) {
      try {
        await _httpClient.post(
          Uri.parse('$_baseUrl/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      } catch (e) {
        // 即使登出请求失败，也要清除本地数据
      }
    }

    await clearStoredAuth();
  }

  /// 获取用户资料
  Future<User> getProfile() async {
    final token = await getAccessToken();
    if (token == null) {
      throw const AuthException('未登录');
    }

    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/auth/profile'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        // 尝试刷新令牌
        await refreshToken();
        return getProfile(); // 递归调用
      } else {
        throw AuthException('获取用户资料失败', response.statusCode);
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw const AuthException('网络连接失败');
    }
  }

  /// 更新用户资料
  Future<User> updateProfile(Map<String, dynamic> updates) async {
    final token = await getAccessToken();
    if (token == null) {
      throw const AuthException('未登录');
    }

    try {
      final response = await _httpClient.put(
        Uri.parse('$_baseUrl/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updates),
      );

      if (response.statusCode == 200) {
        final user = User.fromJson(jsonDecode(response.body));
        // 更新本地存储的用户数据
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, jsonEncode(user.toJson()));
        return user;
      } else if (response.statusCode == 401) {
        // 尝试刷新令牌
        await refreshToken();
        return updateProfile(updates); // 递归调用
      } else {
        final errorData = jsonDecode(response.body);
        throw AuthException(
          errorData['message'] ?? '更新资料失败',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw const AuthException('网络连接失败');
    }
  }

  /// 修改密码
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await getAccessToken();
    if (token == null) {
      throw const AuthException('未登录');
    }

    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/auth/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        // 尝试刷新令牌
        await refreshToken();
        return changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        ); // 递归调用
      } else {
        final errorData = jsonDecode(response.body);
        throw AuthException(
          errorData['message'] ?? '修改密码失败',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw const AuthException('网络连接失败');
    }
  }

  /// 释放资源
  void dispose() {
    _httpClient.close();
  }
}
