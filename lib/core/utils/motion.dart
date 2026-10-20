import 'package:flutter/widgets.dart';

/// Длительности анимаций приложения (короткие, 150–300 мс).
class AppDurations {
  const AppDurations._();

  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 300);
}

extension MotionContext on BuildContext {
  /// Включена ли системная настройка «уменьшить движение».
  bool get reduceMotion => MediaQuery.of(this).disableAnimations;

  /// Длительность с учётом «уменьшить движение» (тогда — без анимации).
  Duration motion(Duration d) => reduceMotion ? Duration.zero : d;
}
