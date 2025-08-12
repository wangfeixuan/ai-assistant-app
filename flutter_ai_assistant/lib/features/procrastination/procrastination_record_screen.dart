import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/procrastination_diary.dart';
import '../../services/procrastination_service.dart';
import '../todo/providers/todo_provider.dart';
import '../todo/models/todo_item.dart';
import 'procrastination_analysis_screen.dart';

class ProcrastinationRecordScreen extends StatefulWidget {
  final String taskTitle;
  final int? taskId;

  const ProcrastinationRecordScreen({
    Key? key,
    required this.taskTitle,
    this.taskId,
  }) : super(key: key);

  @override
  State<ProcrastinationRecordScreen> createState() => _ProcrastinationRecordScreenState();
}

class _ProcrastinationRecordScreenState extends State<ProcrastinationRecordScreen> {
  final ProcrastinationService _service = ProcrastinationService();
  final TextEditingController _customReasonController = TextEditingController();
  
  List<ReasonOption> _reasons = [];
  String? _selectedReason;
  int? _moodBefore;
  int? _moodAfter;
  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // 立即加载本地默认选项，避免界面阻塞
    _reasons = ProcrastinationReason.getAllReasons();
    // 后台异步尝试加载服务器数据
    _loadReasonsFromServer();
  }

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  Future<void> _loadReasonsFromServer() async {
    try {
      // 后台尝试从服务器加载原因选项
      final reasons = await _service.getReasons();
      if (mounted) {
        setState(() {
          _reasons = reasons;
        });
      }
    } catch (e) {
      // 服务器加载失败时保持使用本地选项，不显示错误
      print('后台加载服务器拖延原因失败，继续使用本地选项: $e');
    }
  }

  Future<void> _submitRecord() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择拖延原因')),
      );
      return;
    }

    if (_selectedReason == ProcrastinationReason.custom && 
        _customReasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入自定义原因')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // 记录拖延原因并获取AI分析
      final result = await _service.recordProcrastination(
        taskTitle: widget.taskTitle,
        reasonType: _selectedReason!,
        taskId: widget.taskId,
        customReason: _selectedReason == ProcrastinationReason.custom 
            ? _customReasonController.text.trim() 
            : null,
        moodBefore: _moodBefore,
        moodAfter: _moodAfter,
      );

      // 重新创建任务并标记为优先
      final todoProvider = context.read<TodoProvider>();
      final priorityTask = TodoItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: widget.taskTitle,
        createdAt: DateTime.now(),
        isPriority: true,
        isPostponed: true,
        postponeReason: _selectedReason == ProcrastinationReason.custom 
            ? _customReasonController.text.trim()
            : _selectedReason,
      );
      
      todoProvider.addTodoItem(priorityTask);

      if (mounted) {
        setState(() => _isSubmitting = false);
        
        // 显示AI分析结果
        final analysis = result['analysis'] as SingleProcrastinationAnalysis;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProcrastinationAnalysisScreen(
              taskTitle: widget.taskTitle,
              analysis: analysis,
            ),
          ),
        );
        
        // 返回上一页
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }

  Widget _buildMoodSelector(String title, int? currentValue, Function(int?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (index) {
            final mood = index + 1;
            final isSelected = currentValue == mood;
            return GestureDetector(
              onTap: () => onChanged(mood),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Colors.blue : Colors.grey[200],
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey[400]!,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    _getMoodEmoji(mood),
                    style: TextStyle(
                      fontSize: 24,
                      color: isSelected ? Colors.white : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: const [
            Text('😢', style: TextStyle(fontSize: 12)),
            Text('😕', style: TextStyle(fontSize: 12)),
            Text('😐', style: TextStyle(fontSize: 12)),
            Text('🙂', style: TextStyle(fontSize: 12)),
            Text('😊', style: TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }

  String _getMoodEmoji(int mood) {
    switch (mood) {
      case 1: return '😢';
      case 2: return '😕';
      case 3: return '😐';
      case 4: return '🙂';
      case 5: return '😊';
      default: return '😐';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('记录拖延原因'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 任务信息
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '拖延的任务',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.taskTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 拖延前心情
                  _buildMoodSelector(
                    '拖延前的心情如何？',
                    _moodBefore,
                    (value) => setState(() => _moodBefore = value),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 拖延原因选择
                  const Text(
                    '选择拖延原因',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '不要自责，选择最贴近的原因，我们一起找到解决方案',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 原因选项
                  ..._reasons.map((reason) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: RadioListTile<String>(
                      title: Text(reason.label),
                      value: reason.value,
                      groupValue: _selectedReason,
                      onChanged: (value) {
                        setState(() => _selectedReason = value);
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      tileColor: _selectedReason == reason.value 
                          ? Colors.blue[50] 
                          : Colors.grey[50],
                    ),
                  )).toList(),
                  
                  // 自定义原因输入框
                  if (_selectedReason == ProcrastinationReason.custom) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _customReasonController,
                      decoration: const InputDecoration(
                        labelText: '请输入具体原因',
                        hintText: '比如：被朋友打电话打断了...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // 拖延后心情
                  _buildMoodSelector(
                    '记录后的心情如何？',
                    _moodAfter,
                    (value) => setState(() => _moodAfter = value),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // 提交按钮
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitRecord,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              '保存记录',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 温馨提示
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '💡 温馨提示',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '记录拖延原因不是为了自责，而是为了更好地了解自己，找到改善的方法。每个人都会遇到拖延，重要的是学会与它和谐相处。',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                            height: 1.4,
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
