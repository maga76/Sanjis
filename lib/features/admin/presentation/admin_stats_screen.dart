import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/answer_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/regions.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/content.dart';
import '../application/admin_stats.dart';

/// Статистика (админ): ученики, тесты, средний результат,
/// ученики по классам и регионам, самые сложные вопросы.
class AdminStatsScreen extends ConsumerWidget {
  const AdminStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final stats = ref.watch(adminStatsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.statistics)),
      body: switch (stats) {
        AsyncData(:final value) => RefreshIndicator(
          onRefresh: () => ref.refresh(adminStatsProvider.future),
          child: _StatsBody(data: value),
        ),
        AsyncError() => ErrorView(
          message: l10n.errNetwork,
          onRetry: () => ref.invalidate(adminStatsProvider),
        ),
        _ => const LoadingSkeleton(),
      },
    );
  }
}

class _StatsBody extends ConsumerWidget {
  const _StatsBody({required this.data});

  final AdminStatsData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final content = ref.watch(contentProvider);
    final students = data.students;
    final attempts = data.attempts;
    final answers = attempts.fold(0, (n, a) => n + a.total);
    final correct = attempts.fold(0, (n, a) => n + a.correct);
    final average = answers == 0 ? 0 : (correct * 100 / answers).round();

    final byGrade = <int, int>{};
    final byRegion = <Region?, int>{};
    for (final s in students) {
      if (s.grade != null) byGrade[s.grade!] = (byGrade[s.grade!] ?? 0) + 1;
      final region = Region.fromCode(s.region);
      byRegion[region] = (byRegion[region] ?? 0) + 1;
    }

    final hardest =
        [
          for (final MapEntry(key: id, value: (asked, wrong))
              in data.questionStats.entries)
            if (wrong > 0 && content.questionsById.containsKey(id))
              (content.questionsById[id]!, asked, wrong),
        ]..sort((a, b) {
          final byRate = (b.$3 / b.$2).compareTo(a.$3 / a.$2);
          return byRate != 0 ? byRate : b.$3.compareTo(a.$3);
        });

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.m),
      children: [
        Row(
          children: [
            _Tile(
              icon: Icons.people_alt_rounded,
              value: '${students.length}',
              label: l10n.statStudents,
            ),
            const SizedBox(width: AppSpacing.s),
            _Tile(
              icon: Icons.assignment_turned_in_rounded,
              value: '${attempts.length}',
              label: l10n.statTests,
            ),
            const SizedBox(width: AppSpacing.s),
            _Tile(
              icon: Icons.track_changes_rounded,
              value: '$average%',
              label: l10n.statAvgScore,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.l),
        _Section(
          title: l10n.statByGrade,
          empty: byGrade.isEmpty,
          children: [
            for (final g in AppConstants.grades)
              if (byGrade[g] case final count?)
                _BarRow(
                  label: l10n.gradeN(g),
                  count: count,
                  max: byGrade.values.reduce((a, b) => a > b ? a : b),
                ),
          ],
        ),
        _Section(
          title: l10n.statByRegion,
          empty: byRegion.isEmpty,
          children: [
            for (final MapEntry(key: region, value: count) in byRegion.entries)
              _BarRow(
                label: region?.label(l10n) ?? l10n.regionUnknown,
                count: count,
                max: byRegion.values.reduce((a, b) => a > b ? a : b),
              ),
          ],
        ),
        _Section(
          title: l10n.statHardest,
          empty: hardest.isEmpty,
          children: [
            for (final (question, asked, wrong) in hardest.take(10))
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(
                  Icons.error_outline_rounded,
                  color: context.answerColors.wrong,
                ),
                title: Text(context.pickLang(question.textTg, question.textRu)),
                subtitle: Text(
                  l10n.wrongRate((wrong * 100 / asked).round(), asked),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: scheme.primary),
              const SizedBox(height: AppSpacing.s),
              Text(
                value,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.empty,
    required this.children,
  });

  final String title;
  final bool empty;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.s),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: empty
                  ? SizedBox(
                      height: 160,
                      child: EmptyView(
                        icon: Icons.insights_rounded,
                        message: context.l10n.noDataYet,
                      ),
                    )
                  : Column(children: children),
            ),
          ),
        ],
      ),
    );
  }
}

/// Строка с полоской: подпись, полоса по доле от максимума, число.
class _BarRow extends StatelessWidget {
  const _BarRow({required this.label, required this.count, required this.max});

  final String label;
  final int count;
  final int max;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: count / max,
                minHeight: 10,
                backgroundColor: scheme.primary.withValues(alpha: 0.1),
              ),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              '$count',
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
