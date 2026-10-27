import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Рисунки «мелом» на обложке предмета: формулы, буквы, даты, фигуры —
/// у каждого предмета свои. Рисуются бледно-белым под названием и иконкой.
class SubjectDoodles extends CustomPainter {
  const SubjectDoodles(this.subjectId);

  final String subjectId;

  /// Места для рисунков в долях обложки: свободная часть над наклейкой
  /// с названием, не заходя под иконку справа вверху.
  static const _slots = [
    Offset(0.26, 0.12),
    Offset(0.57, 0.12),
    Offset(0.26, 0.34),
    Offset(0.57, 0.34),
    Offset(0.84, 0.38),
  ];

  static const _doodles = <String, List<_Doodle>>{
    'math': [
      _Doodle.text('π', 28, -0.15),
      _Doodle.text('7+5', 15, 0.1),
      _Doodle.text('÷', 24),
      _Doodle.text('3/4', 15, -0.1),
      _Doodle.text('×', 20, 0.2),
    ],
    'algebra': [
      _Doodle.text('x²', 24, -0.1),
      _Doodle.text('y=kx', 14, 0.08),
      _Doodle.text('(a+b)²', 13, -0.06),
      _Doodle.text('2x=8', 14, 0.1),
      _Doodle.text('x', 20),
    ],
    'geometry': [
      _Doodle.shape(_Shape.triangle, 0.2, -0.1),
      _Doodle.text('90°', 15, 0.1),
      _Doodle.shape(_Shape.circle, 0.17),
      _Doodle.text('πr²', 15, -0.08),
      _Doodle.shape(_Shape.angle, 0.13),
    ],
    'tajik_lang': [
      _Doodle.text('Ғғ', 22, -0.12),
      _Doodle.text('Ҷҷ', 22, 0.1),
      _Doodle.text('Ӯӯ', 20, 0.06),
      _Doodle.text('Ққ', 20, -0.08),
      _Doodle.text('Ҳ', 18),
    ],
    'tajik_lit': [
      _Doodle.text('байт', 15, -0.1),
      _Doodle.shape(_Shape.feather, 0.2, 0.3),
      _Doodle.text('ғазал', 13, 0.08),
      _Doodle.text('рубоӣ', 13, -0.06),
      _Doodle.text('«»', 18),
    ],
    'russian': [
      _Doodle.text('Аа', 22, -0.12),
      _Doodle.text('Бб', 22, 0.1),
      _Doodle.text('Ёё', 20, 0.06),
      _Doodle.text('Жж', 20, -0.08),
      _Doodle.text('Ы', 18),
    ],
    'english': [
      _Doodle.text('ABC', 18, -0.1),
      _Doodle.text('Hello', 14, 0.08),
      _Doodle.text('a b c', 13, 0.05),
      _Doodle.text('is', 16, -0.1),
      _Doodle.text('?', 20),
    ],
    'history': [
      _Doodle.text('874', 16, -0.1),
      _Doodle.shape(_Shape.column, 0.16),
      _Doodle.text('IX–X', 14, 0.06),
      _Doodle.text('1991', 15, -0.06),
      _Doodle.text('988', 14, 0.08),
    ],
    'world_history': [
      _Doodle.text('476', 16, -0.1),
      _Doodle.text('1492', 15, 0.08),
      _Doodle.shape(_Shape.column, 0.16),
      _Doodle.text('1945', 15, -0.06),
      _Doodle.text('XV', 16),
    ],
    'geography': [
      _Doodle.shape(_Shape.globe, 0.22),
      _Doodle.text('38°', 15, 0.1),
      _Doodle.text('N', 18, -0.1),
      _Doodle.shape(_Shape.wave, 0.22),
      _Doodle.shape(_Shape.mountain, 0.14),
    ],
    'biology': [
      _Doodle.shape(_Shape.leaf, 0.2, -0.4),
      _Doodle.shape(_Shape.helix, 0.22, 0.3),
      _Doodle.text('ДНК', 14, -0.06),
      _Doodle.shape(_Shape.cell, 0.16),
      _Doodle.shape(_Shape.leaf, 0.12, 0.6),
    ],
    'physics': [
      _Doodle.shape(_Shape.atom, 0.24),
      _Doodle.text('E=mc²', 14, 0.08),
      _Doodle.text('F=ma', 14, -0.08),
      _Doodle.text('v=s/t', 13, 0.06),
      _Doodle.shape(_Shape.wave, 0.14),
    ],
    'chemistry': [
      _Doodle.shape(_Shape.hexagon, 0.2),
      _Doodle.text('H₂O', 16, 0.08),
      _Doodle.text('CO₂', 15, -0.08),
      _Doodle.text('NaCl', 14, 0.06),
      _Doodle.text('O₂', 15),
    ],
    'informatics': [
      _Doodle.text('</>', 18, -0.08),
      _Doodle.text('0101', 14, 0.08),
      _Doodle.text('{ }', 18, 0.06),
      _Doodle.text('if', 15, -0.1),
      _Doodle.text('1', 16),
    ],
    'nature': [
      _Doodle.shape(_Shape.sun, 0.2),
      _Doodle.shape(_Shape.leaf, 0.18, 0.5),
      _Doodle.shape(_Shape.wave, 0.22),
      _Doodle.text('°C', 15, 0.08),
      _Doodle.shape(_Shape.mountain, 0.14),
    ],
  };

  @override
  void paint(Canvas canvas, Size size) {
    final doodles = _doodles[subjectId];
    if (doodles == null) return;
    const color = Color(0x33FFFFFF);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final (i, d) in doodles.indexed) {
      if (i >= _slots.length) break;
      final center = Offset(
        _slots[i].dx * size.width,
        _slots[i].dy * size.height,
      );
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(d.angle);
      if (d.text != null) {
        final tp = TextPainter(
          text: TextSpan(
            text: d.text,
            style: TextStyle(
              // Шрифт приложения: в нём есть таджикские буквы, π, ², ₂
              fontFamily: 'NotoSans',
              color: color,
              fontSize: d.size,
              fontWeight: FontWeight.w700,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      } else {
        _drawShape(canvas, d.shape!, d.size * size.width, stroke);
      }
      canvas.restore();
    }
  }

  static void _drawShape(Canvas canvas, _Shape shape, double s, Paint p) {
    final h = s / 2;
    switch (shape) {
      case _Shape.triangle:
        canvas.drawPath(
          Path()
            ..moveTo(-h, h * 0.8)
            ..lineTo(h, h * 0.8)
            ..lineTo(-h * 0.2, -h * 0.9)
            ..close(),
          p,
        );
      case _Shape.circle:
        canvas.drawCircle(Offset.zero, h, p);
        canvas.drawLine(Offset.zero, Offset(h, 0), p);
      case _Shape.angle:
        canvas.drawLine(Offset(-h, h), Offset(h, h), p);
        canvas.drawLine(Offset(-h, h), Offset(-h, -h), p);
        canvas.drawRect(Rect.fromLTWH(-h, h - s * 0.25, s * 0.25, s * 0.25), p);
      case _Shape.feather:
        canvas.drawPath(
          Path()
            ..moveTo(0, h)
            ..quadraticBezierTo(-h * 0.7, 0, 0, -h)
            ..quadraticBezierTo(h * 0.7, 0, 0, h)
            ..moveTo(0, h * 1.2)
            ..lineTo(0, -h * 0.6),
          p,
        );
      case _Shape.column:
        canvas.drawLine(Offset(-h, -h), Offset(h, -h), p);
        canvas.drawLine(Offset(-h, h), Offset(h, h), p);
        for (final x in [-h * 0.55, 0.0, h * 0.55]) {
          canvas.drawLine(Offset(x, -h * 0.8), Offset(x, h * 0.8), p);
        }
      case _Shape.globe:
        canvas.drawCircle(Offset.zero, h, p);
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: s * 0.45, height: s),
          p,
        );
        canvas.drawLine(Offset(-h, 0), Offset(h, 0), p);
      case _Shape.wave:
        final path = Path()..moveTo(-h, 0);
        for (var x = -h; x <= h; x += 1) {
          path.lineTo(x, math.sin(x / h * math.pi * 2) * s * 0.12);
        }
        canvas.drawPath(path, p);
      case _Shape.mountain:
        canvas.drawPath(
          Path()
            ..moveTo(-h, h * 0.6)
            ..lineTo(-h * 0.2, -h * 0.6)
            ..lineTo(h * 0.2, 0)
            ..lineTo(h * 0.5, -h * 0.3)
            ..lineTo(h, h * 0.6),
          p,
        );
      case _Shape.leaf:
        canvas.drawPath(
          Path()
            ..moveTo(-h, 0)
            ..quadraticBezierTo(0, -h * 0.9, h, 0)
            ..quadraticBezierTo(0, h * 0.9, -h, 0)
            ..lineTo(h, 0),
          p,
        );
      case _Shape.helix:
        for (final phase in [0.0, math.pi]) {
          final path = Path();
          for (var y = -h; y <= h; y += 1) {
            final x = math.sin(y / h * math.pi * 1.5 + phase) * s * 0.18;
            y == -h ? path.moveTo(x, y) : path.lineTo(x, y);
          }
          canvas.drawPath(path, p);
        }
      case _Shape.cell:
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: s, height: s * 0.7),
          p,
        );
        canvas.drawCircle(Offset(s * 0.1, 0), s * 0.12, p);
      case _Shape.atom:
        for (final a in [0.0, math.pi / 3, -math.pi / 3]) {
          canvas.save();
          canvas.rotate(a);
          canvas.drawOval(
            Rect.fromCenter(center: Offset.zero, width: s, height: s * 0.35),
            p,
          );
          canvas.restore();
        }
        canvas.drawCircle(Offset.zero, s * 0.05, p..style = PaintingStyle.fill);
        p.style = PaintingStyle.stroke;
      case _Shape.hexagon:
        final path = Path();
        for (var i = 0; i < 6; i++) {
          final a = math.pi / 3 * i + math.pi / 6;
          final pt = Offset(math.cos(a) * h, math.sin(a) * h);
          i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
        }
        path.close();
        canvas.drawPath(path, p);
        canvas.drawCircle(Offset.zero, h * 0.5, p);
      case _Shape.sun:
        canvas.drawCircle(Offset.zero, h * 0.45, p);
        for (var i = 0; i < 8; i++) {
          final a = math.pi / 4 * i;
          canvas.drawLine(
            Offset(math.cos(a) * h * 0.65, math.sin(a) * h * 0.65),
            Offset(math.cos(a) * h, math.sin(a) * h),
            p,
          );
        }
    }
  }

  @override
  bool shouldRepaint(SubjectDoodles old) => old.subjectId != subjectId;
}

enum _Shape {
  triangle,
  circle,
  angle,
  feather,
  column,
  globe,
  wave,
  mountain,
  leaf,
  helix,
  cell,
  atom,
  hexagon,
  sun,
}

/// Надпись ([text], размер шрифта [size]) или фигура ([shape],
/// размер в долях ширины обложки [size]), повёрнутая на [angle] радиан.
class _Doodle {
  const _Doodle.text(String this.text, this.size, [this.angle = 0])
    : shape = null;
  const _Doodle.shape(_Shape this.shape, this.size, [this.angle = 0])
    : text = null;

  final String? text;
  final _Shape? shape;
  final double size;
  final double angle;
}
