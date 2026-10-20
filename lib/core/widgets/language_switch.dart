import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/settings/app_settings.dart';
import '../l10n/l10n.dart';
import '../utils/motion.dart';

/// Компактный переключатель языка «ТҶ | РУ».
/// [onDark] — вариант для синей шапки (белые цвета).
class LanguageSwitch extends ConsumerWidget {
  const LanguageSwitch({super.key, this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(settingsProvider.select((s) => s.locale));
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final track = onDark
        ? Colors.white.withValues(alpha: 0.16)
        : scheme.primary.withValues(alpha: 0.08);

    Widget option(Locale value, String label) {
      final selected = locale.languageCode == value.languageCode;
      final fg = selected
          ? (onDark ? const Color(0xFF1E5AA8) : scheme.onPrimary)
          : (onDark ? Colors.white : scheme.primary);
      return Semantics(
        selected: selected,
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => ref.read(settingsProvider.notifier).setLocale(value),
          child: AnimatedContainer(
            duration: context.motion(AppDurations.fast),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 40),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: selected
                  ? (onDark ? Colors.white : scheme.primary)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: fg,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: track,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          option(kTajik, l10n.langTgShort),
          option(kRussian, l10n.langRuShort),
        ],
      ),
    );
  }
}
