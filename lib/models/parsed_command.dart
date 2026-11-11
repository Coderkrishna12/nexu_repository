import 'command_intent.dart';
import 'confidence_level.dart';
import 'task_priority.dart';

class ParsedCommand {
  final String rawText;
  final CommandIntent intent;
  final ConfidenceLevel confidence;
  final String? title;
  final DateTime? targetDate;
  final int? targetTimeMinutes; // Minutes from midnight (e.g. 540 for 9:00 AM)
  final TaskPriority? priority;
  final String? targetQuery; // e.g. "it", "that", "the last task", "call", "buy cable"
  final int? targetIndex; // e.g. 0 for "one"/"first", 1 for "two"/"second"
  final bool usedDefaults;
  final List<String> matchedTokens;
  final List<String> unmatchedTokens;
  final String? explanation;

  const ParsedCommand({
    required this.rawText,
    required this.intent,
    required this.confidence,
    this.title,
    this.targetDate,
    this.targetTimeMinutes,
    this.priority,
    this.targetQuery,
    this.targetIndex,
    this.usedDefaults = false,
    this.matchedTokens = const [],
    this.unmatchedTokens = const [],
    this.explanation,
  });

  Map<String, dynamic> toMap() {
    return {
      'rawText': rawText,
      'intent': intent.displayName,
      'confidence': confidence.displayName,
      'title': title,
      'targetDate': targetDate?.toIso8601String(),
      'targetTimeMinutes': targetTimeMinutes,
      'priority': priority?.displayName,
      'targetQuery': targetQuery,
      'targetIndex': targetIndex,
      'usedDefaults': usedDefaults,
      'matchedTokens': matchedTokens,
      'unmatchedTokens': unmatchedTokens,
      'explanation': explanation,
    };
  }
}

