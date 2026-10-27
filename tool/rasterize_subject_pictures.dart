// Переводит картинки предметов из SVG (tool/subject_svgs/, Twemoji)
// в PNG (assets/subjects/). PNG телефон декодирует в фоне, поэтому запуск
// не тормозит; SVG пришлось бы разбирать при каждом открытии главной.
// Запуск из корня проекта: flutter test tool/rasterize_subject_pictures.dart

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

/// Сторона PNG: крупная картинка на обложке ~60 dp × 3 (плотность экрана).
const _size = 192;

void main() {
  testWidgets('SVG → PNG', (tester) async {
    await tester.runAsync(() async {
      final out = Directory('assets/subjects')..createSync(recursive: true);
      for (final file in Directory('tool/subject_svgs').listSync()) {
        if (!file.path.endsWith('.svg')) continue;
        final svg = File(file.path).readAsStringSync();
        final info = await vg.loadPicture(SvgStringLoader(svg), null);
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder)
          ..scale(_size / info.size.width, _size / info.size.height)
          ..drawPicture(info.picture);
        final image = await recorder.endRecording().toImage(_size, _size);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final name = file.uri.pathSegments.last.replaceAll('.svg', '.png');
        File('${out.path}/$name').writeAsBytesSync(bytes!.buffer.asUint8List());
        info.picture.dispose();
      }
    });
  });
}
