import 'command_intent.dart';
import 'confidence_level.dart';
import 'conversation_state.dart';
import 'parsed_command.dart';
import 'task_item.dart';
import 'undo_action.dart';

class CommandResult {
  final ParsedCommand parsedCommand;
  final String spokenResponse;
  final String visualMessage;
  final List<TaskItem> updatedTasks;
  final ConversationState updatedConversationState;
  final List<UndoAction> updatedUndoStack;
  final String? lastMentionedTaskId;
  final bool wasExecuted;
  final bool requiresConfirmation;

  const CommandResult({
    required this.parsedCommand,
    required this.spokenResponse,
    required this.visualMessage,
    required this.updatedTasks,
    required this.updatedConversationState,
    required this.updatedUndoStack,
    this.lastMentionedTaskId,
    this.wasExecuted = false,
    this.requiresConfirmation = false,
  });

  CommandIntent get intent => parsedCommand.intent;
  ConfidenceLevel get confidence => parsedCommand.confidence;
}

