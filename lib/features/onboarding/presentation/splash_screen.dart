import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/settings/app_settings.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/notebook_header.dart';
import '../../auth/application/auth_service.dart';

/// Заставка: логотип на синем фоне, загрузка языка, затем переход дальше.
/// На этапе 2 здесь добавится проверка входа и роли (ученик / админ).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _goNext();
  }

  Future<void> _goNext() async {
    // Короткая пауза, чтобы логотип не «мигал»
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    final languageChosen = ref.read(settingsProvider).languageChosen;
    final signedIn = ref.read(authServiceProvider).currentUser != null;
    context.go(
      !languageChosen
          ? Routes.language
          : signedIn
          ? Routes.studentHome
          : Routes.login,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: NotebookHeader.color(context),
        // Весь экран — синий лист тетради «в клетку»
        body: NotebookPaper(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 3),
              // Логотип и тексты — по центру
              const Center(child: AppLogo(size: 120, onDark: true)),
              const SizedBox(height: AppSpacing.l),
              Text(
                l10n.appName,
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                l10n.appTagline,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const Spacer(flex: 3),
              const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
