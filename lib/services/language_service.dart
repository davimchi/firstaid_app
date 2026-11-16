import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static final LanguageService instance = LanguageService._init();
  LanguageService._init();

  String _currentLocale = 'en';

  String get currentLocale => _currentLocale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLocale = prefs.getString('locale') ?? 'en';
  }

  Future<void> setLocale(String locale) async {
    if (locale != 'en' && locale != 'sw') return;
    _currentLocale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale);
  }

  /// Translate a raw JSON map stored in SQLite into the current language.
  /// e.g. '{"en":"Bleeding","sw":"Kutokwa damu"}' → "Bleeding" or "Kutokwa damu"
  String tr(String? rawJson) {
    if (rawJson == null || rawJson.isEmpty) return '';
    try {
      final map = jsonDecode(rawJson) as Map<String, dynamic>;
      final val = map[_currentLocale] ?? map['en'] ?? '';
      return val.toString();
    } catch (_) {
      // Not valid JSON — return as-is (plain text)
      return rawJson;
    }
  }

  /// Inline translation for hardcoded UI strings.
  /// Usage: LanguageService.instance.t('Get emergency help', 'Pata msaada wa dharura')
  String t(String en, String sw) => _currentLocale == 'sw' ? sw : en;
}
