import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/todo_item.dart';
import '../models/todo_settings.dart';
import '../models/delay_diary.dart';

/// 待办事项功能提供者 - 支持多级任务结构
/// 包含时间管理、设置管理、拖延日记等完整功能
class TodoProvider extends ChangeNotifier {
  static const String _todosKey = 'todos';
  static const String _settingsKey = 'todo_settings';
  static const String _delayDiaryKey = 'delay_diary';
  
  List<TodoItem> _todos = [];
  TodoSettings _settings = TodoSettings();
  List<DelayDiaryEntry> _delayDiary = [];

  /// 获取所有待办事项
  List<TodoItem> get todos => List.unmodifiable(_todos);
  
  /// 获取主任务列表（用于UI显示）
  List<TodoItem> get mainTasks {
    final tasks = _todos.where((todo) => todo.isMainTask).toList();
    
    // 排序逻辑：
    // 1. 未完成的任务在前，已完成的任务在后
    // 2. 未完成任务中：优先任务置顶，然后按开始时间排序（早的在前）
    // 3. 已完成任务按完成时间排序（最近完成的在前）
    tasks.sort((a, b) {
      // 首先按完成状态排序
      if (a.completed != b.completed) {
        return a.completed ? 1 : -1; // 未完成的在前
      }
      
      if (!a.completed) {
        // 未完成任务的排序
        // 优先任务置顶
        if (a.isPriority && !b.isPriority) return -1;
        if (!a.isPriority && b.isPriority) return 1;
        
        // 都是优先任务或都不是优先任务，按开始时间排序
        if (a.startTime != null && b.startTime != null) {
          return a.startTime!.compareTo(b.startTime!);
        }
        if (a.startTime != null && b.startTime == null) return -1;
        if (a.startTime == null && b.startTime != null) return 1;
        
        // 都没有开始时间，按创建时间排序
        return a.createdAt.compareTo(b.createdAt);
      } else {
        // 已完成任务按完成时间倒序排序（最近完成的在前）
        if (a.completedAt != null && b.completedAt != null) {
          return b.completedAt!.compareTo(a.completedAt!);
        }
        if (a.completedAt != null && b.completedAt == null) return -1;
        if (a.completedAt == null && b.completedAt != null) return 1;
        
        // 都没有完成时间，按创建时间倒序
        return b.createdAt.compareTo(a.createdAt);
      }
    });
    
    return tasks;
  }
  
  /// 获取设置
  TodoSettings get settings => _settings;
  
  /// 获取拖延日记
  List<DelayDiaryEntry> get delayDiary => List.unmodifiable(_delayDiary);
  
  /// 根据父任务ID获取子任务列表
  List<TodoItem> getSubtasks(String parentId) {
    return _todos.where((todo) => todo.parentId == parentId).toList();
  }

  TodoProvider() {
    _loadTodos();
    _loadSettings();
    _loadDelayDiary();
  }

  /// 添加主任务（1级任务）
  void addMainTask(String text, {String source = 'manual'}) {
    try {
      debugPrint('📝 开始添加主任务: $text');
      
      final todo = TodoItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        completed: false,
        createdAt: DateTime.now(),
        level: 1,
        source: source,
      );
      
      _todos.insert(0, todo);
      debugPrint('📝 主任务已添加到列表，当前总数: ${_todos.length}');
      
      _saveTodos();
      notifyListeners();
      
      debugPrint('📝 主任务添加成功！');
    } catch (e) {
      debugPrint('❌ 添加主任务失败: $e');
      notifyListeners();
    }
  }
  
  /// 添加子任务（2级任务）
  void addSubtasks(String parentId, List<String> subtaskTexts) {
    try {
      debugPrint('📝 开始为任务 $parentId 添加 ${subtaskTexts.length} 个子任务');
      
      // 找到父任务
      final parentIndex = _todos.indexWhere((todo) => todo.id == parentId);
      if (parentIndex == -1) {
        debugPrint('❌ 未找到父任务: $parentId');
        return;
      }
      
      final List<String> newSubtaskIds = [];
      
      // 创建子任务
      for (int i = 0; i < subtaskTexts.length; i++) {
        final subtaskText = subtaskTexts[i];
        // 确保每个子任务ID唯一，使用微秒级时间戳 + 随机数
        final uniqueId = '${DateTime.now().microsecondsSinceEpoch}_${i}_${(DateTime.now().millisecond * 1000 + i).hashCode.abs()}';
        
        final subtask = TodoItem(
          id: uniqueId,
          text: subtaskText,
          completed: false,
          createdAt: DateTime.now(),
          level: 2,
          parentId: parentId,
          source: 'ai_split',
        );
        
        _todos.add(subtask);
        newSubtaskIds.add(subtask.id);
        
        debugPrint('📝 创建子任务: ${subtask.id} - $subtaskText');
      }
      
      // 更新父任务的子任务ID列表
      final parentTask = _todos[parentIndex];
      final updatedParent = parentTask.copyWith(
        subtaskIds: [...parentTask.subtaskIds, ...newSubtaskIds],
      );
      _todos[parentIndex] = updatedParent;
      
      _saveTodos();
      notifyListeners();
      
      debugPrint('📝 子任务添加成功！');
    } catch (e) {
      debugPrint('❌ 添加子任务失败: $e');
      notifyListeners();
    }
  }
  
  /// 添加待办任务并返回任务ID（支持设置级别、父任务ID和来源）
  Future<String> addTodoWithId(String text, {
    int level = 1,
    String? parentId,
    String source = 'manual',
  }) async {
    try {
      debugPrint('📝 开始添加任务: $text (level: $level, parentId: $parentId, source: $source)');
      
      final taskId = DateTime.now().millisecondsSinceEpoch.toString();
      final todo = TodoItem(
        id: taskId,
        text: text,
        completed: false,
        createdAt: DateTime.now(),
        level: level,
        parentId: parentId,
        source: source,
      );
      
      _todos.insert(0, todo);
      debugPrint('📝 任务已添加到列表，ID: $taskId');
      
      await _saveTodos();
      notifyListeners();
      
      debugPrint('📝 任务添加成功！');
      return taskId;
    } catch (e) {
      debugPrint('❌ 添加任务失败: $e');
      rethrow;
    }
  }

  /// 更新任务的子任务列表
  Future<void> updateTodoSubtasks(String taskId, List<String> subtaskIds) async {
    try {
      debugPrint('📝 更新任务 $taskId 的子任务列表: $subtaskIds');
      
      final index = _todos.indexWhere((todo) => todo.id == taskId);
      if (index == -1) {
        debugPrint('❌ 未找到要更新的任务: $taskId');
        return;
      }
      
      final task = _todos[index];
      _todos[index] = task.copyWith(subtaskIds: subtaskIds);
      
      await _saveTodos();
      notifyListeners();
      
      debugPrint('📝 子任务列表更新成功！');
    } catch (e) {
      debugPrint('❌ 更新子任务列表失败: $e');
      rethrow;
    }
  }

  /// 兼容旧版本的添加方法
  void addTodo(String text) {
    addMainTask(text);
  }

  /// 直接添加TodoItem对象
  void addTodoItem(TodoItem todoItem) {
    _todos.add(todoItem);
    _saveTodos();
    notifyListeners();
  }

  /// 重新排序主任务
  void reorderMainTasks(int oldIndex, int newIndex) {
    final mainTasksList = mainTasks;
    if (oldIndex >= mainTasksList.length || newIndex >= mainTasksList.length || oldIndex == newIndex) {
      return;
    }
    
    final movedTask = mainTasksList[oldIndex];
    final targetTask = mainTasksList[newIndex];
    
    // 不允许在已完成和未完成任务之间拖拽
    if (movedTask.completed != targetTask.completed) {
      return;
    }
    
    // 对于相同状态的任务，直接调整在_todos中的位置
    final movedTaskIndex = _todos.indexWhere((todo) => todo.id == movedTask.id);
    if (movedTaskIndex == -1) return;
    
    _todos.removeAt(movedTaskIndex);
    
    // 找到目标任务在_todos中的位置
    final targetTaskIndex = _todos.indexWhere((todo) => todo.id == targetTask.id);
    if (targetTaskIndex == -1) {
      _todos.add(movedTask);
    } else {
      if (newIndex > oldIndex) {
        // 向后移动，插入在目标任务之后
        _todos.insert(targetTaskIndex + 1, movedTask);
      } else {
        // 向前移动，插入在目标任务之前
        _todos.insert(targetTaskIndex, movedTask);
      }
    }
    
    _saveTodos();
    notifyListeners();
  }

  /// 切换任务完成状态
  void toggleTodo(String todoId) {
    debugPrint('🔄 开始切换任务状态: $todoId');
    
    final index = _todos.indexWhere((todo) => todo.id == todoId);
    if (index == -1) {
      debugPrint('❌ 未找到任务: $todoId');
      return;
    }
    
    final todo = _todos[index];
    final oldCompleted = todo.completed;
    final newCompleted = !oldCompleted;
    
    debugPrint('🔄 任务详情: ${todo.text} (level: ${todo.level}) - 状态变化: $oldCompleted -> $newCompleted');
    
    _todos[index] = todo.copyWith(
      completed: newCompleted,
      completedAt: newCompleted ? DateTime.now() : null,
    );
    
    // 如果是主任务，不强制更新子任务状态，让用户自由选择每个子任务
    if (todo.isMainTask && todo.hasSubtasks) {
      debugPrint('🔄 主任务状态改变，但不强制更新子任务，由用户自由选择');
      // 不调用 _updateSubtasksStatus，让子任务保持独立状态
    }
    // 如果是子任务，检查是否需要更新父任务状态
    else if (todo.isSubtask && todo.parentId != null) {
      debugPrint('🔄 子任务状态变化，检查父任务状态: ${todo.parentId}');
      _updateParentTaskStatus(todo.parentId!);
    }
    
    _saveTodos();
    notifyListeners();
    
    debugPrint('🔄 任务状态切换完成: $todoId');
  }
  
  /// 更新子任务状态（当主任务状态改变时）
  void _updateSubtasksStatus(String parentId, bool completed) {
    for (int i = 0; i < _todos.length; i++) {
      if (_todos[i].parentId == parentId) {
        _todos[i] = _todos[i].copyWith(completed: completed);
      }
    }
  }
  
  /// 更新父任务状态（当子任务状态改变时）
  void _updateParentTaskStatus(String parentId) {
    final subtasks = getSubtasks(parentId);
    if (subtasks.isEmpty) return;
    
    final allCompleted = subtasks.every((subtask) => subtask.completed);
    final parentIndex = _todos.indexWhere((todo) => todo.id == parentId);
    
    if (parentIndex != -1) {
      final currentParentCompleted = _todos[parentIndex].completed;
      // 只有当父任务状态真正需要改变时才更新，避免不必要的更新
      if (currentParentCompleted != allCompleted) {
        debugPrint('🔄 更新父任务状态: $parentId -> $allCompleted');
        _todos[parentIndex] = _todos[parentIndex].copyWith(completed: allCompleted);
      }
    }
  }

  /// 删除任务
  void deleteTodo(String todoId) {
    try {
      debugPrint('🗑️ 开始删除任务: $todoId');
      
      final todoIndex = _todos.indexWhere((t) => t.id == todoId);
      if (todoIndex == -1) {
        debugPrint('❌ 未找到要删除的任务: $todoId');
        return;
      }
      
      final todo = _todos[todoIndex];
      debugPrint('🗑️ 找到任务: ${todo.text} (level: ${todo.level})');
      
      // 如果是主任务（1级），同时删除所有子任务
      if (todo.level == 1 && todo.subtaskIds.isNotEmpty) {
        debugPrint('🗑️ 删除主任务及其 ${todo.subtaskIds.length} 个子任务');
        
        // 先删除所有子任务
        final subtasksToDelete = todo.subtaskIds.toList();
        for (final subtaskId in subtasksToDelete) {
          final subtaskIndex = _todos.indexWhere((t) => t.id == subtaskId);
          if (subtaskIndex != -1) {
            debugPrint('🗑️ 删除子任务: ${_todos[subtaskIndex].text}');
            _todos.removeAt(subtaskIndex);
          }
        }
      }
      // 如果是子任务（2级），从父任务的子任务列表中移除
      else if (todo.level == 2 && todo.parentId != null) {
        debugPrint('🗑️ 删除子任务，同时更新父任务');
        
        final parentIndex = _todos.indexWhere((t) => t.id == todo.parentId);
        if (parentIndex != -1) {
          final parent = _todos[parentIndex];
          final updatedSubtaskIds = parent.subtaskIds.where((id) => id != todoId).toList();
          _todos[parentIndex] = parent.copyWith(subtaskIds: updatedSubtaskIds);
          debugPrint('🗑️ 已从父任务中移除子任务ID: $todoId');
        }
      }
      
      // 最后删除任务本身（重新查找索引以确保准确性）
      final finalTodoIndex = _todos.indexWhere((t) => t.id == todoId);
      if (finalTodoIndex != -1) {
        _todos.removeAt(finalTodoIndex);
        debugPrint('🗑️ 任务删除成功: ${todo.text}');
      }
      
      _saveTodos();
      notifyListeners();
      
    } catch (e) {
      debugPrint('❌ 删除任务失败: $e');
      notifyListeners();
    }
  }

  /// 编辑任务
  void editTodo(String todoId, String newText) {
    try {
      debugPrint('✏️ 开始编辑任务: $todoId -> $newText');
      
      final index = _todos.indexWhere((todo) => todo.id == todoId);
      if (index == -1) {
        debugPrint('❌ 未找到要编辑的任务: $todoId');
        return;
      }
      
      final oldTask = _todos[index];
      debugPrint('✏️ 找到任务: ${oldTask.text} (level: ${oldTask.level})');
      
      if (newText.trim().isEmpty) {
        debugPrint('❌ 新任务内容为空，取消编辑');
        return;
      }
      
      _todos[index] = oldTask.copyWith(text: newText.trim());
      debugPrint('✏️ 任务编辑成功: ${oldTask.text} -> ${newText.trim()}');
      
      _saveTodos();
      notifyListeners();
      
    } catch (e) {
      debugPrint('❌ 编辑任务失败: $e');
      notifyListeners();
    }
  }

  /// 切换主任务展开状态
  void toggleTaskExpansion(String todoId) {
    debugPrint('🔄 切换任务展开状态: $todoId');
    
    // 使用延迟执行，避免在widget构建过程中直接修改状态
    Future.microtask(() {
      try {
        final index = _todos.indexWhere((todo) => todo.id == todoId);
        if (index == -1) {
          debugPrint('❌ 未找到任务: $todoId');
          return;
        }
        
        final task = _todos[index];
        if (task.level != 1) {
          debugPrint('❌ 只有1级任务可以展开');
          return;
        }
        
        // 直接修改展开状态
        final newTask = TodoItem(
          id: task.id,
          text: task.text,
          completed: task.completed,
          createdAt: task.createdAt,
          level: task.level,
          parentId: task.parentId,
          subtaskIds: task.subtaskIds,
          isExpanded: !task.isExpanded,
          source: task.source,
          startTime: task.startTime,
          estimatedDuration: task.estimatedDuration,
          deadline: task.deadline,
          completedAt: task.completedAt,
          taskType: task.taskType,
          dailyDuration: task.dailyDuration,
          currentOccurrence: task.currentOccurrence,
          totalOccurrences: task.totalOccurrences,
          parentTaskId: task.parentTaskId,
          isDelayed: task.isDelayed,
          needsProcrastinationDiary: task.needsProcrastinationDiary,
          isPostponed: task.isPostponed,
          postponedDays: task.postponedDays,
          postponeReason: task.postponeReason,
          delayLevel: task.delayLevel,
          lastRemindTime: task.lastRemindTime,
          remindCount: task.remindCount,
          ignoreCount: task.ignoreCount,
          lastIgnoreTime: task.lastIgnoreTime,
          isPriority: task.isPriority,
          isRolledOver: task.isRolledOver,
          originalDate: task.originalDate,
          sortOrder: task.sortOrder,
        );
        
        _todos[index] = newTask;
        debugPrint('✅ 展开状态切换成功: ${task.text} -> ${newTask.isExpanded}');
        
        _saveTodos();
        notifyListeners();
        
      } catch (e) {
        debugPrint('❌ 展开功能错误: $e');
      }
    });
  }
  
  /// 清空已完成的待办事项
  void clearCompleted() {
    // 先收集要删除的主任务ID
    final completedMainTaskIds = _todos
        .where((todo) => todo.isMainTask && todo.completed)
        .map((todo) => todo.id)
        .toList();
    
    // 删除已完成的主任务及其子任务
    for (final mainTaskId in completedMainTaskIds) {
      final mainTask = _todos.firstWhere((t) => t.id == mainTaskId);
      _todos.removeWhere((t) => mainTask.subtaskIds.contains(t.id));
    }
    
    // 删除所有已完成的任务
    _todos.removeWhere((todo) => todo.completed);
    _saveTodos();
    notifyListeners();
  }

  /// 获取统计信息
  Map<String, int> getStats() {
    final mainTasks = _todos.where((todo) => todo.isMainTask).toList();
    final total = mainTasks.length;
    final completed = mainTasks.where((todo) => todo.completed).length;
    final pending = total - completed;
    
    return {
      'total': total,
      'completed': completed,
      'pending': pending,
    };
  }

  /// 从本地存储加载待办事项
  Future<void> _loadTodos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todosJson = prefs.getString(_todosKey);
      
      if (todosJson != null) {
        final List<dynamic> todosList = json.decode(todosJson);
        _todos = todosList.map((json) {
          try {
            return TodoItem.fromJson(json as Map<String, dynamic>);
          } catch (e) {
            // 对于旧版本数据，转换为新格式
            debugPrint('转换旧版本数据: $json');
            return TodoItem(
              id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
              text: json['text']?.toString() ?? '',
              completed: json['completed'] as bool? ?? false,
              createdAt: json['createdAt'] != null 
                  ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
                  : DateTime.now(),
              level: 1, // 旧数据默认为主任务
              source: 'manual',
            );
          }
        }).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading todos: $e');
    }
  }

  /// 保存待办事项到本地存储
  Future<void> _saveTodos() async {
    try {
      debugPrint('💾 开始保存待办事项到本地存储...');
      final prefs = await SharedPreferences.getInstance();
      final todosJson = json.encode(_todos.map((todo) => todo.toJson()).toList());
      await prefs.setString(_todosKey, todosJson);
      debugPrint('💾 待办事项保存成功，共 ${_todos.length} 项');
    } catch (e) {
      debugPrint('❌ 保存待办事项失败: $e');
    }
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
  
  /// 获取任务的完成进度（主任务使用）
  double getTaskProgress(String taskId) {
    final task = _todos.firstWhere((t) => t.id == taskId, orElse: () => throw Exception('Task not found'));
    if (!task.isMainTask || !task.hasSubtasks) {
      return task.completed ? 1.0 : 0.0;
    }
    
    final subtasks = getSubtasks(taskId);
    if (subtasks.isEmpty) return task.completed ? 1.0 : 0.0;
    
    final completedCount = subtasks.where((subtask) => subtask.completed).length;
    return completedCount / subtasks.length;
  }

  // ==================== 时间管理功能 ====================
  
  /// 更新任务时间信息
  void updateTaskTime(String taskId, {
    DateTime? startTime,
    Duration? estimatedDuration,
    DateTime? deadline,
  }) {
    final index = _todos.indexWhere((todo) => todo.id == taskId);
    if (index != -1) {
      _todos[index] = _todos[index].copyWith(
        startTime: startTime,
        estimatedDuration: estimatedDuration,
        deadline: deadline,
      );
      _saveTodos();
      notifyListeners();
    }
  }
  
  /// 标记任务完成（记录完成时间）
  void completeTask(String taskId) {
    final index = _todos.indexWhere((todo) => todo.id == taskId);
    if (index != -1 && !_todos[index].completed) {
      _todos[index] = _todos[index].copyWith(
        completed: true,
        completedAt: DateTime.now(),
      );
      
      // 处理级联更新
      final todo = _todos[index];
      if (todo.isMainTask && todo.hasSubtasks) {
        _updateSubtasksStatus(taskId, true);
      } else if (todo.isSubtask && todo.parentId != null) {
        _updateParentTaskStatus(todo.parentId!);
      }
      
      _saveTodos();
      notifyListeners();
    }
  }
  
  /// 获取需要提醒的任务列表
  List<TodoItem> getTasksNeedingReminder() {
    final now = DateTime.now();
    return _todos.where((task) {
      if (task.completed) return false;
      return task.shouldRemind(_settings.unifiedReminderTime);
    }).toList();
  }
  
  /// 获取过期任务列表
  List<TodoItem> getOverdueTasks() {
    return _todos.where((task) => !task.completed && task.isOverdue).toList();
  }
  
  /// 获取超时任务列表（超过预计完成时间50%）
  List<TodoItem> getOvertimeTasks() {
    return _todos.where((task) => !task.completed && task.isOvertime).toList();
  }
  
  /// 更新任务提醒信息
  void updateTaskReminder(String taskId) {
    final index = _todos.indexWhere((todo) => todo.id == taskId);
    if (index != -1) {
      final task = _todos[index];
      _todos[index] = task.copyWith(
        lastRemindTime: DateTime.now(),
        remindCount: task.remindCount + 1,
      );
      _saveTodos();
      notifyListeners();
    }
  }
  
  /// 忽略任务提醒（记录忽略时间和次数）
  void ignoreTaskReminder(String taskId) {
    final index = _todos.indexWhere((todo) => todo.id == taskId);
    if (index != -1) {
      final task = _todos[index];
      _todos[index] = task.copyWith(
        lastIgnoreTime: DateTime.now(),
        ignoreCount: task.ignoreCount + 1,
      );
      _saveTodos();
      notifyListeners();
      
      debugPrint('🔕 任务「${task.text}」被忽略，忽略次数: ${task.ignoreCount + 1}');
    }
  }
  
  // ==================== 重复任务功能 ====================
  
  /// 创建重复任务模板
  /// 创建每日待办任务
  String createDailyTask(String text, int durationDays) {
    final parentTaskId = 'daily_${DateTime.now().millisecondsSinceEpoch}';
    final task = TodoItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      completed: false,
      createdAt: DateTime.now(),
      level: 1,
      source: 'manual',
      taskType: TaskType.daily,
      dailyDuration: durationDays,
      currentOccurrence: 1,
      totalOccurrences: durationDays,
      parentTaskId: parentTaskId,
      isDelayed: false,
      needsProcrastinationDiary: false,
    );
    
    _todos.insert(0, task);
    _saveTodos();
    notifyListeners();
    return parentTaskId;
  }
  
  /// 生成下一天的每日待办实例
  void generateNextDailyInstance(String parentTaskId) {
    final lastInstance = _todos
        .where((task) => task.parentTaskId == parentTaskId)
        .reduce((a, b) => (a.currentOccurrence ?? 0) > (b.currentOccurrence ?? 0) ? a : b);
    
    if ((lastInstance.currentOccurrence ?? 0) >= (lastInstance.totalOccurrences ?? 0)) {
      return; // 已达到总次数，不再生成
    }
    
    final nextInstance = TodoItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: lastInstance.text,
      completed: false,
      createdAt: DateTime.now(),
      level: lastInstance.level,
      source: lastInstance.source,
      taskType: TaskType.daily,
      dailyDuration: lastInstance.dailyDuration,
      currentOccurrence: (lastInstance.currentOccurrence ?? 0) + 1,
      totalOccurrences: lastInstance.totalOccurrences,
      parentTaskId: parentTaskId,
      isDelayed: false,
      needsProcrastinationDiary: false,
    );
    
    _todos.insert(0, nextInstance);
    _saveTodos();
    notifyListeners();
  }
  
  /// 获取每日待办完成率统计
  Map<String, double> getDailyTaskCompletionRates() {
    final dailyStats = <String, Map<String, dynamic>>{};
    
    for (final task in _todos.where((t) => t.taskType == TaskType.daily)) {
      final parentTaskId = task.parentTaskId!;
      if (!dailyStats.containsKey(parentTaskId)) {
        dailyStats[parentTaskId] = {
          'completed': 0, 
          'totalDays': task.totalOccurrences ?? 0,
          'taskText': task.text,
        };
      }
      if (task.completed) {
        dailyStats[parentTaskId]!['completed'] = (dailyStats[parentTaskId]!['completed'] as int) + 1;
      }
    }
    
    final completionRates = <String, double>{};
    for (final entry in dailyStats.entries) {
      final completed = entry.value['completed'] as int;
      final totalDays = entry.value['totalDays'] as int;
      final taskText = entry.value['taskText'] as String;
      
      // 完成率 = 已完成天数 / 总天数，最大为1.0
      final rate = totalDays > 0 ? (completed / totalDays).clamp(0.0, 1.0) : 0.0;
      completionRates[taskText] = rate;
    }
    
    return completionRates;
  }
  
  /// 获取每日待办详细信息（已完成天数、总天数等）
  Map<String, Map<String, int>> getDailyTaskDetails() {
    final dailyDetails = <String, Map<String, int>>{};
    
    for (final task in _todos.where((t) => t.taskType == TaskType.daily)) {
      final parentTaskId = task.parentTaskId!;
      if (!dailyDetails.containsKey(parentTaskId)) {
        dailyDetails[parentTaskId] = {
          'completed': 0,
          'totalDays': task.totalOccurrences ?? 0,
          'current': 0,
        };
      }
      dailyDetails[parentTaskId]!['current'] = dailyDetails[parentTaskId]!['current']! + 1;
      if (task.completed) {
        dailyDetails[parentTaskId]!['completed'] = dailyDetails[parentTaskId]!['completed']! + 1;
      }
    }
    
    // 将parentTaskId映射为任务名称
    final result = <String, Map<String, int>>{};
    for (final entry in dailyDetails.entries) {
      final taskText = _todos.firstWhere((t) => t.parentTaskId == entry.key).text;
      result[taskText] = entry.value;
    }
    
    return result;
  }

  // ==================== 每日待办核心逻辑 ====================
  
  /// 检查并生成今日的每日待办任务（每天0点调用）
  void generateTodayDailyTasks() {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    
    // 获取所有活跃的每日待办任务组
    final activeDailyTasks = <String, List<TodoItem>>{};
    for (final task in _todos.where((t) => t.taskType == TaskType.daily)) {
      final parentTaskId = task.parentTaskId!;
      if (!activeDailyTasks.containsKey(parentTaskId)) {
        activeDailyTasks[parentTaskId] = [];
      }
      activeDailyTasks[parentTaskId]!.add(task);
    }
    
    for (final entry in activeDailyTasks.entries) {
      final parentTaskId = entry.key;
      final tasks = entry.value;
      
      // 找到最新的任务实例
      final latestTask = tasks.reduce((a, b) => 
        (a.currentOccurrence ?? 0) > (b.currentOccurrence ?? 0) ? a : b);
      
      // 检查是否需要生成新的实例
      final shouldGenerate = (latestTask.currentOccurrence ?? 0) < (latestTask.totalOccurrences ?? 0) &&
                             latestTask.createdAt.isBefore(todayStart);
      
      if (shouldGenerate) {
        generateNextDailyInstance(parentTaskId);
      }
      
      // 检查昨天的任务是否未完成（拖延检测）
      checkForDelayedTasks(parentTaskId, tasks);
    }
    
    _saveTodos();
    notifyListeners();
  }
  
  /// 检查拖延任务
  void checkForDelayedTasks(String parentTaskId, List<TodoItem> tasks) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayStart = DateTime(yesterday.year, yesterday.month, yesterday.day);
    final yesterdayEnd = yesterdayStart.add(const Duration(days: 1));
    
    // 查找昨天的未完成任务
    final yesterdayTasks = tasks.where((task) => 
      task.createdAt.isAfter(yesterdayStart) && 
      task.createdAt.isBefore(yesterdayEnd) &&
      !task.completed &&
      !task.isDelayed
    ).toList();
    
    for (final task in yesterdayTasks) {
      // 将未完成的任务标记为拖延任务
      final delayedTask = task.copyWith(
        isDelayed: true,
        needsProcrastinationDiary: true,
        originalDate: task.createdAt,
      );
      
      // 更新任务
      final index = _todos.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _todos[index] = delayedTask;
      }
    }
  }
  
  /// 获取需要填写拖延日记的任务
  List<TodoItem> getTasksNeedingProcrastinationDiary() {
    return _todos.where((task) => task.needsProcrastinationDiary).toList();
  }
  
  /// 标记拖延日记已填写
  void markProcrastinationDiaryCompleted(String taskId) {
    final index = _todos.indexWhere((task) => task.id == taskId);
    if (index != -1) {
      _todos[index] = _todos[index].copyWith(
        needsProcrastinationDiary: false,
      );
      _saveTodos();
      notifyListeners();
    }
  }
  
  /// 检查是否有拖延任务需要处理（用于页面打开时检查）
  bool hasDelayedTasksNeedingDiary() {
    return _todos.any((task) => task.needsProcrastinationDiary);
  }
  
  // ==================== 跨天任务处理 ====================
  
  /// 处理跨天任务延期
  void rolloverIncompleteTasks() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final tasksToRollover = _todos.where((task) {
      if (task.completed || task.isRolledOver) return false;
      if (task.deadline != null) {
        return task.deadline!.isBefore(yesterday);
      }
      if (task.startTime != null) {
        return task.startTime!.isBefore(yesterday);
      }
      return task.createdAt.isBefore(yesterday);
    }).toList();
    
    for (final task in tasksToRollover) {
      final index = _todos.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _todos[index] = task.copyWith(
          isRolledOver: true,
          isPostponed: true,
          postponedDays: task.postponedDays + 1,
          originalDate: task.originalDate ?? task.createdAt,
          delayLevel: task.currentDelayLevel,
        );
      }
    }
    
    _saveTodos();
    notifyListeners();
  }
  
  /// 获取需要重新安排的任务
  List<TodoItem> getTasksNeedingReschedule() {
    return _todos.where((task) => 
      task.isRolledOver && !task.completed && task.postponedDays > 0
    ).toList();
  }
  
  // ==================== 拖延日记功能 ====================
  
  /// 添加拖延日记条目
  void addDelayDiaryEntry({
    required String taskId,
    required String taskName,
    required DelayReason primaryReason,
    List<DelayReason> secondaryReasons = const [],
    String? customReason,
    String? reflection,
  }) {
    final task = _todos.firstWhere((t) => t.id == taskId, orElse: () => throw Exception('Task not found'));
    
    final entry = DelayDiaryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      taskId: taskId,
      taskName: taskName,
      delayDate: DateTime.now(),
      primaryReason: primaryReason,
      secondaryReasons: secondaryReasons,
      customReason: customReason,
      reflection: reflection,
      delayDays: task.actualDelayDays,
      delayLevel: task.currentDelayLevel,
      createdAt: DateTime.now(),
    );
    
    _delayDiary.insert(0, entry);
    _saveDelayDiary();
    notifyListeners();
  }
  
  /// 解决拖延日记条目
  void resolveDelayDiaryEntry(String entryId, String resolution) {
    final index = _delayDiary.indexWhere((entry) => entry.id == entryId);
    if (index != -1) {
      _delayDiary[index] = _delayDiary[index].copyWith(
        isResolved: true,
        resolvedAt: DateTime.now(),
        resolution: resolution,
      );
      _saveDelayDiary();
      notifyListeners();
    }
  }
  
  /// 获取拖延分析数据
  DelayAnalytics getDelayAnalytics() {
    return DelayAnalytics.fromEntries(_delayDiary);
  }
  
  /// 获取特定任务的拖延历史
  List<DelayDiaryEntry> getTaskDelayHistory(String taskId) {
    return _delayDiary.where((entry) => entry.taskId == taskId).toList();
  }
  
  // ==================== 设置管理功能 ====================
  
  /// 更新设置
  void updateSettings(TodoSettings newSettings) {
    _settings = newSettings;
    _saveSettings();
    notifyListeners();
  }
  
  /// 检查是否在勿扰时段
  bool isInDoNotDisturbPeriod([DateTime? checkTime]) {
    return _settings.isInDoNotDisturbPeriod(checkTime);
  }
  
  /// 生成个性化提醒消息
  String generateReminderMessage(String taskName, DelayLevel delayLevel) {
    return _settings.generateReminderMessage(taskName, delayLevel);
  }
  
  // ==================== 数据持久化功能 ====================
  
  /// 加载设置
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);
      
      if (settingsJson != null) {
        final settingsMap = json.decode(settingsJson) as Map<String, dynamic>;
        _settings = TodoSettings.fromJson(settingsMap);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }
  
  /// 保存设置
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = json.encode(_settings.toJson());
      await prefs.setString(_settingsKey, settingsJson);
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }
  
  /// 加载拖延日记
  Future<void> _loadDelayDiary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final diaryJson = prefs.getString(_delayDiaryKey);
      
      if (diaryJson != null) {
        final List<dynamic> diaryList = json.decode(diaryJson);
        _delayDiary = diaryList.map((json) => 
          DelayDiaryEntry.fromJson(json as Map<String, dynamic>)
        ).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading delay diary: $e');
    }
  }
  
  /// 保存拖延日记
  Future<void> _saveDelayDiary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final diaryJson = json.encode(_delayDiary.map((entry) => entry.toJson()).toList());
      await prefs.setString(_delayDiaryKey, diaryJson);
    } catch (e) {
      debugPrint('Error saving delay diary: $e');
    }
  }
  
  // ==================== 自动清除功能支持 ====================
  
  /// 从备份中添加任务（用于恢复功能）
  void addTodoFromBackup(TodoItem todoItem) {
    // 检查任务是否已存在，避免重复添加
    final existingIndex = _todos.indexWhere((todo) => todo.id == todoItem.id);
    if (existingIndex == -1) {
      _todos.add(todoItem);
      _saveTodos();
      notifyListeners();
    }
  }
  
  /// 批量删除任务（用于自动清除）
  void batchDeleteTodos(List<String> todoIds) {
    int deletedCount = 0;
    for (final todoId in todoIds) {
      final index = _todos.indexWhere((todo) => todo.id == todoId);
      if (index != -1) {
        _todos.removeAt(index);
        deletedCount++;
      }
    }
    
    if (deletedCount > 0) {
      _saveTodos();
      notifyListeners();
      debugPrint('🗑️ 批量删除了 $deletedCount 个任务');
    }
  }
  
  /// 获取符合清除条件的已完成任务
  List<TodoItem> getCompletedTasksForCleanup({
    required Duration olderThan,
    bool excludePriorityTasks = true,
    bool excludeRecurringTasks = true,
  }) {
    final cutoffTime = DateTime.now().subtract(olderThan);
    
    return _todos.where((task) {
      // 只考虑已完成的任务
      if (!task.completed || task.completedAt == null) {
        return false;
      }
      
      // 排除优先任务
      if (excludePriorityTasks && task.isPriority) {
        return false;
      }
      
      // 排除每日待办任务
      if (excludeRecurringTasks && task.taskType == TaskType.daily) {
        return false;
      }
      
      // 检查完成时间是否超过清除期限
      return task.completedAt!.isBefore(cutoffTime);
    }).toList();
  }
  
  /// 获取清除统计信息
  Map<String, int> getCleanupStats() {
    final now = DateTime.now();
    final completedTasks = _todos.where((task) => task.completed).toList();
    
    int oldTasks1Day = 0;
    int oldTasks1Week = 0;
    int oldTasks1Month = 0;
    
    for (final task in completedTasks) {
      if (task.completedAt != null) {
        final daysSinceCompletion = now.difference(task.completedAt!).inDays;
        
        if (daysSinceCompletion >= 1) oldTasks1Day++;
        if (daysSinceCompletion >= 7) oldTasks1Week++;
        if (daysSinceCompletion >= 30) oldTasks1Month++;
      }
    }
    
    return {
      'total_completed': completedTasks.length,
      'old_1_day': oldTasks1Day,
      'old_1_week': oldTasks1Week,
      'old_1_month': oldTasks1Month,
    };
  }

  /// 更新待办事项
  Future<void> updateTodo(TodoItem updatedTodo) async {
    final index = _todos.indexWhere((todo) => todo.id == updatedTodo.id);
    if (index != -1) {
      _todos[index] = updatedTodo;
      await _saveTodos();
      notifyListeners();
      debugPrint('✅ 任务已更新: ${updatedTodo.text}');
    } else {
      debugPrint('❌ 未找到要更新的任务: ${updatedTodo.id}');
    }
  }

  /// 更新任务的重要性和紧急性
  Future<void> updateTaskPriority(String taskId, {bool? isPriority, bool? isUrgent}) async {
    final index = _todos.indexWhere((todo) => todo.id == taskId);
    if (index != -1) {
      final updatedTodo = _todos[index].copyWith(
        isPriority: isPriority,
        isUrgent: isUrgent,
      );
      _todos[index] = updatedTodo;
      await _saveTodos();
      notifyListeners();
      debugPrint('✅ 任务优先级已更新: ${updatedTodo.text} - 重要:${updatedTodo.isPriority}, 紧急:${updatedTodo.isUrgent}');
    } else {
      debugPrint('❌ 未找到要更新优先级的任务: $taskId');
    }
  }
}
