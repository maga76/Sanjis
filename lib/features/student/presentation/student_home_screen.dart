import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/notebook_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/seed/default_subjects.dart';
import '../../auth/application/auth_service.dart';
import '../application/grade_filter.dart';
import 'widgets/subject_card.dart';

/// Главная ученика: приветствие, выбор класса, сетка предметов.
/// Пока предметы берутся из демо-списка; на этапе 4 — из Firestore.
/// Нажатие на предмет открывает его темы.
class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final grade = ref.watch(gradeFilterProvider);
    final subjects =
        defaultSubjects.where((s) => s.availableFor(grade)).toList()
          ..sort((a, b) => a.order.compareTo(b.order));

    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 600 ? 3 : 2;
    final scale = MediaQuery.textScalerOf(context).scale(1);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _HomeHeader(grade: grade)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.m,
              AppSpacing.l,
              AppSpacing.m,
              AppSpacing.s,
            ),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Text(
                    l10n.subjects,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ),
          if (subjects.isEmpty)
            const SliverFillRemaining(hasScrollBody: false, child: EmptyView())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.m,
                AppSpacing.s,
                AppSpacing.m,
                AppSpacing.l,
              ),
              sliver: SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  // Высота растёт вместе с размером шрифта
                  mainAxisExtent: 120 + 60 * scale,
                ),
                itemCount: subjects.length,
                itemBuilder: (context, i) => SubjectCard(
                  subject: subjects[i],
                  onTap: () => context.push(Routes.subject(subjects[i].id)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HomeHeader extends ConsumerWidget {
  const _HomeHeader({required this.grade});

  final int grade;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final name =
        ref.watch(authUserProvider).value?.displayName?.split(' ').first ??
        l10n.studentDefaultName;

    return NotebookHeader(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.m,
        AppSpacing.m,
        AppSpacing.m,
        AppSpacing.l,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.hello(name),
                      style: textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.homeSubtitle,
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white,
                child: Text(
                  name.characters.first.toUpperCase(),
                  style: textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          _GradePill(grade: grade),
        ],
      ),
    );
  }
}

/// Белая «таблетка» с текущим классом — открывает выбор класса.
class _GradePill extends ConsumerWidget {
  const _GradePill({required this.grade});

  final int grade;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _showGradePicker(context, ref, grade),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.school_rounded,
                size: 20,
                color: Color(0xFF1E5AA8),
              ),
              const SizedBox(width: AppSpacing.s),
              Text(
                context.l10n.gradeN(grade),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF1E5AA8),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Icon(Icons.expand_more_rounded, color: Color(0xFF1E5AA8)),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showGradePicker(
  BuildContext context,
  WidgetRef ref,
  int current,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final scheme = Theme.of(sheetContext).colorScheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.m,
            0,
            AppSpacing.m,
            AppSpacing.l,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sheetContext.l10n.chooseGrade,
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.m),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.3,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final g in AppConstants.grades)
                    Material(
                      color: g == current
                          ? scheme.primary
                          : scheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                        onTap: () {
                          ref.read(gradeFilterProvider.notifier).select(g);
                          Navigator.of(sheetContext).pop();
                        },
                        child: Center(
                          child: Text(
                            '$g',
                            style: Theme.of(sheetContext).textTheme.titleLarge
                                ?.copyWith(
                                  color: g == current
                                      ? scheme.onPrimary
                                      : scheme.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
