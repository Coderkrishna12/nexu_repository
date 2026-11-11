import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexu_voicedesk/core/theme/app_theme.dart';
import 'package:nexu_voicedesk/providers/assistant_provider.dart';
import 'package:nexu_voicedesk/services/storage_service.dart';
import 'package:nexu_voicedesk/services/stt_service.dart';
import 'package:nexu_voicedesk/services/tts_service.dart';
import 'package:nexu_voicedesk/ui/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('NEXU VoiceDesk Home UI Smoke Test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);
    final tts = TtsService();
    final stt = SttService();

    final provider = AssistantProvider(
      storage: storage,
      ttsService: tts,
      sttService: stt,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AssistantProvider>.value(value: provider),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify key UI elements render
    expect(find.text('NEXU VoiceDesk'), findsOneWidget);
    expect(find.text('DEMO CLOCK'), findsOneWidget);
    expect(find.textContaining('Understanding Panel ready'), findsOneWidget);
    expect(find.text('SIMULATED VOICE (TYPED INPUT)'), findsOneWidget);

    // Enter a simulated command into the text box
    final textField = find.byType(TextField);
    expect(textField, findsOneWidget);

    await tester.enterText(textField, 'add task buy cable tomorrow at 5 pm high priority');
    await tester.tap(find.text('Send'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Verify task is now visible on screen
    expect(find.text('buy cable'), findsOneWidget);
    expect(find.text('HIGH'), findsOneWidget);
    expect(find.text('CONFIDENCE HIGH'), findsOneWidget);
  });
}
