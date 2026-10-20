import 'package:flutter/material.dart';

import 'answer_colors.dart';
import 'app_colors.dart';

/// Размеры элементов (раздел 8.4 ТЗ).
class AppRadius {
  const AppRadius._();

  static const card = 16.0;
  static const button = 14.0;
  static const option = 14.0;
}

/// Сетка отступов — кратно 8.
class AppSpacing {
  const AppSpacing._();

  static const xs = 4.0;
  static const s = 8.0;
  static const m = 16.0;
  static const l = 24.0;
  static const xl = 32.0;
}

/// Специальные стили текста, которых нет в стандартной TextTheme.
class AppTextStyles {
  const AppTextStyles._();

  /// Текст вопроса — 20.
  static const question = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  /// Текст варианта ответа — 17.
  static const option = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );
}

class AppTheme {
  const AppTheme._();

  static const fontFamily = 'NotoSans';
  static const minButtonHeight = 52.0;

  static ThemeData light() => _build(
    brightness: Brightness.light,
    primary: AppColors.primaryLight,
    secondary: AppColors.secondaryLight,
    background: AppColors.backgroundLight,
    card: AppColors.cardLight,
    text: AppColors.textLight,
    textSecondary: AppColors.textSecondaryLight,
    answers: AnswerColors.light,
  );

  static ThemeData dark() => _build(
    brightness: Brightness.dark,
    primary: AppColors.primaryDark,
    secondary: AppColors.secondaryDark,
    background: AppColors.backgroundDark,
    card: AppColors.cardDark,
    text: AppColors.textDark,
    textSecondary: AppColors.textSecondaryDark,
    answers: AnswerColors.dark,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color primary,
    required Color secondary,
    required Color background,
    required Color card,
    required Color text,
    required Color textSecondary,
    required AnswerColors answers,
  }) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      primary: primary,
      onPrimary: isDark ? const Color(0xFF0B2A52) : Colors.white,
      secondary: secondary,
      onSecondary: const Color(0xFF2B1D00),
      surface: card,
      onSurface: text,
      onSurfaceVariant: textSecondary,
      error: answers.wrong,
    );

    final baseText = ThemeData(brightness: brightness).textTheme;
    final textTheme = baseText
        .copyWith(
          headlineSmall: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
          titleLarge: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          titleSmall: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: const TextStyle(fontSize: 16),
          bodyMedium: const TextStyle(fontSize: 16),
          bodySmall: const TextStyle(fontSize: 13),
          labelLarge: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          labelMedium: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          labelSmall: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        )
        .apply(fontFamily: fontFamily, bodyColor: text, displayColor: text);

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.button),
    );
    const buttonPadding = EdgeInsets.symmetric(horizontal: 24, vertical: 14);
    const buttonMinSize = Size(64, minButtonHeight);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: fontFamily,
      textTheme: textTheme,
      scaffoldBackgroundColor: background,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      extensions: [answers],
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: textSecondary.withValues(alpha: 0.15)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonMinSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: buttonMinSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonMinSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
          side: BorderSide(color: primary, width: 1.5),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: BorderSide(color: textSecondary.withValues(alpha: 0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: BorderSide(color: textSecondary.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        indicatorColor: primary.withValues(alpha: isDark ? 0.25 : 0.12),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        labelStyle: textTheme.labelLarge,
      ),
      dividerTheme: DividerThemeData(
        color: textSecondary.withValues(alpha: 0.2),
        space: 1,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
