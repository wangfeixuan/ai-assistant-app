import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../providers/pomodoro_provider.dart';
import '../models/pomodoro_mode.dart';

/// 番茄钟设置页面
class PomodoroSettingsScreen extends StatelessWidget {
  const PomodoroSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('番茄钟设置'),
        elevation: 0,
      ),
      body: Consumer<PomodoroProvider>(
        builder: (context, provider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 计时模式设置
              _buildCountModeSection(context, provider),
              const SizedBox(height: 24),
              
              // 自定义时长设置
              _buildCustomDurationSection(context, provider),
              const SizedBox(height: 24),
              
              // 每日目标设置
              _buildDailyGoalSection(context, provider),
              const SizedBox(height: 24),
              
              // 严格模式设置
              _buildStrictModeSection(context, provider),
              const SizedBox(height: 24),
              
              // 翻转开始模式设置
              _buildFlipModeSection(context, provider),
              const SizedBox(height: 24),
              
              // 沉浸模式设置
              _buildImmersiveModeSection(context, provider),
            ],
          );
        },
      ),
    );
  }

  /// 构建计时模式设置区域
  Widget _buildCountModeSection(BuildContext context, PomodoroProvider provider) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '计时模式',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    provider.isCountUp ? '正计时模式（从0开始计时）' : '倒计时模式（从设定时间倒数）',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Switch(
                  value: provider.isCountUp,
                  onChanged: (value) {
                    provider.toggleCountMode();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              provider.isCountUp 
                  ? '正计时模式：时间从00:00开始递增，到达设定时间后完成'
                  : '倒计时模式：时间从设定时间开始递减，到达00:00后完成',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建自定义时长设置区域
  Widget _buildCustomDurationSection(BuildContext context, PomodoroProvider provider) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '自定义时长',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            // 专注时间设置
            _buildDurationSetting(
              context,
              provider,
              PomodoroMode.pomodoro,
              '专注时间',
              Icons.work_outline,
            ),
            const SizedBox(height: 12),
            
            // 短休息时间设置
            _buildDurationSetting(
              context,
              provider,
              PomodoroMode.shortBreak,
              '短休息',
              Icons.coffee_outlined,
            ),
            const SizedBox(height: 12),
            
            // 长休息时间设置
            _buildDurationSetting(
              context,
              provider,
              PomodoroMode.longBreak,
              '长休息',
              Icons.hotel_outlined,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建单个时长设置项
  Widget _buildDurationSetting(
    BuildContext context,
    PomodoroProvider provider,
    PomodoroMode mode,
    String label,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final currentMinutes = provider.getCustomDurationMinutes(mode);
    
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        Text(
          '$currentMinutes 分钟',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => _showDurationDialog(context, provider, mode, label),
          icon: const Icon(Icons.edit_outlined, size: 20),
          tooltip: '修改时长',
        ),
      ],
    );
  }

  /// 构建每日目标设置区域
  Widget _buildDailyGoalSection(BuildContext context, PomodoroProvider provider) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '每日目标',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.flag_outlined, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '每日番茄钟目标',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Text(
                  '${provider.dailyGoal} 个',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _showDailyGoalDialog(context, provider),
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: '修改目标',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 显示时长设置对话框（滚动选择器）
  void _showDurationDialog(
    BuildContext context,
    PomodoroProvider provider,
    PomodoroMode mode,
    String label,
  ) {
    showDialog(
      context: context,
      builder: (context) => _DurationPickerDialog(
        provider: provider,
        mode: mode,
        label: label,
      ),
    );
  }

  /// 显示每日目标设置对话框
  void _showDailyGoalDialog(BuildContext context, PomodoroProvider provider) {
    final controller = TextEditingController(text: provider.dailyGoal.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置每日目标'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '每日目标（个）',
                hintText: '请输入1-50之间的数字',
                suffixText: '个番茄钟',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '建议每日完成6-8个番茄钟，约3-4小时专注时间',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final goal = int.tryParse(controller.text);
              if (goal != null && goal > 0 && goal <= 50) {
                provider.setDailyGoal(goal);
                Navigator.of(context).pop();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入1-50之间的有效数字')),
                );
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
  
  /// 构建严格模式设置区域
  Widget _buildStrictModeSection(BuildContext context, PomodoroProvider provider) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security,
                  color: provider.strictModeEnabled ? Colors.pink[400] : theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '严格模式',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 严格模式开关
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                provider.strictModeEnabled ? '已启用严格模式' : '启用严格模式',
                style: theme.textTheme.bodyLarge,
              ),
              subtitle: Text(
                provider.strictModeEnabled 
                    ? '专注期间离开应用将结束会话且不保存数据'
                    : '启用后可提高专注效果，但要求更严格',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              value: provider.strictModeEnabled,
              onChanged: (value) {
                if (value) {
                  _showStrictModeWarning(context, provider);
                } else {
                  provider.toggleStrictMode();
                }
              },
              secondary: Icon(
                provider.strictModeEnabled ? Icons.lock : Icons.lock_open,
                color: provider.strictModeEnabled ? Colors.pink[400] : Colors.grey,
              ),
            ),
            
            if (provider.strictModeEnabled) ...[
              const Divider(),
              const SizedBox(height: 8),
              
              // 违规统计
              _buildViolationStats(context, provider),
            ],
          ],
        ),
      ),
    );
  }
  
  /// 构建违规统计区域
  Widget _buildViolationStats(BuildContext context, PomodoroProvider provider) {
    final theme = Theme.of(context);
    final todayCount = provider.getTodayViolationCount();
    final weekCount = provider.getWeekViolationCount();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '违规统计',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                '今日违规',
                todayCount.toString(),
                Icons.today,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                '本周违规',
                weekCount.toString(),
                Icons.date_range,
                Colors.pink[400]!,
              ),
            ),
          ],
        ),
        
        if (provider.violations.isNotEmpty) ...[
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => _showClearViolationsDialog(context, provider),
            icon: const Icon(Icons.clear_all, size: 16),
            label: const Text('清除违规记录'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }
  
  /// 构建统计卡片
  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 显示严格模式警告对话框
  void _showStrictModeWarning(BuildContext context, PomodoroProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.pink[400]),
            const SizedBox(width: 8),
            const Text('启用严格模式'),
          ],
        ),
        content: const Text(
          '启用严格模式后，在专注期间如果离开应用：\n\n'
          '• 专注会话将立即结束\n'
          '• 本次专注数据不会被保存\n'
          '• 不会计入完成统计\n'
          '• 会记录为拖延行为\n\n'
          '这将帮助您保持专注，但要求更加严格。\n\n'
          '确定要启用吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.toggleStrictMode();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('严格模式已启用'),
                  backgroundColor: Colors.pink[400],
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink[400],
              foregroundColor: Colors.white,
            ),
            child: const Text('启用严格模式'),
          ),
        ],
      ),
    );
  }
  
  /// 显示清除违规记录确认对话框
  void _showClearViolationsDialog(BuildContext context, PomodoroProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除违规记录'),
        content: const Text('确定要清除所有违规记录吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.clearViolations();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('违规记录已清除')),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
  
  /// 构建翻转开始模式设置区域
  Widget _buildFlipModeSection(BuildContext context, PomodoroProvider provider) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.screen_rotation,
                  color: provider.flipModeEnabled ? Colors.blue[600] : theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '翻转开始模式',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 翻转模式开关
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                '启用翻转开始',
                style: theme.textTheme.bodyLarge,
              ),
              subtitle: Text(
                '翻转手机开始计时，恢复正常停止计时',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              value: provider.flipModeEnabled,
              onChanged: (value) {
                if (value) {
                  _showFlipModeEnableDialog(context, provider);
                } else {
                  provider.toggleFlipMode();
                }
              },
              secondary: Icon(
                provider.flipModeEnabled ? Icons.flip : Icons.flip_outlined,
                color: provider.flipModeEnabled ? Colors.blue[600] : Colors.grey,
              ),
            ),
            
            if (provider.flipModeEnabled) ...[
              const Divider(),
              const SizedBox(height: 8),
              
              // 翻转模式状态显示
              _buildFlipModeStatus(context, provider),
              
              const SizedBox(height: 12),
              
              // 功能说明
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          '功能说明',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• 翻转手机屏幕向下开始计时\n'
                      '• 手机恢复正常时暂停计时\n'
                      '• 计时期间不能离开应用\n'
                      '• 强制退出需要3次确认\n'
                      '• 强制退出会记录拖延日记',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.blue[700],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// 构建翻转模式状态显示
  Widget _buildFlipModeStatus(BuildContext context, PomodoroProvider provider) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Expanded(
          child: _buildStatusItem(
            context,
            '当前状态',
            provider.isFlipModeActive ? '翻转中' : '正常',
            provider.isFlipModeActive ? Icons.screen_lock_rotation : Icons.screen_rotation,
            provider.isFlipModeActive ? Colors.green : Colors.grey,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatusItem(
            context,
            '退出尝试',
            '${provider.forceExitAttempts}/3',
            Icons.exit_to_app,
            provider.forceExitAttempts > 0 ? Colors.orange : Colors.grey,
          ),
        ),
      ],
    );
  }
  
  /// 构建状态项
  Widget _buildStatusItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 显示翻转模式启用确认对话框
  void _showFlipModeEnableDialog(BuildContext context, PomodoroProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.screen_rotation, color: Colors.blue[600]),
            const SizedBox(width: 8),
            const Text('启用翻转开始模式'),
          ],
        ),
        content: const Text(
          '启用翻转开始模式后：\n\n'
          '• 翻转手机屏幕向下开始计时\n'
          '• 手机恢复正常时暂停计时\n'
          '• 计时期间不能离开应用\n'
          '• 强制退出需要3次确认\n'
          '• 强制退出会记录拖延日记\n\n'
          '这将帮助您保持专注，但要求更加严格。\n\n'
          '确定要启用吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.toggleFlipMode();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('翻转开始模式已启用'),
                  backgroundColor: Colors.blue[600],
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('启用翻转模式'),
          ),
        ],
      ),
    );
  }
  
  /// 构建沉浸模式设置区域
  Widget _buildImmersiveModeSection(BuildContext context, PomodoroProvider provider) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.fullscreen,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '沉浸模式',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: provider.immersiveModeEnabled,
                  onChanged: (value) {
                    if (value) {
                      _showImmersiveModeEnableDialog(context, provider);
                    } else {
                      provider.setImmersiveMode(false);
                    }
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Text(
              '开启后，番茄钟计时时会进入专用的沉浸式页面，提供简洁美观的专注体验。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            
            if (provider.immersiveModeEnabled) ...[
              const Divider(),
              const SizedBox(height: 8),
              
              // 功能说明
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.purple[700]),
                        const SizedBox(width: 8),
                        Text(
                          '功能特点',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.purple[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• 简洁美观的全屏界面\n'
                      '• 只显示计时器和返回按钮\n'
                      '• 渐变背景和动效加持\n'
                      '• 与翻转模式完美配合',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.purple[700],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// 显示沉浸模式启用确认对话框
  void _showImmersiveModeEnableDialog(BuildContext context, PomodoroProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.fullscreen, color: Colors.purple),
            SizedBox(width: 12),
            Text('启用沉浸模式'),
          ],
        ),
        content: const Text(
          '沉浸模式将为您提供一个简洁美观的专注界面，\n'
          '去除一切干扰，让您完全沉浸在番茄钟中。\n\n'
          '是否启用沉浸模式？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.setImmersiveMode(true);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('沉浸模式已启用，下次开始计时时将进入沉浸界面'),
                  backgroundColor: Colors.purple,
                ),
              );
            },
            child: const Text('启用'),
          ),
        ],
      ),
    );
  }
}

/// 时长选择器对话框
class _DurationPickerDialog extends StatefulWidget {
  final PomodoroProvider provider;
  final PomodoroMode mode;
  final String label;

  const _DurationPickerDialog({
    required this.provider,
    required this.mode,
    required this.label,
  });

  @override
  State<_DurationPickerDialog> createState() => _DurationPickerDialogState();
}

class _DurationPickerDialogState extends State<_DurationPickerDialog> {
  late int selectedMinutes;
  late List<int> minuteOptions;
  late int initialIndex;

  @override
  void initState() {
    super.initState();
    final currentMinutes = widget.provider.getCustomDurationMinutes(widget.mode);
    selectedMinutes = currentMinutes;
    
    // 生成1-120分钟的选项列表
    minuteOptions = List.generate(120, (index) => index + 1);
    initialIndex = minuteOptions.indexOf(currentMinutes).clamp(0, minuteOptions.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('设置${widget.label}时长'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 当前选择显示
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timer_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '$selectedMinutes 分钟',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // 滚动选择器
          SizedBox(
            height: 150,
            child: CupertinoPicker(
              scrollController: FixedExtentScrollController(initialItem: initialIndex),
              itemExtent: 40,
              onSelectedItemChanged: (index) {
                setState(() {
                  selectedMinutes = minuteOptions[index];
                });
              },
              children: minuteOptions.map((minutes) => Center(
                child: Text(
                  '$minutes 分钟',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              )).toList(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.provider.resetToDefaultDuration(widget.mode);
            Navigator.of(context).pop();
          },
          child: const Text('恢复默认'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.provider.setCustomDuration(widget.mode, selectedMinutes);
            Navigator.of(context).pop();
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}
