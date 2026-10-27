// Картинка со всеми обложками предметов — проверить рисунки на глаз.
// Запуск: flutter test tool/preview_subjects.dart → build/subjects_preview.png

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanjish/app/theme/app_theme.dart';
import 'package:sanjish/core/l10n/l10n.dart';
import 'package:sanjish/data/seed/default_subjects.dart';
import 'package:sanjish/features/student/presentation/widgets/subject_card.dart';

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(
      Future.value(ByteData.sublistView(File(f).readAsBytesSync())),
    );
  }
  await loader.load();
}

void main() {
  testWidgets('Обложки предметов', (tester) async {
    // FLUTTER_ROOT задаёт flutter test
    final flutterRoot = Platform.environment['FLUTTER_ROOT']!;
    await tester.runAsync(() async {
      await _loadFont('NotoSans', [
        for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold'])
          'assets/fonts/NotoSans-$w.ttf',
      ]);
      await _loadFont('MaterialIcons', [
        '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ]);
    });

    tester.view.physicalSize = const Size(1080, 4500);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        locale: kTajik,
        supportedLocales: kSupportedLocales,
        localizationsDelegates: kLocalizationsDelegates,
        home: RepaintBoundary(
          key: key,
          child: Scaffold(
            body: GridView.count(
              padding: const EdgeInsets.all(12),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.95,
              children: [
                for (final s in defaultSubjects)
                  SubjectCard(subject: s, onTap: () {}),
              ],
            ),
          ),
        ),
      ),
    );
    // Картинки декодируются асинхронно
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 2)),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('build/subjects_preview.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });
}
