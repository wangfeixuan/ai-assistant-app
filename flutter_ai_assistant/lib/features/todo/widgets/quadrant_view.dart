import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/todo_item.dart';
import '../providers/todo_provider.dart';
import 'hierarchical_todo_item.dart';

/// 四象限任务管理视图
class QuadrantView extends StatefulWidget {
  const QuadrantView({super.key});

  @override
  State<QuadrantView> createState() => _QuadrantViewState();
}

class _QuadrantViewState extends State<QuadrantView> {
  
  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, todoProvider, child) {
        final tasks = todoProvider.mainTasks;
        
        // 按四象限分类任务
        final Map<QuadrantType, List<TodoItem>> quadrantTasks = {
          QuadrantType.importantUrgent: [],
          QuadrantType.importantNotUrgent: [],
          QuadrantType.notImportantUrgent: [],
          QuadrantType.notImportantNotUrgent: [],
        };
        
        for (final task in tasks) {
          quadrantTasks[task.quadrantType]!.add(task);
        }
        
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 上半部分：重要且紧急 | 重要不紧急
              Expanded(
                child: Row(
                  children: [
                    // 重要且紧急
                    Expanded(
                      child: _buildQuadrant(
                        context,
                        QuadrantType.importantUrgent,
                        quadrantTasks[QuadrantType.importantUrgent]!,
                        todoProvider,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 重要不紧急
                    Expanded(
                      child: _buildQuadrant(
                        context,
                        QuadrantType.importantNotUrgent,
                        quadrantTasks[QuadrantType.importantNotUrgent]!,
                        todoProvider,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // 下半部分：不重要但紧急 | 不重要不紧急
              Expanded(
                child: Row(
                  children: [
                    // 不重要但紧急
                    Expanded(
                      child: _buildQuadrant(
                        context,
                        QuadrantType.notImportantUrgent,
                        quadrantTasks[QuadrantType.notImportantUrgent]!,
                        todoProvider,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 不重要不紧急
                    Expanded(
                      child: _buildQuadrant(
                        context,
                        QuadrantType.notImportantNotUrgent,
                        quadrantTasks[QuadrantType.notImportantNotUrgent]!,
                        todoProvider,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建单个象限
  Widget _buildQuadrant(
    BuildContext context,
    QuadrantType quadrantType,
    List<TodoItem> tasks,
    TodoProvider todoProvider,
  ) {
    final quadrantInfo = _getQuadrantInfo(quadrantType);
    
    return DragTarget<TodoItem>(
      onAccept: (task) {
        _moveTaskToQuadrant(task, quadrantType, todoProvider);
      },
      builder: (context, candidateData, rejectedData) {
        final isHighlighted = candidateData.isNotEmpty;
        
        return Container(
          decoration: BoxDecoration(
            color: isHighlighted 
                ? quadrantInfo.color.withOpacity(0.3)
                : quadrantInfo.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHighlighted 
                  ? quadrantInfo.borderColor.withOpacity(0.8)
                  : quadrantInfo.borderColor.withOpacity(0.3),
              width: isHighlighted ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              // 象限标题
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: quadrantInfo.headerColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      quadrantInfo.icon,
                      size: 16,
                      color: quadrantInfo.iconColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        quadrantInfo.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: quadrantInfo.textColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${tasks.length}',
                      style: TextStyle(
                        fontSize: 11,
                        color: quadrantInfo.textColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              // 任务列表
              Expanded(
                child: tasks.isEmpty
                    ? Center(
                        child: Text(
                          '没有任务',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return _buildDraggableTask(task, todoProvider);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建可拖拽的任务项
  Widget _buildDraggableTask(TodoItem task, TodoProvider todoProvider) {
    return Draggable<TodoItem>(
      data: task,
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            task.text,
            style: const TextStyle(fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      childWhenDragging: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          task.text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        child: _buildCompactTaskItem(task, todoProvider),
      ),
    );
  }

  /// 构建紧凑的任务项
  Widget _buildCompactTaskItem(TodoItem task, TodoProvider todoProvider) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 任务标题和完成状态
          Row(
            children: [
              GestureDetector(
                onTap: () => todoProvider.toggleTodo(task.id),
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: task.completed ? Colors.green : Colors.grey.shade400,
                      width: 2,
                    ),
                    color: task.completed ? Colors.green : Colors.transparent,
                  ),
                  child: task.completed
                      ? const Icon(
                          Icons.check,
                          size: 10,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.text,
                  style: TextStyle(
                    fontSize: 12,
                    decoration: task.completed ? TextDecoration.lineThrough : null,
                    color: task.completed ? Colors.grey : Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          // 任务信息
          if (task.deadline != null || task.subtaskIds.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                if (task.deadline != null) ...[
                  Icon(
                    Icons.schedule,
                    size: 10,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    _formatDeadline(task.deadline!),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
                if (task.subtaskIds.isNotEmpty) ...[
                  if (task.deadline != null) const SizedBox(width: 8),
                  Icon(
                    Icons.list,
                    size: 10,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${task.subtaskIds.length}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 移动任务到指定象限
  void _moveTaskToQuadrant(TodoItem task, QuadrantType targetQuadrant, TodoProvider todoProvider) {
    bool newImportant = false;
    bool newUrgent = false;
    
    switch (targetQuadrant) {
      case QuadrantType.importantUrgent:
        newImportant = true;
        newUrgent = true;
        break;
      case QuadrantType.importantNotUrgent:
        newImportant = true;
        newUrgent = false;
        break;
      case QuadrantType.notImportantUrgent:
        newImportant = false;
        newUrgent = true;
        break;
      case QuadrantType.notImportantNotUrgent:
        newImportant = false;
        newUrgent = false;
        break;
    }
    
    // 更新任务的重要性和紧急性
    final updatedTask = task.copyWith(
      isPriority: newImportant,
      isUrgent: newUrgent,
    );
    
    todoProvider.updateTodo(updatedTask);
    
    // 显示提示信息
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('任务「${task.text}」已移动到「${_getQuadrantInfo(targetQuadrant).title}」'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 获取象限信息
  QuadrantInfo _getQuadrantInfo(QuadrantType quadrantType) {
    switch (quadrantType) {
      case QuadrantType.importantUrgent:
        return QuadrantInfo(
          title: '重要且紧急',
          color: Colors.red.shade50,
          headerColor: Colors.red.shade100,
          borderColor: Colors.red.shade300,
          textColor: Colors.red.shade800,
          iconColor: Colors.red.shade700,
          icon: Icons.warning,
        );
      case QuadrantType.importantNotUrgent:
        return QuadrantInfo(
          title: '重要不紧急',
          color: Colors.orange.shade50,
          headerColor: Colors.orange.shade100,
          borderColor: Colors.orange.shade300,
          textColor: Colors.orange.shade800,
          iconColor: Colors.orange.shade700,
          icon: Icons.star,
        );
      case QuadrantType.notImportantUrgent:
        return QuadrantInfo(
          title: '不重要但紧急',
          color: Colors.blue.shade50,
          headerColor: Colors.blue.shade100,
          borderColor: Colors.blue.shade300,
          textColor: Colors.blue.shade800,
          iconColor: Colors.blue.shade700,
          icon: Icons.schedule,
        );
      case QuadrantType.notImportantNotUrgent:
        return QuadrantInfo(
          title: '不重要不紧急',
          color: Colors.green.shade50,
          headerColor: Colors.green.shade100,
          borderColor: Colors.green.shade300,
          textColor: Colors.green.shade800,
          iconColor: Colors.green.shade700,
          icon: Icons.low_priority,
        );
    }
  }

  /// 格式化截止时间
  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}天';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟';
    } else {
      return '已过期';
    }
  }
}

/// 象限信息类
class QuadrantInfo {
  final String title;
  final Color color;
  final Color headerColor;
  final Color borderColor;
  final Color textColor;
  final Color iconColor;
  final IconData icon;

  QuadrantInfo({
    required this.title,
    required this.color,
    required this.headerColor,
    required this.borderColor,
    required this.textColor,
    required this.iconColor,
    required this.icon,
  });
}
