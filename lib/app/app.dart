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
      builder: (context, child) =>
          _TextScaleWrapper(largeFont: settings.largeFont, child: child!),
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
