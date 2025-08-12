import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

/// 认证状态枚举
enum AuthStatus {
  initial,      // 初始状态
  loading,      // 加载中
  authenticated, // 已认证
  unauthenticated, // 未认证
}

/// 认证状态管理Provider
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  
  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;

  AuthProvider({AuthService? authService}) 
      : _authService = authService ?? AuthService();

  // Getters
  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  /// 初始化认证状态
  Future<void> initializeAuth() async {
    _setStatus(AuthStatus.loading);
    
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        _user = await _authService.getStoredUser();
        _setStatus(AuthStatus.authenticated);
      } else {
        _setStatus(AuthStatus.unauthenticated);
      }
    } catch (e) {
      // 初始化失败时不显示错误信息，直接设置为未认证状态
      // 这样用户可以正常使用应用，只是无法进行网络认证
      debugPrint('Auth initialization failed: $e');
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  /// 用户登录
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setStatus(AuthStatus.loading);
    _clearError();

    try {
      final request = LoginRequest(
        account: email, 
        password: password, 
        loginType: LoginType.email,
      );
      final authResponse = await _authService.login(request);
      
      _user = authResponse.user;
      _setStatus(AuthStatus.authenticated);
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      _setStatus(AuthStatus.unauthenticated);
      return false;
    } catch (e) {
      // 网络连接失败时提供更友好的错误信息
      if (e.toString().contains('网络连接失败')) {
        _setError('无法连接到服务器，请检查网络连接或稍后重试');
      } else {
        _setError('登录失败，请稍后重试');
      }
      _setStatus(AuthStatus.unauthenticated);
      return false;
    }
  }

  /// 用户注册
  Future<bool> register({
    required String email,
    required String username,
    required String password,
    required String confirmPassword,
  }) async {
    _setStatus(AuthStatus.loading);
    _clearError();

    try {
      final request = RegisterRequest(
        account: email,
        username: username,
        password: password,
        confirmPassword: confirmPassword,
        loginType: LoginType.email,
      );

      // 验证请求数据
      if (!request.isValid) {
        if (!request.isAccountValid) {
          _setError('请输入有效的邮箱地址或手机号');
        } else if (!request.isUsernameValid) {
          _setError('请输入昵称');
        } else if (!request.isPasswordStrong) {
          _setError('密码至少8位，需包含字母和数字');
        } else if (!request.isPasswordMatch) {
          _setError('两次输入的密码不一致');
        }
        _setStatus(AuthStatus.unauthenticated);
        return false;
      }

      final authResponse = await _authService.register(request);
      
      _user = authResponse.user;
      _setStatus(AuthStatus.authenticated);
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      _setStatus(AuthStatus.unauthenticated);
      return false;
    } catch (e) {
      // 网络连接失败时提供更友好的错误信息
      if (e.toString().contains('网络连接失败')) {
        _setError('无法连接到服务器，请检查网络连接或稍后重试');
      } else {
        _setError('注册失败，请稍后重试');
      }
      _setStatus(AuthStatus.unauthenticated);
      return false;
    }
  }

  /// 用户登录（新版本，支持登录类型）
  Future<bool> loginWithType(LoginRequest request) async {
    _setStatus(AuthStatus.loading);
    _clearError();

    try {
      final authResponse = await _authService.login(request);
      
      _user = authResponse.user;
      _setStatus(AuthStatus.authenticated);
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      _setStatus(AuthStatus.unauthenticated);
      return false;
    } catch (e) {
      // 网络连接失败时提供更友好的错误信息
      if (e.toString().contains('网络连接失败')) {
        _setError('无法连接到服务器，请检查网络连接或稍后重试');
      } else {
        _setError('登录失败，请稍后重试');
      }
      _setStatus(AuthStatus.unauthenticated);
      return false;
    }
  }

  /// 用户注册（新版本，支持登录类型）
  Future<bool> registerWithType(RegisterRequest request) async {
    _setStatus(AuthStatus.loading);
    _clearError();

    try {
      // 验证请求数据
      if (!request.isValid) {
        if (!request.isAccountValid) {
          _setError('请输入有效的${request.loginType.displayName.replaceAll('登录', '')}');
        } else if (!request.isUsernameValid) {
          _setError('请输入昵称');
        } else if (!request.isPasswordStrong) {
          _setError('密码至少8位，需包含字母和数字');
        } else if (!request.isPasswordMatch) {
          _setError('两次输入的密码不一致');
        }
        _setStatus(AuthStatus.unauthenticated);
        return false;
      }

      final authResponse = await _authService.register(request);
      
      _user = authResponse.user;
      _setStatus(AuthStatus.authenticated);
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      _setStatus(AuthStatus.unauthenticated);
      return false;
    } catch (e) {
      // 网络连接失败时提供更友好的错误信息
      if (e.toString().contains('网络连接失败')) {
        _setError('无法连接到服务器，请检查网络连接或稍后重试');
      } else {
        _setError('注册失败，请稍后重试');
      }
      _setStatus(AuthStatus.unauthenticated);
      return false;
    }
  }

  /// 用户登出
  Future<void> logout() async {
    _setStatus(AuthStatus.loading);
    
    try {
      await _authService.logout();
    } catch (e) {
      // 即使登出失败，也要清除本地状态
      debugPrint('Logout error: $e');
    } finally {
      _user = null;
      _clearError();
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  /// 刷新用户资料
  Future<void> refreshProfile() async {
    if (!isAuthenticated) return;

    try {
      _user = await _authService.getProfile();
      notifyListeners();
    } on AuthException catch (e) {
      if (e.message.contains('未登录') || e.message.contains('过期')) {
        // 认证失效，登出用户
        await logout();
      } else {
        _setError(e.message);
      }
    } catch (e) {
      _setError('获取用户资料失败: ${e.toString()}');
    }
  }

  /// 更新用户资料
  Future<bool> updateProfile({
    String? username,
    String? displayName,
    String? avatar,
  }) async {
    if (!isAuthenticated) return false;

    _setStatus(AuthStatus.loading);
    _clearError();

    try {
      final updates = <String, dynamic>{};
      if (username != null) updates['username'] = username;
      if (displayName != null) updates['display_name'] = displayName;
      if (avatar != null) updates['avatar'] = avatar;

      if (updates.isEmpty) {
        _setStatus(AuthStatus.authenticated);
        return true;
      }

      _user = await _authService.updateProfile(updates);
      _setStatus(AuthStatus.authenticated);
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      _setStatus(AuthStatus.authenticated);
      return false;
    } catch (e) {
      _setError('更新资料失败: ${e.toString()}');
      _setStatus(AuthStatus.authenticated);
      return false;
    }
  }

  /// 修改密码
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (!isAuthenticated) return false;

    _setStatus(AuthStatus.loading);
    _clearError();

    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _setStatus(AuthStatus.authenticated);
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      _setStatus(AuthStatus.authenticated);
      return false;
    } catch (e) {
      _setError('修改密码失败: ${e.toString()}');
      _setStatus(AuthStatus.authenticated);
      return false;
    }
  }

  /// 清除错误信息
  void clearError() {
    _clearError();
  }

  /// 设置认证状态
  void _setStatus(AuthStatus status) {
    _status = status;
    // 使用 WidgetsBinding.instance.addPostFrameCallback 确保在构建完成后再通知监听器
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// 设置错误信息
  void _setError(String message) {
    _errorMessage = message;
    // 使用 WidgetsBinding.instance.addPostFrameCallback 确保在构建完成后再通知监听器
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// 清除错误信息
  void _clearError() {
    _errorMessage = null;
    // 使用 WidgetsBinding.instance.addPostFrameCallback 确保在构建完成后再通知监听器
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _authService.dispose();
    super.dispose();
  }
}
