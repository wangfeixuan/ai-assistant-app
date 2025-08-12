import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../core/services/personalization_service.dart';
import '../../../core/services/profile_sync_service.dart';
import '../../../core/utils/keyboard_utils.dart';

/// 编辑资料页面 - 允许用户自定义AI助手名字和自己的昵称
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _aiNameController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _aiNameController.dispose();
    super.dispose();
  }

  /// 加载当前设置
  void _loadCurrentSettings() async {
    final authProvider = context.read<AuthProvider>();
    final personalizationService = PersonalizationService.instance;
    
    // 优先从本地存储加载用户昵称（最新修改的昵称）
    String? savedNickname = await personalizationService.getUserNickname();
    
    if (savedNickname != null && savedNickname.isNotEmpty) {
      // 如果本地有保存的昵称，使用本地昵称
      _nicknameController.text = savedNickname;
    } else if (authProvider.user != null) {
      // 否则使用注册时的昵称作为默认值
      _nicknameController.text = authProvider.user!.displayName ?? authProvider.user!.username;
    }
    
    // 从本地存储加载AI助手名字
    final aiName = await personalizationService.getAiAssistantName();
    _aiNameController.text = aiName;
  }

  /// 保存设置
  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final personalizationService = PersonalizationService.instance;
      
      // 更新用户昵称 - 始终保存到本地存储
      final newNickname = _nicknameController.text.trim();
      await personalizationService.setUserNickname(newNickname);
      
      // 如果用户已登录，同时更新服务器资料
      if (authProvider.user != null) {
        try {
          await authProvider.updateProfile(displayName: newNickname);
        } catch (e) {
          print('更新服务器用户资料失败: $e');
          // 即使服务器更新失败，也不影响本地存储
        }
      }

      // 保存AI助手名字到本地存储
      final newAiName = _aiNameController.text.trim();
      await personalizationService.setAiAssistantName(newAiName);
      
      // 立即通知其他页面AI助手名称已更新
      ProfileSyncService().notifyAINameChanged(newAiName.isNotEmpty ? newAiName : 'AI智能助手');
      debugPrint('🚀 AI助手名称已保存并通知同步: $newAiName');
      
      // 通知用户昵称变化
      ProfileSyncService().notifyUserNicknameChanged(newNickname);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('资料更新成功！'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // 返回true表示有更新
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更新失败：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑资料'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 说明卡片
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '在这里，你可以自定义你的昵称和AI助手的名字，让聊天更加个性化！',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 用户昵称设置
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '你的昵称',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _nicknameController,
                        label: '',
                        hintText: '设置你的专属昵称',
                        prefixIcon: Icons.badge_outlined,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '昵称不能为空';
                          }
                          if (value.trim().length > 20) {
                            return '昵称不能超过20个字符';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // AI助手名字设置
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.smart_toy_outlined,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'AI助手名字',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _aiNameController,
                        label: '',
                        hintText: '为你的AI助手起名',
                        prefixIcon: Icons.psychology_outlined,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'AI助手名字不能为空';
                          }
                          if (value.trim().length > 15) {
                            return 'AI助手名字不能超过15个字符';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // 保存按钮
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: '保存设置',
                  onPressed: _isLoading ? null : _saveSettings,
                  isLoading: _isLoading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}