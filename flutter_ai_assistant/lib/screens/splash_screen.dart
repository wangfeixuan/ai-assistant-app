import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

/// 启动页面 - 应用启动时的欢迎界面
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
    
    // 初始化认证状态
    _initializeApp();
  }

  /// 初始化应用状态
  Future<void> _initializeApp() async {
    try {
      // 获取认证Provider并初始化
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // 并行执行动画和认证初始化
      await Future.wait([
        authProvider.initializeAuth(),
        _animationController.forward(),
      ]);
      
      // 最小显示时间800ms，确保用户能看到启动画面
      await Future.delayed(const Duration(milliseconds: 200));
      
      // 认证状态会通过Consumer自动处理页面跳转
      // 不需要手动导航，因为app.dart中的_buildHomeWidget会处理
    } catch (e) {
      debugPrint('App initialization error: $e');
      // 即使初始化失败，也让应用继续运行
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 应用图标
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.smart_toy,
                  size: 60,
                  color: Color(0xFF3B82F6),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // 应用标题
              Text(
                '拖延症AI助手',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 副标题
              Text(
                '让AI帮你拆解任务，告别拖延',
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.onPrimary.withOpacity(0.8),
                ),
              ),
              
              const SizedBox(height: 48),
              
              // 加载指示器
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
