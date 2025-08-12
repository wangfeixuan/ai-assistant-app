import 'package:flutter/material.dart';

import 'ai_assistant_screen.dart';
import '../features/todo/screens/todo_screen.dart';
import '../features/pomodoro/screens/pomodoro_screen.dart';
import '../features/profile/screens/profile_screen.dart';

/// 主页面 - 包含底部导航和页面切换
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _pages = [
    const AIAssistantScreen(),
    const TodoScreen(),
    const PomodoroScreen(),
    const ProfileScreen(),
  ];
  
  @override
  Widget build(BuildContext context) {
    // 确保索引在有效范围内
    if (_currentIndex >= _pages.length) {
      _currentIndex = 0;
    }
    
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          bottomNavigationBarTheme: Theme.of(context).bottomNavigationBarTheme.copyWith(
            enableFeedback: false,
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.smart_toy),
              label: 'AI助手',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.checklist),
              label: '待办',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.timer),
              label: '番茄钟',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: '个人',
            ),
          ],
        ),
      ),
    );
  }
}
