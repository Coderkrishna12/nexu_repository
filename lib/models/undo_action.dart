import 'task_item.dart';

enum UndoActionType {
  added,
  completed,
  rescheduled,
  deleted,
}

class UndoAction {
  final UndoActionType type;
  final String description;
  final TaskItem task;
  final DateTime? previousDueDateTime;
  final bool? previousIsCompleted;

  const UndoAction({
    required this.type,
    required this.description,
    required this.task,
    this.previousDueDateTime,
    this.previousIsCompleted,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'description': description,
      'task': task.toJson(),
      'previousDueDateTime': previousDueDateTime?.toIso8601String(),
      'previousIsCompleted': previousIsCompleted,
    };
  }

  factory UndoAction.fromJson(Map<String, dynamic> json) {
    return UndoAction(
      type: UndoActionType.values.byName(json['type'] as String),
      description: json['description'] as String,
      task: TaskItem.fromJson(json['task'] as Map<String, dynamic>),
      previousDueDateTime: json['previousDueDateTime'] != null
          ? DateTime.parse(json['previousDueDateTime'] as String)
          : null,
      previousIsCompleted: json['previousIsCompleted'] as bool?,
    );
  }
}
