import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/pomodoro_provider.dart';
import '../models/pomodoro_mode.dart';
import '../widgets/timer_circle.dart';
import 'pomodoro_stats_screen.dart';
import 'pomodoro_settings_screen.dart';
import 'pomodoro_immersive_screen.dart';

/// 番茄钟页面 - 专注时间管理
class PomodoroScreen extends StatelessWidget {
  const PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Consumer<PomodoroProvider>(
            builder: (context, pomodoroProvider, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 页面标题和统计按钮
                  _buildPageHeader(context),
                  
                  const SizedBox(height: 24),
                  
                  // 欢迎语和当前状态
                  _buildWelcomeSection(context, pomodoroProvider),
                  
                  const SizedBox(height: 32),
                  // 模式选择器
                  _buildModeSelector(context, pomodoroProvider),
                  
                  const SizedBox(height: 40),
                  
                  // 简化的计时器显示（避免Stack问题）
                  _buildSimpleTimer(context, pomodoroProvider),
                  
                  const SizedBox(height: 40),
                  
                  // 控制按钮
                  _buildControlButtons(context, pomodoroProvider),
                  
                  const SizedBox(height: 32),
                  
                  // 详细统计信息
                  _buildDetailedStats(context, pomodoroProvider),
                  
                  const SizedBox(height: 24),
                  
                  // 今日目标和进度
                  _buildDailyGoal(context, pomodoroProvider),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// 构建页面标题
  Widget _buildPageHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 页面标题
          Text(
            '🍅 番茄钟',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          
          // 按钮组
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 设置按钮
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PomodoroSettingsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.settings_outlined),
                tooltip: '设置',
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              // 统计按钮
              IconButton(
                onPressed: () => showPomodoroStats(context),
                icon: const Icon(Icons.bar_chart),
                tooltip: '统计数据',
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建欢迎语和当前状态
  Widget _buildWelcomeSection(BuildContext context, PomodoroProvider provider) {
    final theme = Theme.of(context);
    String statusText;
    IconData statusIcon;
    Color statusColor;
    
    if (provider.isRunning) {
      statusText = '专注中 - ${provider.modeDisplayName}';
      statusIcon = Icons.timer;
      statusColor = theme.colorScheme.primary;
    } else if (provider.getTodayCompletedCount() > 0) {
      statusText = '今日已完成 ${provider.getTodayCompletedCount()} 个番茄钟';
      statusIcon = Icons.check_circle;
      statusColor = Colors.green;
    } else {
      statusText = '快来开始专注吧';
      statusIcon = Icons.play_circle;
      statusColor = theme.colorScheme.secondary;
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withOpacity(0.3),
            theme.colorScheme.secondaryContainer.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            statusIcon,
            size: 32,
            color: statusColor,
          ),
          const SizedBox(height: 8),
          Text(
            statusText,
            style: theme.textTheme.titleMedium?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // 显示计时模式信息
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  provider.isCountUp ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  provider.isCountUp ? '正计时模式' : '倒计时模式',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // 翻转模式状态显示
          if (provider.flipModeEnabled) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: provider.isFlipModeActive 
                    ? Colors.green.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: provider.isFlipModeActive 
                      ? Colors.green.withOpacity(0.3)
                      : Colors.blue.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    provider.isFlipModeActive 
                        ? Icons.screen_lock_rotation 
                        : Icons.screen_rotation,
                    size: 16,
                    color: provider.isFlipModeActive 
                        ? Colors.green[700] 
                        : Colors.blue[700],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    provider.isFlipModeActive 
                        ? '翻转模式激活' 
                        : '翻转模式待命',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: provider.isFlipModeActive 
                          ? Colors.green[700] 
                          : Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          if (provider.isRunning) ...[
            const SizedBox(height: 8),
            Text(
              provider.flipModeEnabled && provider.isFlipModeActive
                  ? '手机已翻转，保持专注状态'
                  : '保持专注，成功正向你走来',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  /// 构建模式选择器
  Widget _buildModeSelector(BuildContext context, PomodoroProvider provider) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: PomodoroMode.values.map((mode) {
          final isSelected = mode == provider.currentMode;
          return Expanded(
            child: GestureDetector(
              onTap: () => provider.switchMode(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  mode.displayName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 构建控制按钮
  Widget _buildControlButtons(BuildContext context, PomodoroProvider provider) {
    return Column(
      children: [
        // 第一行：开始/暂停按钮
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              if (!provider.isRunning && provider.immersiveModeEnabled) {
                // 如果启用了沉浸模式且当前未运行，先开始计时器然后跳转到沉浸页面
                provider.startTimer();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PomodoroImmersiveScreen(),
                  ),
                );
              } else {
                // 正常切换计时器状态
                provider.toggleTimer();
              }
            },
            icon: Icon(
              provider.isRunning ? Icons.pause : Icons.play_arrow,
              size: 24,
            ),
            label: Text(
              provider.isRunning ? '暂停' : '开始',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // 第二行：根据计时模式显示不同按钮
        if (provider.isCountUp && provider.isRunning) ...[
          // 正计时模式运行时：显示结束按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                // 显示确认对话框
                final shouldStop = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('结束番茄钟'),
                      content: Text(
                        '确定要结束当前的${provider.modeDisplayName}吗？\n\n'
                        '已进行时间：${provider.formattedTime}\n'
                        '这个时间将被记录到统计中。',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('取消'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('确定结束'),
                        ),
                      ],
                    );
                  },
                );
                
                if (shouldStop == true) {
                  await provider.stopTimer();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${provider.modeDisplayName}已结束，用时${provider.formattedTime}'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.stop, size: 20),
              label: const Text(
                '结束',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        // 第三行：重置和下一个模式按钮
        Row(
          children: [
            // 重置按钮
            Expanded(
              child: OutlinedButton.icon(
                onPressed: provider.resetTimer,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('重置'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // 下一个模式按钮
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  provider.switchToNextMode();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('已切换到${provider.modeDisplayName}模式'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  );
                },
                icon: const Icon(Icons.skip_next, size: 18),
                label: const Text('下一个'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建详细统计信息
  Widget _buildDetailedStats(BuildContext context, PomodoroProvider provider) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '今日统计',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  '已完成',
                  provider.getTodayCompletedCount().toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  '专注时长',
                  provider.getTodayActualFocusTimeFormatted(),
                  Icons.access_time,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建统计卡片
  Widget _buildStatCard(
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  /// 构建每日目标和进度
  Widget _buildDailyGoal(BuildContext context, PomodoroProvider provider) {
    final theme = Theme.of(context);
    final dailyGoal = provider.dailyGoal; // 使用动态的每日目标
    final progress = provider.getTodayCompletedCount() / dailyGoal;
    final progressPercent = (progress * 100).clamp(0, 100).toInt();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '今日目标',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  Text(
                    '${provider.getTodayCompletedCount()}/$dailyGoal',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 设置按钮
                  InkWell(
                    onTap: () => _showDailyGoalDialog(context, provider),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.settings,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: theme.colorScheme.outline.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 1.0 ? Colors.green : theme.colorScheme.primary,
            ),
            minHeight: 8,
          ),
          const SizedBox(height: 8),
          Text(
            progress >= 1.0 
                ? '🎉 恭喜！今日目标已完成！'
                : '还需 ${dailyGoal - provider.getTodayCompletedCount()} 个番茄钟完成今日目标 ($progressPercent%)',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: progress >= 1.0 
                  ? Colors.green 
                  : theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// 显示每日目标设置对话框
  void _showDailyGoalDialog(BuildContext context, PomodoroProvider provider) {
    final TextEditingController controller = TextEditingController(
      text: provider.dailyGoal.toString(),
    );
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    Icons.flag,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text('设置每日目标'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '设置您每天想要完成的番茄钟数量：',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '每日目标（个）',
                      hintText: '请输入 1-50 之间的数字',
                      border: OutlineInputBorder(),
                      suffixText: '个',
                    ),
                    onChanged: (value) {
                      setState(() {}); // 触发UI更新
                    },
                  ),
                  const SizedBox(height: 12),
                  // 快速选择按钮
                  Text(
                    '快速选择：',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [4, 6, 8, 10, 12].map((goal) {
                      final isSelected = controller.text == goal.toString();
                      return ActionChip(
                        label: Text('$goal个'),
                        onPressed: () {
                          controller.text = goal.toString();
                          setState(() {}); // 触发UI更新以显示选中状态
                        },
                        backgroundColor: isSelected
                            ? theme.colorScheme.primaryContainer
                            : null,
                        labelStyle: isSelected
                            ? TextStyle(color: theme.colorScheme.onPrimaryContainer)
                            : null,
                      );
                    }).toList(),
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
                    if (goal != null && goal >= 1 && goal <= 50) {
                      provider.setDailyGoal(goal);
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('每日目标已设置为 $goal 个番茄钟'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('请输入 1-50 之间的数字'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );
  }







  /// 构建圆形进度条计时器
  Widget _buildSimpleTimer(BuildContext context, PomodoroProvider provider) {
    final theme = Theme.of(context);
    
    // 直接使用TimerCircle组件，避免重复显示造成的重影
    return TimerCircle(
      progress: provider.progress,
      timeText: provider.formattedTime,
      primaryColor: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.outline,
      size: 280,
      showCompletionAnimation: provider.showCompletionAnimation,
    );
  }

  /// 构建控制按钮




}
