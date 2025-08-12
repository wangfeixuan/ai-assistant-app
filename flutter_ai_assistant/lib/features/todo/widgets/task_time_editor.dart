import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../models/todo_item.dart';
import '../models/todo_settings.dart';
import 'manual_time_input_dialog.dart';

/// 任务时间编辑组件
/// 支持设置开始时间、预计完成时长、截止时间等
class TaskTimeEditor extends StatefulWidget {
  final TodoItem task;
  final VoidCallback? onSaved;

  const TaskTimeEditor({
    Key? key,
    required this.task,
    this.onSaved,
  }) : super(key: key);

  @override
  State<TaskTimeEditor> createState() => _TaskTimeEditorState();
}

class _TaskTimeEditorState extends State<TaskTimeEditor> {
  DateTime? _startTime;
  Duration? _estimatedDuration;
  DateTime? _deadline;
  
  final List<Duration> _commonDurations = [
    const Duration(minutes: 15),
    const Duration(minutes: 30),
    const Duration(hours: 1),
    const Duration(hours: 2),
    const Duration(hours: 4),
    const Duration(hours: 8),
  ];

  @override
  void initState() {
    super.initState();
    _startTime = widget.task.startTime;
    _estimatedDuration = widget.task.estimatedDuration;
    _deadline = widget.task.deadline;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
          // 标题
          Row(
            children: [
              Icon(Icons.schedule, color: theme.primaryColor),
              const SizedBox(width: 8),
              Text(
                '时间设置',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 开始时间设置
          _buildTimeSection(
            title: '开始时间',
            icon: Icons.play_arrow,
            value: _startTime,
            onTap: () => _selectStartTime(context),
            onClear: () => setState(() => _startTime = null),
          ),
          
          const SizedBox(height: 16),
          
          // 预计完成时长设置
          _buildDurationSection(context),
          
          const SizedBox(height: 16),
          
          // 截止时间设置
          _buildTimeSection(
            title: '截止时间',
            icon: Icons.flag,
            value: _deadline,
            onTap: () => _selectDeadline(context),
            onClear: () => setState(() => _deadline = null),
          ),
          
          const SizedBox(height: 24),
          
          // 操作按钮
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveTimeSettings,
                  child: const Text('保存'),
                ),
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildTimeSection({
    required String title,
    required IconData icon,
    required DateTime? value,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: theme.primaryColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value != null 
                      ? _formatDateTime(value)
                      : '点击设置$title',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: value != null 
                        ? theme.textTheme.bodyMedium?.color
                        : theme.hintColor,
                    ),
                  ),
                ),
                if (value != null)
                  IconButton(
                    onPressed: onClear,
                    icon: const Icon(Icons.clear, size: 20),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.timer, size: 20, color: theme.primaryColor),
            const SizedBox(width: 8),
            Text(
              '预计完成时长',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: '此时长将作为番茄钟倒计时时长',
              child: Icon(
                Icons.info_outline,
                size: 16,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // 当前选择的时长
        InkWell(
          onTap: () => _selectCustomDuration(context),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _estimatedDuration != null 
                      ? _formatDuration(_estimatedDuration!)
                      : '点击设置预计时长',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _estimatedDuration != null 
                        ? theme.textTheme.bodyMedium?.color
                        : theme.hintColor,
                    ),
                  ),
                ),
                if (_estimatedDuration != null)
                  IconButton(
                    onPressed: () => setState(() => _estimatedDuration = null),
                    icon: const Icon(Icons.clear, size: 20),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // 常用时长快捷选择
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _commonDurations.map((duration) {
            final isSelected = _estimatedDuration == duration;
            return FilterChip(
              label: Text(
                _formatDuration(duration),
                style: const TextStyle(
                  fontSize: 14,  // 调整字体大小
                  fontWeight: FontWeight.w500,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _estimatedDuration = selected ? duration : null;
                });
              },
              // 自定义边框颜色
              side: BorderSide(
                color: isSelected ? Colors.blue.shade300 : Colors.grey.shade300,
                width: 1,
              ),
              // 自定义背景色
              backgroundColor: Colors.grey.shade50,
              selectedColor: Colors.blue.shade50,  // 浅蓝色背景
              checkmarkColor: Colors.blue.shade600,  // 深蓝色标记
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final todoProvider = context.read<TodoProvider>();
    final timeInputStyle = todoProvider.settings.timeInputStyle;
    
    final now = DateTime.now();
    final initialDate = _startTime ?? now;
    
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      helpText: '选择日期',
    );
    
    if (date == null) return;
    
    if (!mounted) return;
    
    TimeOfDay? time;
    
    switch (timeInputStyle) {
      case TimeInputStyle.dial:
        // 使用系统默认的拨动指针样式
        time = await showTimePicker(
          context: context,
          initialTime: widget.task.taskType == TaskType.daily 
              ? (_deadline != null ? TimeOfDay.fromDateTime(_deadline!) : const TimeOfDay(hour: 23, minute: 0))
              : TimeOfDay.fromDateTime(_deadline ?? now.add(const Duration(days: 1))),
          helpText: widget.task.taskType == TaskType.daily ? '选择当天截止时间' : '选择时间',
        );
        break;
        
      case TimeInputStyle.manual:
        // 使用手动填写样式
        time = await _showManualTimeInput(context, widget.task.taskType == TaskType.daily 
            ? (_deadline != null ? TimeOfDay.fromDateTime(_deadline!) : const TimeOfDay(hour: 23, minute: 0))
            : TimeOfDay.fromDateTime(_deadline ?? now.add(const Duration(days: 1))));
        break;
        
      case TimeInputStyle.scroll:
      default:
        // 使用上下滚动样式
        time = await _showScrollTimeInput(context, widget.task.taskType == TaskType.daily 
            ? (_deadline != null ? TimeOfDay.fromDateTime(_deadline!) : const TimeOfDay(hour: 23, minute: 0))
            : TimeOfDay.fromDateTime(_deadline ?? now.add(const Duration(days: 1))));
        break;
    }
    
    if (time == null) return;
    
    setState(() {
      _startTime = DateTime(
        date.year,
        date.month,
        date.day,
        time!.hour,
        time.minute,
      );
    });
  }

  Future<void> _selectDeadline(BuildContext context) async {
    final todoProvider = context.read<TodoProvider>();
    final timeInputStyle = todoProvider.settings.timeInputStyle;
    
    final now = DateTime.now();
    final isDailyTask = widget.task.taskType == TaskType.daily;
    
    DateTime? date;
    
    if (isDailyTask) {
      // 每日待办任务：只能选择当天的时间，不显示日期选择器
      date = DateTime(now.year, now.month, now.day);
    } else {
      // 普通任务：可以选择任意日期
      final initialDate = _deadline ?? now.add(const Duration(days: 1));
      
      date = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: now,
        lastDate: now.add(const Duration(days: 365)),
        initialEntryMode: DatePickerEntryMode.calendarOnly,
        helpText: '选择日期',
      );
      
      if (date == null) return;
    }
    
    if (!mounted) return;
    
    TimeOfDay? time;
    
    switch (timeInputStyle) {
      case TimeInputStyle.dial:
        // 使用系统默认的拨动指针样式
        time = await showTimePicker(
          context: context,
          initialTime: widget.task.taskType == TaskType.daily 
              ? (_deadline != null ? TimeOfDay.fromDateTime(_deadline!) : const TimeOfDay(hour: 23, minute: 0))
              : TimeOfDay.fromDateTime(_deadline ?? now.add(const Duration(days: 1))),
          helpText: widget.task.taskType == TaskType.daily ? '选择当天截止时间' : '选择时间',
        );
        break;
        
      case TimeInputStyle.manual:
        // 使用手动填写样式
        time = await _showManualTimeInput(context, widget.task.taskType == TaskType.daily 
            ? (_deadline != null ? TimeOfDay.fromDateTime(_deadline!) : const TimeOfDay(hour: 23, minute: 0))
            : TimeOfDay.fromDateTime(_deadline ?? now.add(const Duration(days: 1))));
        break;
        
      case TimeInputStyle.scroll:
      default:
        // 使用上下滚动样式
        time = await _showScrollTimeInput(context, widget.task.taskType == TaskType.daily 
            ? (_deadline != null ? TimeOfDay.fromDateTime(_deadline!) : const TimeOfDay(hour: 23, minute: 0))
            : TimeOfDay.fromDateTime(_deadline ?? now.add(const Duration(days: 1))));
        break;
    }
    
    if (time == null) return;
    
    setState(() {
      _deadline = DateTime(
        date!.year,
        date!.month,
        date!.day,
        time!.hour,
        time.minute,
      );
    });
  }

  Future<void> _selectCustomDuration(BuildContext context) async {
    int hours = _estimatedDuration?.inHours ?? 1; // 默认1小时
    int minutes = (_estimatedDuration?.inMinutes ?? 0) % 60; // 确保分钟在0-59之间
    
    // 确保小时在1-100范围内
    hours = hours.clamp(1, 100);
    
    final result = await showDialog<Duration>(
      context: context,
      builder: (context) => _DurationPickerDialog(
        initialHours: hours,
        initialMinutes: minutes,
      ),
    );
    
    if (result != null) {
      setState(() {
        _estimatedDuration = result;
      });
    }
  }

  void _saveTimeSettings() {
    final todoProvider = context.read<TodoProvider>();
    
    todoProvider.updateTaskTime(
      widget.task.id,
      startTime: _startTime,
      estimatedDuration: _estimatedDuration,
      deadline: _deadline,
    );
    
    widget.onSaved?.call();
    Navigator.of(context).pop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('时间设置已保存')),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    String dateStr;
    if (date == today) {
      dateStr = '今天';
    } else if (date == tomorrow) {
      dateStr = '明天';
    } else {
      dateStr = '${dateTime.month}月${dateTime.day}日';
    }
    
    final timeStr = '${dateTime.hour.toString().padLeft(2, '0')}:'
                   '${dateTime.minute.toString().padLeft(2, '0')}';
    
    return '$dateStr $timeStr';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}小时${minutes > 0 ? '${minutes}分钟' : ''}';
    } else {
      return '${minutes}分钟';
    }
  }
  
  /// 显示手动填写时间输入对话框
  Future<TimeOfDay?> _showManualTimeInput(BuildContext context, TimeOfDay initialTime) async {
    return showDialog<TimeOfDay>(
      context: context,
      builder: (context) => ManualTimeInputDialog(initialTime: initialTime),
    );
  }

  /// 显示上下滚动时间选择对话框
  Future<TimeOfDay?> _showScrollTimeInput(BuildContext context, TimeOfDay initialTime) async {
    return showDialog<TimeOfDay>(
      context: context,
      builder: (context) => _ScrollTimePickerDialog(initialTime: initialTime),
    );
  }
}

/// 自定义时长选择对话框
class _DurationPickerDialog extends StatefulWidget {
  final int initialHours;
  final int initialMinutes;

  const _DurationPickerDialog({
    required this.initialHours,
    required this.initialMinutes,
  });

  @override
  State<_DurationPickerDialog> createState() => _DurationPickerDialogState();
}

class _DurationPickerDialogState extends State<_DurationPickerDialog> {
  late int _hours;
  late int _minutes;

  @override
  void initState() {
    super.initState();
    _hours = widget.initialHours;
    _minutes = widget.initialMinutes;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('设置预计时长'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 添加番茄钟提示
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '点击"开始任务"时，预计时长将作为番茄钟的倒计时时长',
                    style: TextStyle(fontSize: 13, color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 小时选择 (1-100小时)
              Column(
                children: [
                  const Text('小时'),
                  const SizedBox(height: 8),
                  Container(
                    width: 80,
                    height: 120,
                    child: ListWheelScrollView.useDelegate(
                      itemExtent: 40,
                      perspective: 0.005,
                      diameterRatio: 1.2,
                      physics: const FixedExtentScrollPhysics(),
                      controller: FixedExtentScrollController(initialItem: _hours - 1),
                      onSelectedItemChanged: (index) {
                        setState(() => _hours = index + 1); // 1-100小时
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: 100, // 1-100小时
                        builder: (context, index) {
                          final hourValue = index + 1; // 1-100
                          return Center(
                            child: Text(
                              hourValue.toString(),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: hourValue == _hours 
                                  ? FontWeight.bold 
                                  : FontWeight.normal,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              
              // 分钟选择 (0-60分钟，分度为1)
              Column(
                children: [
                  const Text('分钟'),
                  const SizedBox(height: 8),
                  Container(
                    width: 80,
                    height: 120,
                    child: ListWheelScrollView.useDelegate(
                      itemExtent: 40,
                      perspective: 0.005,
                      diameterRatio: 1.2,
                      physics: const FixedExtentScrollPhysics(),
                      controller: FixedExtentScrollController(initialItem: _minutes),
                      onSelectedItemChanged: (index) {
                        setState(() => _minutes = index); // 0-60分钟
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: 61, // 0-60分钟
                        builder: (context, index) {
                          return Center(
                            child: Text(
                              index.toString(),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: index == _minutes 
                                  ? FontWeight.bold 
                                  : FontWeight.normal,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            // 确保至少有1分钟
            final totalMinutes = _hours * 60 + _minutes;
            if (totalMinutes < 1) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('预计时长至少需要1分钟')),
              );
              return;
            }
            final duration = Duration(hours: _hours, minutes: _minutes);
            Navigator.of(context).pop(duration);
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}

/// 上下滚动时间选择对话框
class _ScrollTimePickerDialog extends StatefulWidget {
  final TimeOfDay initialTime;

  const _ScrollTimePickerDialog({
    required this.initialTime,
  });

  @override
  State<_ScrollTimePickerDialog> createState() => _ScrollTimePickerDialogState();
}

class _ScrollTimePickerDialogState extends State<_ScrollTimePickerDialog> {
  late int _selectedHour;
  late int _selectedMinute;

  @override
  void initState() {
    super.initState();
    _selectedHour = widget.initialTime.hour;
    _selectedMinute = widget.initialTime.minute;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择时间'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 小时选择
              Column(
                children: [
                  const Text('小时'),
                  const SizedBox(height: 8),
                  Container(
                    width: 80,
                    height: 120,
                    child: ListWheelScrollView.useDelegate(
                      itemExtent: 40,
                      perspective: 0.005,
                      diameterRatio: 1.2,
                      physics: const FixedExtentScrollPhysics(),
                      controller: FixedExtentScrollController(initialItem: _selectedHour),
                      onSelectedItemChanged: (index) {
                        setState(() => _selectedHour = index);
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: 24,
                        builder: (context, index) {
                          return Center(
                            child: Text(
                              index.toString().padLeft(2, '0'),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: index == _selectedHour 
                                  ? FontWeight.bold 
                                  : FontWeight.normal,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              
              const Text(':', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              
              // 分钟选择
              Column(
                children: [
                  const Text('分钟'),
                  const SizedBox(height: 8),
                  Container(
                    width: 80,
                    height: 120,
                    child: ListWheelScrollView.useDelegate(
                      itemExtent: 40,
                      perspective: 0.005,
                      diameterRatio: 1.2,
                      physics: const FixedExtentScrollPhysics(),
                      controller: FixedExtentScrollController(initialItem: _selectedMinute),
                      onSelectedItemChanged: (index) {
                        setState(() => _selectedMinute = index);
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: 60,
                        builder: (context, index) {
                          return Center(
                            child: Text(
                              index.toString().padLeft(2, '0'),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: index == _selectedMinute 
                                  ? FontWeight.bold 
                                  : FontWeight.normal,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            final time = TimeOfDay(hour: _selectedHour, minute: _selectedMinute);
            Navigator.of(context).pop(time);
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}
