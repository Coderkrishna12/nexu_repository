import '../models/task_item.dart';
import '../models/undo_action.dart';

/// Abstract Command representing an invertible operation on the task collection.
/// Implements the Command Pattern for transactional undo/redo (Rule C7).
abstract class TaskCommand {
  /// Executes the operation on [currentTasks] and returns the updated list.
  List<TaskItem> execute(List<TaskItem> currentTasks);

  /// Reverses the operation, restoring the previous state.
  List<TaskItem> unexecute(List<TaskItem> currentTasks);

  /// Converts this command into a persistent [UndoAction] for storage.
  UndoAction toUndoAction();
}

/// Command to add a new task item.
class AddTaskCommand implements TaskCommand {
  final TaskItem task;

  const AddTaskCommand(this.task);

  @override
  List<TaskItem> execute(List<TaskItem> currentTasks) {
    return [...currentTasks, task];
  }

  @override
  List<TaskItem> unexecute(List<TaskItem> currentTasks) {
    return currentTasks.where((t) => t.id != task.id).toList();
  }

  @override
  UndoAction toUndoAction() {
    return UndoAction(
      type: UndoActionType.added,
      description: "added '${task.title}'",
      task: task,
    );
  }
}

/// Command to complete or uncomplete a task.
class ToggleCompleteTaskCommand implements TaskCommand {
  final String taskId;
  final bool targetCompletedStatus;
  final bool previousCompletedStatus;
  final TaskItem originalTask;

  const ToggleCompleteTaskCommand({
    required this.taskId,
    required this.targetCompletedStatus,
    required this.previousCompletedStatus,
    required this.originalTask,
  });

  @override
  List<TaskItem> execute(List<TaskItem> currentTasks) {
    return currentTasks.map((t) {
      return (t.id == taskId)
          ? t.copyWith(isCompleted: targetCompletedStatus)
          : t;
    }).toList();
  }

  @override
  List<TaskItem> unexecute(List<TaskItem> currentTasks) {
    return currentTasks.map((t) {
      return (t.id == taskId)
          ? t.copyWith(isCompleted: previousCompletedStatus)
          : t;
    }).toList();
  }

  @override
  UndoAction toUndoAction() {
    return UndoAction(
      type: UndoActionType.completed,
      description:
          "marked '${originalTask.title}' as ${targetCompletedStatus ? 'done' : 'pending'}",
      task: originalTask,
      previousIsCompleted: previousCompletedStatus,
    );
  }
}

/// Command to reschedule a task due timestamp.
class RescheduleTaskCommand implements TaskCommand {
  final String taskId;
  final DateTime newDueDateTime;
  final DateTime previousDueDateTime;
  final TaskItem originalTask;

  const RescheduleTaskCommand({
    required this.taskId,
    required this.newDueDateTime,
    required this.previousDueDateTime,
    required this.originalTask,
  });

  @override
  List<TaskItem> execute(List<TaskItem> currentTasks) {
    return currentTasks.map((t) {
      return (t.id == taskId) ? t.copyWith(dueDateTime: newDueDateTime) : t;
    }).toList();
  }

  @override
  List<TaskItem> unexecute(List<TaskItem> currentTasks) {
    return currentTasks.map((t) {
      return (t.id == taskId)
          ? t.copyWith(dueDateTime: previousDueDateTime)
          : t;
    }).toList();
  }

  @override
  UndoAction toUndoAction() {
    return UndoAction(
      type: UndoActionType.rescheduled,
      description: "rescheduled '${originalTask.title}'",
      task: originalTask,
      previousDueDateTime: previousDueDateTime,
    );
  }
}

/// Command to delete a task item.
class DeleteTaskCommand implements TaskCommand {
  final TaskItem deletedTask;

  const DeleteTaskCommand(this.deletedTask);

  @override
  List<TaskItem> execute(List<TaskItem> currentTasks) {
    return currentTasks.where((t) => t.id != deletedTask.id).toList();
  }

  @override
  List<TaskItem> unexecute(List<TaskItem> currentTasks) {
    return [...currentTasks, deletedTask];
  }

  @override
  UndoAction toUndoAction() {
    return UndoAction(
      type: UndoActionType.deleted,
      description: "deleted '${deletedTask.title}'",
      task: deletedTask,
    );
  }
}
