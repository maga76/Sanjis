import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/subject_style.dart';
import '../../../data/seed/default_subjects.dart';
import '../../../data/seed/demo_questions.dart';

/// Предметы и темы (админ): демо-список. Редактирование — на этапе 3.
class AdminSubjectsScreen extends StatelessWidget {
  const AdminSubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final subjects = [...defaultSubjects]
      ..sort((a, b) => a.order.compareTo(b.order));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.subjects)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.m),
        children: [
          for (final subject in subjects)
            Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.s),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: parseHexColor(subject.color),
                          child: Icon(
                            subjectIcon(subject.icon),
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.pickLang(
                                  subject.nameTg,
                                  subject.nameRu,
                                ),
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                l10n.gradeRange(
                                  subject.minGrade,
                                  subject.maxGrade,
                                ),
                                style: textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s),
                    for (final topic in demoTopics.where(
                      (t) => t.subjectId == subject.id,
                    ))
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Row(
                          children: [
                            Icon(
                              Icons.topic_outlined,
                              size: 18,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: AppSpacing.s),
                            Expanded(
                              child: Text(
                                context.pickLang(topic.nameTg, topic.nameRu),
                              ),
                            ),
                            Text(
                              '${topic.minGrade}–${topic.maxGrade} · '
                              '${topic.questions.length}',
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
        ],
      ),
    );
  }
}
