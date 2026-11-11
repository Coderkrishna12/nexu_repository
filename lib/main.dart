import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/assistant_provider.dart';
import 'services/storage_service.dart';
import 'services/stt_service.dart';
import 'services/tts_service.dart';
import 'ui/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = await StorageService.init();
  final tts = TtsService();
  await tts.init();
  final stt = SttService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AssistantProvider(
            storage: storage,
            ttsService: tts,
            sttService: stt,
          ),
        ),
      ],
      child: const NexuVoiceDeskApp(),
    ),
  );
}

class NexuVoiceDeskApp extends StatelessWidget {
  const NexuVoiceDeskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NEXU VoiceDesk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
