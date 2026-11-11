import 'command_intent.dart';
import 'task_item.dart';

enum ConversationStatus {
  idle,
  awaitingPastTimeConfirmation,
  awaitingAmbiguityResolution,
  awaitingDeleteConfirmation,
}

class ConversationState {
  final ConversationStatus status;
  final String? questionPrompt; // Spoken question to Ravi
  final TaskItem? pendingTask; // Task being created or rescheduled
  final DateTime? proposedNewDueDateTime; // For reschedule
  final List<String> candidateTaskIds; // For C4 ambiguity
  final CommandIntent? pendingIntent; // Intent awaiting resolution
  final String? targetTaskId; // For C5 delete or resolution
  final DateTime? awaitingSince; // Timestamp when question was posed

  const ConversationState({
    this.status = ConversationStatus.idle,
    this.questionPrompt,
    this.pendingTask,
    this.proposedNewDueDateTime,
    this.candidateTaskIds = const [],
    this.pendingIntent,
    this.targetTaskId,
    this.awaitingSince,
  });

  bool get isWaitingForInput => status != ConversationStatus.idle;

  ConversationState copyWith({
    ConversationStatus? status,
    String? questionPrompt,
    TaskItem? pendingTask,
    DateTime? proposedNewDueDateTime,
    List<String>? candidateTaskIds,
    CommandIntent? pendingIntent,
    String? targetTaskId,
    DateTime? awaitingSince,
  }) {
    return ConversationState(
      status: status ?? this.status,
      questionPrompt: questionPrompt ?? this.questionPrompt,
      pendingTask: pendingTask ?? this.pendingTask,
      proposedNewDueDateTime:
          proposedNewDueDateTime ?? this.proposedNewDueDateTime,
      candidateTaskIds: candidateTaskIds ?? this.candidateTaskIds,
      pendingIntent: pendingIntent ?? this.pendingIntent,
      targetTaskId: targetTaskId ?? this.targetTaskId,
      awaitingSince: awaitingSince ?? this.awaitingSince,
    );
  }

  static const idle = ConversationState();
}
