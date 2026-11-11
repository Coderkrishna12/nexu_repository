import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
      });

      _flutterTts.setCancelHandler(() {
        _isSpeaking = false;
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        debugPrint("TTS Error: $msg");
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint("TTS init error: $e");
    }
  }

  /// Speaks [text] aloud. If already speaking, stops and speaks new text immediately.
  Future<void> speak(String text, {bool isMuted = false}) async {
    if (isMuted || text.trim().isEmpty) {
      await stop();
      return;
    }

    try {
      if (!_isInitialized) {
        await init();
      }
      await stop(); // Cut off any previous speech immediately
      await _flutterTts.speak(text).timeout(
            const Duration(milliseconds: 800),
            onTimeout: () => 1,
          );
    } catch (e) {
      debugPrint("TTS speak failed: $e");
    }
  }

  /// Immediately interrupts and cuts off any currently playing speech.
  Future<void> stop() async {
    try {
      _isSpeaking = false;
      await _flutterTts.stop().timeout(
            const Duration(milliseconds: 500),
            onTimeout: () => 1,
          );
    } catch (e) {
      debugPrint("TTS stop error: $e");
    }
  }
}
