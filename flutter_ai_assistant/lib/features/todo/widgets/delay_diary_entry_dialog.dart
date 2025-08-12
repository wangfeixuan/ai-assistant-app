import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/delay_diary.dart';
import '../providers/todo_provider.dart';

/// 拖延日记条目编辑对话框
class DelayDiaryEntryDialog extends StatefulWidget {
  final String taskId;
  final String taskName;
  final DelayDiaryEntry? existingEntry;

  const DelayDiaryEntryDialog({
    super.key,
    required this.taskId,
    required this.taskName,
    this.existingEntry,
  });

  @override
  State<DelayDiaryEntryDialog> createState() => _DelayDiaryEntryDialogState();
}

class _DelayDiaryEntryDialogState extends State<DelayDiaryEntryDialog> {
  late TextEditingController _customReasonController;
  late TextEditingController _reflectionController;
  
  String _primaryReason = '';
  String _secondaryReason = '';
  DelayLevel _delayLevel = DelayLevel.light;
  int _delayDays = 1;
  
  // 预定义的拖延原因
  final List<String> _predefinedReasons = [
    '任务太困难',
    '缺乏动力',
    '时间不够',
    '分心娱乐',
    '完美主义',
    '害怕失败',
    '任务不清晰',
    '缺乏技能',
    '环境干扰',
    '身体疲惫',
    '情绪低落',
  ];

  @override
  void initState() {
    super.initState();
    _customReasonController = TextEditingController();
    _reflectionController = TextEditingController();
    
    if (widget.existingEntry != null) {
      final entry = widget.existingEntry!;
      _primaryReason = entry.primaryReason;
      _secondaryReason = entry.secondaryReason;
      _customReasonController.text = entry.customReason;
      _reflectionController.text = entry.reflection;
      _delayLevel = entry.delayLevel;
      _delayDays = entry.delayDays;
    }
  }

  @override
  void dispose() {
    _customReasonController.dispose();
    _reflectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit_note, color: Colors.orange.shade600, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '拖延日记',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.taskName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    color: Colors.orange.shade600,
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
                    _buildDelayDaysSection(),
                    const SizedBox(height: 20),
                    _buildDelayLevelSection(),
                    const SizedBox(height: 20),
                    _buildPrimaryReasonSection(),
                    const SizedBox(height: 20),
                    _buildSecondaryReasonSection(),
                    const SizedBox(height: 20),
                    _buildCustomReasonSection(),
                    const SizedBox(height: 20),
                    _buildReflectionSection(),
                  ],
                ),
              ),
            ),
            
            // 按钮区域
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
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
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveEntry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade400,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('保存'),
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
  
  Widget _buildDelayDaysSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '拖延天数',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _delayDays.toDouble(),
                min: 1,
                max: 30,
                divisions: 29,
                activeColor: Colors.orange.shade400,
                onChanged: (value) {
                  setState(() {
                    _delayDays = value.round();
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Text(
                '$_delayDays 天',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.orange.shade700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildDelayLevelSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '拖延程度',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: DelayLevel.values.map((level) {
            final isSelected = _delayLevel == level;
            Color color;
            String text;
            
            switch (level) {
              case DelayLevel.light:
                color = Colors.green;
                text = '轻度';
                break;
              case DelayLevel.moderate:
                color = Colors.orange;
                text = '中度';
                break;
              case DelayLevel.severe:
                color = Colors.red;
                text = '严重';
                break;
            }
            
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _delayLevel = level;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.2) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? color : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? color.shade700 : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildPrimaryReasonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '主要原因',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _predefinedReasons.map((reason) {
            final isSelected = _primaryReason == reason;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _primaryReason = isSelected ? '' : reason;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue.shade100 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? Colors.blue.shade300 : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  reason,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildSecondaryReasonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '次要原因（可选）',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _predefinedReasons.where((reason) => reason != _primaryReason).map((reason) {
            final isSelected = _secondaryReason == reason;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _secondaryReason = isSelected ? '' : reason;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.green.shade100 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? Colors.green.shade300 : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  reason,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.green.shade700 : Colors.grey.shade600,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildCustomReasonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '其他原因（可选）',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _customReasonController,
          decoration: InputDecoration(
            hintText: '描述其他拖延原因...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.orange.shade400),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          maxLines: 2,
        ),
      ],
    );
  }
  
  Widget _buildReflectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '反思总结（可选）',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _reflectionController,
          decoration: InputDecoration(
            hintText: '写下你的反思和改进计划...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.orange.shade400),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          maxLines: 3,
        ),
      ],
    );
  }
  
  void _saveEntry() {
    if (_primaryReason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择主要拖延原因')),
      );
      return;
    }
    
    final todoProvider = Provider.of<TodoProvider>(context, listen: false);
    
    final entry = DelayDiaryEntry(
      id: widget.existingEntry?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      taskId: widget.taskId,
      taskName: widget.taskName,
      delayDate: widget.existingEntry?.delayDate ?? DateTime.now(),
      delayDays: _delayDays,
      delayLevel: _delayLevel,
      primaryReason: _primaryReason,
      secondaryReason: _secondaryReason,
      customReason: _customReasonController.text.trim(),
      reflection: _reflectionController.text.trim(),
      isResolved: widget.existingEntry?.isResolved ?? false,
      resolvedAt: widget.existingEntry?.resolvedAt,
    );
    
    if (widget.existingEntry != null) {
      todoProvider.updateDelayDiaryEntry(entry);
    } else {
      todoProvider.addDelayDiaryEntry(entry);
    }
    
    Navigator.of(context).pop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.existingEntry != null ? '拖延日记已更新' : '拖延日记已保存'),
        backgroundColor: Colors.orange.shade400,
      ),
    );
  }
}

/// 显示拖延日记条目编辑对话框
Future<DelayDiaryEntry?> showDelayDiaryEntryDialog(
  BuildContext context, {
  required String taskId,
  required String taskName,
  DelayDiaryEntry? existingEntry,
}) {
  return showDialog<DelayDiaryEntry?>(
    context: context,
    barrierDismissible: true,
    useRootNavigator: false,
    builder: (BuildContext dialogContext) => DelayDiaryEntryDialog(
      key: ValueKey('delay_diary_dialog_${taskId}_${DateTime.now().millisecondsSinceEpoch}'),
      taskId: taskId,
      taskName: taskName,
      existingEntry: existingEntry,
    ),
  );
}
