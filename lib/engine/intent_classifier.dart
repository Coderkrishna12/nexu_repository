import '../models/command_intent.dart';
import '../models/confidence_level.dart';
import '../models/conversation_state.dart';
import '../models/parsed_command.dart';
import '../models/task_priority.dart';
import 'date_time_parser.dart';

class IntentClassifier {
  /// Known words in the NEXU VoiceDesk vocabulary
  static const Set<String> _knownVocabulary = {
    'add', 'create', 'new', 'task', 'tasks',
    'mark', 'complete', 'completed', 'done', 'finish', 'finished',
    'move', 'reschedule', 'shift', 'postpone', 'change',
    'delete', 'remove', 'cancel',
    'list', 'show', 'what', 'whats', 'is', 'due', 'today', 'tomorrow', 'do', 'i', 'have', 'all',
    'undo', 'revert', 'that', 'it', 'the', 'last',
    'yes', 'yeah', 'yep', 'sure', 'confirm', 'proceed', 'ok',
    'no', 'nope', 'stop', 'dont',
    'one', 'two', 'three', 'first', 'second', 'third', '1', '2', '3',
    'high', 'urgent', 'normal', 'medium', 'low', 'priority',
    'at', 'to', 'on', 'am', 'pm', 'as', 'for',
    'monday', 'mon', 'tuesday', 'tue', 'tues', 'wednesday', 'wed',
    'thursday', 'thu', 'thur', 'thurs', 'friday', 'fri', 'saturday', 'sat', 'sunday', 'sun',
    'january', 'february', 'march', 'april', 'may', 'june',
    'july', 'august', 'september', 'october', 'november', 'december',
    'jan', 'feb', 'mar', 'apr', 'jun', 'jul', 'aug', 'sep', 'sept', 'oct', 'nov', 'dec',
    // Domain task words common in Ravi's field technician context:
    'buy', 'cable', 'wire', 'call', 'vendor', 'ravi', 'fix', 'pump', 'motor',
    'replace', 'inspect', 'clean', 'check', 'order', 'repair', 'drill', 'battery',
  };

  /// Parses raw input into a [ParsedCommand] given the current [conversationState] and [demoClock].
  static ParsedCommand parse(
    String input, {
    required ConversationState conversationState,
    required DateTime demoClock,
  }) {
    final rawTrimmed = input.trim();
    if (rawTrimmed.isEmpty) {
      return const ParsedCommand(
        rawText: '',
        intent: CommandIntent.unknown,
        confidence: ConfidenceLevel.low,
        explanation: 'Empty voice input received.',
      );
    }

    // Normalized text (lowercase, stripped punctuation except colons)
    String normalized = rawTrimmed.toLowerCase().replaceAll(RegExp(r'[,.?!;"]'), ' ');
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();

    // A. Check for conversation state responses first
    if (conversationState.isWaitingForInput) {
      final stateResponse = _handleConversationState(
        rawTrimmed,
        normalized,
        conversationState,
      );
      if (stateResponse != null) {
        return stateResponse;
      }
    }

    // B. Check UNDO: "undo that", "undo", "revert that"
    if (normalized == 'undo that' ||
        normalized == 'undo' ||
        normalized == 'revert that' ||
        normalized == 'revert') {
      return ParsedCommand(
        rawText: rawTrimmed,
        intent: CommandIntent.undo,
        confidence: ConfidenceLevel.high,
        matchedTokens: normalized.split(' '),
        explanation: 'Matched undo command pattern perfectly.',
      );
    }

    // C. Check LIST: "what is due today", "what is due tomorrow", "what's due today", "list tasks", "show tasks"
    final listRegex = RegExp(
      r'^(?:what\s+is\s+due|what\s*s\s+due|list\s+tasks|show\s+tasks|what\s+tasks\s+do\s+i\s+have|list\s+all\s+tasks|what\s+do\s+i\s+have)(?:\s+(?:due\s+)?(today|tomorrow|all))?$',
    );
    final listMatch = listRegex.firstMatch(normalized);
    if (listMatch != null ||
        normalized == 'what is due' ||
        normalized == 'what is due today' ||
        normalized == 'what is due tomorrow') {
      DateTime targetDate = demoClock;
      bool usedDefaults = false;
      if (normalized.contains('tomorrow')) {
        targetDate = demoClock.add(const Duration(days: 1));
      } else if (!normalized.contains('today')) {
        usedDefaults = true;
      }

      return ParsedCommand(
        rawText: rawTrimmed,
        intent: CommandIntent.list,
        confidence: usedDefaults ? ConfidenceLevel.medium : ConfidenceLevel.high,
        targetDate: DateTime(targetDate.year, targetDate.month, targetDate.day),
        usedDefaults: usedDefaults,
        matchedTokens: normalized.split(' '),
        explanation: 'Matched query for due tasks.',
      );
    }

    // D. Check DELETE: "delete the last task", "delete buy cable", "delete task call vendor", "remove it"
    final deleteRegex = RegExp(
      r'^(?:delete|remove)\s+(?:task\s+)?(.+)$',
    );
    final deleteMatch = deleteRegex.firstMatch(normalized);
    if (deleteMatch != null) {
      final target = deleteMatch.group(1)!.trim();
      return ParsedCommand(
        rawText: rawTrimmed,
        intent: CommandIntent.delete,
        confidence: ConfidenceLevel.high,
        targetQuery: target,
        matchedTokens: ['delete', ...target.split(' ')],
        explanation: 'Matched delete command targeting "$target".',
      );
    }

    // E. Check COMPLETE: "mark buy cable done", "mark task buy cable done", "mark call done", "complete buy cable", "mark it done"
    final markDoneRegex = RegExp(
      r'^(?:mark\s+(?:task\s+)?(.+?)\s+(?:as\s+)?(?:done|completed|finished)|complete\s+(?:task\s+)?(.+?))$',
    );
    final markMatch = markDoneRegex.firstMatch(normalized);
    if (markMatch != null) {
      final target = (markMatch.group(1) ?? markMatch.group(2))!.trim();
      return ParsedCommand(
        rawText: rawTrimmed,
        intent: CommandIntent.complete,
        confidence: ConfidenceLevel.high,
        targetQuery: target,
        matchedTokens: ['mark', 'done', ...target.split(' ')],
        explanation: 'Matched completion command targeting "$target".',
      );
    }

    // F. Check RESCHEDULE: "move it to Friday at 10", "reschedule buy cable to tomorrow at 5 pm", "move task buy cable to Friday at 10"
    final rescheduleRegex = RegExp(
      r'^(?:move|reschedule|shift|postpone|change)\s+(?:task\s+)?(.+?)\s+to\s+(.+)$',
    );
    final rescheduleMatch = rescheduleRegex.firstMatch(normalized);
    if (rescheduleMatch != null) {
      final target = rescheduleMatch.group(1)!.trim();
      final destinationDateTimeStr = rescheduleMatch.group(2)!.trim();

      final parsedDt = DateTimeParser.parse(destinationDateTimeStr, demoClock);
      final hasDate = parsedDt.hasExplicitDate;
      final hasTime = parsedDt.hasExplicitTime;

      // Default date to today if missing, default time to 9:00 AM if missing
      final date = parsedDt.date ?? DateTime(demoClock.year, demoClock.month, demoClock.day);
      final timeMinutes = parsedDt.timeMinutes ?? (9 * 60);
      final usedDefaults = !hasDate || !hasTime;

      return ParsedCommand(
        rawText: rawTrimmed,
        intent: CommandIntent.reschedule,
        confidence: usedDefaults ? ConfidenceLevel.medium : ConfidenceLevel.high,
        targetQuery: target,
        targetDate: date,
        targetTimeMinutes: timeMinutes,
        usedDefaults: usedDefaults,
        matchedTokens: [
          'move',
          'to',
          ...target.split(' '),
          ...parsedDt.matchedTokens,
        ],
        explanation: 'Matched reschedule command for "$target".',
      );
    }

    // G. Check ADD:
    // Examples:
    // "add task buy cable tomorrow at 5 pm high priority"
    // "add task call vendor"
    // "create task fix pump high priority"
    // "add buy groceries at 3 pm"
    final addPrefixRegex = RegExp(r'^(?:add|create|new)\s+(?:task\s+)?', caseSensitive: false);
    final addMatch = addPrefixRegex.firstMatch(normalized);
    if (addMatch != null) {
      String remainder = normalized.substring(addMatch.end).trim();

      // Extract Priority
      TaskPriority? extractedPriority;
      bool hasExplicitPriority = false;
      final priorityRegex = RegExp(r'\b(high|urgent|normal|medium|low)\s*(?:priority)?\b', caseSensitive: false);
      final pMatch = priorityRegex.firstMatch(remainder);
      if (pMatch != null) {
        hasExplicitPriority = true;
        extractedPriority = TaskPriority.fromString(pMatch.group(1));
        remainder = remainder.replaceRange(pMatch.start, pMatch.end, ' ');
      }

      // Extract Date and Time
      final parsedDt = DateTimeParser.parse(remainder, demoClock);
      remainder = parsedDt.cleanedText;

      // The remaining tokens make up the task title
      String title = remainder.replaceAll(RegExp(r'\s+'), ' ').trim();

      // Defaults per Rule C1:
      // If no date is given -> today
      // If no time is given -> 9:00 AM (540 minutes)
      // Default priority -> Normal
      final bool usedDefaults = !parsedDt.hasExplicitDate || !parsedDt.hasExplicitTime || !hasExplicitPriority;
      final resolvedDate = parsedDt.date ?? DateTime(demoClock.year, demoClock.month, demoClock.day);
      final resolvedTimeMinutes = parsedDt.timeMinutes ?? (9 * 60);
      final resolvedPriority = extractedPriority ?? TaskPriority.normal;

      if (title.isNotEmpty) {
        return ParsedCommand(
          rawText: rawTrimmed,
          intent: CommandIntent.add,
          confidence: usedDefaults ? ConfidenceLevel.medium : ConfidenceLevel.high,
          title: title,
          targetDate: resolvedDate,
          targetTimeMinutes: resolvedTimeMinutes,
          priority: resolvedPriority,
          usedDefaults: usedDefaults,
          matchedTokens: [
            'add',
            'task',
            ...title.split(' '),
            if (hasExplicitPriority) pMatch!.group(0)!,
            ...parsedDt.matchedTokens,
          ],
          explanation: usedDefaults
              ? 'Task parsed with C1 defaults applied (Confidence: Medium).'
              : 'All task slots explicitly provided and recognized (Confidence: High).',
        );
      }
    }

    // H. Fallback / Rule C6 Low Confidence Check
    // If words don't match any known pattern, or nonsense like "make coffee fly to the moon"
    final words = normalized.split(' ');
    final unknownTokens = words.where((w) => !_knownVocabulary.contains(w)).toList();

    return ParsedCommand(
      rawText: rawTrimmed,
      intent: CommandIntent.unknown,
      confidence: ConfidenceLevel.low,
      unmatchedTokens: unknownTokens,
      explanation: 'No known command pattern matched. Confidence: Low. Please rephrase.',
    );
  }

  /// Handles conversational turns when waiting for user response (Past time, Ambiguity, Delete confirmation)
  static ParsedCommand? _handleConversationState(
    String rawText,
    String normalized,
    ConversationState state,
  ) {
    // 1. Confirmations (Yes / No)
    final yesWords = {'yes', 'yeah', 'yep', 'sure', 'confirm', 'proceed', 'ok', 'okay', 'move it', 'delete it'};
    final noWords = {'no', 'nope', 'cancel', 'stop', 'dont', 'do not', 'nevermind', 'abort', 'keep it'};

    if (yesWords.contains(normalized)) {
      return ParsedCommand(
        rawText: rawText,
        intent: CommandIntent.confirmYes,
        confidence: ConfidenceLevel.high,
        matchedTokens: normalized.split(' '),
        explanation: 'User confirmed affirmative ("$normalized").',
      );
    }

    if (noWords.contains(normalized)) {
      return ParsedCommand(
        rawText: rawText,
        intent: CommandIntent.confirmNo,
        confidence: ConfidenceLevel.high,
        matchedTokens: normalized.split(' '),
        explanation: 'User responded negative ("$normalized").',
      );
    }

    // 2. Ambiguity resolution options: "one", "two", "the first", "the second", "1", "2"
    if (state.status == ConversationStatus.awaitingAmbiguityResolution) {
      int? selectedIndex;
      if (normalized == 'one' ||
          normalized == 'first' ||
          normalized == 'the first' ||
          normalized == '1' ||
          normalized == 'option one' ||
          normalized == 'number one') {
        selectedIndex = 0;
      } else if (normalized == 'two' ||
          normalized == 'second' ||
          normalized == 'the second' ||
          normalized == '2' ||
          normalized == 'option two' ||
          normalized == 'number two') {
        selectedIndex = 1;
      } else if (normalized == 'three' ||
          normalized == 'third' ||
          normalized == 'the third' ||
          normalized == '3' ||
          normalized == 'option three' ||
          normalized == 'number three') {
        selectedIndex = 2;
      }

      if (selectedIndex != null) {
        return ParsedCommand(
          rawText: rawText,
          intent: CommandIntent.selectOption,
          confidence: ConfidenceLevel.high,
          targetIndex: selectedIndex,
          matchedTokens: normalized.split(' '),
          explanation: 'User selected option index $selectedIndex.',
        );
      }
    }

    return null;
  }
}
