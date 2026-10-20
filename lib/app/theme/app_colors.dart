import 'package:flutter/material.dart';

/// Палитра приложения (раздел 8.2 ТЗ).
/// Основной цвет — синий: зелёный и красный зарезервированы
/// для подсветки правильного и неправильного ответа.
class AppColors {
  const AppColors._();

  // Светлая тема
  static const primaryLight = Color(0xFF1E5AA8);
  static const secondaryLight = Color(0xFFF2A900);
  static const backgroundLight = Color(0xFFF6F8FB);
  static const cardLight = Color(0xFFFFFFFF);
  static const textLight = Color(0xFF1A1D21);
  static const textSecondaryLight = Color(0xFF5F6B7A);

  // Тёмная тема
  static const primaryDark = Color(0xFF7FB2FF);
  static const secondaryDark = Color(0xFFFFC94D);
  static const backgroundDark = Color(0xFF101418);
  static const cardDark = Color(0xFF1B2127);
  static const textDark = Color(0xFFE8EAED);
  static const textSecondaryDark = Color(0xFF9AA4B0);

  // Подсветка ответов
  static const correctBgLight = Color(0xFFE6F6EA);
  static const correctLight = Color(0xFF1E9E4A);
  static const wrongBgLight = Color(0xFFFDECEC);
  static const wrongLight = Color(0xFFD93025);

  static const correctBgDark = Color(0xFF16351F);
  static const correctDark = Color(0xFF4CD07D);
  static const wrongBgDark = Color(0xFF3A1A1A);
  static const wrongDark = Color(0xFFFF6B60);

  // Флаг Таджикистана — только как акцент
  static const flagRed = Color(0xFFCC0000);
  static const flagWhite = Color(0xFFFFFFFF);
  static const flagGreen = Color(0xFF006600);
}
