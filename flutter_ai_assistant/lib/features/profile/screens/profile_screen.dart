import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../widgets/theme_selector.dart';
import '../../../widgets/custom_button.dart';
import '../../../screens/auth_screen.dart';
import '../../../core/services/personalization_service.dart';
import '../../../core/themes/theme_manager.dart';
import 'edit_profile_screen.dart';
import '../../../screens/settings_screen.dart';
import '../../todo/providers/todo_provider.dart';
import '../../todo/models/todo_settings.dart';
import '../../todo/screens/auto_cleanup_settings_screen.dart';

/// 个人页面 - 包含主题选择和个人设置
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _localNickname;

  @override
  void initState() {
    super.initState();
    _loadLocalNickname();
  }

  /// 加载本地保存的昵称
  Future<void> _loadLocalNickname() async {
    final personalizationService = PersonalizationService.instance;
    final nickname = await personalizationService.getUserNickname();
    if (mounted) {
      setState(() {
        _localNickname = nickname;
      });
    }
  }

  /// 获取显示的昵称（优先使用本地保存的昵称）
  String _getDisplayNickname(AuthProvider authProvider) {
    if (_localNickname != null && _localNickname!.isNotEmpty) {
      return _localNickname!;
    }
    if (authProvider.user != null) {
      return authProvider.user!.displayName ?? authProvider.user!.username;
    }
    return '用户';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
          appBar: AppBar(
            title: const Text('个人中心'),
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 用户信息卡片
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                if (authProvider.isAuthenticated && authProvider.user != null) {
                  final user = authProvider.user!;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: theme.colorScheme.primary,
                            backgroundImage: user.avatar != null 
                                ? NetworkImage(user.avatar!) 
                                : null,
                            child: user.avatar == null 
                                ? Text(
                                    _getDisplayNickname(authProvider).isNotEmpty 
                                        ? _getDisplayNickname(authProvider)[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getDisplayNickname(authProvider),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user.loginAccount, // 使用loginAccount获取登录账号
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                                if (user.isPremium) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      '高级会员',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () async {
                              final result = await Navigator.of(context).push<bool>(
                                MaterialPageRoute(
                                  builder: (context) => const EditProfileScreen(),
                                ),
                              );
                              
                              // 如果返回true表示有更新，可以刷新界面
                              if (result == true && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('资料更新成功！'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  // 未登录状态
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 48,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '登录后享受完整功能',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '数据云端同步，多设备无缝切换',
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          CustomButton(
                            text: '立即登录',
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const AuthScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
            
            const SizedBox(height: 24),

            // 主题外观板块
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.palette,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '主题外观',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const ThemeSelector(showTitle: false, isCompact: true),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 3. 应用设置板块（单独）
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.settings,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '应用设置',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSettingItem(
                      context,
                      icon: Icons.notifications_outlined,
                      title: '提醒设置',
                      subtitle: '提醒时间、勿扰模式、个性化设置',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                    Consumer<TodoProvider>(
                      builder: (context, todoProvider, child) {
                        final settings = todoProvider.settings;
                        String currentStyleText;
                        switch (settings.timeInputStyle) {
                          case TimeInputStyle.scroll:
                            currentStyleText = '上下滚动';
                            break;
                          case TimeInputStyle.dial:
                            currentStyleText = '拨动指针';
                            break;
                          case TimeInputStyle.manual:
                            currentStyleText = '手动填写';
                            break;
                        }
                        
                        return _buildSettingItem(
                          context,
                          icon: Icons.schedule_outlined,
                          title: '时间设置样式',
                          subtitle: '当前：$currentStyleText',
                          onTap: () => _showTimeInputStyleDialog(context, todoProvider, settings),
                        );
                      },
                    ),
                    _buildSettingItem(
                      context,
                      icon: Icons.auto_delete_outlined,
                      title: '自动清除设置',
                      subtitle: '定时清除已完成的旧任务',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AutoCleanupSettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 4. 其他功能板块
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.more_horiz,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '更多功能',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSettingItem(
                      context,
                      icon: Icons.backup_outlined,
                      title: '数据备份',
                      subtitle: '备份你的待办事项和设置',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('数据备份功能开发中...')),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildSettingItem(
                      context,
                      icon: Icons.help_outline,
                      title: '帮助与反馈',
                      subtitle: '使用指南和问题反馈',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('帮助功能开发中...')),
                        );
                      },
                    ),
                    
                    // 退出登录（仅在已登录时显示）
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        if (authProvider.isAuthenticated) {
                          return Column(
                            children: [
                              const Divider(height: 1, indent: 56),
                              _buildSettingItem(
                                context,
                                icon: Icons.logout,
                                title: '退出登录',
                                subtitle: '清除本地数据并退出账户',
                                isDestructive: true,
                                onTap: () => _showLogoutDialog(context, authProvider),
                              ),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 关于信息
            const SizedBox(height: 24),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '关于应用',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.psychology,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '拖延症AI助手',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '版本 1.0.0',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '让AI帮你拆解任务，告别拖延。集成番茄钟、任务管理和智能助手，帮助你提升专注力，高效完成目标。',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建设置项
  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive 
            ? theme.colorScheme.error
            : theme.colorScheme.primary,
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive 
              ? theme.colorScheme.error
              : theme.colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 12,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
    );
  }

  /// 显示登出确认对话框
  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认登出'),
        content: const Text('登出后将清除本地数据，确定要继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await authProvider.logout();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('已成功登出'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Text(
              '确认',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 显示时间设置样式选择对话框
  void _showTimeInputStyleDialog(BuildContext context, TodoProvider todoProvider, TodoSettings settings) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('选择时间设置样式'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStyleOption(
                context,
                icon: Icons.swap_vert,
                title: '上下滚动',
                subtitle: '使用滚轮选择时间（默认）',
                isSelected: settings.timeInputStyle == TimeInputStyle.scroll,
                onTap: () {
                  todoProvider.updateSettings(settings.copyWith(timeInputStyle: TimeInputStyle.scroll));
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 8),
              _buildStyleOption(
                context,
                icon: Icons.access_time,
                title: '拨动指针',
                subtitle: '使用系统时钟样式选择',
                isSelected: settings.timeInputStyle == TimeInputStyle.dial,
                onTap: () {
                  todoProvider.updateSettings(settings.copyWith(timeInputStyle: TimeInputStyle.dial));
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 8),
              _buildStyleOption(
                context,
                icon: Icons.keyboard,
                title: '手动填写',
                subtitle: '直接输入数字',
                isSelected: settings.timeInputStyle == TimeInputStyle.manual,
                onTap: () {
                  todoProvider.updateSettings(settings.copyWith(timeInputStyle: TimeInputStyle.manual));
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
  }

  /// 构建样式选项
  Widget _buildStyleOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
