import 'package:flutter/material.dart';

/// Иконки, доступные для предметов. Имя хранится в Firestore (`subjects.icon`).
/// Список фиксированный — так иконки не вырезаются при сборке release.
const subjectIcons = <String, IconData>{
  'calculate': Icons.calculate_rounded,
  'functions': Icons.functions_rounded,
  'square_foot': Icons.square_foot_rounded,
  'menu_book': Icons.menu_book_rounded,
  'auto_stories': Icons.auto_stories_rounded,
  'spellcheck': Icons.spellcheck_rounded,
  'translate': Icons.translate_rounded,
  'account_balance': Icons.account_balance_rounded,
  'public': Icons.public_rounded,
  'map': Icons.map_rounded,
  'eco': Icons.eco_rounded,
  'bolt': Icons.bolt_rounded,
  'science': Icons.science_rounded,
  'computer': Icons.computer_rounded,
  'park': Icons.park_rounded,
  'school': Icons.school_rounded,
  'palette': Icons.palette_rounded,
  'music_note': Icons.music_note_rounded,
  'sports_soccer': Icons.sports_soccer_rounded,
  'psychology': Icons.psychology_rounded,
};

IconData subjectIcon(String name) => subjectIcons[name] ?? Icons.school_rounded;

/// `#RRGGBB` → Color. При ошибке — основной синий.
Color parseHexColor(String hex) {
  final value = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
  return value == null ? const Color(0xFF1E5AA8) : Color(0xFF000000 | value);
}

/// Цвет предмета с поправкой на тёмную тему (светлее, чтобы был контраст).
Color subjectColor(BuildContext context, String hex) {
  final color = parseHexColor(hex);
  return Theme.of(context).brightness == Brightness.dark
      ? Color.lerp(color, Colors.white, 0.35)!
      : color;
}
