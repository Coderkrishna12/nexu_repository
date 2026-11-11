import 'package:uuid/uuid.dart';

import '../models/command_intent.dart';
import '../models/command_result.dart';
import '../models/conversation_state.dart';
import '../models/parsed_command.dart';
import '../models/task_item.dart';
import '../models/task_priority.dart';
import '../models/undo_action.dart';
import 'date_time_parser.dart';
import 'intent_classifier.dart';

class CommandEngine {
  static const _uuid = Uuid();
  static const int maxUndoHistory = 5;

  /// Pure execution function:
  /// Takes user raw text, current tasks, conversation state, undo stack,
  /// last mentioned task ID, and demo clock.
  /// Returns a new [CommandResult] without any external side-effects.
  static CommandResult processInput({
    required String rawInput,
    required List<TaskItem> currentTasks,
    required ConversationState conversationState,
    required List<UndoAction> undoStack,
    required String? lastMentionedTaskId,
    required DateTime demoClock,
  }) {
    // 1. Parse the command using our pure Intent Classifier
    final parsed = IntentClassifier.parse(
      rawInput,
      conversationState: conversationState,
      demoClock: demoClock,
    );

    // 2. Route based on active conversational state OR intent
    if (conversationState.isWaitingForInput) {
      // If the user issues a fresh command (ADD, COMPLETE, RESCHEDULE, DELETE, LIST, UNDO),
      // allow it to supersede/preempt the previous question rather than trapping the user in deadlock.
      if (parsed.intent != CommandIntent.confirmYes &&
          parsed.intent != CommandIntent.confirmNo &&
          parsed.intent != CommandIntent.selectOption &&
          parsed.intent != CommandIntent.unknown) {
        conversationState = ConversationState.idle;
      } else {
        return _handleActiveStateResponse(
          parsed: parsed,
          currentTasks: currentTasks,
          conversationState: conversationState,
          undoStack: undoStack,
          lastMentionedTaskId: lastMentionedTaskId,
          demoClock: demoClock,
        );
      }
    }

    // 3. Handle standard intents
    switch (parsed.intent) {
      case CommandIntent.add:
        return _handleAdd(
          parsed: parsed,
          currentTasks: currentTasks,
          conversationState: conversationState,
          undoStack: undoStack,
          lastMentionedTaskId: lastMentionedTaskId,
          demoClock: demoClock,
        );

      case CommandIntent.complete:
        return _handleComplete(
          parsed: parsed,
          currentTasks: currentTasks,
          conversationState: conversationState,
          undoStack: undoStack,
          lastMentionedTaskId: lastMentionedTaskId,
          demoClock: demoClock,
        );

      case CommandIntent.reschedule:
        return _handleReschedule(
          parsed: parsed,
          currentTasks: currentTasks,
          conversationState: conversationState,
          undoStack: undoStack,
          lastMentionedTaskId: lastMentionedTaskId,
          demoClock: demoClock,
        );

      case CommandIntent.delete:
        return _handleDelete(
          parsed: parsed,
          currentTasks: currentTasks,
          conversationState: conversationState,
          undoStack: undoStack,
          lastMentionedTaskId: lastMentionedTaskId,
          demoClock: demoClock,
        );

      case CommandIntent.list:
        return _handleList(
          parsed: parsed,
          currentTasks: currentTasks,
          conversationState: conversationState,
          undoStack: undoStack,
          lastMentionedTaskId: lastMentionedTaskId,
          demoClock: demoClock,
        );

      case CommandIntent.undo:
        return _handleUndo(
          parsed: parsed,
          currentTasks: currentTasks,
          conversationState: conversationState,
          undoStack: undoStack,
          lastMentionedTaskId: lastMentionedTaskId,
        );

      case CommandIntent.confirmYes:
      case CommandIntent.confirmNo:
      case CommandIntent.selectOption:
      case CommandIntent.unknown:
        // Rule C6: Low confidence or unknown command -> no action, ask to rephrase
        return CommandResult(
          parsedCommand: parsed,
          spokenResponse: "I didn't understand that. Please try rephrasing.",
          visualMessage: "Confidence Low: Unknown command. No action taken.",
          updatedTasks: currentTasks,
          updatedConversationState: conversationState,
          updatedUndoStack: undoStack,
          lastMentionedTaskId: lastMentionedTaskId,
          wasExecuted: false,
        );
    }
  }

  // -------------------------------------------------------------
  // Conversational Turn Handling (Past Time, Ambiguity, Delete)
  // -------------------------------------------------------------
  static CommandResult _handleActiveStateResponse({
    required ParsedCommand parsed,
    required List<TaskItem> currentTasks,
    required ConversationState conversationState,
    required List<UndoAction> undoStack,
    required String? lastMentionedTaskId,
    required DateTime demoClock,
  }) {
    // State 1: Past Time Confirmation (Rule C2)
    if (conversationState.status == ConversationStatus.awaitingPastTimeConfirmation) {
      if (parsed.intent == CommandIntent.confirmYes) {
        final pending = conversationState.pendingTask;
        if (pending != null) {
          // Move date to tomorrow
          final tomorrow = demoClock.add(const Duration(days: 1));
          final newDueDateTime = DateTime(
            tomorrow.year,
            tomorrow.month,
            tomorrow.day,
            pending.dueDateTime.hour,
            pending.dueDateTime.minute,
          );
          final updatedTask = pending.copyWith(dueDateTime: newDueDateTime);
          final newTasks = [...currentTasks, updatedTask];

          final undoItem = UndoAction(
            type: UndoActionType.added,
            description: "added '${updatedTask.title}'",
            task: updatedTask,
          );
          final newUndoStack = _pushUndo(undoStack, undoItem);

          final dateStr = DateTimeParser.formatFullDateTime(newDueDateTime);
          final response = "Added '${updatedTask.title}', due $dateStr.";

          return CommandResult(
            parsedCommand: parsed,
            spokenResponse: response,
            visualMessage: response,
            updatedTasks: newTasks,
            updatedConversationState: ConversationState.idle,
            updatedUndoStack: newUndoStack,
            lastMentionedTaskId: updatedTask.id,
            wasExecuted: true,
          );
        }
      } else if (parsed.intent == CommandIntent.confirmNo) {
        return CommandResult(
          parsedCommand: parsed,
          spokenResponse: "Task cancelled.",
          visualMessage: "Task creation cancelled.",
          updatedTasks: currentTasks,
          updatedConversationState: ConversationState.idle,
          updatedUndoStack: undoStack,
          lastMentionedTaskId: lastMentionedTaskId,
          wasExecuted: false,
        );
      }
    }

    // State 2: Ambiguity Resolution (Rule C4)
    if (conversationState.status == ConversationStatus.awaitingAmbiguityResolution) {
      if (parsed.intent == CommandIntent.selectOption && parsed.targetIndex != null) {
        final index = parsed.targetIndex!;
        final candidateIds = conversationState.candidateTaskIds;
        if (index >= 0 && index < candidateIds.length) {
          final chosenId = candidateIds[index];
          final chosenTask = currentTasks.firstWhere((t) => t.id == chosenId);

          // Now execute the pending intent on this chosen task!
          if (conversationState.pendingIntent == CommandIntent.complete) {
            final updatedTasks = currentTasks.map((t) {
              return t.id == chosenId ? t.copyWith(isCompleted: true) : t;
            }).toList();

            final undoItem = UndoAction(
              type: UndoActionType.completed,
              description: "marked '${chosenTask.title}' done",
              task: chosenTask,
              previousIsCompleted: chosenTask.isCompleted,
            );
            final newUndoStack = _pushUndo(undoStack, undoItem);

            final response = "Marked '${chosenTask.title}' done.";
            return CommandResult(
              parsedCommand: parsed,
              spokenResponse: response,
              visualMessage: response,
              updatedTasks: updatedTasks,
              updatedConversationState: ConversationState.idle,
              updatedUndoStack: newUndoStack,
              lastMentionedTaskId: chosenId,
              wasExecuted: true,
            );
          } else if (conversationState.pendingIntent == CommandIntent.delete) {
            // Initiate C5 confirmation for chosen task
            return CommandResult(
              parsedCommand: parsed,
              spokenResponse: "Are you sure you want to delete '${chosenTask.title}'?",
              visualMessage: "Confirm deletion of '${chosenTask.title}' (voice or tap, 8s timeout)",
              updatedTasks: currentTasks,
              updatedConversationState: ConversationState(
                status: ConversationStatus.awaitingDeleteConfirmation,
                targetTaskId: chosenId,
                awaitingSince: DateTime.now(),
                questionPrompt: "Are you sure you want to delete '${chosenTask.title}'?",
              ),
              updatedUndoStack: undoStack,
              lastMentionedTaskId: chosenId,
              wasExecuted: false,
              requiresConfirmation: true,
            );
          }
        }
      }
    }

    // State 3: Delete Confirmation (Rule C5)
    if (conversationState.status == ConversationStatus.awaitingDeleteConfirmation) {
      final targetId = conversationState.targetTaskId;
      final targetTask = currentTasks.cast<TaskItem?>().firstWhere(
            (t) => t?.id == targetId,
            orElse: () => null,
          );

      if (parsed.intent == CommandIntent.confirmYes && targetTask != null) {
        final updatedTasks = currentTasks.where((t) => t.id != targetId).toList();
        final undoItem = UndoAction(
          type: UndoActionType.deleted,
          description: "deleted '${targetTask.title}'",
          task: targetTask,
        );
        final newUndoStack = _pushUndo(undoStack, undoItem);

        final response = "Deleted '${targetTask.title}'.";
        return CommandResult(
          parsedCommand: parsed,
          spokenResponse: response,
          visualMessage: response,
          updatedTasks: updatedTasks,
          updatedConversationState: ConversationState.idle,
          updatedUndoStack: newUndoStack,
          lastMentionedTaskId: null,
          wasExecuted: true,
        );
      } else if (parsed.intent == CommandIntent.confirmNo) {
        return CommandResult(
          parsedCommand: parsed,
          spokenResponse: "Deletion cancelled.",
          visualMessage: "Deletion cancelled.",
          updatedTasks: currentTasks,
          updatedConversationState: ConversationState.idle,
          updatedUndoStack: undoStack,
          lastMentionedTaskId: lastMentionedTaskId,
          wasExecuted: false,
        );
      }
    }

    // If state is not resolved by response, repeat prompt or fallback
    return CommandResult(
      parsedCommand: parsed,
      spokenResponse: conversationState.questionPrompt ?? "Please answer the question.",
      visualMessage: conversationState.questionPrompt ?? "Awaiting answer.",
      updatedTasks: currentTasks,
      updatedConversationState: conversationState,
      updatedUndoStack: undoStack,
      lastMentionedTaskId: lastMentionedTaskId,
      wasExecuted: false,
    );
  }

  // -------------------------------------------------------------
  // ADD Intent Handler (Rules C1, C2, C6)
  // -------------------------------------------------------------
  static CommandResult _handleAdd({
    required ParsedCommand parsed,
    required List<TaskItem> currentTasks,
    required ConversationState conversationState,
    required List<UndoAction> undoStack,
    required String? lastMentionedTaskId,
    required DateTime demoClock,
  }) {
    final title = parsed.title?.trim() ?? 'Untitled Task';
    final targetDate = parsed.targetDate ?? DateTime(demoClock.year, demoClock.month, demoClock.day);
    final timeMinutes = parsed.targetTimeMinutes ?? (9 * 60);
    final priority = parsed.priority ?? TaskPriority.normal;

    final hour = timeMinutes ~/ 60;
    final minute = timeMinutes % 60;
    final scheduledDue = DateTime(targetDate.year, targetDate.month, targetDate.day, hour, minute);

    final newTask = TaskItem(
      id: _uuid.v4(),
      title: title,
      dueDateTime: scheduledDue,
      priority: priority,
    );

    // Rule C2: Past Time Check
    // If the resulting time has already passed on the demo clock, do not save.
    // Ask: "That time has passed. Move it to tomorrow?" and wait for yes or no.
    if (scheduledDue.isBefore(demoClock)) {
      const question = "That time has passed. Move it to tomorrow?";
      return CommandResult(
        parsedCommand: parsed,
        spokenResponse: question,
        visualMessage: question,
        updatedTasks: currentTasks,
        updatedConversationState: ConversationState(
          status: ConversationStatus.awaitingPastTimeConfirmation,
          pendingTask: newTask,
          awaitingSince: DateTime.now(),
          questionPrompt: question,
        ),
        updatedUndoStack: undoStack,
        lastMentionedTaskId: lastMentionedTaskId,
        wasExecuted: false,
        requiresConfirmation: true,
      );
    }

    // Future time -> Save task immediately
    final updatedTasks = [...currentTasks, newTask];
    final undoItem = UndoAction(
      type: UndoActionType.added,
      description: "added '$title'",
      task: newTask,
    );
    final newUndoStack = _pushUndo(undoStack, undoItem);

    final dateStr = DateTimeParser.formatFullDateTime(scheduledDue);
    final spokenResponse = "Added '$title', due $dateStr, ${priority.displayName} priority.";
    final visualMsg = "Task added: '$title' (${priority.displayName}), Due: $dateStr.";

    return CommandResult(
      parsedCommand: parsed,
      spokenResponse: spokenResponse,
      visualMessage: visualMsg,
      updatedTasks: updatedTasks,
      updatedConversationState: ConversationState.idle,
      updatedUndoStack: newUndoStack,
      lastMentionedTaskId: newTask.id,
      wasExecuted: true,
    );
  }

  // -------------------------------------------------------------
  // COMPLETE Intent Handler (Rules C3, C4)
  // -------------------------------------------------------------
  static CommandResult _handleComplete({
    required ParsedCommand parsed,
    required List<TaskItem> currentTasks,
    required ConversationState conversationState,
    required List<UndoAction> undoStack,
    required String? lastMentionedTaskId,
    required DateTime demoClock,
  }) {
    final query = parsed.targetQuery?.toLowerCase().trim() ?? '';
    final resolved = _resolveTargetTasks(query, currentTasks, lastMentionedTaskId);

    if (resolved.isContextMissing) {
      const msg = "Which task do you want to complete?";
      return CommandResult(
        parsedCommand: parsed,
        spokenResponse: msg,
        visualMessage: msg,
        updatedTasks: currentTasks,
        updatedConversationState: conversationState,
        updatedUndoStack: undoStack,
        lastMentionedTaskId: lastMentionedTaskId,
        wasExecuted: false,
      );
    }

    if (resolved.matches.isEmpty) {
      final msg = "I couldn't find any task matching '$query'.";
      return CommandResult(
        parsedCommand: parsed,
        spokenResponse: msg,
        visualMessage: msg,
        updatedTasks: currentTasks,
        updatedConversationState: conversationState,
        updatedUndoStack: undoStack,
        lastMentionedTaskId: lastMentionedTaskId,
        wasExecuted: false,
      );
    }

    // Rule C4: Ambiguity
    if (resolved.matches.length > 1) {
      const question = "Which one?";
      return CommandResult(
        parsedCommand: parsed,
        spokenResponse: question,
        visualMessage: "Which one? Multiple tasks match '$query'.",
        updatedTasks: currentTasks,
        updatedConversationState: ConversationState(
          status: ConversationStatus.awaitingAmbiguityResolution,
          candidateTaskIds: resolved.matches.map((t) => t.id).toList(),
          pendingIntent: CommandIntent.complete,
          awaitingSince: DateTime.now(),
          questionPrompt: question,
        ),
        updatedUndoStack: undoStack,
        lastMentionedTaskId: lastMentionedTaskId,
        wasExecuted: false,
        requiresConfirmation: true,
      );
    }

    // Single matching task
    final targetTask = resolved.matches.first;
    final updatedTasks = currentTasks.map((t) {
      return t.id == targetTask.id ? t.copyWith(isCompleted: true) : t;
    }).toList();

    final undoItem = UndoAction(
      type: UndoActionType.completed,
      description: "marked '${targetTask.title}' done",
      task: targetTask,
      previousIsCompleted: targetTask.isCompleted,
    );
    final newUndoStack = _pushUndo(undoStack, undoItem);

    final response = "Marked '${targetTask.title}' done.";
    return CommandResult(
      parsedCommand: parsed,
      spokenResponse: response,
      visualMessage: response,
      updatedTasks: updatedTasks,
      updatedConversationState: ConversationState.idle,
      updatedUndoStack: newUndoStack,
      lastMentionedTaskId: targetTask.id,
      wasExecuted: true,
    );
  }

  // -------------------------------------------------------------
  // RESCHEDULE Intent Handler (Rules C2, C3, C4)
  // -------------------------------------------------------------
  static CommandResult _handleReschedule({
    required ParsedCommand parsed,
    required List<TaskItem> currentTasks,
    required ConversationState conversationState,
    required List<UndoAction> undoStack,
    required String? lastMentionedTaskId,
    required DateTime demoClock,
  }) {
    final query = parsed.targetQuery?.toLowerCase().trim() ?? '';
    final resolved = _resolveTargetTasks(query, currentTasks, lastMentionedTaskId);

    if (resolved.isContextMissing) {
      const msg = "Which task do you want to move?";
      return CommandResult(
        parsedCommand: parsed,
        spokenResponse: msg,
        visualMessage: msg,
        updatedTasks: currentTasks,
        updatedConversationState: conversationState,
        updatedUndoStack: undoStack,
        lastMentionedTaskId: lastMentionedTaskId,
        wasExecuted: false,
      );
    }

    if (resolved.matches.isEmpty) {
      final msg = "I couldn't find any task matching '$query'.";
      return CommandResult(
        parsedCommand: parsed,
        spokenResponse: msg,
        visualMessage: msg,
        updatedTasks: currentTasks,
        updatedConversationState: conversationState,
        updatedUndoStack: undoStack,
        lastMentionedTaskId: lastMentionedTaskId,
        wasExecuted: false,
      );
    }

    if (resolved.matches.length > 1) {
      const question = "Which one?";
      return CommandResult(
        parsedCommand: parsed,
        spokenResponse: question,
        visualMessage: "Which one? Multiple tasks match '$query'.",
        updatedTasks: currentTasks,
        updatedConversationState: ConversationState(
          status: ConversationStatus.awaitingAmbiguityResolution,
          candidateTaskIds: resolved.matches.map((t) => t.id).toList(),
          pendingIntent: CommandIntent.reschedule,
          awaitingSince: DateTime.now(),
          questionPrompt: question,
        ),
        updatedUndoStack: undoStack,
        lastMentionedTaskId: lastMentionedTaskId,
        wasExecuted: false,
        requiresConfirmation: true,
      );
    }

    final targetTask = resolved.matches.first;
    final targetDate = parsed.targetDate ?? DateTime(demoClock.year, demoClock.month, demoClock.day);
    final timeMinutes = parsed.targetTimeMinutes ?? (targetTask.dueDateTime.hour * 60 + targetTask.dueDateTime.minute);

    final hour = timeMinutes ~/ 60;
    final minute = timeMinutes % 60;
    final newDueDateTime = DateTime(targetDate.year, targetDate.month, targetDate.day, hour, minute);

    // Rule C2: Past Time check on reschedule
    if (newDueDateTime.isBefore(demoClock)) {
      const question = "That time has passed. Move it to tomorrow?";
      final updatedTask = targetTask.copyWith(dueDateTime: newDueDateTime);
      return CommandResult(
        parsedCommand: parsed,
        spokenResponse: question,
        visualMessage: question,
        updatedTasks: currentTasks,
        updatedConversationState: ConversationState(
          status: ConversationStatus.awaitingPastTimeConfirmation,
          pendingTask: updatedTask,
          awaitingSince: DateTime.now(),
          questionPrompt: question,
        ),
        updatedUndoStack: undoStack,
        lastMentionedTaskId: targetTask.id,
        wasExecuted: false,
        requiresConfirmation: true,
      );
    }

    final updatedTasks = currentTasks.map((t) {
      return t.id == targetTask.id ? t.copyWith(dueDateTime: newDueDateTime) : t;
    }).toList();

    final undoItem = UndoAction(
      type: UndoActionType.rescheduled,
      description: "rescheduled '${targetTask.title}'",
      task: targetTask,
      previousDueDateTime: targetTask.dueDateTime,
    );
    final newUndoStack = _pushUndo(undoStack, undoItem);

    final formatted = DateTimeParser.formatFullDateTime(newDueDateTime);
    final response = "Last task rescheduled to $formatted.";

    return CommandResult(
      parsedCommand: parsed,
      spokenResponse: response,
      visualMessage: response,
      updatedTasks: updatedTasks,
      updatedConversationState: ConversationState.idle,
      updatedUndoStack: newUndoStack,
      lastMentionedTaskId: targetTask.id,
      wasExecuted: true,
    );
  }

  // -------------------------------------------------------------
  // DELETE Intent Handler (Rule C5: Safety Confirmation)
  // -------------------------------------------------------------
  static CommandResult _handleDelete({
    required ParsedCommand parsed,
    required List<TaskItem> currentTasks,
    required ConversationState conversationState,
    required List<UndoAction> undoStack,
    required String? lastMentionedTaskId,
    required DateTime demoClock,
  }) {
    final query = parsed.targetQuery?.toLowerCase().trim() ?? '';
    final resolved = _resolveTargetTasks(query, currentTasks, lastMentionedTaskId);

    if (resolved.isContextMissing) {
      const msg = "Which task do you want to delete?";
      return CommandResult(
        parsedCommand: parsed,
        spokenResponse: msg,
        visualMessage: msg,
        updatedTasks: currentTasks,
        updatedConversationState: conversationState,
        updatedUndoStack: undoStack,
        lastMentionedTaskId: lastMentionedTaskId,
        wasExecuted: false,
      );
    }

    if (resolved.matches.isEmpty) {
      final msg = "I couldn't find any task matching '$query'.";
      return CommandResult(
        parsedCommand: parsed,
        spokenResponse: msg,
        visualMessage: msg,
        updatedTasks: currentTasks,
        updatedConversationState: conversationState,
        updatedUndoStack: undoStack,
        lastMentionedTaskId: lastMentionedTaskId,
        wasExecuted: false,
      );
    }

    if (resolved.matches.length > 1) {
      const question = "Which one?";
      return CommandResult(
        parsedCommand: parsed,
        spokenResponse: question,
        visualMessage: "Which one? Multiple tasks match '$query'.",
        updatedTasks: currentTasks,
        updatedConversationState: ConversationState(
          status: ConversationStatus.awaitingAmbiguityResolution,
          candidateTaskIds: resolved.matches.map((t) => t.id).toList(),
          pendingIntent: CommandIntent.delete,
          awaitingSince: DateTime.now(),
          questionPrompt: question,
        ),
        updatedUndoStack: undoStack,
        lastMentionedTaskId: lastMentionedTaskId,
        wasExecuted: false,
        requiresConfirmation: true,
      );
    }

    // Rule C5: DELETE always needs confirmation by voice ("yes"/"no") or tap
    // No answer within 8 seconds means cancel
    final targetTask = resolved.matches.first;
    final prompt = "Are you sure you want to delete '${targetTask.title}'?";

    return CommandResult(
      parsedCommand: parsed,
      spokenResponse: prompt,
      visualMessage: "Confirm delete '${targetTask.title}'? (8s timeout)",
      updatedTasks: currentTasks,
      updatedConversationState: ConversationState(
        status: ConversationStatus.awaitingDeleteConfirmation,
        targetTaskId: targetTask.id,
        awaitingSince: DateTime.now(),
        questionPrompt: prompt,
      ),
      updatedUndoStack: undoStack,
      lastMentionedTaskId: targetTask.id,
      wasExecuted: false,
      requiresConfirmation: true,
    );
  }

  // -------------------------------------------------------------
  // LIST Intent Handler
  // -------------------------------------------------------------
  static CommandResult _handleList({
    required ParsedCommand parsed,
    required List<TaskItem> currentTasks,
    required ConversationState conversationState,
    required List<UndoAction> undoStack,
    required String? lastMentionedTaskId,
    required DateTime demoClock,
  }) {
    final filterDate = parsed.targetDate;
    List<TaskItem> matchingTasks;

    if (filterDate != null) {
      matchingTasks = currentTasks.where((t) {
        return t.dueDateTime.year == filterDate.year &&
            t.dueDateTime.month == filterDate.month &&
            t.dueDateTime.day == filterDate.day;
      }).toList();
    } else {
      matchingTasks = currentTasks;
    }

    final dateFormatted = filterDate != null
        ? DateTimeParser.formatDateOnly(filterDate)
        : "all time";

    if (matchingTasks.isEmpty) {
      final msg = "You have no tasks due $dateFormatted.";
      return CommandResult(
        parsedCommand: parsed,
        spokenResponse: msg,
        visualMessage: msg,
        updatedTasks: currentTasks,
        updatedConversationState: ConversationState.idle,
        updatedUndoStack: undoStack,
        lastMentionedTaskId: lastMentionedTaskId,
        wasExecuted: true,
      );
    }

    final count = matchingTasks.length;
    final taskWord = count == 1 ? "task" : "tasks";
    final titles = matchingTasks.map((t) => t.title).join(", ");
    final spokenResponse = "You have $count $taskWord due $dateFormatted: $titles.";
    final visualMsg = "Tasks due $dateFormatted ($count): $titles.";

    // If there's only 1 task or last listed, set as context
    final newContextId = matchingTasks.isNotEmpty ? matchingTasks.last.id : lastMentionedTaskId;

    return CommandResult(
      parsedCommand: parsed,
      spokenResponse: spokenResponse,
      visualMessage: visualMsg,
      updatedTasks: currentTasks,
      updatedConversationState: ConversationState.idle,
      updatedUndoStack: undoStack,
      lastMentionedTaskId: newContextId,
      wasExecuted: true,
    );
  }

  // -------------------------------------------------------------
  // UNDO Intent Handler (Rule C7)
  // -------------------------------------------------------------
  static CommandResult _handleUndo({
    required ParsedCommand parsed,
    required List<TaskItem> currentTasks,
    required ConversationState conversationState,
    required List<UndoAction> undoStack,
    required String? lastMentionedTaskId,
  }) {
    if (undoStack.isEmpty) {
      const msg = "Nothing to undo.";
      return CommandResult(
        parsedCommand: parsed,
        spokenResponse: msg,
        visualMessage: msg,
        updatedTasks: currentTasks,
        updatedConversationState: ConversationState.idle,
        updatedUndoStack: undoStack,
        lastMentionedTaskId: lastMentionedTaskId,
        wasExecuted: false,
      );
    }

    // Pop the most recent action
    final actionToUndo = undoStack.first;
    final remainingUndo = undoStack.sublist(1);
    List<TaskItem> updatedTasks = List.from(currentTasks);
    String? newContextId = lastMentionedTaskId;

    switch (actionToUndo.type) {
      case UndoActionType.added:
        // Undo ADD -> Remove the task
        updatedTasks.removeWhere((t) => t.id == actionToUndo.task.id);
        newContextId = updatedTasks.isNotEmpty ? updatedTasks.last.id : null;
        break;

      case UndoActionType.completed:
        // Undo COMPLETE -> Restore previous isCompleted status
        updatedTasks = updatedTasks.map((t) {
          return t.id == actionToUndo.task.id
              ? t.copyWith(isCompleted: actionToUndo.previousIsCompleted ?? false)
              : t;
        }).toList();
        newContextId = actionToUndo.task.id;
        break;

      case UndoActionType.rescheduled:
        // Undo RESCHEDULE -> Restore previous dueDateTime
        updatedTasks = updatedTasks.map((t) {
          return t.id == actionToUndo.task.id
              ? t.copyWith(dueDateTime: actionToUndo.previousDueDateTime)
              : t;
        }).toList();
        newContextId = actionToUndo.task.id;
        break;

      case UndoActionType.deleted:
        // Undo DELETE -> Re-add the deleted task
        updatedTasks.add(actionToUndo.task);
        newContextId = actionToUndo.task.id;
        break;
    }

    final spoken = "Reversed: ${actionToUndo.description}.";
    final visual = "Undo successful: reversed ${actionToUndo.description}.";

    return CommandResult(
      parsedCommand: parsed,
      spokenResponse: spoken,
      visualMessage: visual,
      updatedTasks: updatedTasks,
      updatedConversationState: ConversationState.idle,
      updatedUndoStack: remainingUndo,
      lastMentionedTaskId: newContextId,
      wasExecuted: true,
    );
  }

  // -------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------
  static _ResolvedTasks _resolveTargetTasks(
    String query,
    List<TaskItem> tasks,
    String? lastMentionedTaskId,
  ) {
    if (query == 'it' || query == 'that' || query == 'the last task' || query == 'last task' || query == 'this') {
      if (lastMentionedTaskId != null) {
        final task = tasks.cast<TaskItem?>().firstWhere(
              (t) => t?.id == lastMentionedTaskId,
              orElse: () => null,
            );
        if (task != null) {
          return _ResolvedTasks(matches: [task]);
        }
      }
      // If no lastMentionedTaskId, return most recent task if available or context missing
      if (tasks.isNotEmpty) {
        return _ResolvedTasks(matches: [tasks.last]);
      }
      return const _ResolvedTasks(matches: [], isContextMissing: true);
    }

    // Otherwise, match against task titles (case-insensitive substring)
    final matches = tasks.where((t) => t.title.toLowerCase().contains(query)).toList();
    return _ResolvedTasks(matches: matches);
  }

  static List<UndoAction> _pushUndo(List<UndoAction> stack, UndoAction action) {
    final list = [action, ...stack];
    if (list.length > maxUndoHistory) {
      return list.sublist(0, maxUndoHistory);
    }
    return list;
  }
}

class _ResolvedTasks {
  final List<TaskItem> matches;
  final bool isContextMissing;

  const _ResolvedTasks({
    required this.matches,
    this.isContextMissing = false,
  });
}
