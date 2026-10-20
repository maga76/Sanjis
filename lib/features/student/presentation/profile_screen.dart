import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/subject_style.dart';
import '../../../core/widgets/flag_stripe.dart';
import '../../../core/widgets/notebook_header.dart';
import '../../../data/models/attempt.dart';
import '../../../data/seed/default_subjects.dart';
import '../../../data/seed/demo_questions.dart';
import '../application/grade_filter.dart';
import '../application/progress.dart';
import 'widgets/header_stat.dart';

/// Профиль ученика. Имя пока заглушка (появится на этапе 2),
/// статистика и последние результаты — из локально сохранённых тестов.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final name = l10n.studentDefaultName;
    final grade = ref.watch(gradeFilterProvider);
    final progress = ref.watch(progressProvider);
    final lastAttempts = progress.attempts.take(10).toList();

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          NotebookHeader(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.m,
              AppSpacing.s,
              AppSpacing.m,
              AppSpacing.l,
            ),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: l10n.settings,
                    onPressed: () => context.push(Routes.settings),
                    icon: const Icon(
                      Icons.settings_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 42,
                    backgroundColor: scheme.secondary,
                    child: Text(
                      name.characters.first.toUpperCase(),
                      style: textTheme.headlineSmall?.copyWith(
                        color: const Color(0xFF2B1D00),
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                Text(
                  name,
                  style: textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.gradeN(grade),
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                const FlagStripe(width: 56, height: 6, radius: 3),
                const SizedBox(height: AppSpacing.l),
                Row(
                  children: [
                    Expanded(
                      child: HeaderStat(
                        icon: Icons.assignment_turned_in_rounded,
                        value: '${progress.testsCount}',
                        label: l10n.statTests,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Expanded(
                      child: HeaderStat(
                        icon: Icons.question_answer_rounded,
                        value: '${progress.answersCount}',
                        label: l10n.statAnswers,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Expanded(
                      child: HeaderStat(
                        icon: Icons.track_changes_rounded,
                        value: '${progress.accuracy}%',
                        label: l10n.statAccuracy,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.lastResults, style: textTheme.titleLarge),
                const SizedBox(height: AppSpacing.s),
                if (lastAttempts.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.l),
                      child: Column(
                        children: [
                          Icon(
                            Icons.insights_rounded,
                            size: 48,
                            color: scheme.primary.withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: AppSpacing.s),
                          Text(
                            l10n.noResultsYet,
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  for (final attempt in lastAttempts)
                    _AttemptTile(attempt: attempt),
                const SizedBox(height: AppSpacing.m),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    leading: Icon(
                      Icons.settings_rounded,
                      color: scheme.primary,
                    ),
                    title: Text(l10n.settings),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(Routes.settings),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Строка последнего результата: оценка, предмет, тема, дата и процент.
class _AttemptTile extends StatelessWidget {
  const _AttemptTile({required this.attempt});

  final Attempt attempt;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final subject = defaultSubjects
        .where((s) => s.id == attempt.subjectId)
        .firstOrNull;
    final topic = demoTopicsById[attempt.topicId];
    final color = subject == null
        ? scheme.primary
        : subjectColor(context, subject.color);
    final title = subject == null
        ? l10n.workOnMistakes
        : context.pickLang(subject.nameTg, subject.nameRu);
    final topicName = topic == null
        ? (subject == null ? null : l10n.allTopics)
        : context.pickLang(topic.nameTg, topic.nameRu);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(
            '${attempt.mark}',
            style: textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          [
            ?topicName,
            DateFormatter.date(attempt.finishedAt, l10n),
          ].join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${attempt.percent}%',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              l10n.scoreOf(attempt.correct, attempt.total),
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
