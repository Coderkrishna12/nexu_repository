import 'package:flutter_test/flutter_test.dart';
import 'package:nexu_voicedesk/models/conversation_state.dart';
import 'package:nexu_voicedesk/providers/assistant_provider.dart';
import 'package:nexu_voicedesk/services/storage_service.dart';
import 'package:nexu_voicedesk/services/stt_service.dart';
import 'package:nexu_voicedesk/services/tts_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AssistantProvider Integration & State Flow Tests', () {
    late StorageService storage;
    late TtsService tts;
    late SttService stt;
    late AssistantProvider provider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      storage = StorageService(prefs);
      tts = TtsService();
      stt = SttService();
      provider = AssistantProvider(
        storage: storage,
        ttsService: tts,
        sttService: stt,
      );
    });

    test('Initial state matches assessment default demo clock', () {
      expect(provider.demoClock, equals(AssistantProvider.defaultDemoClock));
      expect(provider.tasks.isEmpty, isTrue);
      expect(provider.history.isEmpty, isTrue);
      expect(provider.undoStack.isEmpty, isTrue);
      expect(provider.isMuted, isFalse);
    });

    test('Adding task persists to storage and records in history', () async {
      await provider.submitCommand('add task buy cable tomorrow at 5 pm high priority');

      expect(provider.tasks.length, equals(1));
      expect(provider.tasks.first.title, equals('buy cable'));
      expect(provider.history.length, equals(1));
      expect(provider.history.first.userSpokenText, equals('add task buy cable tomorrow at 5 pm high priority'));
      expect(provider.undoStack.length, equals(1));

      // Reloading from storage retains tasks and history
      final reloadedTasks = storage.loadTasks();
      expect(reloadedTasks.length, equals(1));
      expect(reloadedTasks.first.title, equals('buy cable'));

      final reloadedHistory = storage.loadHistory();
      expect(reloadedHistory.length, equals(1));
    });

    test('Multi-turn C2 Past Time confirmation flow via tap', () async {
      // 9:00 AM default time has passed on 10:00 AM demo clock
      await provider.submitCommand('add task call vendor');

      expect(provider.conversationState.status, equals(ConversationStatus.awaitingPastTimeConfirmation));
      expect(provider.tasks.isEmpty, isTrue);

      // Confirm via tap
      await provider.confirmPastTimeByTap(true);

      expect(provider.conversationState.status, equals(ConversationStatus.idle));
      expect(provider.tasks.length, equals(1));
      expect(provider.tasks.first.title, equals('call vendor'));
      // Moved to 12 Nov, 9:00 AM
      expect(provider.tasks.first.dueDateTime.day, equals(12));
    });

    test('Multi-turn C5 Delete confirmation flow via tap and undo', () async {
      await provider.submitCommand('add task buy cable tomorrow at 5 pm high priority');
      expect(provider.tasks.length, equals(1));

      await provider.submitCommand('delete the last task');
      expect(provider.isAwaitingDeleteConfirmation, isTrue);
      expect(provider.tasks.length, equals(1)); // not deleted yet

      // Confirm deletion via tap
      await provider.confirmDeleteByTap(true);
      expect(provider.isAwaitingDeleteConfirmation, isFalse);
      expect(provider.tasks.isEmpty, isTrue);

      // Undo deletion
      await provider.submitCommand('undo that');
      expect(provider.tasks.length, equals(1));
      expect(provider.tasks.first.title, equals('buy cable'));
    });

    test('Mute toggle suppresses TTS without affecting state', () async {
      expect(provider.isMuted, isFalse);
      await provider.toggleMute();
      expect(provider.isMuted, isTrue);

      await provider.submitCommand('add task buy cable tomorrow at 5 pm high priority');
      expect(provider.tasks.length, equals(1));
      expect(storage.loadMute(), isTrue);
    });

    test('Adjusting Demo Clock and Resetting to Assessment Default', () async {
      final customClock = DateTime(2026, 12, 25, 14, 30);
      await provider.setDemoClock(customClock);
      expect(provider.demoClock, equals(customClock));

      await provider.resetDemoClockToDefault();
      expect(provider.demoClock, equals(AssistantProvider.defaultDemoClock));
    });
  });
}

