import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/l10n/l10n.dart';

/// Экземпляр SharedPreferences. Подменяется в main() уже загруженным
/// значением, чтобы настройки читались синхронно, без мигания экрана.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider не подменён в main()',
  ),
);

/// Локальные настройки пользователя.
@immutable
class AppSettings {
  const AppSettings({
    required this.locale,
    required this.themeMode,
    required this.largeFont,
    required this.languageChosen,
  });

  final Locale locale;
  final ThemeMode themeMode;
  final bool largeFont;

  /// Выбирал ли пользователь язык на первом запуске.
  final bool languageChosen;

  AppSettings copyWith({
    Locale? locale,
    ThemeMode? themeMode,
    bool? largeFont,
    bool? languageChosen,
  }) => AppSettings(
    locale: locale ?? this.locale,
    themeMode: themeMode ?? this.themeMode,
    largeFont: largeFont ?? this.largeFont,
    languageChosen: languageChosen ?? this.languageChosen,
  );
}

class SettingsController extends Notifier<AppSettings> {
  static const _kLocale = 'settings.locale';
  static const _kTheme = 'settings.themeMode';
  static const _kLargeFont = 'settings.largeFont';
  static const _kLanguageChosen = 'settings.languageChosen';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final code = prefs.getString(_kLocale);
    final locale = kSupportedLocales.firstWhere(
      (l) => l.languageCode == code,
      orElse: () => kTajik,
    );
    final themeName = prefs.getString(_kTheme);
    final themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == themeName,
      orElse: () => ThemeMode.system,
    );
    return AppSettings(
      locale: locale,
      themeMode: themeMode,
      largeFont: prefs.getBool(_kLargeFont) ?? false,
      languageChosen: prefs.getBool(_kLanguageChosen) ?? false,
    );
  }

  /// Меняет язык — применяется сразу, без перезапуска.
  Future<void> setLocale(Locale locale) async {
    state = state.copyWith(locale: locale);
    await _prefs.setString(_kLocale, locale.languageCode);
  }

  /// Отмечает, что экран выбора языка пройден.
  Future<void> markLanguageChosen() async {
    state = state.copyWith(languageChosen: true);
    await _prefs.setBool(_kLanguageChosen, true);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setString(_kTheme, mode.name);
  }

  Future<void> setLargeFont(bool value) async {
    state = state.copyWith(largeFont: value);
    await _prefs.setBool(_kLargeFont, value);
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);
