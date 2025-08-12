import 'package:flutter/material.dart';

/// 成就模型
class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final DateTime unlockedAt;
  final bool isUnlocked;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.unlockedAt,
    this.isUnlocked = true,
  });

  /// 从Map创建Achievement
  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      icon: IconData(map['iconCode'] ?? Icons.star.codePoint, fontFamily: 'MaterialIcons'),
      unlockedAt: DateTime.fromMillisecondsSinceEpoch(map['unlockedAt'] ?? 0),
      isUnlocked: map['isUnlocked'] ?? false,
    );
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconCode': icon.codePoint,
      'unlockedAt': unlockedAt.millisecondsSinceEpoch,
      'isUnlocked': isUnlocked,
    };
  }

  /// 创建副本
  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    IconData? icon,
    DateTime? unlockedAt,
    bool? isUnlocked,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }

  @override
  String toString() {
    return 'Achievement(id: $id, title: $title, description: $description, isUnlocked: $isUnlocked)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Achievement && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}