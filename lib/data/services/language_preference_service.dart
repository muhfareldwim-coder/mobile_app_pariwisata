import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguagePreferenceService {
  static const _languageKey = 'jembergo_language';
  static const _defaultLocale = Locale('id', 'ID');
  static const supportedLocales = [Locale('id', 'ID'), Locale('en', 'US')];
  static final ValueNotifier<Locale> locale = ValueNotifier(_defaultLocale);

  static Future<void> restore() async {
    final preferences = await SharedPreferences.getInstance();
    final languageCode = preferences.getString(_languageKey);
    locale.value = supportedLocales.firstWhere(
      (supportedLocale) => supportedLocale.languageCode == languageCode,
      orElse: () => _defaultLocale,
    );
  }

  static Future<void> setLocale(Locale newLocale) async {
    final supportedLocale = supportedLocales.firstWhere(
      (supportedLocale) =>
          supportedLocale.languageCode == newLocale.languageCode,
      orElse: () => _defaultLocale,
    );
    if (supportedLocale.languageCode != newLocale.languageCode) {
      throw ArgumentError.value(
        newLocale,
        'newLocale',
        'Bahasa tidak didukung',
      );
    }

    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _languageKey,
      supportedLocale.languageCode,
    );
    if (!saved) {
      throw StateError('Gagal menyimpan pilihan bahasa.');
    }
    locale.value = supportedLocale;
  }

  static String labelFor(Locale value) =>
      value.languageCode == 'en' ? 'English (US)' : 'Bahasa Indonesia (ID)';
}
