import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auto_cleanup_service.dart';
import '../providers/todo_provider.dart';

class AutoCleanupSettingsScreen extends StatefulWidget {
  const AutoCleanupSettingsScreen({super.key});

  @override
  State<AutoCleanupSettingsScreen> createState() => _AutoCleanupSettingsScreenState();
}

class _AutoCleanupSettingsScreenState extends State<AutoCleanupSettingsScreen> {
  late AutoCleanupService _cleanupService;
  late AutoCleanupSettings _settings;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final todoProvider = Provider.of<TodoProvider>(context, listen: false);
    _cleanupService = AutoCleanupService(todoProvider);
    _initializeSettings();
  }
  
  /// 初始化设置，确保从存储中加载
  Future<void> _initializeSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    await _cleanupService.ensureSettingsLoaded();
    
    setState(() {
      _settings = _cleanupService.settings;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _cleanupService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('自动清除设置'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('加载设置中...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOverviewCard(),
                  const SizedBox(height: 16),
                  _buildMainSettings(),
                  const SizedBox(height: 16),
                  _buildAdvancedSettings(),
                  const SizedBox(height: 16),
                  _buildActionButtons(),
            const SizedBox(height: 16),
            _buildBackupSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard() {
    final todoProvider = Provider.of<TodoProvider>(context);
    final stats = todoProvider.getCleanupStats();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_delete, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  '清除概览',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('已完成任务', '${stats['total_completed']}', Colors.blue),
                _buildStatItem('1天前', '${stats['old_1_day']}', Colors.orange),
                _buildStatItem('1周前', '${stats['old_1_week']}', Colors.red),
                _buildStatItem('1月前', '${stats['old_1_month']}', Colors.grey),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _settings.enabled 
                  ? '自动清除已启用 - ${_settings.strategyDisplayName}'
                  : '自动清除已禁用',
              style: TextStyle(
                color: _settings.enabled ? Colors.green : Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_settings.lastCleanupTime != null) ...[
              const SizedBox(height: 4),
              Text(
                '上次清除: ${_formatDateTime(_settings.lastCleanupTime!)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildMainSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '基本设置',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('启用自动清除'),
              subtitle: const Text('定期自动删除已完成的旧任务'),
              value: _settings.enabled,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(enabled: value);
                });
                _updateSettings();
              },
            ),
            if (_settings.enabled) ...[
              const Divider(),
              ListTile(
                title: const Text('清除策略'),
                subtitle: Text(_settings.strategyDisplayName),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _showStrategySelector,
              ),
              if (_settings.strategy == AutoCleanupStrategy.custom) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      const Text('自定义天数: '),
                      Expanded(
                        child: Slider(
                          value: _settings.customDays.toDouble(),
                          min: 1,
                          max: 90,
                          divisions: 89,
                          label: '${_settings.customDays}天',
                          onChanged: (value) {
                            setState(() {
                              _settings = _settings.copyWith(customDays: value.round());
                            });
                          },
                          onChangeEnd: (value) {
                            _updateSettings();
                          },
                        ),
                      ),
                      Text('${_settings.customDays}天'),
                    ],
                  ),
                ),
              ],
              const Divider(),
              ListTile(
                title: const Text('执行时间'),
                subtitle: Text('每日 ${_settings.cleanupTime.format(context)}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _showTimePicker,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSettings() {
    if (!_settings.enabled) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '高级设置',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('保留重要任务'),
              subtitle: const Text('不清除标记为优先的任务'),
              value: _settings.keepImportantTasks,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(keepImportantTasks: value);
                });
                _updateSettings();
              },
            ),
            SwitchListTile(
              title: const Text('保留重复任务'),
              subtitle: const Text('不清除重复任务模板和实例'),
              value: _settings.keepRecurringTasks,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(keepRecurringTasks: value);
                });
                _updateSettings();
              },
            ),
            SwitchListTile(
              title: const Text('创建备份'),
              subtitle: const Text('清除前自动备份被删除的任务'),
              value: _settings.createBackup,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(createBackup: value);
                });
                _updateSettings();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '手动操作',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _performManualCleanup,
                    icon: _isLoading 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cleaning_services),
                    label: Text(_isLoading ? '清除中...' : '立即清除'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showPreviewDialog,
                    icon: const Icon(Icons.preview),
                    label: const Text('预览清除'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupSection() {
    if (!_settings.createBackup) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '备份管理',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.backup),
              title: const Text('查看备份'),
              subtitle: const Text('管理和恢复已删除的任务'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _showBackupManager,
            ),
          ],
        ),
      ),
    );
  }

  void _showStrategySelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择清除策略'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AutoCleanupStrategy.values
              .where((strategy) => strategy != AutoCleanupStrategy.disabled)
              .map((strategy) => RadioListTile<AutoCleanupStrategy>(
                    title: Text(_getStrategyName(strategy)),
                    subtitle: Text(_getStrategyDescription(strategy)),
                    value: strategy,
                    groupValue: _settings.strategy,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _settings = _settings.copyWith(strategy: value);
                        });
                        _updateSettings();
                        Navigator.of(context).pop();
                      }
                    },
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  void _showTimePicker() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _settings.cleanupTime,
    );
    
    if (time != null) {
      setState(() {
        _settings = _settings.copyWith(cleanupTime: time);
      });
      _updateSettings();
    }
  }

  void _performManualCleanup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final count = await _cleanupService.performManualCleanup();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(count > 0 ? '已清除 $count 个任务' : '没有需要清除的任务'),
            backgroundColor: count > 0 ? Colors.green : Colors.grey,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('清除失败: $e'),
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

  void _showPreviewDialog() {
    final todoProvider = Provider.of<TodoProvider>(context, listen: false);
    final tasksToCleanup = todoProvider.getCompletedTasksForCleanup(
      olderThan: Duration(days: _settings.cleanupIntervalDays),
      excludePriorityTasks: _settings.keepImportantTasks,
      excludeRecurringTasks: _settings.keepRecurringTasks,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除预览'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: tasksToCleanup.isEmpty
              ? const Center(child: Text('没有符合条件的任务'))
              : ListView.builder(
                  itemCount: tasksToCleanup.length,
                  itemBuilder: (context, index) {
                    final task = tasksToCleanup[index];
                    return ListTile(
                      leading: Icon(
                        task.isPriority ? Icons.priority_high : Icons.task_alt,
                        color: task.isPriority ? Colors.red : Colors.grey,
                      ),
                      title: Text(
                        task.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '完成于: ${_formatDateTime(task.completedAt!)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
          if (tasksToCleanup.isNotEmpty)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performManualCleanup();
              },
              child: Text('清除 ${tasksToCleanup.length} 个任务'),
            ),
        ],
      ),
    );
  }

  void _showBackupManager() async {
    final backups = await _cleanupService.getBackupList();
    
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('备份管理'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: backups.isEmpty
              ? const Center(child: Text('暂无备份'))
              : ListView.builder(
                  itemCount: backups.length,
                  itemBuilder: (context, index) {
                    final backup = backups[index];
                    return ListTile(
                      leading: const Icon(Icons.backup),
                      title: Text('${backup['count']} 个任务'),
                      subtitle: Text(_formatDateTime(backup['timestamp'])),
                      trailing: IconButton(
                        icon: const Icon(Icons.restore),
                        onPressed: () => _restoreBackup(backup['key']),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _restoreBackup(String backupKey) async {
    final success = await _cleanupService.restoreBackup(backupKey);
    
    if (mounted) {
      Navigator.of(context).pop(); // 关闭备份管理对话框
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '备份恢复成功' : '备份恢复失败'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _updateSettings() async {
    await _cleanupService.updateSettings(_settings);
  }

  String _getStrategyName(AutoCleanupStrategy strategy) {
    switch (strategy) {
      case AutoCleanupStrategy.daily:
        return '每日清除';
      case AutoCleanupStrategy.weekly:
        return '每周清除';
      case AutoCleanupStrategy.monthly:
        return '每月清除';
      case AutoCleanupStrategy.custom:
        return '自定义';
      case AutoCleanupStrategy.disabled:
        return '禁用';
    }
  }

  String _getStrategyDescription(AutoCleanupStrategy strategy) {
    switch (strategy) {
      case AutoCleanupStrategy.daily:
        return '每天清除1天前完成的任务';
      case AutoCleanupStrategy.weekly:
        return '每周清除7天前完成的任务';
      case AutoCleanupStrategy.monthly:
        return '每月清除30天前完成的任务';
      case AutoCleanupStrategy.custom:
        return '自定义清除间隔天数';
      case AutoCleanupStrategy.disabled:
        return '不自动清除任务';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
