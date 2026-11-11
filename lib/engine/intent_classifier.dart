import '../models/command_intent.dart';
import '../models/confidence_level.dart';
import '../models/conversation_state.dart';
import '../models/parsed_command.dart';
import '../models/task_priority.dart';
import 'date_time_parser.dart';
import 'fuzzy_matcher.dart';

class IntentClassifier {
  /// Known words in the NEXU VoiceDesk vocabulary (all lowercase, strictly unique)
  static const Set<String> _knownVocabulary = {
    // Intent anchors & verbs
    'add',
    'create',
    'new',
    'task',
    'tasks',
    'tas',
    'name',
    'named',
    'called',
    'title',
    'schedule',
    'remind',
    'set',
    'put',
    'need',
    'want',
    'log',
    'make',
    'have',
    'plan',
    'book',
    'mark',
    'complete',
    'completed',
    'done',
    'finish',
    'finished',
    'check',
    'off',
    'close',
    'wrap',
    'resolve',
    'move',
    'reschedule',
    'shift',
    'postpone',
    'change',
    'delay',
    'push',
    'defer',
    'delete',
    'remove',
    'cancel',
    'discard',
    'drop',
    'erase',
    'clear',
    'rid',
    'trash',
    'list',
    'show',
    'what',
    'whats',
    'is',
    'due',
    'today',
    'tomorrow',
    'do',
    'i',
    'all',
    'every',
    'tell',
    'agenda',
    'todo',
    'todos',
    'my',
    'plate',
    'items',
    'view',
    'display',
    'read',
    'undo', 'revert', 'that', 'it', 'the', 'last', 'take', 'back', 'this',
    'yes',
    'yeah',
    'yep',
    'yup',
    'sure',
    'confirm',
    'proceed',
    'ok',
    'okay',
    'fine',
    'definitely',
    'absolutely',
    'no', 'nope', 'nah', 'stop', 'dont', 'keep', 'leave', 'nevermind', 'abort',
    'one',
    'two',
    'three',
    'first',
    'second',
    'third',
    '1',
    '2',
    '3',
    'option',
    'number',
    'top',
    'high', 'urgent', 'normal', 'medium', 'low', 'priority',
    // Prepositions, pronouns, particles
    'at',
    'to',
    'on',
    'am',
    'pm',
    'as',
    'for',
    'until',
    'by',
    'in',
    'with',
    'a',
    'an',
    'me',
    'from',
    'of',
    'into',
    'onto',
    // Days of the week
    'monday', 'mon', 'tuesday', 'tue', 'tues', 'wednesday', 'wed',
    'thursday',
    'thu',
    'thur',
    'thurs',
    'friday',
    'fri',
    'saturday',
    'sat',
    'sunday',
    'sun',
    // Months
    'january', 'february', 'march', 'april', 'may', 'june',
    'july', 'august', 'september', 'october', 'november', 'december',
    'jan',
    'feb',
    'mar',
    'apr',
    'jun',
    'jul',
    'aug',
    'sep',
    'sept',
    'oct',
    'nov',
    'dec',
    // Workshop domain nouns & components
    'buy', 'purchase', 'order', 'procure', 'cable', 'cables', 'wire', 'wires',
    'call', 'contact', 'vendor', 'vendors', 'ravi',
    'fix', 'repair', 'service', 'pump', 'pumps', 'motor', 'motors',
    'replace', 'swap', 'inspect', 'examine', 'clean', 'flush',
    'drill', 'battery', 'batteries', 'tool', 'tools', 'parts', 'generator',
    'valve',
    'valves',
    'pipe',
    'pipes',
    'panel',
    'switch',
    'switches',
    'fuse',
    'fuses',
    'relay', 'sensor', 'sensors', 'filter', 'filters', 'oil', 'grease', 'tape',
    'multimeter', 'gauge', 'meter', 'get', 'bring', 'technician', 'workshop',
    'garage', 'factory', 'bearing', 'bearings', 'shaft', 'gear', 'gears',
    'belt', 'belts', 'chain', 'pulley', 'clutch', 'brake', 'brakes',
    'engine', 'cylinder', 'radiator', 'hose', 'hoses', 'coolant', 'hydraulic',
    'exhaust', 'tank', 'wrench', 'spanner', 'screwdriver', 'hammer', 'grinder',
    'welder', 'cutter', 'tighten', 'loosen', 'calibrate', 'measure', 'align',
    'adjust', 'install', 'mount', 'deliver', 'collect', 'ship', 'receive',
    'pack', 'store', 'test', 'audit',
  };

  static const List<String> _fuzzyCorrectionCandidates = [
    'task',
    'vendor',
    'priority',
    'reschedule',
    'delete',
    'tomorrow',
    'undo',
    'today',
    'cable',
    'complete',
    'friday',
    'minute',
    'morning',
  ];

  /// Preprocesses text to fix common speech recognition acoustic misrecognitions and typos
  static String _normalizeAcousticAndSttErrors(String text) {
    var s = text;
    // Replace punctuation
    s = s.replaceAll(RegExp(r'[,.?!;"]'), ' ');
    // Common STT time boundaries
    s = s.replaceAll(RegExp(r'\ba\s+m\b', caseSensitive: false), 'am');
    s = s.replaceAll(RegExp(r'\bp\s+m\b', caseSensitive: false), 'pm');
    s = s.replaceAll(RegExp(r"\bo'clock\b", caseSensitive: false), '');
    // Acoustic & phoneme normalizations:
    // "golden", "gold on", "cold on", "called on" -> "call done"
    s = s.replaceAll(
      RegExp(
        r'\b(?:golden|gold\s+on|cold\s+on|called\s+on|gold\s+done|cold\s+done|col\s+done|cal\s+done|cold\s+one|gold\s+in)\b',
        caseSensitive: false,
      ),
      'call done',
    );
    // Task word slips
    s = s.replaceAll(
      RegExp(r'\b(?:tas|taks|tast|tsk|dask)\b', caseSensitive: false),
      'task',
    );
    // Call word slips
    s = s.replaceAll(
      RegExp(r'\b(?:col|cal|kall)\b', caseSensitive: false),
      'call',
    );
    // Vendor slips
    s = s.replaceAll(
      RegExp(r'\b(?:vender|venders)\b', caseSensitive: false),
      'vendor',
    );
    // Date/time slips
    s = s.replaceAll(
      RegExp(r'\b(?:tomorow|tommorrow|tmrw)\b', caseSensitive: false),
      'tomorrow',
    );
    s = s.replaceAll(
      RegExp(r'\b(?:priorty|prioriti)\b', caseSensitive: false),
      'priority',
    );
    s = s.replaceAll(
      RegExp(r'\breshedule\b', caseSensitive: false),
      'reschedule',
    );
    // Undo slips
    s = s.replaceAll(
      RegExp(
        r'\b(?:undu|un\s+do|and\s+do\s+that|an\s+do\s+that)\b',
        caseSensitive: false,
      ),
      'undo that',
    );
    // Due today slips
    s = s.replaceAll(
      RegExp(r'\b(?:due\s+to\s+day|do\s+today)\b', caseSensitive: false),
      'due today',
    );
    // Buy cable slips
    s = s.replaceAll(
      RegExp(
        r'\b(?:by\s+cable|bye\s+cable|bi\s+cable|buy\s+table)\b',
        caseSensitive: false,
      ),
      'buy cable',
    );
    // Fix pump slips
    s = s.replaceAll(
      RegExp(r'\b(?:fix\s+pup|fix\s+bump)\b', caseSensitive: false),
      'fix pump',
    );

    // Dynamic token fuzzy correction using Levenshtein distance for unexpected acoustic slips
    final tokens = s.split(' ');
    final corrected = <String>[];
    for (final token in tokens) {
      final lower = token.toLowerCase();
      if (lower.length >= 4 && !_knownVocabulary.contains(lower)) {
        final match = FuzzyMatcher.findBestMatch(
          lower,
          _fuzzyCorrectionCandidates,
          maxDistance: 1,
        );
        corrected.add(match ?? token);
      } else {
        corrected.add(token);
      }
    }
    s = corrected.join(' ');

    // Collapse whitespace
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

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

    // Normalized text with acoustic/STT error normalization
    String normalized = _normalizeAcousticAndSttErrors(
      rawTrimmed,
    ).toLowerCase();

    // Strip conversational / polite prefixes (e.g. "i said ...", "please ...", "can you ...")
    final conversationalPrefixes = RegExp(
      r'^(?:i\s+said\s+|i\s+told\s+you\s+to\s+|please\s+|can\s+you\s+(?:please\s+)?|could\s+you\s+(?:please\s+)?|would\s+you\s+(?:please\s+)?|hey\s+voicedesk\s+|voicedesk\s+|assistant\s+|just\s+|okay\s+|so\s+|actually\s+|i\s+want\s+to\s+|i\s+need\s+to\s+)',
      caseSensitive: false,
    );
    normalized = normalized.replaceFirst(conversationalPrefixes, '').trim();

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

    // B. Check UNDO: "undo that", "undo", "revert that", "take that back", "undo please"
    if (_isUndoCommand(normalized)) {
      return ParsedCommand(
        rawText: rawTrimmed,
        intent: CommandIntent.undo,
        confidence: ConfidenceLevel.high,
        matchedTokens: normalized.split(' '),
        explanation: 'Matched undo command pattern.',
      );
    }

    // C. Check LIST: "what is due today", "what tasks do i have", "show my tasks", "list tasks"
    final listCommand = _tryParseListCommand(rawTrimmed, normalized, demoClock);
    if (listCommand != null) {
      return listCommand;
    }

    // D. Check DELETE: "delete the last task", "remove buy cable", "delete task call vendor"
    final deleteCommand = _tryParseDeleteCommand(rawTrimmed, normalized);
    if (deleteCommand != null) {
      return deleteCommand;
    }

    // E. Check COMPLETE: "mark buy cable done", "call done", "complete buy cable", "done with buy cable"
    final completeCommand = _tryParseCompleteCommand(rawTrimmed, normalized);
    if (completeCommand != null) {
      return completeCommand;
    }

    // F. Check RESCHEDULE: "move it to Friday at 10", "reschedule buy cable to tomorrow at 5 pm"
    final rescheduleCommand = _tryParseRescheduleCommand(
      rawTrimmed,
      normalized,
      demoClock,
    );
    if (rescheduleCommand != null) {
      return rescheduleCommand;
    }

    // G. Check ADD: "add task buy cable tomorrow at 5 pm high priority", "add tas name call vendor", "buy cable tomorrow"
    final addCommand = _tryParseAddCommand(rawTrimmed, normalized, demoClock);
    if (addCommand != null) {
      return addCommand;
    }

    // H. Fallback / Rule C6 Low Confidence Check
    // If words don't match any known pattern, or nonsense like "make coffee fly to the moon"
    final words = normalized.split(' ');
    final unknownTokens = words
        .where((w) => !_knownVocabulary.contains(w))
        .toList();

    return ParsedCommand(
      rawText: rawTrimmed,
      intent: CommandIntent.unknown,
      confidence: ConfidenceLevel.low,
      unmatchedTokens: unknownTokens,
      explanation:
          'No known command pattern matched. Confidence: Low. Please rephrase.',
    );
  }

  // -------------------------------------------------------------
  // Conversational Turn Responses (Yes, No, Option Selection)
  // -------------------------------------------------------------
  static ParsedCommand? _handleConversationState(
    String rawText,
    String normalized,
    ConversationState state,
  ) {
    // 1. Confirmations (Yes / No)
    final yesWords = {
      'yes',
      'yeah',
      'yep',
      'yup',
      'sure',
      'confirm',
      'proceed',
      'ok',
      'okay',
      'fine',
      'move it',
      'delete it',
      'do it',
      'go ahead',
      'yes please',
      'absolutely',
    };
    final noWords = {
      'no',
      'nope',
      'nah',
      'cancel',
      'stop',
      'dont',
      'do not',
      'nevermind',
      'abort',
      'keep it',
      'leave it',
      'no thanks',
      'do not delete',
      'dont move',
    };

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
          normalized == 'the first one' ||
          normalized == '1' ||
          normalized == 'option one' ||
          normalized == 'number one') {
        selectedIndex = 0;
      } else if (normalized == 'two' ||
          normalized == 'second' ||
          normalized == 'the second' ||
          normalized == 'the second one' ||
          normalized == '2' ||
          normalized == 'option two' ||
          normalized == 'number two') {
        selectedIndex = 1;
      } else if (normalized == 'three' ||
          normalized == 'third' ||
          normalized == 'the third' ||
          normalized == 'the third one' ||
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

  // -------------------------------------------------------------
  // Intent Matchers & Slot Extractors
  // -------------------------------------------------------------
  static bool _isUndoCommand(String normalized) {
    if (normalized == 'undo' ||
        normalized == 'undo that' ||
        normalized == 'undo please' ||
        normalized == 'revert' ||
        normalized == 'revert that' ||
        normalized == 'take that back' ||
        normalized == 'take it back' ||
        normalized == 'go back') {
      return true;
    }
    final regex = RegExp(r'\b(?:undo|revert|take\s+back)\b');
    return regex.hasMatch(normalized) &&
        !normalized.contains('task') &&
        !normalized.contains('add');
  }

  static ParsedCommand? _tryParseListCommand(
    String rawTrimmed,
    String normalized,
    DateTime demoClock,
  ) {
    final isListQuery =
        normalized.contains('due') ||
        RegExp(
          r'\b(?:list|show|check|tell\s+me|read|view|display)\b.*\b(?:tasks?|all|schedule|todo|todos|agenda|plate|items)\b',
        ).hasMatch(normalized) ||
        RegExp(
          r'\bwhat\s+(?:tasks?\s+)?(?:do\s+i\s+have|are\s+there|is\s+there|on\s+my\s+list|next)\b',
        ).hasMatch(normalized) ||
        normalized == 'what is due' ||
        normalized == 'show tasks' ||
        normalized == 'list tasks' ||
        normalized == 'tasks today' ||
        normalized == 'tasks tomorrow';

    if (!isListQuery) return null;

    DateTime? targetDate;
    bool usedDefaults = false;

    if (normalized.contains('tomorrow')) {
      targetDate = demoClock.add(const Duration(days: 1));
    } else if (normalized.contains('today')) {
      targetDate = demoClock;
    } else if (normalized.contains('all') || normalized.contains('every')) {
      targetDate = null; // List all
    } else {
      targetDate = demoClock;
      usedDefaults = true;
    }

    return ParsedCommand(
      rawText: rawTrimmed,
      intent: CommandIntent.list,
      confidence: usedDefaults ? ConfidenceLevel.medium : ConfidenceLevel.high,
      targetDate: targetDate != null
          ? DateTime(targetDate.year, targetDate.month, targetDate.day)
          : null,
      usedDefaults: usedDefaults,
      matchedTokens: normalized.split(' '),
      explanation: 'Matched query for scheduled/due tasks.',
    );
  }

  static ParsedCommand? _tryParseDeleteCommand(
    String rawTrimmed,
    String normalized,
  ) {
    final deleteRegex = RegExp(
      r'^(?:delete|remove|cancel|discard|drop|erase|clear|trash|get\s+rid\s+of)\s+(.+)$',
      caseSensitive: false,
    );
    final match = deleteRegex.firstMatch(normalized);
    if (match != null) {
      String target = match.group(1)!.trim();
      target = target.replaceAll(RegExp(r'\b(?:please|now)\b'), '').trim();

      if (target == 'the last task' ||
          target == 'last task' ||
          target == 'last one' ||
          target == 'the task' ||
          target == 'it' ||
          target == 'that' ||
          target == 'this') {
        target = 'the last task';
      } else {
        target = target
            .replaceFirst(
              RegExp(
                r'^(?:the\s+)?(?:task\s+)?(?:named\s+|called\s+|name\s+)?',
                caseSensitive: false,
              ),
              '',
            )
            .trim();
      }

      if (target.isEmpty) return null;

      return ParsedCommand(
        rawText: rawTrimmed,
        intent: CommandIntent.delete,
        confidence: ConfidenceLevel.high,
        targetQuery: target,
        matchedTokens: ['delete', ...target.split(' ')],
        explanation: 'Matched delete command targeting "$target".',
      );
    }
    return null;
  }

  static ParsedCommand? _tryParseCompleteCommand(
    String rawTrimmed,
    String normalized,
  ) {
    // 1. "mark ... (as)? (done|completed|finished)"
    final markRegex = RegExp(
      r'^mark\s+(?:the\s+)?(?:task\s+)?(?:named\s+|called\s+)?(.+?)\s+(?:as\s+)?(?:done|completed|finished)$',
      caseSensitive: false,
    );
    final markMatch = markRegex.firstMatch(normalized);
    if (markMatch != null) {
      String target = markMatch.group(1)!.trim();
      if (target == 'the last task' ||
          target == 'last task' ||
          target == 'last one' ||
          target == 'the task' ||
          target == 'it' ||
          target == 'that' ||
          target == 'this') {
        target = 'the last task';
      }
      return ParsedCommand(
        rawText: rawTrimmed,
        intent: CommandIntent.complete,
        confidence: ConfidenceLevel.high,
        targetQuery: target,
        matchedTokens: ['mark', 'done', ...target.split(' ')],
        explanation: 'Matched completion command targeting "$target".',
      );
    }

    // 2. "[target] (is)? (done|completed|finished)" e.g. "call done", "buy cable done", "fix pump is done"
    final targetDoneRegex = RegExp(
      r'^(?:the\s+)?(?:task\s+)?(?:named\s+|called\s+)?(.+?)\s+(?:is\s+)?(?:done|completed|finished)$',
      caseSensitive: false,
    );
    final tdMatch = targetDoneRegex.firstMatch(normalized);
    if (tdMatch != null) {
      String target = tdMatch.group(1)!.trim();
      target = target
          .replaceFirst(
            RegExp(
              r'^(?:the\s+)?(?:task\s+)?(?:named\s+|called\s+)?',
              caseSensitive: false,
            ),
            '',
          )
          .trim();
      if (target == 'the last task' ||
          target == 'last task' ||
          target == 'last one' ||
          target == 'the task' ||
          target == 'it' ||
          target == 'that' ||
          target == 'this') {
        target = 'the last task';
      }
      if (target.isNotEmpty &&
          !target.startsWith('what') &&
          !target.startsWith('show') &&
          !target.startsWith('list') &&
          !target.startsWith('how') &&
          !target.startsWith('is')) {
        return ParsedCommand(
          rawText: rawTrimmed,
          intent: CommandIntent.complete,
          confidence: ConfidenceLevel.high,
          targetQuery: target,
          matchedTokens: ['done', ...target.split(' ')],
          explanation: 'Matched completion command targeting "$target".',
        );
      }
    }

    // 3. "complete ...", "finish ...", "finished ...", "done with ...", "check off ..."
    final completePrefixRegex = RegExp(
      r'^(?:complete|finish|finished|done\s+with|check\s+off|close|wrap)\s+(?:the\s+)?(?:task\s+)?(?:named\s+|called\s+)?(.+)$',
      caseSensitive: false,
    );
    final compMatch = completePrefixRegex.firstMatch(normalized);
    if (compMatch != null) {
      String target = compMatch.group(1)!.trim();
      target = target
          .replaceAll(RegExp(r'\b(?:as\s+done|done|completed|finished)\b'), '')
          .trim();
      if (target == 'the last task' ||
          target == 'last task' ||
          target == 'last one' ||
          target == 'the task' ||
          target == 'it' ||
          target == 'that' ||
          target == 'this') {
        target = 'the last task';
      }
      return ParsedCommand(
        rawText: rawTrimmed,
        intent: CommandIntent.complete,
        confidence: ConfidenceLevel.high,
        targetQuery: target,
        matchedTokens: ['complete', ...target.split(' ')],
        explanation: 'Matched completion command targeting "$target".',
      );
    }

    // 4. "mark done [target]"
    final markDonePrefix = RegExp(
      r'^mark\s+(?:done|completed)\s+(?:the\s+)?(?:task\s+)?(.+)$',
      caseSensitive: false,
    );
    final mdMatch = markDonePrefix.firstMatch(normalized);
    if (mdMatch != null) {
      String target = mdMatch.group(1)!.trim();
      if (target == 'the last task' ||
          target == 'last task' ||
          target == 'last one' ||
          target == 'the task' ||
          target == 'it' ||
          target == 'that' ||
          target == 'this') {
        target = 'the last task';
      }
      return ParsedCommand(
        rawText: rawTrimmed,
        intent: CommandIntent.complete,
        confidence: ConfidenceLevel.high,
        targetQuery: target,
        matchedTokens: ['mark', 'done', ...target.split(' ')],
        explanation: 'Matched completion command targeting "$target".',
      );
    }

    return null;
  }

  static ParsedCommand? _tryParseRescheduleCommand(
    String rawTrimmed,
    String normalized,
    DateTime demoClock,
  ) {
    final rescheduleRegex = RegExp(
      r'^(?:move|reschedule|shift|postpone|change|delay|push|defer)\s+(?:the\s+)?(?:task\s+)?(?:named\s+|called\s+)?(.+?)\s+(?:to|for|at|until)\s+(.+)$',
      caseSensitive: false,
    );
    final match = rescheduleRegex.firstMatch(normalized);
    if (match != null) {
      String target = match.group(1)!.trim();
      final destinationDateTimeStr = match.group(2)!.trim();

      if (target == 'the last task' ||
          target == 'last task' ||
          target == 'last one' ||
          target == 'the task' ||
          target == 'it' ||
          target == 'that' ||
          target == 'this') {
        target = 'the last task';
      }

      final parsedDt = DateTimeParser.parse(destinationDateTimeStr, demoClock);
      final hasDate = parsedDt.hasExplicitDate;
      final hasTime = parsedDt.hasExplicitTime;

      final date =
          parsedDt.date ??
          DateTime(demoClock.year, demoClock.month, demoClock.day);
      final timeMinutes = parsedDt.timeMinutes ?? (9 * 60);
      final usedDefaults = !hasDate || !hasTime;

      return ParsedCommand(
        rawText: rawTrimmed,
        intent: CommandIntent.reschedule,
        confidence: usedDefaults
            ? ConfidenceLevel.medium
            : ConfidenceLevel.high,
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
    return null;
  }

  static ParsedCommand? _tryParseAddCommand(
    String rawTrimmed,
    String normalized,
    DateTime demoClock,
  ) {
    // 1. Check for standard add prefixes:
    final addPrefixRegex = RegExp(
      r'^(?:add|create|new|schedule|remind\s+me\s+to|set\s+a?\s*task|need\s+to|i\s+want\s+to\s+add|make\s+a\s+task|put|log|plan)\s+(?:a\s+)?(?:new\s+)?(?:task)?\s*(?:named|called|name|with\s+title|with\s+name|to)?\s*',
      caseSensitive: false,
    );

    String remainder = '';
    bool matchedAddPrefix = false;

    final prefixMatch = addPrefixRegex.firstMatch(normalized);
    if (prefixMatch != null) {
      matchedAddPrefix = true;
      remainder = normalized.substring(prefixMatch.end).trim();
    } else {
      // If no explicit "add" prefix, check if sentence contains explicit task timing/priority:
      // e.g. "buy cable tomorrow at 5 pm high priority" or "call vendor tomorrow"
      final parsedCheck = DateTimeParser.parse(normalized, demoClock);
      final hasExplicitTiming =
          parsedCheck.hasExplicitDate || parsedCheck.hasExplicitTime;
      final hasPriorityWord = RegExp(
        r'\b(high|urgent|low|normal)\s*(?:priority)?\b',
        caseSensitive: false,
      ).hasMatch(normalized);

      // Or check if starts with a technician action verb:
      final startsWithTaskAction = RegExp(
        r'^(?:buy|call|fix|repair|inspect|clean|replace|order|check|drill|install|mount|service|drain|flush|calibrate|tighten)\s+',
        caseSensitive: false,
      ).hasMatch(normalized);

      if ((hasExplicitTiming || hasPriorityWord || startsWithTaskAction) &&
          !normalized.contains('what') &&
          !normalized.contains('show') &&
          !normalized.contains('list') &&
          !normalized.startsWith('delete') &&
          !normalized.startsWith('remove') &&
          !normalized.startsWith('mark') &&
          !normalized.startsWith('move')) {
        matchedAddPrefix = true;
        remainder = normalized;
      }
    }

    if (!matchedAddPrefix || remainder.isEmpty) {
      return null;
    }

    // Extract Priority
    TaskPriority? extractedPriority;
    bool hasExplicitPriority = false;
    final priorityRegex = RegExp(
      r'\b(high|urgent|normal|medium|low)\s*(?:priority)?\b',
      caseSensitive: false,
    );
    final pMatch = priorityRegex.firstMatch(remainder);
    if (pMatch != null) {
      hasExplicitPriority = true;
      extractedPriority = TaskPriority.fromString(pMatch.group(1));
      remainder = remainder.replaceRange(pMatch.start, pMatch.end, ' ');
    }

    // Extract Date and Time
    final parsedDt = DateTimeParser.parse(remainder, demoClock);
    remainder = parsedDt.cleanedText;

    // Remaining tokens make up the task title
    String title = remainder.replaceAll(RegExp(r'\s+'), ' ').trim();
    title = title
        .replaceFirst(
          RegExp(
            r'^(?:named|called|title|name|to|for|task)\s+',
            caseSensitive: false,
          ),
          '',
        )
        .trim();

    if (title.isEmpty) {
      return null;
    }

    // Defaults per Rule C1:
    final bool usedDefaults =
        !parsedDt.hasExplicitDate ||
        !parsedDt.hasExplicitTime ||
        !hasExplicitPriority;
    final resolvedDate =
        parsedDt.date ??
        DateTime(demoClock.year, demoClock.month, demoClock.day);
    final resolvedTimeMinutes = parsedDt.timeMinutes ?? (9 * 60);
    final resolvedPriority = extractedPriority ?? TaskPriority.normal;

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
