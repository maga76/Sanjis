import 'package:flutter/material.dart';

/// Логотип Sanjish: синий «тетрадный» квадрат в клетку с золотой линией полей,
/// белая открытая книга и золотой значок с галочкой.
///
/// Рисуется векторно, поэтому один и тот же рисунок используется и в
/// приложении (`AppLogo`), и для иконки Android (`tool/generate_icons.dart`).
class SanjishLogoPainter extends CustomPainter {
  const SanjishLogoPainter({
    this.drawBackground = true,
    this.drawForeground = true,
    this.contentScale = 1,
    this.cornerRadius = 0.28,
    this.inset = 0,
  });

  final bool drawBackground;
  final bool drawForeground;

  /// Масштаб книги и значка относительно центра (для адаптивной иконки
  /// содержимое должно уместиться в безопасную зону).
  final double contentScale;

  /// Скругление фона в долях стороны; 0 — квадрат.
  final double cornerRadius;

  /// Отступ фона от краёв в долях стороны.
  final double inset;

  static const _blueLight = Color(0xFF3A7BD5);
  static const _blue = Color(0xFF1E5AA8);
  static const _blueDark = Color(0xFF143E78);
  static const _cover = Color(0xFF0E2F5C);
  static const _gold = Color(0xFFF2A900);
  static const _page = Color(0xFFFFFFFF);
  static const _pageShade = Color(0xFFE6EEF9);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // Дальше рисуем в единичном квадрате 1×1
    canvas.scale(size.width, size.height);
    if (drawBackground) _paintBackground(canvas);
    if (drawForeground) {
      canvas.save();
      canvas.translate(0.5, 0.5);
      canvas.scale(contentScale);
      canvas.translate(-0.5, -0.5);
      _paintBook(canvas);
      _paintBadge(canvas);
      canvas.restore();
    }
    canvas.restore();
  }

  void _paintBackground(Canvas canvas) {
    final rect = Rect.fromLTWH(inset, inset, 1 - 2 * inset, 1 - 2 * inset);
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(cornerRadius * rect.width),
    );
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_blueLight, _blue, _blueDark],
          stops: [0, 0.55, 1],
        ).createShader(rect),
    );

    // Клетка тетради
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 0.004;
    const step = 1 / 12;
    for (var v = step; v < 1; v += step) {
      canvas.drawLine(Offset(v, 0), Offset(v, 1), grid);
      canvas.drawLine(Offset(0, v), Offset(1, v), grid);
    }

    // Золотая линия полей
    canvas.drawLine(
      const Offset(0.86, 0),
      const Offset(0.86, 1),
      Paint()
        ..color = _gold.withValues(alpha: 0.55)
        ..strokeWidth = 0.009,
    );
    canvas.restore();
  }

  void _paintBook(Canvas canvas) {
    // Мягкая тень под книгой
    canvas.drawOval(
      const Rect.fromLTRB(0.2, 0.74, 0.8, 0.84),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.02),
    );

    // Обложка, выглядывающая из-под страниц
    final cover = Path()
      ..moveTo(0.5, 0.45)
      ..quadraticBezierTo(0.35, 0.39, 0.17, 0.42)
      ..lineTo(0.17, 0.76)
      ..quadraticBezierTo(0.35, 0.73, 0.5, 0.80)
      ..quadraticBezierTo(0.65, 0.73, 0.83, 0.76)
      ..lineTo(0.83, 0.42)
      ..quadraticBezierTo(0.65, 0.39, 0.5, 0.45)
      ..close();
    canvas.drawPath(cover, Paint()..color = _cover);

    Path page(double outerX) {
      final ctrlX = 0.5 + (outerX - 0.5) * 0.48;
      return Path()
        ..moveTo(0.5, 0.40)
        ..quadraticBezierTo(ctrlX, 0.32, outerX, 0.36)
        ..lineTo(outerX, 0.71)
        ..quadraticBezierTo(ctrlX, 0.67, 0.5, 0.75)
        ..close();
    }

    canvas.drawPath(page(0.21), Paint()..color = _page);
    canvas.drawPath(page(0.79), Paint()..color = _pageShade);

    // Корешок
    canvas.drawLine(
      const Offset(0.5, 0.40),
      const Offset(0.5, 0.75),
      Paint()
        ..color = _blue.withValues(alpha: 0.35)
        ..strokeWidth = 0.008,
    );

    // Строчки текста на страницах
    final lines = Paint()
      ..color = _blue.withValues(alpha: 0.38)
      ..strokeWidth = 0.018
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final y in [0.46, 0.53, 0.60]) {
      for (final (from, to) in [(0.27, 0.44), (0.56, 0.73)]) {
        // Строчка выгнута, как и верхний край страницы
        canvas.drawPath(
          Path()
            ..moveTo(from, y)
            ..quadraticBezierTo((from + to) / 2, y - 0.02, to, y),
          lines,
        );
      }
    }
  }

  void _paintBadge(Canvas canvas) {
    const center = Offset(0.72, 0.29);
    const radius = 0.125;
    canvas.drawCircle(
      center + const Offset(0, 0.012),
      radius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.012),
    );
    canvas.drawCircle(center, radius, Paint()..color = Colors.white);
    canvas.drawCircle(center, radius - 0.02, Paint()..color = _gold);
    canvas.drawPath(
      Path()
        ..moveTo(0.665, 0.292)
        ..lineTo(0.705, 0.332)
        ..lineTo(0.78, 0.252),
      Paint()
        ..color = _blueDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.034
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(SanjishLogoPainter old) =>
      old.drawBackground != drawBackground ||
      old.drawForeground != drawForeground ||
      old.contentScale != contentScale ||
      old.cornerRadius != cornerRadius ||
      old.inset != inset;
}
