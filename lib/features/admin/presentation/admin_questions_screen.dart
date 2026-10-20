import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/answer_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/subject_style.dart';
import '../../../data/content.dart';
import '../../../data/models/question.dart';
import '../../../data/seed/default_subjects.dart';

/// Вопросы (админ): по предметам и темам. Нажатие — редактирование,
/// «+» — новый вопрос.
class AdminQuestionsScreen extends ConsumerWidget {
  const AdminQuestionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final content = ref.watch(contentProvider);
    final subjects = [...defaultSubjects]
      ..sort((a, b) => a.order.compareTo(b.order));

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.questions} · ${content.questionsById.length}'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.m,
          AppSpacing.s,
          AppSpacing.m,
          88,
        ),
        children: [
          for (final subject in subjects) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                4,
                AppSpacing.m,
                4,
                AppSpacing.s,
              ),
              child: Row(
                children: [
                  Icon(
                    subjectIcon(subject.icon),
                    color: subjectColor(context, subject.color),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: Text(
                      context.pickLang(subject.nameTg, subject.nameRu),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            for (final topic in content.topicsOf(subject.id))
              _TopicQuestions(
                topic: topic,
                color: subjectColor(context, subject.color),
              ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.adminQuestion()),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.newQuestion),
      ),
    );
  }
}

/// Тема, раскрывающаяся в список вопросов с правильными ответами.
class _TopicQuestions extends StatelessWidget {
  const _TopicQuestions({required this.topic, required this.color});

  final Topic topic;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        title: Text(
          context.pickLang(topic.nameTg, topic.nameRu),
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${l10n.gradeRange(topic.minGrade, topic.maxGrade)} · '
          '${l10n.questionsCount(topic.questions.length)}',
        ),
        children: [
          for (final (i, q) in topic.questions.indexed)
            ListTile(
              dense: true,
              onTap: () => context.push(Routes.adminQuestion(id: q.id)),
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Text(
                  '${i + 1}',
                  style: textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              title: Text(context.pickLang(q.textTg, q.textRu)),
              subtitle: Text(
                l10n.correctAnswerIs(
                  (context.isTajik ? q.optionsTg : q.optionsRu)[q.correctIndex],
                ),
                style: textTheme.bodySmall?.copyWith(
                  color: context.answerColors.correct,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: const Icon(Icons.edit_outlined, size: 18),
            ),
          ListTile(
            dense: true,
            leading: Icon(Icons.add_circle_outline_rounded, color: color),
            title: Text(l10n.newQuestion),
            onTap: () => context.push(Routes.adminQuestion(topicId: topic.id)),
          ),
        ],
      ),
    );
  }
}
