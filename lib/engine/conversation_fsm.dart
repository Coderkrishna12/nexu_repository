import '../models/command_intent.dart';
import '../models/command_result.dart';
import '../models/conversation_state.dart';
import '../models/parsed_command.dart';
import '../models/task_item.dart';
import '../models/undo_action.dart';
import 'task_commands.dart';

/// Context passed to FSM steps during multi-turn evaluation.
class FsmContext {
  final ParsedCommand parsed;
  final List<TaskItem> currentTasks;
  final ConversationState conversationState;
  final List<UndoAction> undoStack;
  final String? lastMentionedTaskId;
  final DateTime demoClock;

  const FsmContext({
    required this.parsed,
    required this.currentTasks,
    required this.conversationState,
    required this.undoStack,
    required this.lastMentionedTaskId,
    required this.demoClock,
  });
}

/// Abstract state node in the Conversation Finite State Machine.
abstract class ConversationStep {
  CommandResult handle(FsmContext ctx);
}

/// Idle Step: User is not in a pending confirmation dialogue.
class IdleStep implements ConversationStep {
  const IdleStep();

  @override
  CommandResult handle(FsmContext ctx) {
    return CommandResult(
      parsedCommand: ctx.parsed,
      spokenResponse: "I didn't understand that. Please try rephrasing.",
      visualMessage: "Confidence Low: Unknown command. No action taken.",
      updatedTasks: ctx.currentTasks,
      updatedConversationState: ConversationState.idle,
      updatedUndoStack: ctx.undoStack,
      lastMentionedTaskId: ctx.lastMentionedTaskId,
      wasExecuted: false,
    );
  }
}

/// Awaiting Past Time Confirmation Step (Rule C2).
class AwaitingPastTimeStep implements ConversationStep {
  const AwaitingPastTimeStep();

  @override
  CommandResult handle(FsmContext ctx) {
    final pending = ctx.conversationState.pendingTask;
    if (pending == null) {
      return const IdleStep().handle(ctx);
    }

    if (ctx.parsed.intent == CommandIntent.confirmYes) {
      // Move to tomorrow at the requested time
      final movedTime = DateTime(
        ctx.demoClock.year,
        ctx.demoClock.month,
        ctx.demoClock.day + 1,
        pending.dueDateTime.hour,
        pending.dueDateTime.minute,
      );
      final finalTask = pending.copyWith(dueDateTime: movedTime);
      final cmd = AddTaskCommand(finalTask);
      final updatedTasks = cmd.execute(ctx.currentTasks);
      final updatedUndo = [cmd.toUndoAction(), ...ctx.undoStack];

      final spokenTime = (finalTask.dueDateTime.minute == 0)
          ? '${finalTask.dueDateTime.hour > 12 ? finalTask.dueDateTime.hour - 12 : finalTask.dueDateTime.hour} ${finalTask.dueDateTime.hour >= 12 ? "PM" : "AM"}'
          : '${finalTask.dueDateTime.hour > 12 ? finalTask.dueDateTime.hour - 12 : finalTask.dueDateTime.hour}:${finalTask.dueDateTime.minute.toString().padLeft(2, '0')} ${finalTask.dueDateTime.hour >= 12 ? "PM" : "AM"}';

      return CommandResult(
        parsedCommand: ctx.parsed,
        spokenResponse: "Moved to tomorrow at $spokenTime.",
        visualMessage:
            "Task '${finalTask.title}' scheduled for tomorrow at $spokenTime.",
        updatedTasks: updatedTasks,
        updatedConversationState: ConversationState.idle,
        updatedUndoStack: updatedUndo,
        lastMentionedTaskId: finalTask.id,
        wasExecuted: true,
      );
    } else if (ctx.parsed.intent == CommandIntent.confirmNo) {
      return CommandResult(
        parsedCommand: ctx.parsed,
        spokenResponse: "Task cancelled.",
        visualMessage: "Task was not created.",
        updatedTasks: ctx.currentTasks,
        updatedConversationState: ConversationState.idle,
        updatedUndoStack: ctx.undoStack,
        lastMentionedTaskId: ctx.lastMentionedTaskId,
        wasExecuted: false,
      );
    }

    // Default: re-prompt
    return CommandResult(
      parsedCommand: ctx.parsed,
      spokenResponse: "Please say yes to move to tomorrow, or no to cancel.",
      visualMessage: "Awaiting confirmation: move to tomorrow?",
      updatedTasks: ctx.currentTasks,
      updatedConversationState: ctx.conversationState,
      updatedUndoStack: ctx.undoStack,
      lastMentionedTaskId: ctx.lastMentionedTaskId,
      wasExecuted: false,
      requiresConfirmation: true,
    );
  }
}

/// Awaiting Delete Confirmation Step (Rule C5).
class AwaitingDeleteStep implements ConversationStep {
  const AwaitingDeleteStep();

  @override
  CommandResult handle(FsmContext ctx) {
    final pending = ctx.conversationState.pendingTask;
    if (pending == null) {
      return const IdleStep().handle(ctx);
    }

    if (ctx.parsed.intent == CommandIntent.confirmYes) {
      final cmd = DeleteTaskCommand(pending);
      final updatedTasks = cmd.execute(ctx.currentTasks);
      final updatedUndo = [cmd.toUndoAction(), ...ctx.undoStack];

      return CommandResult(
        parsedCommand: ctx.parsed,
        spokenResponse: "Deleted task '${pending.title}'.",
        visualMessage: "Deleted task '${pending.title}'.",
        updatedTasks: updatedTasks,
        updatedConversationState: ConversationState.idle,
        updatedUndoStack: updatedUndo,
        lastMentionedTaskId: updatedTasks.isNotEmpty
            ? updatedTasks.last.id
            : null,
        wasExecuted: true,
      );
    } else if (ctx.parsed.intent == CommandIntent.confirmNo) {
      return CommandResult(
        parsedCommand: ctx.parsed,
        spokenResponse: "Task kept.",
        visualMessage: "Deletion cancelled. Task retained.",
        updatedTasks: ctx.currentTasks,
        updatedConversationState: ConversationState.idle,
        updatedUndoStack: ctx.undoStack,
        lastMentionedTaskId: pending.id,
        wasExecuted: false,
      );
    }

    return CommandResult(
      parsedCommand: ctx.parsed,
      spokenResponse:
          "Are you sure you want to delete '${pending.title}'? Say yes or no.",
      visualMessage: "Confirm deletion: '${pending.title}'?",
      updatedTasks: ctx.currentTasks,
      updatedConversationState: ctx.conversationState,
      updatedUndoStack: ctx.undoStack,
      lastMentionedTaskId: ctx.lastMentionedTaskId,
      wasExecuted: false,
      requiresConfirmation: true,
    );
  }
}

/// Awaiting Ambiguity Resolution Step (Rule C4).
class AwaitingAmbiguityStep implements ConversationStep {
  const AwaitingAmbiguityStep();

  @override
  CommandResult handle(FsmContext ctx) {
    final candidates = ctx.conversationState.candidateTaskIds;
    if (candidates.isEmpty) {
      return const IdleStep().handle(ctx);
    }

    int? selectedIndex;
    if (ctx.parsed.targetIndex != null) {
      selectedIndex = ctx.parsed.targetIndex;
    } else {
      // Check if user spoke a title word matching one candidate
      final lower = ctx.parsed.rawText.toLowerCase();
      for (var i = 0; i < candidates.length; i++) {
        final match = ctx.currentTasks
            .where((t) => t.id == candidates[i])
            .firstOrNull;
        if (match != null && lower.contains(match.title.toLowerCase())) {
          selectedIndex = i;
          break;
        }
      }
    }

    if (selectedIndex != null &&
        selectedIndex >= 0 &&
        selectedIndex < candidates.length) {
      final chosenId = candidates[selectedIndex];
      final targetTask = ctx.currentTasks
          .where((t) => t.id == chosenId)
          .firstOrNull;
      if (targetTask != null) {
        final cmd = ToggleCompleteTaskCommand(
          taskId: targetTask.id,
          targetCompletedStatus: true,
          previousCompletedStatus: targetTask.isCompleted,
          originalTask: targetTask,
        );
        final updatedTasks = cmd.execute(ctx.currentTasks);
        final updatedUndo = [cmd.toUndoAction(), ...ctx.undoStack];

        return CommandResult(
          parsedCommand: ctx.parsed,
          spokenResponse: "Marked '${targetTask.title}' done.",
          visualMessage: "Marked task '${targetTask.title}' as complete.",
          updatedTasks: updatedTasks,
          updatedConversationState: ConversationState.idle,
          updatedUndoStack: updatedUndo,
          lastMentionedTaskId: targetTask.id,
          wasExecuted: true,
        );
      }
    }

    return CommandResult(
      parsedCommand: ctx.parsed,
      spokenResponse: "Which one did you mean? Please specify.",
      visualMessage: "Ambiguity: Multiple tasks matched. Please select one.",
      updatedTasks: ctx.currentTasks,
      updatedConversationState: ctx.conversationState,
      updatedUndoStack: ctx.undoStack,
      lastMentionedTaskId: ctx.lastMentionedTaskId,
      wasExecuted: false,
      requiresConfirmation: true,
    );
  }
}
