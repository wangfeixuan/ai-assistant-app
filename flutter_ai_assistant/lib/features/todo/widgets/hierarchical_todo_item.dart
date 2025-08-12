import 'package:flutter/material.dart';
import '../models/todo_item.dart';

/// 多级任务展示组件
/// 支持主任务和子任务的层级显示，可展开/折叠
class HierarchicalTodoItem extends StatelessWidget {
  final TodoItem mainTask;
  final List<TodoItem> subtasks;
  final VoidCallback? onToggleCompleted;
  final VoidCallback? onToggleExpansion;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTimeManage;
  final VoidCallback? onStartTask; // 新增：开始任务回调
  final Function(String)? onSubtaskToggle;
  final Function(String)? onSubtaskDelete;

  const HierarchicalTodoItem({
    super.key,
    required this.mainTask,
    required this.subtasks,
    this.onToggleCompleted,
    this.onToggleExpansion,
    this.onEdit,
    this.onDelete,
    this.onTimeManage,
    this.onStartTask, // 新增：开始任务回调
    this.onSubtaskToggle,
    this.onSubtaskDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _calculateProgress();
    final isPriority = mainTask.isPriority;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // 主任务
            _buildMainTaskTile(context, theme, progress),
            
            // 子任务列表（展开时显示）
            if (mainTask.isExpanded && subtasks.isNotEmpty)
              _buildSafeSubtasksList(context, theme),
          ],
        ),
      ),
    );
  }

  /// 构建主任务磁贴
  Widget _buildMainTaskTile(BuildContext context, ThemeData theme, double progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 主任务内容行
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 完成状态复选框
              GestureDetector(
                onTap: () => onToggleCompleted?.call(),
                child: Checkbox(
                  value: mainTask.completed,
                  onChanged: (_) => onToggleCompleted?.call(),
                ),
              ),
              const SizedBox(width: 12),
              
              // 任务内容和信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 任务文本
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            mainTask.text,
                            style: TextStyle(
                              decoration: mainTask.completed 
                                  ? TextDecoration.lineThrough 
                                  : null,
                              color: mainTask.completed 
                                  ? theme.colorScheme.onSurface.withOpacity(0.6)
                                  : theme.colorScheme.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        // 拖延任务标记（小星星图标）
                        if (mainTask.isDelayed) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Colors.red,
                            ),
                          ),
                        ],
                        // 优先任务标记
                        if (mainTask.isPriority && !mainTask.isDelayed) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: theme.colorScheme.primary.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // 任务信息行
                    Row(
                      children: [
                        // 创建时间
                        Text(
                          _formatDateTime(mainTask.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                        
                        // 任务来源标识
                        if (mainTask.isAiGenerated) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'AI拆分',
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                        
                        // 每日待办次数显示
                        if (mainTask.taskType == TaskType.daily) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '第${mainTask.currentOccurrence ?? 1}次/共${mainTask.totalOccurrences ?? 1}次',
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.secondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                        
                        // 拖延任务日期显示
                        if (mainTask.isDelayed && mainTask.originalDate != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '拖延自${_formatDate(mainTask.originalDate!)}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                        
                        const Spacer(),
                        
                        // 子任务数量
                        if (subtasks.isNotEmpty)
                          Text(
                            '${subtasks.where((s) => s.completed).length}/${subtasks.length}',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    
                    // 时间信息行
                    if (mainTask.startTime != null || mainTask.deadline != null || mainTask.estimatedDuration != null) ...[
                      const SizedBox(height: 6),
                      _buildTimeInfoRow(theme),
                    ],
                    
                    // 进度条（仅当有子任务时显示）
                    if (subtasks.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildProgressBar(theme, progress),
                    ],
                  ],
                ),
              ),
              
              // 更多操作按钮
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'start':
                      onStartTask?.call();
                      break;
                    case 'time':
                      onTimeManage?.call();
                      break;
                    case 'edit':
                      onEdit?.call();
                      break;
                    case 'delete':
                      onDelete?.call();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'start',
                    child: Row(
                      children: [
                        Icon(Icons.play_arrow, size: 20, color: Colors.green),
                        SizedBox(width: 8),
                        Text('开始任务'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'time',
                    child: Row(
                      children: [
                        Icon(Icons.schedule, size: 20),
                        SizedBox(width: 8),
                        Text('时间管理'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 8),
                        Text('编辑'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20),
                        SizedBox(width: 8),
                        Text('删除'),
                      ],
                    ),
                  ),
                ],
                child: const Icon(Icons.more_vert),
              ),
            ],
          ),
          
          // 展开按钮（右下角）
          if (subtasks.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: onToggleExpansion,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          mainTask.isExpanded ? '收起步骤' : '展开步骤',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          mainTask.isExpanded 
                              ? Icons.keyboard_arrow_up 
                              : Icons.keyboard_arrow_down,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 构建时间信息行
  Widget _buildTimeInfoRow(ThemeData theme) {
    final List<Widget> timeChips = [];
    
    // 开始时间
    if (mainTask.startTime != null) {
      final isStarted = DateTime.now().isAfter(mainTask.startTime!);
      timeChips.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isStarted 
                ? Colors.green.withOpacity(0.1) 
                : Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.play_arrow,
                size: 12,
                color: isStarted ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 2),
              Text(
                _formatTimeInfo(mainTask.startTime!),
                style: TextStyle(
                  fontSize: 10,
                  color: isStarted ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // 预计时长
    if (mainTask.estimatedDuration != null) {
      timeChips.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer,
                size: 12,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 2),
              Text(
                _formatDuration(mainTask.estimatedDuration!),
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // 截止时间
    if (mainTask.deadline != null) {
      final isOverdue = mainTask.isOverdue;
      final isUrgent = !isOverdue && DateTime.now().add(const Duration(hours: 24)).isAfter(mainTask.deadline!);
      
      Color chipColor = Colors.blue;
      if (isOverdue) {
        chipColor = Colors.red;
      } else if (isUrgent) {
        chipColor = Colors.orange;
      }
      
      timeChips.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: chipColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isOverdue ? Icons.warning : Icons.flag,
                size: 12,
                color: chipColor,
              ),
              const SizedBox(width: 2),
              Text(
                _formatTimeInfo(mainTask.deadline!),
                style: TextStyle(
                  fontSize: 10,
                  color: chipColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // 每日待办任务标识 - 已移除紫色标签
    // if (mainTask.taskType == TaskType.daily) {
    //   timeChips.add(
    //     Container(
    //       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    //       decoration: BoxDecoration(
    //         color: Colors.purple.withOpacity(0.1),
    //         borderRadius: BorderRadius.circular(6),
    //       ),
    //       child: Row(
    //         mainAxisSize: MainAxisSize.min,
    //         children: [
    //           const Icon(
    //             Icons.repeat,
    //             size: 12,
    //             color: Colors.purple,
    //           ),
    //           const SizedBox(width: 2),
    //           Text(
    //             mainTask.taskTypeDescription,
    //             style: const TextStyle(
    //               fontSize: 10,
    //               color: Colors.purple,
    //               fontWeight: FontWeight.w500,
    //             ),
    //           ),
    //         ],
    //       ),
    //     ),
    //   );
    // }
    
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: timeChips,
    );
  }

  /// 构建进度条
  Widget _buildProgressBar(ThemeData theme, double progress) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: theme.colorScheme.onSurface.withOpacity(0.1),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: progress == 1.0 
                ? Colors.green 
                : theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  /// 安全构建子任务列表 - 使用稳定的key系统
  Widget _buildSafeSubtasksList(BuildContext context, ThemeData theme) {
    try {
      // 检查子任务列表是否有效
      if (subtasks.isEmpty) {
        return const SizedBox.shrink();
      }
      
      // 过滤出有效的子任务并按ID排序，确保稳定性
      final validSubtasks = subtasks
          .where((task) => task.id.isNotEmpty && task.text.isNotEmpty)
          .toList()
        ..sort((a, b) => a.id.compareTo(b.id)); // 按ID排序确保顺序稳定
      
      if (validSubtasks.isEmpty) {
        return const SizedBox.shrink();
      }
      
      // 使用主任务ID作为容器key的基础
      final containerKey = 'subtasks_container_${mainTask.id}';
      
      return Container(
        key: ValueKey(containerKey),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.5),
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.onSurface.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 子任务标题
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.list_alt,
                    size: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '详细步骤',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            
            // 子任务项目 - 使用统一的key系统
            ...validSubtasks.asMap().entries.map((entry) {
              final index = entry.key;
              final subtask = entry.value;
              
              // 创建绝对唯一的key，包含主任务ID、子任务ID和索引
              final uniqueKey = 'safe_${mainTask.id}_${subtask.id}_$index';
              
              return _SubtaskItemWidget(
                key: ValueKey(uniqueKey),
                subtask: subtask,
                stepNumber: index + 1,
                theme: theme,
                onToggle: () {
                  debugPrint('🔄 点击子任务: ${subtask.id} (${subtask.text})');
                  onSubtaskToggle?.call(subtask.id);
                },
                onDelete: onSubtaskDelete != null ? () {
                  debugPrint('🗑️ 删除子任务: ${subtask.id}');
                  onSubtaskDelete?.call(subtask.id);
                } : null,
              );
            }).toList(),
          ],
        ),
      );
    } catch (e) {
      debugPrint('❌ 子任务列表渲染错误: $e');
      return Container(
        padding: const EdgeInsets.all(16),
        child: Text(
          '子任务加载出现问题',
          style: TextStyle(
            color: theme.colorScheme.error,
            fontSize: 12,
          ),
        ),
      );
    }
  }
  



  


  /// 计算完成进度
  double _calculateProgress() {
    if (subtasks.isEmpty) {
      return mainTask.completed ? 1.0 : 0.0;
    }
    
    final completedCount = subtasks.where((subtask) => subtask.completed).length;
    return completedCount / subtasks.length;
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  /// 格式化时间信息（用于开始时间和截止时间）
  String _formatTimeInfo(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (date == today) {
      return '今天 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (date == tomorrow) {
      return '明天 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }

  /// 格式化时长
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0 && minutes > 0) {
      return '${hours}h${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }
  
  /// 格式化日期（用于拖延任务显示）
  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (date == today) {
      return '今天';
    } else if (date == yesterday) {
      return '昨天';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }
}

/// 独立的子任务组件 - 确保稳定的状态管理
class _SubtaskItemWidget extends StatelessWidget {
  final TodoItem subtask;
  final int stepNumber;
  final ThemeData theme;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;

  const _SubtaskItemWidget({
    required Key key,
    required this.subtask,
    required this.stepNumber,
    required this.theme,
    this.onToggle,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.onSurface.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 步骤编号/完成状态
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: subtask.completed 
                    ? Colors.green 
                    : theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: subtask.completed 
                      ? Colors.green 
                      : theme.colorScheme.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Center(
                child: subtask.completed
                    ? const Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.white,
                      )
                    : Text(
                        stepNumber.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // 任务文本
            Expanded(
              child: Text(
                subtask.text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: subtask.completed 
                      ? theme.colorScheme.onSurface.withOpacity(0.6)
                      : theme.colorScheme.onSurface,
                  decoration: subtask.completed 
                      ? TextDecoration.lineThrough 
                      : TextDecoration.none,
                ),
              ),
            ),
            
            // 删除按钮（如果提供了删除回调）
            if (onDelete != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
