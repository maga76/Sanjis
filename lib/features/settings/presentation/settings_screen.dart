import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../app/routes.dart';
import '../../../app/settings/app_settings.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/l10n/l10n.dart';
import '../../auth/application/auth_service.dart';

/// Версия приложения из сборки (pubspec.yaml → version).
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version} (${info.buildNumber})';
});

/// Настройки: язык, тема, размер шрифта, выход, версия.
/// Используется и учеником (отдельный экран), и админом (вкладка).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, this.embedded = false});

  /// true — экран встроен во вкладку админа (без кнопки «назад»).
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final version = switch (ref.watch(appVersionProvider)) {
      AsyncData(:final value) => value,
      _ => '—',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        automaticallyImplyLeading: !embedded,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.m),
        children: [
          _SectionTitle(l10n.language),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: kTajik.languageCode,
                label: Text(l10n.langTajik),
              ),
              ButtonSegment(
                value: kRussian.languageCode,
                label: Text(l10n.langRussian),
              ),
            ],
            selected: {settings.locale.languageCode},
            onSelectionChanged: (s) =>
                controller.setLocale(s.first == 'ru' ? kRussian : kTajik),
          ),
          const SizedBox(height: AppSpacing.l),
          _SectionTitle(l10n.theme),
          // Три варианта темы — списком, чтобы длинные подписи
          // помещались на узких экранах
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final (mode, icon, label) in [
                  (ThemeMode.light, Icons.light_mode_outlined, l10n.themeLight),
                  (ThemeMode.dark, Icons.dark_mode_outlined, l10n.themeDark),
                  (
                    ThemeMode.system,
                    Icons.brightness_auto_outlined,
                    l10n.themeSystem,
                  ),
                ])
                  ListTile(
                    leading: Icon(icon),
                    title: Text(label),
                    selected: settings.themeMode == mode,
                    trailing: settings.themeMode == mode
                        ? const Icon(Icons.check_rounded)
                        : null,
                    onTap: () => controller.setThemeMode(mode),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          _SectionTitle(l10n.fontSize),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: false, label: Text(l10n.fontNormal)),
              ButtonSegment(value: true, label: Text(l10n.fontLarge)),
            ],
            selected: {settings.largeFont},
            onSelectionChanged: (s) => controller.setLargeFont(s.first),
          ),
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go(Routes.login);
            },
            icon: const Icon(Icons.logout_rounded),
            label: Text(l10n.logout),
          ),
          const SizedBox(height: AppSpacing.l),
          Center(
            child: Text(
              '${l10n.appVersion}: $version',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.s),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );
}
