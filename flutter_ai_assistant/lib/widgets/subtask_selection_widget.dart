import 'package:flutter/material.dart';
import '../models/ai_task.dart';

class SubTaskSelectionWidget extends StatefulWidget {
  final List<SubTask> subtasks;
  final Function(List<SubTask>) onSelectionChanged;
  final Function(List<SubTask>) onAddSelected;
  final bool isLoading;

  const SubTaskSelectionWidget({
    Key? key,
    required this.subtasks,
    required this.onSelectionChanged,
    required this.onAddSelected,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<SubTaskSelectionWidget> createState() => _SubTaskSelectionWidgetState();
}

class _SubTaskSelectionWidgetState extends State<SubTaskSelectionWidget> {
  List<SubTask> get selectedTasks => 
      widget.subtasks.where((task) => task.isSelected).toList();

  void _toggleSelection(SubTask task) {
    setState(() {
      task.isSelected = !task.isSelected;
    });
    widget.onSelectionChanged(selectedTasks);
  }

  void _selectAll() {
    setState(() {
      for (var task in widget.subtasks) {
        task.isSelected = true;
      }
    });
    widget.onSelectionChanged(selectedTasks);
  }

  void _selectNone() {
    setState(() {
      for (var task in widget.subtasks) {
        task.isSelected = false;
      }
    });
    widget.onSelectionChanged(selectedTasks);
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Icons.priority_high;
      case 'medium':
        return Icons.remove;
      case 'low':
        return Icons.keyboard_arrow_down;
      default:
        return Icons.remove;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题和操作按钮
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '拆分的子任务 (${widget.subtasks.length}个)',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: _selectAll,
                  child: const Text('全选'),
                ),
                TextButton(
                  onPressed: _selectNone,
                  child: const Text('全不选'),
                ),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // 子任务列表
        ...widget.subtasks.map((task) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: CheckboxListTile(
            value: task.isSelected,
            onChanged: (bool? value) => _toggleSelection(task),
            title: Text(
              task.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  task.description,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // 优先级标签
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(task.priority).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getPriorityColor(task.priority).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getPriorityIcon(task.priority),
                            size: 14,
                            color: _getPriorityColor(task.priority),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            task.priorityText,
                            style: TextStyle(
                              fontSize: 12,
                              color: _getPriorityColor(task.priority),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // 分类标签
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        task.category,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // 预估时间
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          task.estimatedTime,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            isThreeLine: true,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        )),
        
        const SizedBox(height: 16),
        
        // 选择统计和添加按钮
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '已选择 ${selectedTasks.length} / ${widget.subtasks.length} 个任务',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 16), // 添加明确的间距
              ElevatedButton.icon(
                onPressed: selectedTasks.isNotEmpty && !widget.isLoading
                    ? () => widget.onAddSelected(selectedTasks)
                    : null,
                icon: widget.isLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_task, size: 16),
                label: Text(
                  widget.isLoading ? '添加中...' : '添加到待办',
                  style: const TextStyle(fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
        
        // 提示信息
        if (selectedTasks.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              '💡 请选择要添加到待办列表的子任务',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
