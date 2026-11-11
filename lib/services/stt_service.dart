import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SttService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;
  bool _isListening = false;
  String _lastError = '';
  List<stt.LocaleName> _locales = [];
  String? preferredLocaleId;

  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;
  String get lastError => _lastError;
  List<stt.LocaleName> get locales => _locales;

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

      if (_isAvailable) {
        try {
          _locales = await _speech.locales();
          // Detect en_IN (English - India) for Indian English accent recognition
          final enIn = _locales.where((l) {
            final id = l.localeId.toLowerCase().replaceAll('-', '_');
            return id.startsWith('en_in');
          }).firstOrNull;

          if (enIn != null) {
            preferredLocaleId ??= enIn.localeId;
          } else {
            final sysLocale = await _speech.systemLocale();
            preferredLocaleId ??= sysLocale?.localeId;
          }
          debugPrint("STT initialized with preferred locale: $preferredLocaleId");
        } catch (localeErr) {
          debugPrint("STT locale detection note: $localeErr");
        }
      }

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
        onError(
          "Speech recognition unavailable or microphone permission denied.",
        );
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
          localeId: preferredLocaleId,
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
          cancelOnError: false,
          pauseFor: const Duration(seconds: 8),
          listenFor: const Duration(seconds: 60),
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
