import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/ai_task.dart';
import '../services/ai_service.dart';
import '../widgets/subtask_selection_widget.dart';
import '../features/daily_quote/providers/quote_provider.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({Key? key}) : super(key: key);

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _taskController = TextEditingController();
  final AIService _aiService = AIService();
  
  bool _isLoading = false;
  bool _isAIConnected = false;
  String _aiStatus = '';
  AITaskBreakdown? _currentBreakdown;

  @override
  void initState() {
    super.initState();
    _checkAIStatus();
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  Future<void> _checkAIStatus() async {
    try {
      final status = await _aiService.getAIStatus();
      setState(() {
        _isAIConnected = status['isConnected'] as bool;
        _aiStatus = status['message'] as String;
      });
    } catch (e) {
      setState(() {
        _isAIConnected = false;
        _aiStatus = 'AI服务检查失败: $e';
      });
    }
  }

  Future<void> _breakdownTask() async {
    final task = _taskController.text.trim();
    if (task.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入要拆分的任务')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final breakdown = await _aiService.breakdownTaskSimple(task);
      setState(() {
        _currentBreakdown = breakdown;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('任务拆分失败: $e')),
      );
    }
  }

  Future<void> _addSelectedTasks(List<SubTask> selectedTasks) async {
    if (selectedTasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择要添加的子任务')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _aiService.addSubTasksToTodo(selectedTasks);
      setState(() {
        _isLoading = false;
        _currentBreakdown = null;
        _taskController.clear();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('成功添加 ${selectedTasks.length} 个任务到待办列表')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('添加任务失败: $e')),
      );
    }
  }

  void _clearResults() {
    setState(() {
      _currentBreakdown = null;
      _taskController.clear();
    });
  }

  // 键盘收起功能
  void _dismissKeyboard() {
    print('🎹 AI助手界面：点击空白区域，开始收起键盘...');
    
    // 机制1: 取消当前焦点
    FocusScope.of(context).unfocus();
    
    // 机制2: 强制隐藏键盘
    FocusManager.instance.primaryFocus?.unfocus();
    
    // 机制3: 延迟确保键盘收起
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        FocusScope.of(context).unfocus();
      }
    });
    
    print('🎹 AI助手界面：键盘收起操作完成');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI智能助手'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _isAIConnected ? Icons.cloud_done : Icons.cloud_off,
              color: _isAIConnected ? Colors.green : Colors.red,
            ),
            onPressed: _checkAIStatus,
            tooltip: _isAIConnected ? 'AI服务已连接' : 'AI服务未连接',
          ),
        ],
      ),
      body: GestureDetector(
        onTap: _dismissKeyboard,
        behavior: HitTestBehavior.opaque,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // 每日鼓励语录
            Consumer<QuoteProvider>(
              builder: (context, quoteProvider, child) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '今日鼓励',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            quoteProvider.currentDate,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        quoteProvider.currentQuote,
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // 任务输入区域
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '输入要拆分的任务',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _taskController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: '例如：准备期末考试、学习Flutter开发、完成毕业设计...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isAIConnected && !_isLoading ? _breakdownTask : null,
                        icon: _isLoading 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome),
                        label: Text(_isLoading ? '正在分析...' : 'AI智能拆分'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 拆分结果显示
            if (_currentBreakdown != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '任务分析结果',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _clearResults,
                            tooltip: '清除结果',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // 原始任务
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '原始任务:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(_currentBreakdown!.originalTask),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // AI分析
                      const Text(
                        'AI分析:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentBreakdown!.analysis,
                        style: const TextStyle(height: 1.5),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // 子任务选择
                      SubTaskSelectionWidget(
                        subtasks: _currentBreakdown!.subtasks,
                        onSelectionChanged: (selectedTasks) {
                          // 可以在这里处理选择变化
                        },
                        onAddSelected: _addSelectedTasks,
                        isLoading: _isLoading,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // 实用建议
                      if (_currentBreakdown!.tips.isNotEmpty) ...[
                        const Text(
                          '💡 实用建议:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...(_currentBreakdown!.tips.map((tip) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                              Expanded(child: Text(tip)),
                            ],
                          ),
                        ))),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
