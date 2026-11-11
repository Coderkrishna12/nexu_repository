import 'command_intent.dart';
import 'confidence_level.dart';
import 'parsed_command.dart';
import 'task_priority.dart';

class ParsedCommandLog {
  final String id;
  final String userSpokenText;
  final CommandIntent intent;
  final ConfidenceLevel confidence;
  final String? extractedTitle;
  final DateTime? extractedDate;
  final int? extractedTimeMinutes;
  final TaskPriority? extractedPriority;
  final String? targetQuery;
  final String responseMessage;
  final bool wasExecuted;
  final DateTime timestamp;

  ParsedCommandLog({
    required this.id,
    required this.userSpokenText,
    required this.intent,
    required this.confidence,
    this.extractedTitle,
    this.extractedDate,
    this.extractedTimeMinutes,
    this.extractedPriority,
    this.targetQuery,
    required this.responseMessage,
    required this.wasExecuted,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ParsedCommandLog.fromParsedCommand({
    required String id,
    required ParsedCommand parsed,
    required String responseMessage,
    required bool wasExecuted,
  }) {
    return ParsedCommandLog(
      id: id,
      userSpokenText: parsed.rawText,
      intent: parsed.intent,
      confidence: parsed.confidence,
      extractedTitle: parsed.title,
      extractedDate: parsed.targetDate,
      extractedTimeMinutes: parsed.targetTimeMinutes,
      extractedPriority: parsed.priority,
      targetQuery: parsed.targetQuery,
      responseMessage: responseMessage,
      wasExecuted: wasExecuted,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userSpokenText': userSpokenText,
      'intent': intent.name,
      'confidence': confidence.name,
      'extractedTitle': extractedTitle,
      'extractedDate': extractedDate?.toIso8601String(),
      'extractedTimeMinutes': extractedTimeMinutes,
      'extractedPriority': extractedPriority?.name,
      'targetQuery': targetQuery,
      'responseMessage': responseMessage,
      'wasExecuted': wasExecuted,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ParsedCommandLog.fromJson(Map<String, dynamic> json) {
    return ParsedCommandLog(
      id: json['id'] as String,
      userSpokenText: json['userSpokenText'] as String,
      intent: CommandIntent.values.byName(json['intent'] as String),
      confidence: ConfidenceLevel.values.byName(json['confidence'] as String),
      extractedTitle: json['extractedTitle'] as String?,
      extractedDate: json['extractedDate'] != null
          ? DateTime.parse(json['extractedDate'] as String)
          : null,
      extractedTimeMinutes: json['extractedTimeMinutes'] as int?,
      extractedPriority: json['extractedPriority'] != null
          ? TaskPriority.values.byName(json['extractedPriority'] as String)
          : null,
      targetQuery: json['targetQuery'] as String?,
      responseMessage: json['responseMessage'] as String,
      wasExecuted: (json['wasExecuted'] as bool?) ?? false,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }
}

