import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/todo_item.dart';
import '../providers/todo_provider.dart';

/// 添加待办对话框组件 - 支持选择任务类型
class AddTodoDialog extends StatefulWidget {
  const AddTodoDialog({super.key});

  @override
  State<AddTodoDialog> createState() => _AddTodoDialogState();
}

class _AddTodoDialogState extends State<AddTodoDialog> {
  final TextEditingController _todoController = TextEditingController();
  TaskType _selectedTaskType = TaskType.today;
  int _dailyDuration = 7; // 默认7天

  @override
  void dispose() {
    _todoController.dispose();
    super.dispose();
  }

  void _addTodo() {
    final text = _todoController.text.trim();
    if (text.isEmpty) return;

    final todoProvider = context.read<TodoProvider>();
    if (_selectedTaskType == TaskType.daily) {
      todoProvider.createDailyTask(text, _dailyDuration);
    } else {
      todoProvider.addTodo(text);
    }
    
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 400,
          maxHeight: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.add_task,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '添加待办事项',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            
            // 内容区域
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 任务内容输入
                    TextField(
                      controller: _todoController,
                      decoration: InputDecoration(
                        hintText: '输入待办事项...',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Theme.of(context).primaryColor),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      autofocus: true,
                      onSubmitted: (_) => _addTodo(),
                    ),
                    const SizedBox(height: 24),
                    
                    // 任务类型选择
                    Text(
                      '任务类型',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // 今日待办选项
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _selectedTaskType == TaskType.today 
                              ? Theme.of(context).primaryColor 
                              : Colors.grey[300]!,
                          width: _selectedTaskType == TaskType.today ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: RadioListTile<TaskType>(
                        title: Row(
                          children: [
                            Icon(
                              Icons.today,
                              color: _selectedTaskType == TaskType.today 
                                  ? Theme.of(context).primaryColor 
                                  : Colors.grey[600],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text('今日待办'),
                          ],
                        ),
                        subtitle: const Text('一次性任务，今天完成'),
                        value: TaskType.today,
                        groupValue: _selectedTaskType,
                        onChanged: (value) {
                          setState(() {
                            _selectedTaskType = value!;
                          });
                        },
                        activeColor: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // 每日待办选项
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _selectedTaskType == TaskType.daily 
                              ? Theme.of(context).primaryColor 
                              : Colors.grey[300]!,
                          width: _selectedTaskType == TaskType.daily ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: RadioListTile<TaskType>(
                        title: Row(
                          children: [
                            Icon(
                              Icons.repeat,
                              color: _selectedTaskType == TaskType.daily 
                                  ? Theme.of(context).primaryColor 
                                  : Colors.grey[600],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text('每日待办'),
                          ],
                        ),
                        subtitle: Text('连续${_dailyDuration}天重复任务'),
                        value: TaskType.daily,
                        groupValue: _selectedTaskType,
                        onChanged: (value) {
                          setState(() {
                            _selectedTaskType = value!;
                          });
                        },
                        activeColor: Theme.of(context).primaryColor,
                      ),
                    ),
                    
                    // 持续天数设置（仅当选择每日待办时显示）
                    if (_selectedTaskType == TaskType.daily) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).primaryColor.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: Theme.of(context).primaryColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '持续天数',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    '${_dailyDuration}天',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: Theme.of(context).primaryColor,
                                inactiveTrackColor: Theme.of(context).primaryColor.withOpacity(0.3),
                                thumbColor: Theme.of(context).primaryColor,
                                overlayColor: Theme.of(context).primaryColor.withOpacity(0.2),
                                valueIndicatorColor: Theme.of(context).primaryColor,
                              ),
                              child: Slider(
                                value: _dailyDuration.toDouble(),
                                min: 1,
                                max: 30,
                                divisions: 29,
                                label: '${_dailyDuration}天',
                                onChanged: (value) {
                                  setState(() {
                                    _dailyDuration = value.round();
                                  });
                                },
                              ),
                            ),
                            Text(
                              '系统将在未来${_dailyDuration}天内每天自动生成这个任务',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // 按钮区域
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        '取消',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _addTodo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '添加',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
