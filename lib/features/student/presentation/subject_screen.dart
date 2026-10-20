import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/subject_style.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/subject.dart';
import '../../../data/seed/default_subjects.dart';
import '../../../data/content.dart';
import '../application/grade_filter.dart';

/// Предмет: выбор класса. Дальше — темы этого класса и тест.
class SubjectScreen extends ConsumerWidget {
  const SubjectScreen({super.key, required this.subjectId});

  final String subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final subject = defaultSubjects.where((s) => s.id == subjectId).firstOrNull;
    if (subject == null) {
      return Scaffold(appBar: AppBar(), body: const EmptyView());
    }
    // Класс, выбранный на главной, подсвечивается
    final current = ref.watch(gradeFilterProvider);
    final color = parseHexColor(subject.color);
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.pickLang(subject.nameTg, subject.nameRu)),
            Text(
              l10n.gradeRange(subject.minGrade, subject.maxGrade),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.m,
              AppSpacing.m,
              AppSpacing.m,
              AppSpacing.s,
            ),
            sliver: SliverToBoxAdapter(
              child: Text(
                l10n.chooseGrade,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.m,
              AppSpacing.s,
              AppSpacing.m,
              AppSpacing.l,
            ),
            sliver: SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: width >= 600 ? 3 : 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 120 * MediaQuery.textScalerOf(context).scale(1),
              ),
              itemCount: subject.grades.length,
              itemBuilder: (context, i) {
                final grade = subject.grades[i];
                return _GradeCard(
                  subject: subject,
                  grade: grade,
                  selected: grade == current,
                  onTap: () =>
                      context.push(Routes.subjectGrade(subject.id, grade)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeCard extends ConsumerWidget {
  const _GradeCard({
    required this.subject,
    required this.grade,
    required this.selected,
    required this.onTap,
  });

  final Subject subject;
  final int grade;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final color = subjectColor(context, subject.color);
    final topics = ref.watch(contentProvider).topicsFor(subject.id, grade);
    final questions = topics.fold(0, (sum, t) => sum + t.questions.length);

    return Material(
      color: selected
          ? color.withValues(alpha: 0.14)
          : scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(
          color: selected ? color : scheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: color,
                child: Text(
                  '$grade',
                  style: textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.gradeN(grade),
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.topicsCount(topics.length),
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      l10n.questionsCount(questions),
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
