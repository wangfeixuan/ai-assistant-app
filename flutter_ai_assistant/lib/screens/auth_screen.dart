import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/login_type_selector.dart';
import '../models/user.dart';
import '../core/utils/keyboard_utils.dart';

/// 认证页面（登录/注册）
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  // 登录类型
  LoginType _loginType = LoginType.email;
  LoginType _registerType = LoginType.email;

  // 登录表单控制器
  final _loginAccountController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  // 注册表单控制器
  final _registerAccountController = TextEditingController();
  final _registerUsernameController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerConfirmPasswordController = TextEditingController();

  // 密码可见性控制
  bool _loginPasswordVisible = false;
  bool _registerPasswordVisible = false;
  bool _registerConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginAccountController.dispose();
    _loginPasswordController.dispose();
    _registerAccountController.dispose();
    _registerUsernameController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 使用增强的键盘隐藏方法
        KeyboardUtils.hideKeyboard(context);
      },
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Column(
            children: [
            // 固定头部区域
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildTabBar(),
                ],
              ),
            ),
            // 可滚动的表单区域
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Expanded(
                      child: _buildTabBarView(),
                    ),
                    _buildErrorMessage(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  /// 构建页面头部
  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 60, // 减小尺寸
          height: 60, // 减小尺寸
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.psychology,
            size: 32, // 减小图标
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        const SizedBox(height: 12), // 减小间距
        Text(
          '拖延症AI助手',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith( // 使用更小的标题
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        const SizedBox(height: 4), // 减小间距
        Text(
          '让AI帮你拆解任务，告别拖延',
          style: Theme.of(context).textTheme.bodySmall?.copyWith( // 使用更小的文本
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// 构建标签栏
  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 3,
        ),
        insets: const EdgeInsets.symmetric(horizontal: 8), // 减小内边距，让下划线更长
      ),
      labelColor: Theme.of(context).colorScheme.primary,
      unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
      labelStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.normal,
        fontSize: 16,
      ),
      dividerColor: Colors.transparent,
      tabs: const [
        Tab(text: '登录'),
        Tab(text: '注册'),
      ],
    );
  }

  /// 构建标签页内容
  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        SingleChildScrollView(
          child: _buildLoginForm(),
        ),
        SingleChildScrollView(
          child: _buildRegisterForm(),
        ),
      ],
    );
  }

  /// 构建登录表单
  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        children: [
          // 登录方式选择器
          LoginTypeSelector(
            selectedType: _loginType,
            onChanged: (type) {
              setState(() {
                _loginType = type;
                _loginAccountController.clear(); // 清空输入内容
              });
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _loginAccountController,
            label: _loginType == LoginType.email ? '邮箱' : '手机号',
            hintText: _loginType == LoginType.email 
              ? '请输入邮箱地址' 
              : '请输入手机号',
            keyboardType: _loginType == LoginType.email 
              ? TextInputType.emailAddress 
              : TextInputType.phone,
            prefixIcon: _loginType == LoginType.email 
              ? Icons.email_outlined 
              : Icons.phone_outlined,
            validator: (value) => _validateAccountByType(value, _loginType),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _loginPasswordController,
            label: '密码',
            hintText: '请输入密码',
            obscureText: !_loginPasswordVisible,
            prefixIcon: Icons.lock_outlined,
            suffixIcon: IconButton(
              icon: Icon(
                _loginPasswordVisible
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _loginPasswordVisible = !_loginPasswordVisible;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入密码';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return CustomButton(
                text: '登录',
                isLoading: authProvider.isLoading,
                onPressed: () => _handleLogin(authProvider),
              );
            },
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              // TODO: 实现忘记密码功能
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('忘记密码功能即将上线')),
              );
            },
            child: Text(
              '忘记密码？',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建注册表单
  Widget _buildRegisterForm() {
    return Form(
      key: _registerFormKey,
      child: Column(
        children: [
          // 注册方式选择器
          LoginTypeSelector(
            selectedType: _registerType,
            onChanged: (type) {
              setState(() {
                _registerType = type;
                _registerAccountController.clear(); // 清空输入内容
              });
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _registerAccountController,
            label: _registerType == LoginType.email ? '邮箱' : '手机号',
            hintText: _registerType == LoginType.email 
              ? '请输入邮箱地址' 
              : '请输入手机号',
            keyboardType: _registerType == LoginType.email 
              ? TextInputType.emailAddress 
              : TextInputType.phone,
            prefixIcon: _registerType == LoginType.email 
              ? Icons.email_outlined 
              : Icons.phone_outlined,
            validator: (value) => _validateAccountByType(value, _registerType),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _registerUsernameController,
            label: '昵称',
            hintText: '请输入您的昵称',
            prefixIcon: Icons.person_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入昵称';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _registerPasswordController,
            label: '密码',
            hintText: '请输入密码',
            obscureText: !_registerPasswordVisible,
            prefixIcon: Icons.lock_outlined,
            suffixIcon: IconButton(
              icon: Icon(
                _registerPasswordVisible
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _registerPasswordVisible = !_registerPasswordVisible;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入密码';
              }
              if (value.length < 8) {
                return '密码至少8位';
              }
              if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(value)) {
                return '密码需包含字母和数字';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _registerConfirmPasswordController,
            label: '确认密码',
            hintText: '请再次输入密码',
            obscureText: !_registerConfirmPasswordVisible,
            prefixIcon: Icons.lock_outlined,
            suffixIcon: IconButton(
              icon: Icon(
                _registerConfirmPasswordVisible
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _registerConfirmPasswordVisible = !_registerConfirmPasswordVisible;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请确认密码';
              }
              if (value != _registerPasswordController.text) {
                return '两次输入的密码不一致';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return CustomButton(
                text: '注册',
                isLoading: authProvider.isLoading,
                onPressed: () => _handleRegister(authProvider),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 根据登录类型验证账号
  String? _validateAccountByType(String? value, LoginType type) {
    if (value == null || value.isEmpty) {
      return type == LoginType.email ? '请输入邮箱' : '请输入手机号';
    }
    
    switch (type) {
      case LoginType.email:
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        if (!emailRegex.hasMatch(value)) {
          return '请输入正确的邮箱格式';
        }
        break;
      case LoginType.phone:
        final phoneRegex = RegExp(r'^1[3-9]\d{9}$');
        if (!phoneRegex.hasMatch(value)) {
          return '请输入正确的手机号格式';
        }
        break;
    }
    
    return null;
  }

  /// 构建错误信息显示
  Widget _buildErrorMessage() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.errorMessage == null) {
          return const SizedBox.shrink();
        }

        // 5秒后自动清除错误信息
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted && authProvider.errorMessage != null) {
            authProvider.clearError();
          }
        });

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.error.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.onErrorContainer,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  authProvider.errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    fontSize: 14,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  size: 18,
                ),
                onPressed: () {
                  authProvider.clearError();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 处理登录
  Future<void> _handleLogin(AuthProvider authProvider) async {
    if (!_loginFormKey.currentState!.validate()) return;

    final loginRequest = LoginRequest(
      account: _loginAccountController.text.trim(),
      password: _loginPasswordController.text,
      loginType: _loginType,
    );

    final success = await authProvider.loginWithType(loginRequest);

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  /// 处理注册
  Future<void> _handleRegister(AuthProvider authProvider) async {
    if (!_registerFormKey.currentState!.validate()) return;

    final registerRequest = RegisterRequest(
      account: _registerAccountController.text.trim(),
      username: _registerUsernameController.text.trim(),
      password: _registerPasswordController.text,
      confirmPassword: _registerConfirmPasswordController.text,
      loginType: _registerType,
    );

    final success = await authProvider.registerWithType(registerRequest);

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }
}
