import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Цвета подсветки ответов как расширение темы:
/// `Theme.of(context).extension<AnswerColors>()!`.
@immutable
class AnswerColors extends ThemeExtension<AnswerColors> {
  const AnswerColors({
    required this.correctBackground,
    required this.correct,
    required this.wrongBackground,
    required this.wrong,
  });

  /// Фон карточки правильного ответа.
  final Color correctBackground;

  /// Рамка и иконка правильного ответа.
  final Color correct;

  /// Фон карточки неправильного ответа.
  final Color wrongBackground;

  /// Рамка и иконка неправильного ответа.
  final Color wrong;

  static const light = AnswerColors(
    correctBackground: AppColors.correctBgLight,
    correct: AppColors.correctLight,
    wrongBackground: AppColors.wrongBgLight,
    wrong: AppColors.wrongLight,
  );

  static const dark = AnswerColors(
    correctBackground: AppColors.correctBgDark,
    correct: AppColors.correctDark,
    wrongBackground: AppColors.wrongBgDark,
    wrong: AppColors.wrongDark,
  );

  @override
  AnswerColors copyWith({
    Color? correctBackground,
    Color? correct,
    Color? wrongBackground,
    Color? wrong,
  }) => AnswerColors(
    correctBackground: correctBackground ?? this.correctBackground,
    correct: correct ?? this.correct,
    wrongBackground: wrongBackground ?? this.wrongBackground,
    wrong: wrong ?? this.wrong,
  );

  @override
  AnswerColors lerp(ThemeExtension<AnswerColors>? other, double t) {
    if (other is! AnswerColors) return this;
    return AnswerColors(
      correctBackground: Color.lerp(
        correctBackground,
        other.correctBackground,
        t,
      )!,
      correct: Color.lerp(correct, other.correct, t)!,
      wrongBackground: Color.lerp(wrongBackground, other.wrongBackground, t)!,
      wrong: Color.lerp(wrong, other.wrong, t)!,
    );
  }
}

extension AnswerColorsContext on BuildContext {
  AnswerColors get answerColors =>
      Theme.of(this).extension<AnswerColors>() ?? AnswerColors.light;
}
