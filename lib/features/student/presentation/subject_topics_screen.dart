import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/answer_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/subject_style.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/content.dart';
import '../../../data/models/attempt.dart';
import '../../../data/models/question.dart';
import '../../../data/seed/default_subjects.dart';
import '../application/grade_filter.dart';
import '../application/progress.dart';

/// Темы предмета для класса ученика — как оглавление в тетради:
/// обложка цвета предмета, страница в линейку с красной линией полей.
class SubjectTopicsScreen extends ConsumerWidget {
  const SubjectTopicsScreen({super.key, required this.subjectId});

  final String subjectId;

  /// Высота строки = шаг линовки.
  static const _rowHeight = 64.0;

  /// Ширина полей слева, где стоят номера тем.
  static const _margin = 56.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final grade = ref.watch(gradeFilterProvider);
    final progress = ref.watch(progressProvider);
    final subject = defaultSubjects.where((s) => s.id == subjectId).firstOrNull;
    final topics = ref.watch(contentProvider).topicsFor(subjectId, grade);
    final cover = parseHexColor(subject?.color ?? '');
    final ink = subjectColor(context, subject?.color ?? '');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rule = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : const Color(0xFFD5E1EF);
    final marginLine = const Color(
      0xFFE05A5A,
    ).withValues(alpha: isDark ? 0.55 : 0.8);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Cover(
            color: cover,
            title: subject == null
                ? l10n.topics
                : context.pickLang(subject.nameTg, subject.nameRu),
            subtitle: l10n.gradeN(grade),
          ),
          Expanded(
            child: topics.isEmpty
                ? EmptyView(
                    icon: Icons.menu_book_rounded,
                    message: l10n.noTopicsForGrade,
                  )
                : Stack(
                    children: [
                      // Линия полей через всю страницу
                      Positioned(
                        left: _margin,
                        top: 0,
                        bottom: 0,
                        child: Container(width: 1.5, color: marginLine),
                      ),
                      ListView(
                        padding: const EdgeInsets.only(top: AppSpacing.s),
                        children: [
                          for (final (i, topic) in topics.indexed)
                            _TopicLine(
                              number: i + 1,
                              topic: topic,
                              ink: ink,
                              rule: rule,
                              best: progress.bestPercentFor(topic.id),
                              onTap: () => context.push(
                                Routes.testFor(
                                  subjectId: subjectId,
                                  topicId: topic.id,
                                  grade: grade,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
          ),
          if (topics.length > 1)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.m,
                  AppSpacing.s,
                  AppSpacing.m,
                  AppSpacing.m,
                ),
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: cover,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: () => context.push(
                    Routes.testFor(subjectId: subjectId, grade: grade),
                  ),
                  child: Text(l10n.testAllTopics),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Обложка тетради: цвет предмета, корешок снизу, название крупно.
class _Cover extends StatelessWidget {
  const _Cover({
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          border: Border(
            bottom: BorderSide(
              color: Color.lerp(color, Colors.black, 0.3)!,
              width: 6,
            ),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, AppSpacing.m, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BackButton(color: Colors.white),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: textTheme.titleSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
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

/// Строка оглавления: номер на полях, название темы, справа —
/// лучший результат или сколько в теме вопросов.
class _TopicLine extends StatelessWidget {
  const _TopicLine({
    required this.number,
    required this.topic,
    required this.ink,
    required this.rule,
    required this.best,
    required this.onTap,
  });

  final int number;
  final Topic topic;
  final Color ink;
  final Color rule;
  final int? best;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.answerColors;
    final best = this.best;
    final scoreColor = switch (best == null ? null : Attempt.markFor(best)) {
      5 => colors.correct,
      2 => colors.wrong,
      _ => scheme.onSurface,
    };

    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(
          minHeight: SubjectTopicsScreen._rowHeight,
        ),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: rule)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: SubjectTopicsScreen._margin,
              child: Text(
                '$number',
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  color: ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  context.pickLang(topic.nameTg, topic.nameRu),
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            Text(
              best == null
                  ? l10n.questionsCount(topic.questions.length)
                  : '$best%',
              style: best == null
                  ? textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    )
                  : textTheme.titleMedium?.copyWith(
                      color: scoreColor,
                      fontWeight: FontWeight.w800,
                    ),
            ),
            const SizedBox(width: AppSpacing.m),
          ],
        ),
      ),
    );
  }
}
