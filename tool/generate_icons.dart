// Генерирует иконки Android из логотипа приложения (SanjishLogoPainter).
// Запуск из корня проекта:
//   flutter test tool/generate_icons.dart
// Результат: android/app/src/main/res/mipmap-*/, web/favicon.png, web/icons/
// и build/icon_preview.png.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanjish/core/widgets/logo_painter.dart';

const _res = 'android/app/src/main/res';

/// Плотности экрана: папка → множитель от mdpi.
const _densities = {
  'mdpi': 1.0,
  'hdpi': 1.5,
  'xhdpi': 2.0,
  'xxhdpi': 3.0,
  'xxxhdpi': 4.0,
};

Future<void> _render(String path, int px, CustomPainter painter) async {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), Size(px.toDouble(), px.toDouble()));
  final image = await recorder.endRecording().toImage(px, px);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  testWidgets('Иконки Android', (tester) async {
    await tester.runAsync(() async {
      for (final MapEntry(key: density, value: k) in _densities.entries) {
        final dir = '$_res/mipmap-$density';
        // Обычная иконка (Android 7 и старше): 48 dp, скруглённый квадрат
        await _render(
          '$dir/ic_launcher.png',
          (48 * k).round(),
          const SanjishLogoPainter(inset: 0.04, cornerRadius: 0.24),
        );
        // Адаптивная иконка (Android 8+): слои 108 dp, видна середина 66 dp
        await _render(
          '$dir/ic_launcher_background.png',
          (108 * k).round(),
          const SanjishLogoPainter(drawForeground: false, cornerRadius: 0),
        );
        await _render(
          '$dir/ic_launcher_foreground.png',
          (108 * k).round(),
          const SanjishLogoPainter(drawBackground: false, contentScale: 0.62),
        );
      }
      // Веб: вкладка браузера и иконка «на главный экран»
      await _render(
        'web/favicon.png',
        64,
        const SanjishLogoPainter(cornerRadius: 0.24),
      );
      for (final size in [192, 512]) {
        await _render(
          'web/icons/Icon-$size.png',
          size,
          const SanjishLogoPainter(inset: 0.04, cornerRadius: 0.24),
        );
        // Маскируемая: фон на весь квадрат, рисунок в безопасной зоне
        await _render(
          'web/icons/Icon-maskable-$size.png',
          size,
          const SanjishLogoPainter(cornerRadius: 0, contentScale: 0.8),
        );
      }
      await _render('build/icon_preview.png', 512, const SanjishLogoPainter());
    });
  });
}
