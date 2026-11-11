import 'task_priority.dart';

class TaskItem {
  final String id;
  final String title;
  final DateTime dueDateTime;
  final TaskPriority priority;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? updatedAt;

  TaskItem({
    required this.id,
    required this.title,
    required this.dueDateTime,
    this.priority = TaskPriority.normal,
    this.isCompleted = false,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  TaskItem copyWith({
    String? id,
    String? title,
    DateTime? dueDateTime,
    TaskPriority? priority,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      dueDateTime: dueDateTime ?? this.dueDateTime,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'dueDateTime': dueDateTime.toIso8601String(),
      'priority': priority.name,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] as String,
      title: json['title'] as String,
      dueDateTime: DateTime.parse(json['dueDateTime'] as String),
      priority: TaskPriority.fromString(json['priority'] as String?),
      isCompleted: (json['isCompleted'] as bool?) ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          dueDateTime == other.dueDateTime &&
          priority == other.priority &&
          isCompleted == other.isCompleted;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      dueDateTime.hashCode ^
      priority.hashCode ^
      isCompleted.hashCode;
}
