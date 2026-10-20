import 'package:flutter/material.dart';

import 'flag_stripe.dart';
import 'logo_painter.dart';

/// Логотип Sanjish (рисунок — [SanjishLogoPainter], как у иконки приложения)
/// и маленькая трёхцветная полоска снизу.
/// [onDark] — белая обводка и тень, чтобы логотип читался на синей шапке.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 96, this.onDark = false});

  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.28);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          // Обводка поверх рисунка, чтобы не уменьшать его
          foregroundDecoration: onDark
              ? BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(color: Colors.white, width: size * 0.035),
                )
              : null,
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0B2A52).withValues(alpha: 0.3),
                blurRadius: size * 0.2,
                offset: Offset(0, size * 0.08),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: const CustomPaint(
              painter: SanjishLogoPainter(cornerRadius: 0),
            ),
          ),
        ),
        SizedBox(height: size * 0.12),
        FlagStripe(width: size * 0.5, height: size * 0.06),
      ],
    );
  }
}
