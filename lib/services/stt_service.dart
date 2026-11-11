import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SttService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;
  bool _isListening = false;
  String _lastError = '';

  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;
  String get lastError => _lastError;

  Future<bool> initialize({
    Function(String error)? onError,
    VoidCallback? onStatusChanged,
  }) async {
    try {
      _isAvailable = await _speech.initialize(
        onError: (val) {
          _isListening = false;
          _lastError = val.errorMsg;
          debugPrint("STT onError: ${val.errorMsg}");
          onError?.call(val.errorMsg);
        },
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            _isListening = false;
          }
          onStatusChanged?.call();
        },
      );
      return _isAvailable;
    } catch (e) {
      _isAvailable = false;
      _lastError = e.toString();
      debugPrint("STT initialization failed: $e");
      return false;
    }
  }

  Future<void> startListening({
    required Function(String text, bool isFinal) onResult,
    required Function(String error) onError,
  }) async {
    if (!_isAvailable) {
      final initialized = await initialize(onError: onError);
      if (!initialized) {
        onError("Speech recognition unavailable or microphone permission denied.");
        return;
      }
    }

    try {
      _isListening = true;
      _lastError = '';
      await _speech.listen(
        onResult: (val) {
          onResult(val.recognizedWords, val.finalResult);
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.confirmation,
          partialResults: true,
          cancelOnError: true,
        ),
      );
    } catch (e) {
      _isListening = false;
      _lastError = e.toString();
      onError(e.toString());
    }
  }

  Future<void> stopListening() async {
    try {
      _isListening = false;
      await _speech.stop();
    } catch (e) {
      debugPrint("STT stop error: $e");
    }
  }

  Future<void> cancelListening() async {
    try {
      _isListening = false;
      await _speech.cancel();
    } catch (e) {
      debugPrint("STT cancel error: $e");
    }
  }
}
