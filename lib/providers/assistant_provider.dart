import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../engine/command_engine.dart';
import '../models/command_intent.dart';
import '../models/confidence_level.dart';
import '../models/conversation_state.dart';
import '../models/parsed_command_log.dart';
import '../models/task_item.dart';
import '../models/undo_action.dart';
import '../services/storage_service.dart';
import '../services/stt_service.dart';
import '../services/tts_service.dart';

class AssistantProvider extends ChangeNotifier {
  static const _uuid = Uuid();

  // Assessment Default Demo Clock: Wednesday, 11 November 2026, 10:00 AM
  static final DateTime defaultDemoClock = DateTime(2026, 11, 11, 10, 0);

  final StorageService _storage;
  final TtsService _ttsService;
  final SttService _sttService;

  List<TaskItem> _tasks = [];
  ConversationState _conversationState = ConversationState.idle;
  List<UndoAction> _undoStack = [];
  String? _lastMentionedTaskId;
  DateTime _demoClock = defaultDemoClock;
  List<ParsedCommandLog> _history = [];

  bool _isListening = false;
  String _liveTranscript = '';
  bool _isMuted = false;
  String? _micErrorMessage;

  // Rule C5: 8-second countdown timer
  int _deleteCountdownSeconds = 8;
  Timer? _deleteTimer;

  AssistantProvider({
    required StorageService storage,
    required TtsService ttsService,
    required SttService sttService,
  })  : _storage = storage,
        _ttsService = ttsService,
        _sttService = sttService {
    _loadFromStorage();
  }

  // Getters
  List<TaskItem> get tasks => List.unmodifiable(_tasks);
  ConversationState get conversationState => _conversationState;
  List<UndoAction> get undoStack => List.unmodifiable(_undoStack);
  String? get lastMentionedTaskId => _lastMentionedTaskId;
  DateTime get demoClock => _demoClock;
  List<ParsedCommandLog> get history => List.unmodifiable(_history);
  bool get isListening => _isListening;
  String get liveTranscript => _liveTranscript;
  bool get isMuted => _isMuted;
  String? get micErrorMessage => _micErrorMessage;
  int get deleteCountdownSeconds => _deleteCountdownSeconds;
  bool get isAwaitingDeleteConfirmation =>
      _conversationState.status == ConversationStatus.awaitingDeleteConfirmation;
  String? get sttLocale => _sttService.preferredLocaleId;
  List<dynamic> get sttLocales => _sttService.locales;

  void setSttLocale(String localeId) {
    _sttService.preferredLocaleId = localeId;
    notifyListeners();
  }

  void _loadFromStorage() {
    _tasks = _storage.loadTasks();
    _history = _storage.loadHistory();
    _undoStack = _storage.loadUndoStack();
    _isMuted = _storage.loadMute();
    _demoClock = _storage.loadDemoClock() ?? defaultDemoClock;
    if (_tasks.isNotEmpty) {
      _lastMentionedTaskId = _tasks.last.id;
    }
  }

  // -------------------------------------------------------------
  // Command Processing (Voice & Simulated Voice pipeline)
  // -------------------------------------------------------------
  Future<void> submitCommand(String rawInput) async {
    final trimmed = rawInput.trim();
    if (trimmed.isEmpty) return;

    // Interrupt any ongoing speech immediately
    await _ttsService.stop();

    // Cancel any active delete countdown timer
    _cancelDeleteTimer();

    // Process through pure command engine
    final result = CommandEngine.processInput(
      rawInput: trimmed,
      currentTasks: _tasks,
      conversationState: _conversationState,
      undoStack: _undoStack,
      lastMentionedTaskId: _lastMentionedTaskId,
      demoClock: _demoClock,
    );

    _tasks = result.updatedTasks;
    _conversationState = result.updatedConversationState;
    _undoStack = result.updatedUndoStack;
    _lastMentionedTaskId = result.lastMentionedTaskId;

    // Create log entry for the Understanding Panel
    final logEntry = ParsedCommandLog.fromParsedCommand(
      id: _uuid.v4(),
      parsed: result.parsedCommand,
      responseMessage: result.visualMessage,
      wasExecuted: result.wasExecuted,
    );
    _history = [logEntry, ..._history];

    // If waiting for delete confirmation (Rule C5), start 8s countdown
    if (_conversationState.status == ConversationStatus.awaitingDeleteConfirmation) {
      _startDeleteCountdown();
    }

    // Persist changes
    await _storage.saveTasks(_tasks);
    await _storage.saveHistory(_history);
    await _storage.saveUndoStack(_undoStack);

    notifyListeners();

    // Speak reply
    await _ttsService.speak(result.spokenResponse, isMuted: _isMuted);
  }

  // -------------------------------------------------------------
  // Rule C5: Delete 8-Second Safety Countdown Timer
  // -------------------------------------------------------------
  void _startDeleteCountdown() {
    _cancelDeleteTimer();
    _deleteCountdownSeconds = 8;

    _deleteTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      _deleteCountdownSeconds--;
      if (_deleteCountdownSeconds <= 0) {
        _cancelDeleteTimer();
        // 8 seconds elapsed with no answer -> cancel deletion!
        _conversationState = ConversationState.idle;
        notifyListeners();

        const timeoutMsg = "No answer received. Deletion cancelled.";
        final timeoutLog = ParsedCommandLog(
          id: _uuid.v4(),
          userSpokenText: "(8s timeout)",
          intent: CommandIntent.confirmNo,
          confidence: ConfidenceLevel.high,
          responseMessage: timeoutMsg,
          wasExecuted: false,
        );
        _history = [timeoutLog, ..._history];
        await _storage.saveHistory(_history);

        await _ttsService.speak(timeoutMsg, isMuted: _isMuted);
      } else {
        notifyListeners();
      }
    });
  }

  void _cancelDeleteTimer() {
    _deleteTimer?.cancel();
    _deleteTimer = null;
  }

  // -------------------------------------------------------------
  // Quick Actions (Tap alternatives for gloved technician)
  // -------------------------------------------------------------
  Future<void> confirmDeleteByTap(bool confirm) async {
    _cancelDeleteTimer();
    await submitCommand(confirm ? "yes" : "no");
  }

  Future<void> confirmPastTimeByTap(bool move) async {
    await submitCommand(move ? "yes" : "no");
  }

  Future<void> selectAmbiguityOptionByTap(int index) async {
    final optionWords = ["one", "two", "three"];
    final word = index < optionWords.length ? optionWords[index] : "${index + 1}";
    await submitCommand(word);
  }

  bool _isHoldingButton = false;

  // -------------------------------------------------------------
  // Voice Input (Hold-to-Talk)
  // -------------------------------------------------------------
  Future<void> startListening({bool isHold = false}) async {
    // Interrupt TTS immediately
    await _ttsService.stop();

    _isHoldingButton = isHold;
    _micErrorMessage = null;
    _liveTranscript = '';
    _isListening = true;
    notifyListeners();

    await _sttService.startListening(
      onResult: (text, isFinal) {
        _liveTranscript = text;
        notifyListeners();
        // If user tapped rather than held down, auto-stop on final recognition
        if (!_isHoldingButton && isFinal && text.trim().isNotEmpty) {
          stopListening();
        }
      },
      onError: (error) {
        _isListening = false;
        _micErrorMessage = error;
        notifyListeners();
      },
    );
  }

  Future<void> stopListening() async {
    if (!_isListening) return;
    _isListening = false;
    await _sttService.stopListening();
    // Allow brief moment for STT engine to emit the final speech buffer
    await Future.delayed(const Duration(milliseconds: 150));
    final captured = _liveTranscript.trim();
    notifyListeners();

    if (captured.isNotEmpty) {
      await submitCommand(captured);
    }
  }

  Future<void> cancelListening() async {
    _isListening = false;
    _liveTranscript = '';
    await _sttService.cancelListening();
    notifyListeners();
  }

  // -------------------------------------------------------------
  // Settings & Demo Clock
  // -------------------------------------------------------------
  Future<void> setDemoClock(DateTime newClock) async {
    _demoClock = newClock;
    await _storage.saveDemoClock(newClock);
    notifyListeners();
  }

  Future<void> resetDemoClockToDefault() async {
    await setDemoClock(defaultDemoClock);
  }

  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    await _storage.saveMute(_isMuted);
    if (_isMuted) {
      await _ttsService.stop();
    }
    notifyListeners();
  }

  Future<void> clearAll() async {
    _cancelDeleteTimer();
    _tasks = [];
    _history = [];
    _undoStack = [];
    _lastMentionedTaskId = null;
    _conversationState = ConversationState.idle;
    await _storage.clearAll();
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelDeleteTimer();
    super.dispose();
  }
}
