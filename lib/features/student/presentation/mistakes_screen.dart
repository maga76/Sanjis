import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/answer_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/subject_style.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/question.dart';
import '../../../data/seed/default_subjects.dart';
import '../../../data/seed/demo_questions.dart';
import '../application/progress.dart';

/// Работа над ошибками: вопросы с неправильными ответами и тест по ним.
/// Правильно отвеченный в тесте вопрос уходит из списка.
class MistakesScreen extends ConsumerWidget {
  const MistakesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final questions = [
      for (final id in ref.watch(progressProvider).mistakeIds)
        ?demoQuestionsById[id],
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.workOnMistakes)),
      body: questions.isEmpty
          ? EmptyView(
              icon: Icons.emoji_events_rounded,
              message: l10n.noMistakesTitle,
              hint: l10n.noMistakesHint,
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.m),
              children: [
                Text(
                  l10n.questionsCount(questions.length),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.s),
                FilledButton.icon(
                  onPressed: () => context.push(Routes.testMistakes),
                  icon: const Icon(Icons.replay_rounded),
                  label: Text(l10n.startMistakesTest),
                ),
                const SizedBox(height: AppSpacing.m),
                for (final q in questions) _MistakeCard(question: q),
              ],
            ),
    );
  }
}

class _MistakeCard extends StatelessWidget {
  const _MistakeCard({required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final topic = demoTopicsById[question.topicId];
    final subject = defaultSubjects
        .where((s) => s.id == topic?.subjectId)
        .firstOrNull;
    final options = context.isTajik ? question.optionsTg : question.optionsRu;
    final color = subject == null
        ? Theme.of(context).colorScheme.primary
        : subjectColor(context, subject.color);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subject != null)
              Text(
                [
                  context.pickLang(subject.nameTg, subject.nameRu),
                  if (topic != null)
                    context.pickLang(topic.nameTg, topic.nameRu),
                ].join(' · '),
                style: textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.pickLang(question.textTg, question.textRu),
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: context.answerColors.correct,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    l10n.correctAnswerIs(options[question.correctIndex]),
                    style: textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
