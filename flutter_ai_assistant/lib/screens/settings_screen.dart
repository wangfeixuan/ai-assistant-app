import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/todo/providers/todo_provider.dart';
import '../features/todo/models/todo_settings.dart';
import '../features/todo/screens/auto_cleanup_settings_screen.dart';
import '../features/todo/services/auto_cleanup_service.dart';

/// 统一设置页面 - 包含所有应用设置
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: Colors.deepPurple.shade50,
        foregroundColor: Colors.deepPurple.shade700,
        elevation: 0,
      ),
      body: Consumer<TodoProvider>(
        builder: (context, todoProvider, child) {
          final settings = todoProvider.settings;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReminderSection(context, todoProvider, settings),
                const SizedBox(height: 24),
                _buildDoNotDisturbSection(context, todoProvider, settings),
                const SizedBox(height: 24),
                _buildNotificationAttitudeSection(context, todoProvider, settings),
                const SizedBox(height: 24),
                _buildAdvancedSection(context, todoProvider, settings),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildReminderSection(BuildContext context, TodoProvider todoProvider, TodoSettings settings) {
    return _buildSectionCard(
      title: '通知提醒',
      icon: Icons.notifications,
      color: Colors.blue,
      children: [
        _buildTimePickerTile(
          title: '统一提醒时间',
          subtitle: '每日未完成任务提醒时间',
          time: TimeOfDay.fromDateTime(settings.unifiedReminderTime),
          onChanged: (time) {
            final now = DateTime.now();
            final newDateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
            todoProvider.updateSettings(settings.copyWith(unifiedReminderTime: newDateTime));
          },
        ),
        _buildSwitchTile(
          title: '启用震动',
          subtitle: '提醒时震动设备',
          value: settings.enableVibration,
          onChanged: (value) {
            todoProvider.updateSettings(settings.copyWith(enableVibration: value));
          },
        ),
        _buildSwitchTile(
          title: '启用声音',
          subtitle: '提醒时播放声音',
          value: settings.enableSound,
          onChanged: (value) {
            todoProvider.updateSettings(settings.copyWith(enableSound: value));
          },
        ),
        _buildDropdownTile<NotificationFrequency>(
          title: '提醒频率',
          subtitle: '未完成任务的每日提醒次数：低频率每日1次，正常每日2-3次，高频率每日4-5次',
          value: settings.notificationFrequency,
          items: NotificationFrequency.values,
          itemBuilder: (frequency) {
            switch (frequency) {
              case NotificationFrequency.low:
                return '低频率（每日1次提醒）';
              case NotificationFrequency.normal:
                return '正常（每日2-3次提醒）';
              case NotificationFrequency.high:
                return '高频率（每日4-5次提醒）';
            }
          },
          onChanged: (value) {
            if (value != null) {
              todoProvider.updateSettings(settings.copyWith(notificationFrequency: value));
            }
          },
        ),
      ],
    );
  }
  
  Widget _buildDoNotDisturbSection(BuildContext context, TodoProvider todoProvider, TodoSettings settings) {
    return _buildSectionCard(
      title: '勿扰模式',
      icon: Icons.do_not_disturb,
      color: Colors.orange,
      children: [
        _buildSwitchTile(
          title: '启用勿扰模式',
          subtitle: '在指定时间段内不发送提醒',
          value: settings.enableDoNotDisturb,
          onChanged: (value) {
            todoProvider.updateSettings(settings.copyWith(enableDoNotDisturb: value));
          },
        ),
        if (settings.enableDoNotDisturb) ...[
          _buildTimePickerTile(
            title: '勿扰开始时间',
            time: TimeOfDay.fromDateTime(settings.doNotDisturbStart),
            onChanged: (time) {
              final now = DateTime.now();
              final newDateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
              todoProvider.updateSettings(settings.copyWith(doNotDisturbStart: newDateTime));
            },
          ),
          _buildTimePickerTile(
            title: '勿扰结束时间',
            time: TimeOfDay.fromDateTime(settings.doNotDisturbEnd),
            onChanged: (time) {
              final now = DateTime.now();
              final newDateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
              todoProvider.updateSettings(settings.copyWith(doNotDisturbEnd: newDateTime));
            },
          ),
          _buildWeekdaySelector(
            title: '勿扰日期',
            selectedDays: settings.doNotDisturbDays,
            onChanged: (days) {
              todoProvider.updateSettings(settings.copyWith(doNotDisturbDays: days));
            },
          ),
        ],
      ],
    );
  }
  
  Widget _buildNotificationAttitudeSection(BuildContext context, TodoProvider todoProvider, TodoSettings settings) {
    return _buildSectionCard(
      title: '通知态度',
      icon: Icons.psychology,
      color: Colors.green,
      children: [
        _buildDropdownTile<ReminderStyle>(
          title: '提醒风格',
          subtitle: '选择提醒消息的语言风格（昵称使用个人资料中设置的用户名）',
          value: settings.reminderStyle,
          items: ReminderStyle.values,
          itemBuilder: (style) {
            switch (style) {
              case ReminderStyle.gentle:
                return '温和';
              case ReminderStyle.strict:
                return '严格';
              case ReminderStyle.encouraging:
                return '鼓励';
            }
          },
          onChanged: (value) {
            if (value != null) {
              todoProvider.updateSettings(settings.copyWith(reminderStyle: value));
            }
          },
        ),
      ],
    );
  }
  
  Widget _buildAdvancedSection(BuildContext context, TodoProvider todoProvider, TodoSettings settings) {
    return _buildSectionCard(
      title: '高级设置',
      icon: Icons.settings,
      color: Colors.purple,
      children: [
        _buildSwitchTile(
          title: '启用智能提醒',
          subtitle: '根据任务状态智能发送提醒',
          value: settings.enableSmartReminder,
          onChanged: (value) {
            todoProvider.updateSettings(settings.copyWith(enableSmartReminder: value));
          },
        ),
        _buildSwitchTile(
          title: '尊重番茄钟专注模式',
          subtitle: '番茄钟进行时不发送提醒',
          value: settings.respectPomodoroFocus,
          onChanged: (value) {
            todoProvider.updateSettings(settings.copyWith(respectPomodoroFocus: value));
          },
        ),
        _buildSwitchTile(
          title: '进度提醒',
          subtitle: '任务超时50%时发送提醒',
          value: settings.enableProgressReminder,
          onChanged: (value) {
            todoProvider.updateSettings(settings.copyWith(enableProgressReminder: value));
          },
        ),
        _buildSwitchTile(
          title: '拖延提醒',
          subtitle: '任务拖延时发送提醒',
          value: settings.enableDelayReminder,
          onChanged: (value) {
            todoProvider.updateSettings(settings.copyWith(enableDelayReminder: value));
          },
        ),
        _buildSwitchTile(
          title: '跨天任务自动延期',
          subtitle: '未完成任务自动延期到第二天',
          value: settings.enableCrossDayRollover,
          onChanged: (value) {
            todoProvider.updateSettings(settings.copyWith(enableCrossDayRollover: value));
          },
        ),
        _buildDropdownTile<DelayTolerance>(
          title: '拖延容忍度',
          subtitle: '设置对任务拖延的容忍程度',
          value: settings.delayTolerance,
          items: DelayTolerance.values,
          itemBuilder: (tolerance) {
            switch (tolerance) {
              case DelayTolerance.strict:
                return '严格';
              case DelayTolerance.normal:
                return '正常';
              case DelayTolerance.lenient:
                return '宽松';
            }
          },
          onChanged: (value) {
            if (value != null) {
              todoProvider.updateSettings(settings.copyWith(delayTolerance: value));
            }
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.auto_delete, color: Colors.orange),
          title: const Text('自动清除设置'),
          subtitle: const Text('配置已完成任务的自动清除'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AutoCleanupSettingsScreen(),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.science, color: Colors.green),
          title: const Text('测试自动清除'),
          subtitle: const Text('立即执行一次清除测试'),
          trailing: const Icon(Icons.play_arrow),
          onTap: () => _testAutoCleanup(context, todoProvider),
        ),
      ],
    );
  }
  

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
  
  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontSize: 16)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)) : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.deepPurple.shade400,
      ),
    );
  }
  
  Widget _buildTimePickerTile({
    required String title,
    String? subtitle,
    required TimeOfDay time,
    required ValueChanged<TimeOfDay> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontSize: 16)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)) : null,
      trailing: InkWell(
        onTap: () async {
          final newTime = await showTimePicker(
            context: context,
            initialTime: time,
          );
          if (newTime != null) {
            onChanged(newTime);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.deepPurple.shade200),
          ),
          child: Text(
            time.format(context),
            style: TextStyle(
              fontSize: 16,
              color: Colors.deepPurple.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTextFieldTile({
    required String title,
    String? subtitle,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        ],
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: value)..selection = TextSelection.fromPosition(TextPosition(offset: value.length)),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.deepPurple.shade400),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
  
  Widget _buildDropdownTile<T>({
    required String title,
    String? subtitle,
    required T value,
    required List<T> items,
    required String Function(T) itemBuilder,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        ],
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.deepPurple.shade400),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(itemBuilder(item)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
  
  Widget _buildSliderTile({
    required String title,
    String? subtitle,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            Text('${value.round()}', style: TextStyle(fontSize: 16, color: Colors.deepPurple.shade600, fontWeight: FontWeight.w500)),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        ],
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: Colors.deepPurple.shade400,
          onChanged: onChanged,
        ),
      ],
    );
  }
  
  Widget _buildNavigationTile({
    required String title,
    String? subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.deepPurple.shade600,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekdaySelector({
    required String title,
    required List<int> selectedDays,
    required ValueChanged<List<int>> onChanged,
  }) {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(7, (index) {
            final dayIndex = index + 1;
            final isSelected = selectedDays.contains(dayIndex);
            
            return GestureDetector(
              onTap: () {
                final newDays = List<int>.from(selectedDays);
                if (isSelected) {
                  newDays.remove(dayIndex);
                } else {
                  newDays.add(dayIndex);
                }
                onChanged(newDays);
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.deepPurple.shade400 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    weekdays[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
  
  /// 测试自动清除功能
  Future<void> _testAutoCleanup(BuildContext context, TodoProvider todoProvider) async {
    // 显示加载对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('正在执行清除测试...'),
          ],
        ),
      ),
    );
    
    try {
      // 创建自动清除服务实例
      final cleanupService = AutoCleanupService(todoProvider);
      
      // 等待服务初始化完成
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 执行测试
      await cleanupService.testAutoCleanup();
      
      // 关闭加载对话框
      if (context.mounted) {
        Navigator.of(context).pop();
        
        // 显示成功消息
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('自动清除测试完成！请查看终端日志获取详细信息。'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // 关闭加载对话框
      if (context.mounted) {
        Navigator.of(context).pop();
        
        // 显示错误消息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('测试失败：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}