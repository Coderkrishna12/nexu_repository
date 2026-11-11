import 'package:flutter_test/flutter_test.dart';
import 'package:nexu_voicedesk/engine/command_engine.dart';
import 'package:nexu_voicedesk/models/command_intent.dart';
import 'package:nexu_voicedesk/models/confidence_level.dart';
import 'package:nexu_voicedesk/models/conversation_state.dart';
import 'package:nexu_voicedesk/models/task_item.dart';
import 'package:nexu_voicedesk/models/task_priority.dart';
import 'package:nexu_voicedesk/models/undo_action.dart';

void main() {
  group('NEXU VoiceDesk Acceptance Examples & Rules Test Suite', () {
    // Standard assessment demo clock: Wednesday, 11 November 2026, 10:00 AM
    final demoClock = DateTime(2026, 11, 11, 10, 0);

    test('Example 1: add task buy cable tomorrow at 5 pm high priority', () {
      final result = CommandEngine.processInput(
        rawInput: 'add task buy cable tomorrow at 5 pm high priority',
        currentTasks: [],
        conversationState: ConversationState.idle,
        undoStack: [],
        lastMentionedTaskId: null,
        demoClock: demoClock,
      );

      expect(result.intent, equals(CommandIntent.add));
      expect(result.confidence, equals(ConfidenceLevel.high));
      expect(result.updatedTasks.length, equals(1));

      final task = result.updatedTasks.first;
      expect(task.title, equals('buy cable'));
      // Tomorrow is Thu 12 Nov 2026, 5:00 PM (17:00)
      expect(task.dueDateTime.year, equals(2026));
      expect(task.dueDateTime.month, equals(11));
      expect(task.dueDateTime.day, equals(12));
      expect(task.dueDateTime.hour, equals(17));
      expect(task.dueDateTime.minute, equals(0));
      expect(task.priority, equals(TaskPriority.high));
      expect(result.wasExecuted, isTrue);
    });

    test('Example 2: add task call vendor (Rule C1 & C2: past time triggers confirmation)', () {
      final result = CommandEngine.processInput(
        rawInput: 'add task call vendor',
        currentTasks: [],
        conversationState: ConversationState.idle,
        undoStack: [],
        lastMentionedTaskId: null,
        demoClock: demoClock,
      );

      expect(result.intent, equals(CommandIntent.add));
      expect(result.confidence, equals(ConfidenceLevel.medium)); // defaults used
      expect(result.requiresConfirmation, isTrue);
      expect(result.updatedConversationState.status, equals(ConversationStatus.awaitingPastTimeConfirmation));
      expect(result.spokenResponse, contains('That time has passed. Move it to tomorrow?'));
      expect(result.wasExecuted, isFalse); // not saved yet

      // Follow-up: User responds "yes"
      final confirmResult = CommandEngine.processInput(
        rawInput: 'yes',
        currentTasks: result.updatedTasks,
        conversationState: result.updatedConversationState,
        undoStack: result.updatedUndoStack,
        lastMentionedTaskId: result.lastMentionedTaskId,
        demoClock: demoClock,
      );

      expect(confirmResult.wasExecuted, isTrue);
      expect(confirmResult.updatedTasks.length, equals(1));
      final task = confirmResult.updatedTasks.first;
      expect(task.title, equals('call vendor'));
      // Moved to tomorrow at 9:00 AM (Thu 12 Nov, 9:00 AM)
      expect(task.dueDateTime.day, equals(12));
      expect(task.dueDateTime.hour, equals(9));
      expect(task.dueDateTime.minute, equals(0));
    });

    test('Example 3: move it to Friday at 10 (Rule C3 context)', () {
      // Setup initial task in context
      final initialTask = TaskItem(
        id: 'task-1',
        title: 'buy cable',
        dueDateTime: DateTime(2026, 11, 12, 17, 0),
        priority: TaskPriority.high,
      );

      final result = CommandEngine.processInput(
        rawInput: 'move it to Friday at 10',
        currentTasks: [initialTask],
        conversationState: ConversationState.idle,
        undoStack: [],
        lastMentionedTaskId: initialTask.id,
        demoClock: demoClock,
      );

      expect(result.intent, equals(CommandIntent.reschedule));
      expect(result.wasExecuted, isTrue);
      final rescheduledTask = result.updatedTasks.first;
      // Friday is 13 Nov 2026, 10:00 AM
      expect(rescheduledTask.dueDateTime.year, equals(2026));
      expect(rescheduledTask.dueDateTime.month, equals(11));
      expect(rescheduledTask.dueDateTime.day, equals(13));
      expect(rescheduledTask.dueDateTime.hour, equals(10));
      expect(rescheduledTask.dueDateTime.minute, equals(0));
    });

    test('Example 4: mark call done with two tasks containing "call" (Rule C4 Ambiguity)', () {
      final taskA = TaskItem(
        id: 'task-a',
        title: 'call Ravi',
        dueDateTime: DateTime(2026, 11, 11, 14, 0),
      );
      final taskB = TaskItem(
        id: 'task-b',
        title: 'call vendor',
        dueDateTime: DateTime(2026, 11, 11, 16, 0),
      );

      final result = CommandEngine.processInput(
        rawInput: 'mark call done',
        currentTasks: [taskA, taskB],
        conversationState: ConversationState.idle,
        undoStack: [],
        lastMentionedTaskId: null,
        demoClock: demoClock,
      );

      expect(result.intent, equals(CommandIntent.complete));
      expect(result.requiresConfirmation, isTrue);
      expect(result.updatedConversationState.status, equals(ConversationStatus.awaitingAmbiguityResolution));
      expect(result.spokenResponse, equals('Which one?'));
      expect(result.wasExecuted, isFalse); // No change until answered

      // Now user answers "the first" / "one"
      final answerResult = CommandEngine.processInput(
        rawInput: 'one',
        currentTasks: result.updatedTasks,
        conversationState: result.updatedConversationState,
        undoStack: result.updatedUndoStack,
        lastMentionedTaskId: result.lastMentionedTaskId,
        demoClock: demoClock,
      );

      expect(answerResult.wasExecuted, isTrue);
      final completedTask = answerResult.updatedTasks.firstWhere((t) => t.id == 'task-a');
      expect(completedTask.isCompleted, isTrue);
      final uncompletedTask = answerResult.updatedTasks.firstWhere((t) => t.id == 'task-b');
      expect(uncompletedTask.isCompleted, isFalse);
    });

    test('Example 5: delete the last task (Rule C5 safety confirmation)', () {
      final task = TaskItem(
        id: 'task-del',
        title: 'inspect drill',
        dueDateTime: DateTime(2026, 11, 11, 12, 0),
      );

      final result = CommandEngine.processInput(
        rawInput: 'delete the last task',
        currentTasks: [task],
        conversationState: ConversationState.idle,
        undoStack: [],
        lastMentionedTaskId: task.id,
        demoClock: demoClock,
      );

      expect(result.intent, equals(CommandIntent.delete));
      expect(result.requiresConfirmation, isTrue);
      expect(result.updatedConversationState.status, equals(ConversationStatus.awaitingDeleteConfirmation));
      expect(result.updatedTasks.length, equals(1)); // not deleted yet!

      // Confirm with "yes"
      final confirmResult = CommandEngine.processInput(
        rawInput: 'yes',
        currentTasks: result.updatedTasks,
        conversationState: result.updatedConversationState,
        undoStack: result.updatedUndoStack,
        lastMentionedTaskId: result.lastMentionedTaskId,
        demoClock: demoClock,
      );

      expect(confirmResult.wasExecuted, isTrue);
      expect(confirmResult.updatedTasks.isEmpty, isTrue);
      expect(confirmResult.spokenResponse, contains("Deleted 'inspect drill'"));
    });

    test('Example 6: what is due today (Rule C1 date filter & counts read aloud)', () {
      final taskToday1 = TaskItem(
        id: 't1',
        title: 'buy cable',
        dueDateTime: DateTime(2026, 11, 11, 11, 0),
      );
      final taskToday2 = TaskItem(
        id: 't2',
        title: 'fix pump',
        dueDateTime: DateTime(2026, 11, 11, 15, 0),
      );
      final taskTomorrow = TaskItem(
        id: 't3',
        title: 'clean motor',
        dueDateTime: DateTime(2026, 11, 12, 9, 0),
      );

      final result = CommandEngine.processInput(
        rawInput: 'what is due today',
        currentTasks: [taskToday1, taskToday2, taskTomorrow],
        conversationState: ConversationState.idle,
        undoStack: [],
        lastMentionedTaskId: null,
        demoClock: demoClock,
      );

      expect(result.intent, equals(CommandIntent.list));
      expect(result.spokenResponse, contains('You have 2 tasks due Wed 11 Nov: buy cable, fix pump.'));
      expect(result.wasExecuted, isTrue);
    });

    test('Example 7: undo that (Rule C7 reverses last action)', () {
      final task = TaskItem(
        id: 'task-added',
        title: 'buy cable',
        dueDateTime: DateTime(2026, 11, 12, 17, 0),
      );

      // Simulate state right after adding task
      final undoAction = UndoAction(
        type: UndoActionType.added,
        description: "added 'buy cable'",
        task: task,
      );

      final result = CommandEngine.processInput(
        rawInput: 'undo that',
        currentTasks: [task],
        conversationState: ConversationState.idle,
        undoStack: [undoAction],
        lastMentionedTaskId: task.id,
        demoClock: demoClock,
      );

      expect(result.intent, equals(CommandIntent.undo));
      expect(result.wasExecuted, isTrue);
      expect(result.updatedTasks.isEmpty, isTrue);
      expect(result.spokenResponse, contains("Reversed: added 'buy cable'"));

      // Second undo with empty stack
      final secondUndo = CommandEngine.processInput(
        rawInput: 'undo that',
        currentTasks: result.updatedTasks,
        conversationState: ConversationState.idle,
        undoStack: result.updatedUndoStack,
        lastMentionedTaskId: null,
        demoClock: demoClock,
      );

      expect(secondUndo.spokenResponse, equals('Nothing to undo.'));
    });

    test('Example 8: make coffee fly to the moon (Rule C6 Confidence Low)', () {
      final result = CommandEngine.processInput(
        rawInput: 'make coffee fly to the moon',
        currentTasks: [],
        conversationState: ConversationState.idle,
        undoStack: [],
        lastMentionedTaskId: null,
        demoClock: demoClock,
      );

      expect(result.confidence, equals(ConfidenceLevel.low));
      expect(result.wasExecuted, isFalse);
      expect(result.spokenResponse, contains('rephrasing'));
    });

    test('Edge case: Context missing when referring to "it" with no tasks', () {
      final result = CommandEngine.processInput(
        rawInput: 'move it to Friday at 10',
        currentTasks: [],
        conversationState: ConversationState.idle,
        undoStack: [],
        lastMentionedTaskId: null,
        demoClock: demoClock,
      );

      expect(result.wasExecuted, isFalse);
      expect(result.spokenResponse, contains('Which task do you want to move?'));
    });

    test('Edge case: Past time rejected with "no" cancels task creation', () {
      final result = CommandEngine.processInput(
        rawInput: 'add task call vendor',
        currentTasks: [],
        conversationState: ConversationState.idle,
        undoStack: [],
        lastMentionedTaskId: null,
        demoClock: demoClock,
      );

      expect(result.requiresConfirmation, isTrue);

      final cancelResult = CommandEngine.processInput(
        rawInput: 'no',
        currentTasks: result.updatedTasks,
        conversationState: result.updatedConversationState,
        undoStack: result.updatedUndoStack,
        lastMentionedTaskId: result.lastMentionedTaskId,
        demoClock: demoClock,
      );

      expect(cancelResult.wasExecuted, isFalse);
      expect(cancelResult.updatedTasks.isEmpty, isTrue);
      expect(cancelResult.spokenResponse, contains('Task cancelled'));
    });

    test('Edge case: Delete confirmation rejected with "no"', () {
      final task = TaskItem(
        id: 't-del-reject',
        title: 'clean motor',
        dueDateTime: DateTime(2026, 11, 12, 10, 0),
      );

      final result = CommandEngine.processInput(
        rawInput: 'delete clean motor',
        currentTasks: [task],
        conversationState: ConversationState.idle,
        undoStack: [],
        lastMentionedTaskId: task.id,
        demoClock: demoClock,
      );

      expect(result.requiresConfirmation, isTrue);

      final cancelResult = CommandEngine.processInput(
        rawInput: 'no',
        currentTasks: result.updatedTasks,
        conversationState: result.updatedConversationState,
        undoStack: result.updatedUndoStack,
        lastMentionedTaskId: result.lastMentionedTaskId,
        demoClock: demoClock,
      );

      expect(cancelResult.wasExecuted, isFalse);
      expect(cancelResult.updatedTasks.length, equals(1));
      expect(cancelResult.spokenResponse, contains('Deletion cancelled'));
    });

    test('Edge case: Multi-step Undo sequence across complete and reschedule', () {
      final task = TaskItem(
        id: 't-seq',
        title: 'fix pump',
        dueDateTime: DateTime(2026, 11, 11, 15, 0),
        isCompleted: false,
      );

      // 1. Complete task
      final completeResult = CommandEngine.processInput(
        rawInput: 'mark fix pump done',
        currentTasks: [task],
        conversationState: ConversationState.idle,
        undoStack: [],
        lastMentionedTaskId: task.id,
        demoClock: demoClock,
      );
      expect(completeResult.updatedTasks.first.isCompleted, isTrue);
      expect(completeResult.updatedUndoStack.length, equals(1));

      // 2. Undo completion
      final undoResult = CommandEngine.processInput(
        rawInput: 'undo that',
        currentTasks: completeResult.updatedTasks,
        conversationState: ConversationState.idle,
        undoStack: completeResult.updatedUndoStack,
        lastMentionedTaskId: completeResult.lastMentionedTaskId,
        demoClock: demoClock,
      );
      expect(undoResult.updatedTasks.first.isCompleted, isFalse);
      expect(undoResult.spokenResponse, contains("Reversed: marked 'fix pump' done"));
    });
  });
}
