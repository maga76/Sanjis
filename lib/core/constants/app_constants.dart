/// Общие константы приложения.
class AppConstants {
  const AppConstants._();

  /// Классы фиксированы: 1–11, не редактируются.
  static const grades = <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];

  /// Минимальная длина пароля (требование Firebase Auth).
  static const minPasswordLength = 6;

  /// Во сколько раз увеличивается текст в режиме «крупный шрифт».
  static const largeFontFactor = 1.15;
}
