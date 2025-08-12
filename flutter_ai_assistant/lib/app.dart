import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/themes/theme_manager.dart';
import 'core/themes/color_themes.dart';
import 'core/widgets/app_wrapper.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  // 全局导航键，用于在应用启动时访问context
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeManager, AuthProvider>(
      builder: (context, themeManager, authProvider, child) {
        // 安全地获取主题，如果ThemeManager未初始化则使用默认主题
        final theme = _getSafeTheme(themeManager);
        
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: '拖延症AI助手',
          debugShowCheckedModeBanner: false,
          
          // 国际化配置
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('zh', 'CN'), // 中文简体
            Locale('en', 'US'), // 英文（备用）
          ],
          locale: const Locale('zh', 'CN'), // 默认中文
          
          // 主题配置 - 使用安全的主题获取
          theme: theme,
          
          // 根据认证状态决定首页
          home: _buildHomeWidget(authProvider),
          
          // 路由配置
          routes: {
            '/splash': (context) => const SplashScreen(),
            '/auth': (context) => const AuthScreen(),
            '/home': (context) => const HomeScreen(),
          },
          
          // 全局配置
          builder: (context, child) {
            return AppWrapper(
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.0), // 固定字体缩放
                ),
                child: child!,
              ),
            );
          },
        );
      },
    );
  }
  
  /// 安全地获取主题，防止初始化过程中的错误
  ThemeData _getSafeTheme(ThemeManager themeManager) {
    try {
      // 直接使用ThemeManager的当前主题，不检查初始化状态
      // 因为ThemeManager在构造时就设置了默认主题
      final currentTheme = themeManager.currentTheme;
      debugPrint('🎨 当前应用的主题: ${themeManager.currentThemeName}');
      return currentTheme;
    } catch (e) {
      // 如果出现任何错误，使用Flutter的默认主题
      debugPrint('❌ 获取主题时出错，使用Flutter默认主题: $e');
      return ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      );
    }
  }

  /// 根据认证状态构建主页面
  Widget _buildHomeWidget(AuthProvider authProvider) {
    try {
      switch (authProvider.status) {
        case AuthStatus.initial:
        case AuthStatus.loading:
          return const SplashScreen();
        case AuthStatus.authenticated:
          return const HomeScreen();
        case AuthStatus.unauthenticated:
          return const AuthScreen();
      }
    } catch (e) {
      debugPrint('Error determining home widget, showing splash: $e');
      return const SplashScreen();
    }
  }
}
