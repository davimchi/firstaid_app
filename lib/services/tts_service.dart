import 'package:flutter_tts/flutter_tts.dart';
import 'language_service.dart';

class TtsService {
  static final TtsService instance = TtsService._init();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  TtsService._init();

  Future<void> _init() async {
    if (_isInitialized) return;
    
    // Set basic settings for clarity in an emergency
    await _flutterTts.setSpeechRate(0.45); // Slightly slower for clear instructions
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    _isInitialized = true;
  }

  Future<void> speak(String text) async {
    await _init();
    await stop(); // Stop any currently playing audio

    // Set language based on app locale
    final locale = LanguageService.instance.currentLocale;
    // FlutterTTS uses standard locale codes (e.g., 'en-US', 'sw-KE')
    if (locale == 'sw') {
      await _flutterTts.setLanguage('sw-KE'); 
    } else {
      await _flutterTts.setLanguage('en-US');
    }

    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    if (_isInitialized) {
      await _flutterTts.stop();
    }
  }

  Future<bool> isSpeaking() async {
    if (!_isInitialized) return false;
    final speaking = await _flutterTts.isLanguageAvailable("en-US"); // Just a dummy call to check status
    // Note: FlutterTts doesn't have a perfect isSpeaking() method, so we'll manage state in the UI.
    return false; 
  }
}
