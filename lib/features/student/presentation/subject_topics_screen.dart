import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/subject_style.dart';
import '../../../core/widgets/notebook_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/content.dart';
import '../../../data/models/question.dart';
import '../../../data/models/subject.dart';
import '../../../data/seed/default_subjects.dart';
import '../application/grade_filter.dart';
import '../application/progress.dart';

/// Темы предмета для класса ученика. Шапка — лист «в клетку» цвета предмета,
/// у каждой темы — кольцо с лучшим результатом.
class SubjectTopicsScreen extends ConsumerWidget {
  const SubjectTopicsScreen({super.key, required this.subjectId});

  final String subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final grade = ref.watch(gradeFilterProvider);
    final progress = ref.watch(progressProvider);
    final subject = defaultSubjects.where((s) => s.id == subjectId).firstOrNull;
    final topics = ref.watch(contentProvider).topicsFor(subjectId, grade);
    final color = parseHexColor(subject?.color ?? '');
    final accent = subjectColor(context, subject?.color ?? '');
    final done = topics
        .where((t) => progress.bestPercentFor(t.id) != null)
        .length;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _Header(
              subject: subject,
              color: color,
              grade: grade,
              done: done,
              total: topics.length,
            ),
          ),
          if (topics.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyView(
                icon: Icons.menu_book_rounded,
                message: l10n.noTopicsForGrade,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.m,
                AppSpacing.l,
                AppSpacing.m,
                AppSpacing.m,
              ),
              sliver: SliverList.separated(
                itemCount: topics.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.s + 4),
                itemBuilder: (context, i) => _TopicCard(
                  topic: topics[i],
                  accent: accent,
                  best: progress.bestPercentFor(topics[i].id),
                  onTap: () => context.push(
                    Routes.testFor(
                      subjectId: subjectId,
                      topicId: topics[i].id,
                      grade: grade,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: topics.length > 1
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.m,
                  AppSpacing.s,
                  AppSpacing.m,
                  AppSpacing.m,
                ),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                  ),
                  onPressed: () => context.push(
                    Routes.testFor(subjectId: subjectId, grade: grade),
                  ),
                  icon: const Icon(Icons.shuffle_rounded),
                  label: Text(l10n.testAllTopics),
                ),
              ),
            )
          : null,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.subject,
    required this.color,
    required this.grade,
    required this.done,
    required this.total,
  });

  final Subject? subject;
  final Color color;
  final int grade;
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final subject = this.subject;
    return NotebookHeader(
      background: color,
      padding: const EdgeInsets.fromLTRB(4, 4, AppSpacing.m, AppSpacing.l),
      child: Stack(
        children: [
          // Крупная иконка предмета — как рисунок на обложке
          if (subject != null)
            Positioned(
              right: -8,
              bottom: -16,
              child: Icon(
                subjectIcon(subject.icon),
                size: 132,
                color: Colors.white.withValues(alpha: 0.13),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BackButton(color: Colors.white),
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject == null
                          ? l10n.topics
                          : context.pickLang(subject.nameTg, subject.nameRu),
                      style: textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.gradeN(grade),
                      style: textTheme.titleSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    if (total > 0) ...[
                      const SizedBox(height: AppSpacing.m),
                      Text(
                        l10n.topicsDone(done, total),
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: done / total,
                          minHeight: 6,
                          color: const Color(0xFFFFD25A),
                          backgroundColor: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Тема: кольцо с лучшим результатом (или значок «начать»),
/// название и сколько в теме вопросов.
class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.topic,
    required this.accent,
    required this.best,
    required this.onTap,
  });

  final Topic topic;
  final Color accent;
  final int? best;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final best = this.best;

    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 56,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: (best ?? 0) / 100,
                      strokeWidth: 5,
                      strokeCap: StrokeCap.round,
                      color: accent,
                      backgroundColor: accent.withValues(alpha: 0.16),
                    ),
                    Center(
                      child: best == null
                          ? Icon(Icons.play_arrow_rounded, color: accent)
                          : Text(
                              '$best%',
                              style: textTheme.labelLarge?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.pickLang(topic.nameTg, topic.nameRu),
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.questionsCount(topic.questions.length),
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
