import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceService {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  bool _isAvailable = false;
  bool _isListening = false;
  bool _isInitialized = false;

  // Locales
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

  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;

  String mapLocale(String locale) {
    final clean = locale.toLowerCase().split('-').first.split('_').first;
    return _localeMap[clean] ?? _localeMap['en']!;
  }

  // Init
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _isAvailable = await _speechToText.initialize(
        onError: (val) {
          debugPrint('VoiceService STT Error: ${val.errorMsg}');
          _isListening = false;
        },
        onStatus: (val) {
          debugPrint('VoiceService STT Status: $val');
          if (val == 'notListening' || val == 'done') {
            _isListening = false;
          }
        },
      );

      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _isInitialized = true;
      debugPrint('VoiceService initialized successfully. STT Available: $_isAvailable');
    } catch (e, stackTrace) {
      debugPrint('VoiceService error: $e\n$stackTrace');
      _isAvailable = false;
    }
  }

  // Listen
  Future<void> startListening({
    required String locale,
    required Function(String) onResult,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_isAvailable) {
      debugPrint('VoiceService: STT unavailable');
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

  // Stop listening
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

  // Speak
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

  // Stop speaking
  Future<void> stopSpeaking() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('VoiceService stopSpeaking error: $e');
    }
  }

  // Dispose
  void dispose() {
    stopListening();
    stopSpeaking();
  }
}
