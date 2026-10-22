import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/l10n/l10n.dart';
import 'router.dart';
import 'settings/app_settings.dart';
import 'theme/app_theme.dart';

/// Корневой виджет приложения.
class SanjishApp extends ConsumerWidget {
  const SanjishApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: kSupportedLocales,
      localizationsDelegates: kLocalizationsDelegates,
      routerConfig: router,
      builder: (context, child) => _PhoneFrame(
        child: _TextScaleWrapper(largeFont: settings.largeFont, child: child!),
      ),
    );
  }
}

/// Применяет режим «крупный шрифт» (+15%) поверх системного масштаба.
/// Системный масштаб ограничен, чтобы вёрстка не ломалась на огромных шрифтах.
class _TextScaleWrapper extends StatelessWidget {
  const _TextScaleWrapper({required this.largeFont, required this.child});

  final bool largeFont;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final system = mq.textScaler.clamp(maxScaleFactor: 1.3);
    final factor = largeFont ? AppConstants.largeFontFactor : 1.0;
    // scale(16)/16 — эффективный коэффициент системы для основного текста
    final scaler = TextScaler.linear(system.scale(16) / 16 * factor);
    return MediaQuery(
      data: mq.copyWith(textScaler: scaler),
      child: child,
    );
  }
}

/// На широком экране (браузер на компьютере) приложение показывается
/// «телефоном» по центру, а не растягивается на весь монитор.
class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.child});

  final Widget child;

  static const _width = 420.0;
  static const _maxHeight = 900.0;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    if (mq.size.width < 600) return child;

    final height = (mq.size.height - 48).clamp(560.0, _maxHeight);
    return ColoredBox(
      color: const Color(0xFF0F2A4D),
      child: Center(
        child: Container(
          width: _width,
          height: height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF2C4A75), width: 6),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 40,
                offset: Offset(0, 16),
              ),
            ],
          ),
          // Внутри всё считает, что экран — размером с телефон
          child: MediaQuery(
            data: mq.copyWith(
              size: Size(_width - 12, height - 12),
              padding: EdgeInsets.zero,
              viewPadding: EdgeInsets.zero,
              viewInsets: EdgeInsets.zero,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
