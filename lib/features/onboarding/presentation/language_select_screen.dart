import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/settings/app_settings.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/motion.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/notebook_header.dart';

/// Выбор языка при первом запуске. Показывается один раз.
/// Нажатие на язык сразу переключает интерфейс.
class LanguageSelectScreen extends ConsumerWidget {
  const LanguageSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final selected = ref.watch(settingsProvider.select((s) => s.locale));
    final controller = ref.read(settingsProvider.notifier);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NotebookHeader(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.l,
              AppSpacing.xl,
              AppSpacing.l,
              AppSpacing.xl,
            ),
            child: Column(
              children: [
                const AppLogo(size: 96, onDark: true),
                const SizedBox(height: AppSpacing.m),
                Text(
                  l10n.appName,
                  style: textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.appTagline,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.l),
              children: [
                Text(l10n.chooseLanguage, style: textTheme.titleLarge),
                const SizedBox(height: AppSpacing.m),
                _LanguageCard(
                  flag: '🇹🇯',
                  label: l10n.langTajik,
                  selected: selected.languageCode == kTajik.languageCode,
                  onTap: () => controller.setLocale(kTajik),
                ),
                const SizedBox(height: 12),
                _LanguageCard(
                  flag: '🇷🇺',
                  label: l10n.langRussian,
                  selected: selected.languageCode == kRussian.languageCode,
                  onTap: () => controller.setLocale(kRussian),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.l,
                0,
                AppSpacing.l,
                AppSpacing.m,
              ),
              child: FilledButton.icon(
                onPressed: () async {
                  await controller.markLanguageChosen();
                  if (context.mounted) context.go(Routes.login);
                },
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(l10n.continueButton),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Большая карточка-кнопка с названием языка.
class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.flag,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String flag;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? scheme.primary.withValues(alpha: 0.10)
            : scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: onTap,
          child: AnimatedContainer(
            duration: context.motion(AppDurations.fast),
            height: 76,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: selected
                    ? scheme.primary
                    : scheme.onSurfaceVariant.withValues(alpha: 0.2),
                width: selected ? 2.5 : 1.5,
              ),
            ),
            child: Row(
              children: [
                Text(flag, style: const TextStyle(fontSize: 30)),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: context.motion(AppDurations.fast),
                  child: selected
                      ? Icon(
                          Icons.check_circle_rounded,
                          key: const ValueKey(true),
                          color: scheme.primary,
                          size: 30,
                        )
                      : Icon(
                          Icons.circle_outlined,
                          key: const ValueKey(false),
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                          size: 30,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
