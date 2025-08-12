import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/todo_provider.dart';
import '../widgets/hierarchical_todo_item.dart';
import '../widgets/task_time_editor.dart';
import '../widgets/add_todo_dialog.dart';
import '../widgets/quadrant_view.dart';
import '../models/todo_item.dart';
import '../../procrastination/procrastination_record_screen.dart';
import '../../../core/utils/overlay_manager.dart';
import '../../procrastination/procrastination_diary_screen.dart';
import '../../../core/utils/keyboard_utils.dart';
import '../../pomodoro/providers/pomodoro_provider.dart';
import '../../pomodoro/screens/pomodoro_immersive_screen.dart';
import '../../pomodoro/models/pomodoro_mode.dart';

/// 视图模式枚举
enum ViewMode {
  list,      // 列表视图
  quadrant,  // 四象限视图
}

/// 待办事项页面 - 集成番茄钟功能和四象限管理
class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final TextEditingController _todoController = TextEditingController();
  ViewMode _currentViewMode = ViewMode.list; // 当前视图模式

  @override
  void initState() {
    super.initState();
    // 延迟检查拖延任务，等待页面渲染完成
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForDelayedTasks();
    });
  }

  @override
  void dispose() {
    _todoController.dispose();
    super.dispose();
  }
  
  /// 切换视图模式
  void _toggleViewMode() {
    setState(() {
      _currentViewMode = _currentViewMode == ViewMode.list 
          ? ViewMode.quadrant 
          : ViewMode.list;
    });
  }

  /// 检查是否有拖延任务需要填写拖延日记
  void _checkForDelayedTasks() {
    final todoProvider = context.read<TodoProvider>();
    if (todoProvider.hasDelayedTasksNeedingDiary()) {
      _showProcrastinationDiaryDialog();
    }
  }
  
  /// 显示拖延日记填写对话框
  void _showProcrastinationDiaryDialog() {
    final todoProvider = context.read<TodoProvider>();
    final delayedTasks = todoProvider.getTasksNeedingProcrastinationDiary();
    
    if (delayedTasks.isEmpty) return;
    
    // 只处理第一个拖延任务
    final task = delayedTasks.first;
    
    context.showSafeDialog<void>(
      keyPrefix: 'procrastination_diary',
      barrierDismissible: false, // 强制填写
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('拖延反思'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('任务「${task.text}」未在计划时间内完成'),
            const SizedBox(height: 8),
            const Text('请填写拖延原因，帮助你更好地管理时间：'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _navigateToProcrastinationDiary();
            },
            child: const Text('去填写'),
          ),
          ElevatedButton(
            onPressed: () {
              // 标记为已处理，但不填写日记
              todoProvider.markProcrastinationDiaryCompleted(task.id);
              Navigator.of(dialogContext).pop();
            },
            child: const Text('跳过'),
          ),
        ],
      ),
    );
  }

  void _addTodo({TaskType taskType = TaskType.today, int? dailyDuration}) {
    final text = _todoController.text.trim();
    if (text.isEmpty) return;

    final todoProvider = context.read<TodoProvider>();
    if (taskType == TaskType.daily && dailyDuration != null) {
      todoProvider.createDailyTask(text, dailyDuration);
    } else {
      todoProvider.addTodo(text);
    }
    _todoController.clear();
  }

  void _showAddTodoDialog() {
    context.showSafeDialog<void>(
      keyPrefix: 'add_todo',
      barrierDismissible: true,
      builder: (BuildContext dialogContext) => const AddTodoDialog(),
    );
  }

  void _navigateToProcrastinationDiary() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProcrastinationDiaryScreen(),
      ),
    );
  }
  
  void _showEditTodoDialog(TodoItem todo) {
    // 使用唯一的key避免GlobalKey重复
    final dialogKey = 'edit_todo_${todo.id}_${DateTime.now().millisecondsSinceEpoch}';
    
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        // 在对话框内部创建和管理TextEditingController
        return _EditTodoDialog(
          key: ValueKey(dialogKey),
          todo: todo,
          onSave: (newText) {
            if (newText.isNotEmpty && mounted) {
              try {
                final todoProvider = context.read<TodoProvider>();
                todoProvider.editTodo(todo.id, newText);
                debugPrint('✅ 任务编辑成功: ${todo.text} -> $newText');
              } catch (e) {
                debugPrint('❌ 保存编辑任务失败: $e');
              }
            }
          },
        );
      },
    );
  }
  


  void _showTimeManagementDialog(TodoItem todo) {
    context.showSafeDialog<void>(
      keyPrefix: 'time_management_${todo.id}',
      barrierDismissible: true,
      builder: (BuildContext dialogContext) => Dialog(
        child: TaskTimeEditor(
          task: todo,
          onSaved: () {
            // 刷新界面以显示更新的时间信息
            setState(() {});
          },
        ),
      ),
    );
  }

  /// 为指定任务开始番茄钟计时
  void _startPomodoroForTask(TodoItem task) {
    final pomodoroProvider = context.read<PomodoroProvider>();
    
    // 根据任务的预计时间设置番茄钟时长
    if (task.estimatedDuration != null && task.estimatedDuration!.inMinutes > 0) {
      // 如果任务有预计时间，使用预计时间作为番茄钟时长
      pomodoroProvider.setCustomDuration(PomodoroMode.pomodoro, task.estimatedDuration!.inMinutes);
    }
    // 如果没有预计时间，使用用户当前的番茄钟设置（正计时或倒计时）
    
    // 导航到番茄钟沉浸式界面
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PomodoroImmersiveScreen(),
      ),
    );
    
    // 开始计时
    pomodoroProvider.startTimer();
    
    // 显示提示信息
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已为任务「${task.text}」开始番茄钟计时'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showDeleteConfirmDialog(TodoItem todo) {
    final isCompleted = todo.completed;
    final taskTitle = todo.text;
    
    context.showSafeDialog<void>(
      keyPrefix: 'delete_confirm_${todo.id}',
      barrierDismissible: true,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('删除任务'),
        content: Text(
          isCompleted 
              ? '确定要删除已完成的任务“$taskTitle”吗？'
              : '任务“$taskTitle”还未完成，确定要删除吗？',
        ),
        actions: [
          if (!isCompleted) ...[
            // 第一行：取消 和 直接删除
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('取消'),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      Navigator.of(dialogContext).pop();
                      // 直接删除任务
                      final todoProvider = context.read<TodoProvider>();
                      todoProvider.deleteTodo(todo.id);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('直接删除'),
                  ),
                ),
              ],
            ),
            // 第二行：记录拖延原因
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  // 跳转到拖延记录页面
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (context) => ProcrastinationRecordScreen(
                        taskTitle: taskTitle,
                      ),
                    ),
                  );
                  
                  // 如果成功记录了拖延原因，则删除任务
                  if (result == true && context.mounted) {
                    final todoProvider = context.read<TodoProvider>();
                    todoProvider.deleteTodo(todo.id);
                    // 移除底部通知，保持界面简洁
                  }
                },
                style: TextButton.styleFrom(
                  backgroundColor: Theme.of(dialogContext).colorScheme.primaryContainer,
                  foregroundColor: Theme.of(dialogContext).colorScheme.onPrimaryContainer,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  '记录拖延原因',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ] else ...[
            // 已完成任务的删除按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('取消'),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      final todoProvider = context.read<TodoProvider>();
                      todoProvider.deleteTodo(todo.id);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('确认删除'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentViewMode == ViewMode.list ? '待办事项' : '四象限管理'),
        elevation: 0,
        leading: IconButton(
          onPressed: _toggleViewMode,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              _currentViewMode == ViewMode.list 
                  ? Icons.grid_view 
                  : Icons.list,
              key: ValueKey(_currentViewMode),
            ),
          ),
          tooltip: _currentViewMode == ViewMode.list ? '切换到四象限视图' : '切换到列表视图',
        ),
        actions: [
          if (_currentViewMode == ViewMode.list)
            IconButton(
              onPressed: _navigateToProcrastinationDiary,
              icon: const Icon(Icons.book),
              tooltip: '拖延日记',
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _currentViewMode == ViewMode.list 
            ? _buildListView(theme)
            : _buildQuadrantView(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTodoDialog,
        tooltip: '添加待办事项',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 构建列表视图
  Widget _buildListView(ThemeData theme) {
    return Column(
      key: const ValueKey('list_view'),
      children: [
        // 待办事项列表
        Expanded(
          child: Consumer<TodoProvider>(
            builder: (context, todoProvider, child) {
              final mainTasks = todoProvider.mainTasks;
              
              if (mainTasks.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.checklist_outlined,
                        size: 64,
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '暂无待办事项',
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '点击右下角按钮添加第一个待办事项',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ReorderableListView.builder(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: 88, // 添加底部间距，避免被浮动按钮遮挡
                ),
                itemCount: mainTasks.length,
                onReorder: (oldIndex, newIndex) {
                  // 调整newIndex，因为ReorderableListView的特殊处理
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  todoProvider.reorderMainTasks(oldIndex, newIndex);
                },
                itemBuilder: (context, index) {
                  final mainTask = mainTasks[index];
                  final subtasks = todoProvider.getSubtasks(mainTask.id);
                  
                  return HierarchicalTodoItem(
                    key: ValueKey('main_task_${mainTask.id}_${mainTask.completed}_${mainTask.isExpanded}'),
                    mainTask: mainTask,
                    subtasks: subtasks,
                    onToggleCompleted: () {
                      debugPrint('🔄 点击主任务: ${mainTask.id} (${mainTask.text}) - 当前状态: ${mainTask.completed}');
                      todoProvider.toggleTodo(mainTask.id);
                    },
                    onToggleExpansion: () {
                      try {
                        debugPrint('📜 切换展开状态: ${mainTask.id} (${mainTask.text}) - 当前展开: ${mainTask.isExpanded}');
                        
                        // 检查任务是否为空或无效
                        if (mainTask.id.isEmpty) {
                          debugPrint('❌ 任务ID为空，无法切换展开状态');
                          return;
                        }
                        
                        // 检查是否为主任务
                        if (mainTask.level != 1) {
                          debugPrint('❌ 只有主任务可以切换展开状态，当前任务级别: ${mainTask.level}');
                          return;
                        }
                        
                        // 检查是否有子任务
                        if (mainTask.subtaskIds.isEmpty) {
                          debugPrint('❌ 任务没有子任务，无法切换展开状态');
                          return;
                        }
                        
                        todoProvider.toggleTaskExpansion(mainTask.id);
                        debugPrint('✅ 展开状态切换成功');
                      } catch (e) {
                        debugPrint('❌ 切换展开状态失败: $e');
                      }
                    },
                    onEdit: () => _showEditTodoDialog(mainTask),
                    onDelete: () => _showDeleteConfirmDialog(mainTask),
                    onTimeManage: () => _showTimeManagementDialog(mainTask),
                    onStartTask: () => _startPomodoroForTask(mainTask),
                    onSubtaskToggle: (subtaskId) {
                      debugPrint('🔄 点击子任务: $subtaskId');
                      todoProvider.toggleTodo(subtaskId);
                    },
                    onSubtaskDelete: (subtaskId) {
                      debugPrint('🗑️ 删除子任务: $subtaskId');
                      todoProvider.deleteTodo(subtaskId);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// 构建四象限视图
  Widget _buildQuadrantView() {
    return const QuadrantView(
      key: ValueKey('quadrant_view'),
    );
  }
}

/// 独立的编辑任务对话框组件 - 确保正确的生命周期管理
class _EditTodoDialog extends StatefulWidget {
  final TodoItem todo;
  final Function(String) onSave;

  const _EditTodoDialog({
    required Key key,
    required this.todo,
    required this.onSave,
  }) : super(key: key);

  @override
  State<_EditTodoDialog> createState() => _EditTodoDialogState();
}

class _EditTodoDialogState extends State<_EditTodoDialog> {
  late TextEditingController _editController;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.todo.text);
    debugPrint('📝 创建编辑对话框: ${widget.todo.id}');
  }

  @override
  void dispose() {
    if (!_isDisposed) {
      _isDisposed = true;
      try {
        _editController.dispose();
        debugPrint('📝 释放编辑对话框: ${widget.todo.id}');
      } catch (e) {
        debugPrint('⚠️ TextEditingController 释放异常: $e');
      }
    }
    super.dispose();
  }

  void _saveAndClose() {
    if (!_isDisposed && mounted) {
      final newText = _editController.text.trim();
      if (newText.isNotEmpty) {
        widget.onSave(newText);
      }
      Navigator.of(context).pop();
    }
  }

  void _cancelAndClose() {
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑任务'),
      content: TextField(
        controller: _editController,
        decoration: const InputDecoration(
          hintText: '输入任务内容...',
          hintStyle: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
          border: OutlineInputBorder(),
        ),
        autofocus: true,
        maxLines: null,
        onSubmitted: (_) => _saveAndClose(),
      ),
      actions: [
        TextButton(
          onPressed: _cancelAndClose,
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _saveAndClose,
          child: const Text('保存'),
        ),
      ],
    );
  }
}
