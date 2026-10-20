import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Тонкая трёхцветная полоска цветов флага Таджикистана (только акцент).
class FlagStripe extends StatelessWidget {
  const FlagStripe({super.key, this.height = 4, this.width, this.radius = 2});

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        height: height,
        width: width,
        child: Column(
          children: [
            const Expanded(child: ColoredBox(color: AppColors.flagRed)),
            Expanded(
              child: ColoredBox(
                // На тёмном фоне белая полоса чуть приглушена
                color: isDark ? const Color(0xFFDADDE1) : AppColors.flagWhite,
              ),
            ),
            const Expanded(child: ColoredBox(color: AppColors.flagGreen)),
          ],
        ),
      ),
    );
  }
}
