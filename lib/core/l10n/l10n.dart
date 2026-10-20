import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../l10n/generated/app_localizations.dart';
import 'tg_fallback_localizations.dart';

export '../../l10n/generated/app_localizations.dart';

/// Поддерживаемые языки. Первый — язык по умолчанию.
const kTajik = Locale('tg');
const kRussian = Locale('ru');
const kSupportedLocales = <Locale>[kTajik, kRussian];

/// Полный список делегатов локализации для MaterialApp.
/// Таджикские обёртки идут первыми — Flutter берёт первый подходящий делегат.
const kLocalizationsDelegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  ...tgFallbackDelegates,
  GlobalMaterialLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
];

extension L10nContext on BuildContext {
  /// Короткий доступ к строкам: `context.l10n.subjects`.
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// true, если интерфейс сейчас на таджикском.
  bool get isTajik => Localizations.localeOf(this).languageCode == 'tg';

  /// Выбирает поле `...Tg` или `...Ru` из данных Firestore.
  /// Если на текущем языке текста нет — возвращает текст на другом языке.
  String pickLang(String? tg, String? ru) {
    final primary = isTajik ? tg : ru;
    final fallback = isTajik ? ru : tg;
    if (primary != null && primary.trim().isNotEmpty) return primary;
    return fallback ?? '';
  }
}
