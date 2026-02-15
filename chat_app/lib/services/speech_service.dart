import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Service for speech-to-text voice command input.
///
/// Singleton pattern following HapticService.
class SpeechService {
  SpeechService._();
  static final SpeechService instance = SpeechService._();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  /// Whether the service is currently listening for speech.
  bool get isListening => _isListening;

  /// Whether speech recognition is available on this device.
  bool get isAvailable => _isInitialized;

  /// Initialize the speech recognition engine.
  /// Call once before first use. Safe to call multiple times.
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    try {
      _isInitialized = await _speech.initialize(
        onError: (error) {
          debugPrint('Speech error: ${error.errorMsg}');
          _isListening = false;
        },
        onStatus: (status) {
          debugPrint('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
      );
      return _isInitialized;
    } catch (e) {
      debugPrint('Speech init failed: $e');
      return false;
    }
  }

  /// Start listening for speech input.
  ///
  /// [onResult] is called with the recognized text and whether it's a final result.
  /// [localeId] defaults to 'en_US'.
  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    String localeId = 'en_US',
  }) async {
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) return;
    }
    if (_isListening) return;

    _isListening = true;
    await _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords, result.finalResult);
      },
      localeId: localeId,
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.confirmation,
        cancelOnError: true,
        partialResults: true,
      ),
    );
  }

  /// Stop listening and keep the recognized text.
  Future<void> stopListening() async {
    if (!_isListening) return;
    await _speech.stop();
    _isListening = false;
  }

  /// Cancel listening and discard any recognized text.
  Future<void> cancel() async {
    await _speech.cancel();
    _isListening = false;
  }
}
