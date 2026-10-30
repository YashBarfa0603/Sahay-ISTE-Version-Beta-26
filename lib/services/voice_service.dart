import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Voice service wrapping speech-to-text (STT) and text-to-speech (TTS)
/// with support for 8 major Indian languages.
class VoiceService {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  bool _isAvailable = false;
  bool _isListening = false;
  bool _isInitialized = false;

  /// Mapping from standard ISO language codes to Indian speech locales
  static const Map<String, String> _localeMap = {
    'en': 'en-IN',
    'hi': 'hi-IN',
    'ta': 'ta-IN',
    'mr': 'mr-IN',
    'bn': 'bn-IN',
    'gu': 'gu-IN',
    'kn': 'kn-IN',
    'or': 'or-IN',
  };

  /// Check whether Speech-To-Text hardware/service is initialized and available
  bool get isAvailable => _isAvailable;

  /// Check whether currently actively listening to audio input
  bool get isListening => _isListening;

  /// Convert standard 2-letter language code to speech locale tag
  String mapLocale(String locale) {
    final clean = locale.toLowerCase().split('-').first.split('_').first;
    return _localeMap[clean] ?? _localeMap['en']!;
  }

  /// Initialize both STT and TTS engines
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _isAvailable = await _speechToText.initialize(
        onError: (val) {
          debugPrint('VoiceService STT Error: ${val.errorMsg} (permanent: ${val.permanent})');
          _isListening = false;
        },
        onStatus: (val) {
          debugPrint('VoiceService STT Status: $val');
          if (val == 'notListening' || val == 'done') {
            _isListening = false;
          }
        },
      );

      // Configure default TTS settings for clear Indian English/Hindi vocalization
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _isInitialized = true;
      debugPrint('VoiceService initialized successfully. STT Available: $_isAvailable');
    } catch (e, stackTrace) {
      debugPrint('VoiceService initialization failed: $e\n$stackTrace');
      _isAvailable = false;
    }
  }

  /// Start listening for voice input in the specified locale.
  /// Calls [onResult] with the latest recognized text.
  Future<void> startListening({
    required String locale,
    required Function(String) onResult,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_isAvailable) {
      debugPrint('VoiceService: STT is not available on this device.');
      return;
    }

    final speechLocale = mapLocale(locale);

    try {
      _isListening = true;
      await _speechToText.listen(
        onResult: (result) {
          final words = result.recognizedWords;
          if (words.isNotEmpty) {
            onResult(words);
          }
        },
        listenOptions: stt.SpeechListenOptions(
          localeId: speechLocale,
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      debugPrint('VoiceService startListening error: $e');
      _isListening = false;
    }
  }

  /// Stop listening for voice input
  Future<void> stopListening() async {
    try {
      if (_isListening) {
        await _speechToText.stop();
        _isListening = false;
      }
    } catch (e) {
      debugPrint('VoiceService stopListening error: $e');
      _isListening = false;
    }
  }

  /// Speak text aloud in the given locale
  Future<void> speak(String text, {String locale = 'en'}) async {
    if (text.trim().isEmpty) return;

    try {
      final speechLocale = mapLocale(locale);
      await _flutterTts.setLanguage(speechLocale);
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('VoiceService speak error: $e');
    }
  }

  /// Stop speech output
  Future<void> stopSpeaking() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('VoiceService stopSpeaking error: $e');
    }
  }

  /// Release resources and stop any active audio operations
  void dispose() {
    stopListening();
    stopSpeaking();
  }
}
