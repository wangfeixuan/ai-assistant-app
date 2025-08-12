class AITaskBreakdown {
  final String originalTask;
  final String analysis;
  final List<SubTask> subtasks;
  final List<String> tips;
  final DateTime createdAt;

  AITaskBreakdown({
    required this.originalTask,
    required this.analysis,
    required this.subtasks,
    required this.tips,
    required this.createdAt,
  });

  factory AITaskBreakdown.fromJson(Map<String, dynamic> json) {
    final breakdown = json['breakdown'] as Map<String, dynamic>;
    return AITaskBreakdown(
      originalTask: json['original_task'] as String,
      analysis: breakdown['analysis'] as String,
      subtasks: (breakdown['subtasks'] as List)
          .map((item) => SubTask.fromJson(item as Map<String, dynamic>))
          .toList(),
      tips: (breakdown['tips'] as List).cast<String>(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class SubTask {
  final int id;
  final String title;
  final String description;
  final String category;
  final String priority;
  final String estimatedTime;
  bool isSelected;

  SubTask({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.estimatedTime,
    this.isSelected = false,
  });

  factory SubTask.fromJson(Map<String, dynamic> json) {
    return SubTask(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      priority: json['priority'] as String,
      estimatedTime: json['estimated_time'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'estimated_time': estimatedTime,
    };
  }

  // 转换为待办任务格式
  Map<String, dynamic> toTodoTask() {
    return {
      'title': title,
      'description': description,
      'priority': priority.toLowerCase(), // 直接使用字符串格式
    };
  }

  int _mapPriorityToNumber(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return 3;
      case 'medium':
        return 2;
      case 'low':
        return 1;
      default:
        return 2;
    }
  }

  String get priorityText {
    switch (priority.toLowerCase()) {
      case 'high':
        return '高优先级';
      case 'medium':
        return '中优先级';
      case 'low':
        return '低优先级';
      default:
        return '中优先级';
    }
  }
}

class AITaskRequest {
  final String task;

  AITaskRequest({required this.task});

  Map<String, dynamic> toJson() {
    return {
      'task': task,
    };
  }
}
