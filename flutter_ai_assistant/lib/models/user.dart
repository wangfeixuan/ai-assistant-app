/// 登录类型枚举
enum LoginType {
  email('email', '邮箱登录'),
  phone('phone', '手机号登录');

  const LoginType(this.value, this.displayName);
  final String value;
  final String displayName;
}

/// 用户数据模型
class User {
  final String id;
  final String? email; // 邮箱，可能为空（手机号登录用户）
  final String? phone; // 手机号，可能为空（邮箱登录用户）
  final String username;
  final String? avatar;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isPremium;
  final String? displayName; // 用户自定义昵称
  final String? aiAssistantName; // AI助手名字
  final LoginType loginType; // 登录类型

  const User({
    required this.id,
    this.email,
    this.phone,
    required this.username,
    this.avatar,
    required this.createdAt,
    this.lastLoginAt,
    this.isPremium = false,
    this.displayName,
    this.aiAssistantName,
    required this.loginType,
  }) : assert(email != null || phone != null, '邮箱和手机号至少需要一个');

  /// 获取登录账号（邮箱或手机号）
  String get loginAccount {
    switch (loginType) {
      case LoginType.email:
        return email ?? '';
      case LoginType.phone:
        return phone ?? '';
    }
  }

  /// 从JSON创建User对象
  factory User.fromJson(Map<String, dynamic> json) {
    // 确定登录类型
    final loginTypeStr = json['login_type'] as String? ?? 'phone';
    final loginType = LoginType.values.firstWhere(
      (type) => type.value == loginTypeStr,
      orElse: () => LoginType.phone,
    );

    // 处理email和phone字段，确保至少有一个不为null
    String? email = json['email'] as String?;
    String? phone = json['phone'] as String?;
    final username = json['username'] as String;
    
    // 调试日志
    print('🔍 User.fromJson调试: username=$username, email=$email, phone=$phone');
    
    // 如果服务器返回的email和phone都为null，从username推断
    if (email == null && phone == null) {
      if (username.contains('@')) {
        email = username;
        print('📧 从username推断email: $email');
      } else {
        phone = username;
        print('📱 从username推断phone: $phone');
      }
    }
    
    // 最终验证
    print('✅ 最终结果: email=$email, phone=$phone');
    if (email == null && phone == null) {
      print('❌ 警告: email和phone都为null，将使用username作为phone');
      phone = username; // 强制设置phone以满足断言
    }

    return User(
      id: json['id'].toString(), // 处理整数ID
      email: email,
      phone: phone,
      username: json['username'] as String,
      avatar: json['avatar'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastLoginAt: json['last_login_at'] != null 
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
      isPremium: json['is_premium'] as bool? ?? false,
      displayName: json['display_name'] as String?,
      aiAssistantName: json['ai_assistant_name'] as String?,
      loginType: loginType,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'username': username,
      'avatar': avatar,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'is_premium': isPremium,
      'display_name': displayName,
      'ai_assistant_name': aiAssistantName,
      'login_type': loginType.value,
    };
  }

  /// 创建副本
  User copyWith({
    String? id,
    String? email,
    String? phone,
    String? username,
    String? avatar,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isPremium,
    String? displayName,
    String? aiAssistantName,
    LoginType? loginType,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      username: username ?? this.username,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isPremium: isPremium ?? this.isPremium,
      displayName: displayName ?? this.displayName,
      aiAssistantName: aiAssistantName ?? this.aiAssistantName,
      loginType: loginType ?? this.loginType,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'User(id: $id, email: $email, username: $username, isPremium: $isPremium)';
  }
}

/// 认证响应数据模型
class AuthResponse {
  final User user;
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  const AuthResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresAt: json['expires_at'] != null 
          ? DateTime.parse(json['expires_at'] as String)
          : DateTime.now().add(const Duration(hours: 24)), // 默认24小时过期
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_at': expiresAt.toIso8601String(),
    };
  }
}

/// 登录请求数据模型
class LoginRequest {
  final String account; // 登录账号（邮箱或手机号）
  final String password;
  final LoginType loginType; // 登录类型

  const LoginRequest({
    required this.account,
    required this.password,
    required this.loginType,
  });

  Map<String, dynamic> toJson() {
    // 后端API期望的字段格式：{"login": "用户名或邮箱", "password": "密码"}
    return {
      'login': account, // 后端期望的字段名是login，不是username或email
      'password': password,
    };
  }

  /// 验证邮箱格式
  bool get isEmailValid {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(account);
  }

  /// 验证手机号格式（中国大陆）
  bool get isPhoneValid {
    return RegExp(r'^1[3-9]\d{9}$').hasMatch(account);
  }

  /// 验证账号是否与登录类型匹配
  bool get isAccountValid {
    switch (loginType) {
      case LoginType.email:
        return isEmailValid;
      case LoginType.phone:
        return isPhoneValid;
    }
  }
}

/// 注册请求数据模型
class RegisterRequest {
  final String account; // 注册账号（邮箱或手机号）
  final String username;
  final String password;
  final String confirmPassword;
  final LoginType loginType; // 登录类型

  const RegisterRequest({
    required this.account,
    required this.username,
    required this.password,
    required this.confirmPassword,
    required this.loginType,
  });

  Map<String, dynamic> toJson() {
    // 根据后端错误信息"用户名、邮箱和密码为必填项"，提供所有必需字段
    final Map<String, dynamic> data = {
      'username': username,
      'password': password,
      'confirm_password': confirmPassword,
    };

    // 根据登录类型设置邮箱或手机号
    if (loginType == LoginType.email) {
      data['email'] = account;
    } else {
      // 手机号注册时，使用手机号作为邮箱字段或提供默认邮箱
      data['email'] = account.contains('@') ? account : '$account@phone.local';
      data['phone'] = account;
    }

    return data;
  }

  /// 验证密码是否匹配
  bool get isPasswordMatch => password == confirmPassword;

  /// 验证邮箱格式
  bool get isEmailValid {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(account);
  }

  /// 验证手机号格式（中国大陆）
  bool get isPhoneValid {
    return RegExp(r'^1[3-9]\d{9}$').hasMatch(account);
  }

  /// 验证账号是否与登录类型匹配
  bool get isAccountValid {
    switch (loginType) {
      case LoginType.email:
        return isEmailValid;
      case LoginType.phone:
        return isPhoneValid;
    }
  }

  /// 验证密码强度（至少8位，包含字母和数字）
  bool get isPasswordStrong {
    return password.length >= 8 && 
           RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(password);
  }

  /// 验证昵称（只需要非空）
  bool get isUsernameValid {
    return username.trim().isNotEmpty;
  }

  /// 验证所有字段
  bool get isValid {
    return isAccountValid && 
           isUsernameValid && 
           isPasswordStrong && 
           isPasswordMatch;
  }
}
