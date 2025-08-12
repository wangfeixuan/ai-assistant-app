import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/ai_task.dart';
import '../services/ai_service.dart';
import '../services/ai_connection_manager.dart';
import '../widgets/subtask_selection_widget.dart';
import '../features/daily_quote/providers/quote_provider.dart';
import '../features/todo/providers/todo_provider.dart';
import '../core/services/personalization_service.dart';
import '../core/services/profile_sync_service.dart';
import '../core/utils/overlay_manager.dart';
import 'dart:async';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({Key? key}) : super(key: key);

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> with WidgetsBindingObserver, RouteAware {
  final TextEditingController _taskController = TextEditingController();
  final AIService _aiService = AIService();
  bool _isLoading = false;
  String _aiAssistantName = 'AI智能助手';
  AITaskBreakdown? _currentBreakdown;
  
  // 同步服务和订阅
  final ProfileSyncService _syncService = ProfileSyncService();
  StreamSubscription<String>? _aiNameSubscription;
  
  // AI连接管理器
  final AIConnectionManager _connectionManager = AIConnectionManager.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAIAssistantName();
    _setupSyncListeners();
    _setupConnectionListener();
  }
  
  /// 设置同步监听器
  void _setupSyncListeners() {
    // 监听AI助手名称变化
    _aiNameSubscription = _syncService.aiNameStream.listen((newName) {
      if (mounted && _aiAssistantName != newName) {
        setState(() {
          _aiAssistantName = newName;
        });
        debugPrint('🔄 AI助手名称实时同步更新: $newName');
      }
    });
  }
  
  /// 设置AI连接状态监听器
  void _setupConnectionListener() {
    // 监听AI连接状态变化
    _connectionManager.addListener(() {
      if (mounted) {
        setState(() {
          // 触发UI重建以反映连接状态变化
        });
        debugPrint('🔄 AI连接状态更新: ${_connectionManager.isConnected}');
      }
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 每次页面依赖变化时刷新AI助手名称（比如从其他页面返回时）
    _loadAIAssistantName();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _taskController.dispose();
    _aiNameSubscription?.cancel(); // 清理同步监听器
    _connectionManager.removeListener(() {}); // 清理连接监听器
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 当应用程序重新获得焦点时，刷新AI助手名字
    if (state == AppLifecycleState.resumed) {
      _loadAIAssistantName();
      _connectionManager.resumeHeartbeat();
    } else if (state == AppLifecycleState.paused) {
      _connectionManager.pauseHeartbeat();
    }
  }

  /// 手动刷新AI连接状态（用于下拉刷新等场景）
  Future<void> _refreshAIStatus() async {
    await _connectionManager.refresh();
    if (mounted) {
      setState(() {
        // 触发UI重建
      });
    }
  }

  /// 加载AI助手名字
  Future<void> _loadAIAssistantName() async {
    try {
      final personalizationService = PersonalizationService.instance;
      final aiName = await personalizationService.getAiAssistantName();
      final newName = aiName.isNotEmpty ? aiName : 'AI智能助手';
      
      // 只有当名称真正发生变化时才更新UI，减少不必要的重建
      if (mounted && _aiAssistantName != newName) {
        setState(() {
          _aiAssistantName = newName;
        });
        debugPrint('🤖 AI助手名称已更新: $_aiAssistantName');
      }
    } catch (e) {
      debugPrint('加载AI助手名字失败: $e');
    }
  }
  
  /// 强制刷新AI助手名称（用于从设置页面返回时）
  void _forceRefreshAIName() {
    // 立即加载最新名称，不等待延迟
    _loadAIAssistantName();
  }



  Future<void> _breakdownTask() async {
    final task = _taskController.text.trim();
    if (task.isEmpty) {
      context.showSafeSnackBar('请输入要拆分的任务');
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
      context.showSafeSnackBar('任务拆分失败: $e');
    }
  }

  Future<void> _addSelectedTasks(List<SubTask> selectedTasks) async {
    if (selectedTasks.isEmpty) {
      context.showSafeSnackBar('请选择要添加的子任务');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 使用TodoProvider添加主任务和子任务的层次结构
      final todoProvider = context.read<TodoProvider>();
      final mainTaskText = _currentBreakdown!.originalTask;
      
      // 首先添加主任务（1级任务）
      final mainTaskId = await todoProvider.addTodoWithId(
        mainTaskText,
        level: 1,
        source: 'ai_split',
      );
      
      // 然后添加选中的子任务（2级任务）
      final subtaskIds = <String>[];
      for (final task in selectedTasks) {
        final subtaskId = await todoProvider.addTodoWithId(
          task.title,
          level: 2,
          parentId: mainTaskId,
          source: 'ai_split',
        );
        subtaskIds.add(subtaskId);
      }
      
      // 更新主任务的子任务ID列表
      await todoProvider.updateTodoSubtasks(mainTaskId, subtaskIds);
      
      setState(() {
        _isLoading = false;
        _currentBreakdown = null;
        _taskController.clear();
      });
      
      context.showSafeSnackBar(
        '✅ 成功添加主任务「$mainTaskText」及 ${selectedTasks.length} 个子任务到待办列表',
        backgroundColor: Colors.green,
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      context.showSafeSnackBar(
        '❌ 添加任务失败: $e',
        backgroundColor: Colors.red,
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
    // 移除频繁的AI助手名字刷新，避免widget重建导致输入框失焦
    return Scaffold(
      appBar: AppBar(
        title: Text(_aiAssistantName),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _connectionManager.isConnected ? Icons.cloud_done : Icons.cloud_off,
              color: _connectionManager.isConnected ? Colors.green : Colors.red,
            ),
            onPressed: _refreshAIStatus,
            tooltip: _connectionManager.isConnected ? 'AI服务已连接' : 'AI服务未连接',
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
                        decoration: InputDecoration(
                          hintText: '例如：准备期末考试、学习Flutter开发、完成毕业设计...',
                          hintStyle: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _connectionManager.isConnected && !_isLoading ? _breakdownTask : null,
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

              // 任务分析结果
              if (_currentBreakdown != null) ...[
                const SizedBox(height: 20),
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
                        
                        // 简化的任务显示
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.task_alt,
                                color: Theme.of(context).primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _currentBreakdown!.originalTask,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
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
                        
                        // 简化的提示
                        if (_currentBreakdown!.tips.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.lightbulb, color: Colors.blue, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _currentBreakdown!.tips.first,
                                    style: const TextStyle(fontSize: 13),
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
              ],
            ],
          ),
        ),
      ),
    );
  }
}
