import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Во Flutter нет встроенных Material/Cupertino/Widgets-локализаций
/// для таджикского языка (`tg`). Без них приложение падает с ошибкой
/// "No MaterialLocalizations found".
///
/// Эти делегаты для `tg` подставляют русские системные локализации
/// (кнопки диалогов, календарь, подсказки полей), а тексты самого
/// приложения по-прежнему берутся из app_tg.arb.
///
/// Делегаты нужно ставить в списке ПЕРЕД Global*Localizations.delegate.
const _fallbackLocale = Locale('ru');

bool _isTajik(Locale locale) => locale.languageCode == 'tg';

class TgMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const TgMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => _isTajik(locale);

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(_fallbackLocale);

  @override
  bool shouldReload(TgMaterialLocalizationsDelegate old) => false;
}

class TgCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const TgCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => _isTajik(locale);

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      GlobalCupertinoLocalizations.delegate.load(_fallbackLocale);

  @override
  bool shouldReload(TgCupertinoLocalizationsDelegate old) => false;
}

class TgWidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const TgWidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => _isTajik(locale);

  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      GlobalWidgetsLocalizations.delegate.load(_fallbackLocale);

  @override
  bool shouldReload(TgWidgetsLocalizationsDelegate old) => false;
}

/// Делегаты-обёртки для таджикского — подключаются в MaterialApp.
const tgFallbackDelegates = <LocalizationsDelegate<dynamic>>[
  TgMaterialLocalizationsDelegate(),
  TgCupertinoLocalizationsDelegate(),
  TgWidgetsLocalizationsDelegate(),
];
