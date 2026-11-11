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
        // "interrupted" or "canceled" is expected normal behavior when speech is interrupted
        final str = msg.toString().toLowerCase();
        if (str.contains('interrupted') || str.contains('cancel')) {
          return;
        }
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
      if (_isSpeaking) {
        await stop();
        // Brief pause to allow the native audio track to release
        await Future.delayed(const Duration(milliseconds: 60));
      }
      _isSpeaking = true;
      await _flutterTts
          .speak(text)
          .timeout(const Duration(seconds: 1), onTimeout: () => 1);
    } catch (e) {
      _isSpeaking = false;
      debugPrint("TTS speak failed: $e");
    }
  }

  /// Immediately interrupts and cuts off any currently playing speech.
  Future<void> stop() async {
    try {
      _isSpeaking = false;
      await _flutterTts.stop().timeout(
        const Duration(milliseconds: 400),
        onTimeout: () => 1,
      );
    } catch (e) {
      debugPrint("TTS stop error: $e");
    }
  }
}
