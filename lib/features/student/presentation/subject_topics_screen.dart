import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/subject_style.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/question.dart';
import '../../../data/seed/default_subjects.dart';
import '../../../data/content.dart';
import '../application/progress.dart';

/// Темы предмета в классе и тест по всем темам сразу.
class SubjectTopicsScreen extends ConsumerWidget {
  const SubjectTopicsScreen({
    super.key,
    required this.subjectId,
    required this.grade,
  });

  final String subjectId;
  final int grade;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final progress = ref.watch(progressProvider);
    final subject = defaultSubjects.where((s) => s.id == subjectId).firstOrNull;
    final topics = ref.watch(contentProvider).topicsFor(subjectId, grade);
    final color = parseHexColor(subject?.color ?? '');
    final totalQuestions = topics.fold(0, (sum, t) => sum + t.questions.length);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subject == null
                  ? l10n.topics
                  : context.pickLang(subject.nameTg, subject.nameRu),
            ),
            Text(
              l10n.gradeN(grade),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
      body: topics.isEmpty
          ? EmptyView(
              icon: Icons.menu_book_rounded,
              message: l10n.noTopicsForGrade,
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.m),
              children: [
                if (topics.length > 1) ...[
                  _AllTopicsCard(
                    color: color,
                    questions: totalQuestions,
                    onTap: () => context.push(
                      Routes.testFor(subjectId: subjectId, grade: grade),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),
                ],
                Text(
                  l10n.topics,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.s),
                for (var i = 0; i < topics.length; i++) ...[
                  _TopicCard(
                    number: i + 1,
                    topic: topics[i],
                    color: subjectColor(context, subject?.color ?? ''),
                    bestPercent: progress.bestPercentFor(topics[i].id),
                    onTap: () => context.push(
                      Routes.testFor(
                        subjectId: subjectId,
                        topicId: topics[i].id,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s),
                ],
              ],
            ),
    );
  }
}

class _AllTopicsCard extends StatelessWidget {
  const _AllTopicsCard({
    required this.color,
    required this.questions,
    required this.onTap,
  });

  final Color color;
  final int questions;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(AppRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shuffle_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.allTopics,
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${l10n.allTopicsHint} · ${l10n.questionsCount(questions)}',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.play_circle_fill_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.number,
    required this.topic,
    required this.color,
    required this.bestPercent,
    required this.onTap,
  });

  final int number;
  final Topic topic;
  final Color color;
  final int? bestPercent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Text(
                  '$number',
                  style: textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
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
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.questionsCount(topic.questions.length),
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (bestPercent != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        l10n.bestResult(bestPercent!),
                        style: textTheme.bodySmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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
