import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanjish/app/app.dart';
import 'package:sanjish/app/settings/app_settings.dart';
import 'package:sanjish/core/l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpApp(WidgetTester tester, Map<String, Object> prefs) async {
  // Экран телефона (на широком экране приложение рисуется «телефоном»)
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(prefs);
  final instance = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(instance)],
      child: const SanjishApp(),
    ),
  );
  // Заставка ждёт ~700 мс, затем переходит дальше
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Таджикский: Material-локализации есть, приложение не падает', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: kTajik,
        supportedLocales: kSupportedLocales,
        localizationsDelegates: kLocalizationsDelegates,
        home: Builder(
          builder: (context) => Column(
            children: [
              Text(context.l10n.subjects),
              // Кнопка из Material-локализаций (подставлены русские)
              Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Фанҳо'), findsOneWidget);
    expect(find.text('Отмена'), findsOneWidget);
  });

  testWidgets('Первый запуск: выбор языка, по умолчанию таджикский', (
    tester,
  ) async {
    await _pumpApp(tester, {});

    expect(find.text('Забонро интихоб кунед'), findsOneWidget);

    // Нажатие на «Русский» сразу переключает интерфейс
    await tester.tap(find.text('Русский'));
    await tester.pumpAndSettle();
    expect(find.text('Выберите язык'), findsOneWidget);

    // «Продолжить» → экран входа на русском
    await tester.tap(find.text('Продолжить'));
    await tester.pumpAndSettle();
    expect(find.text('Войти'), findsOneWidget);
  });

  testWidgets('Повторный запуск: экран выбора языка не показывается', (
    tester,
  ) async {
    await _pumpApp(tester, {
      'settings.languageChosen': true,
      'settings.locale': 'tg',
    });

    expect(find.text('Забонро интихоб кунед'), findsNothing);
    expect(find.text('Ворид шудан'), findsOneWidget);
  });
}
