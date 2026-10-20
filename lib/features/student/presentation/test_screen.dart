import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/answer_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/attempt.dart';
import '../../../data/models/question.dart';
import '../../../data/seed/default_subjects.dart';
import '../../../data/content.dart';
import '../application/grade_filter.dart';
import '../application/progress.dart';

/// Предмет попытки для теста по ошибкам (вопросы из разных предметов).
const kMistakesSubjectId = 'mistakes';

/// Сколько вопросов в тесте по всем темам и по ошибкам.
const _maxQuestions = 10;

/// Тест: вопрос → выбор ответа → подсветка и объяснение → «Далее».
/// В конце — результат с оценкой 2–5, попытка сохраняется.
class TestScreen extends ConsumerStatefulWidget {
  const TestScreen({
    super.key,
    this.subjectId,
    this.topicId,
    this.grade,
    this.mistakes = false,
  });

  final String? subjectId;
  final String? topicId;

  /// Класс для теста по всем темам; по умолчанию — выбранный на главной.
  final int? grade;
  final bool mistakes;

  @override
  ConsumerState<TestScreen> createState() => _TestScreenState();
}

/// Вопрос с перемешанными вариантами: [order] — индексы исходных вариантов.
class _Item {
  _Item(this.question, Random random)
    : order = List.generate(question.optionCount, (i) => i)..shuffle(random);

  final Question question;
  final List<int> order;
}

class _TestScreenState extends ConsumerState<TestScreen> {
  final _random = Random();
  late List<Question> _questions;
  late List<_Item> _items;
  var _index = 0;

  /// Выбранный вариант (позиция на экране) для текущего вопроса.
  int? _selected;
  final _answers = <String, bool>{};
  Attempt? _result;

  @override
  void initState() {
    super.initState();
    _questions = _pickQuestions();
    _shuffle();
  }

  List<Question> _pickQuestions() {
    if (widget.mistakes) {
      final ids = ref.read(progressProvider).mistakeIds;
      return [
        for (final id in ids) ?ref.read(contentProvider).questionsById[id],
      ].take(_maxQuestions).toList();
    }
    final content = ref.read(contentProvider);
    final topic = content.topicsById[widget.topicId];
    if (topic != null) return topic.questions;

    final int grade = widget.grade ?? ref.read(gradeFilterProvider);
    final all = [
      for (final t in content.topicsFor(widget.subjectId ?? '', grade))
        ...t.questions,
    ]..shuffle(_random);
    return all.take(_maxQuestions).toList();
  }

  void _shuffle() {
    _items = [for (final q in _questions) _Item(q, _random)]..shuffle(_random);
    _index = 0;
    _selected = null;
    _answers.clear();
    _result = null;
  }

  String get _subjectId => widget.mistakes
      ? kMistakesSubjectId
      : widget.subjectId ??
            ref.read(contentProvider).topicsById[widget.topicId]?.subjectId ??
            '';

  String _title(BuildContext context) {
    final l10n = context.l10n;
    if (widget.mistakes) return l10n.workOnMistakes;
    if (ref.read(contentProvider).topicsById[widget.topicId]
        case final topic?) {
      return context.pickLang(topic.nameTg, topic.nameRu);
    }
    final subject = defaultSubjects
        .where((s) => s.id == widget.subjectId)
        .firstOrNull;
    return subject == null
        ? l10n.allTopics
        : context.pickLang(subject.nameTg, subject.nameRu);
  }

  void _select(int position) {
    if (_selected != null) return;
    final item = _items[_index];
    setState(() {
      _selected = position;
      _answers[item.question.id] =
          item.order[position] == item.question.correctIndex;
    });
  }

  Future<void> _next() async {
    if (_index < _items.length - 1) {
      setState(() {
        _index++;
        _selected = null;
      });
      return;
    }
    final answers = Map.of(_answers);
    setState(() {
      _result = Attempt(
        subjectId: _subjectId,
        topicId: widget.topicId,
        correct: answers.values.where((ok) => ok).length,
        total: answers.length,
        finishedAt: DateTime.now(),
      );
    });
    await ref
        .read(progressProvider.notifier)
        .recordTest(
          subjectId: _subjectId,
          topicId: widget.topicId,
          answers: answers,
        );
  }

  Future<void> _confirmExit() async {
    final l10n = context.l10n;
    final exit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.exitTestTitle),
        content: Text(l10n.exitTestBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.exitTest),
          ),
        ],
      ),
    );
    if (exit == true && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(_title(context))),
        body: const EmptyView(icon: Icons.quiz_outlined),
      );
    }
    if (_result case final result?) {
      return _ResultView(
        title: _title(context),
        result: result,
        onRetry: () => setState(_shuffle),
      );
    }

    // Без подтверждения можно выйти, пока нет ни одного ответа
    final started = _answers.isNotEmpty;
    return PopScope(
      canPop: !started,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: _QuestionView(
        title: _title(context),
        item: _items[_index],
        index: _index,
        total: _items.length,
        selected: _selected,
        onSelect: _select,
        onNext: _next,
        onClose: started ? _confirmExit : () => context.pop(),
      ),
    );
  }
}

class _QuestionView extends StatelessWidget {
  const _QuestionView({
    required this.title,
    required this.item,
    required this.index,
    required this.total,
    required this.selected,
    required this.onSelect,
    required this.onNext,
    required this.onClose,
  });

  final String title;
  final _Item item;
  final int index;
  final int total;
  final int? selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onNext;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final question = item.question;
    final options = context.isTajik ? question.optionsTg : question.optionsRu;
    final answered = selected != null;
    final isCorrect =
        answered && item.order[selected!] == question.correctIndex;
    final isLast = index == total - 1;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          icon: const Icon(Icons.close_rounded),
          onPressed: onClose,
        ),
        title: Text(title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (index + (answered ? 1 : 0)) / total,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.m),
                children: [
                  Text(
                    l10n.questionOf(index + 1, total),
                    style: textTheme.labelLarge?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    context.pickLang(question.textTg, question.textRu),
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),
                  for (var pos = 0; pos < item.order.length; pos++) ...[
                    _OptionTile(
                      letter: String.fromCharCode(0x41 + pos),
                      text: options[item.order[pos]],
                      state: !answered
                          ? _OptionState.idle
                          : item.order[pos] == question.correctIndex
                          ? _OptionState.correct
                          : pos == selected
                          ? _OptionState.wrong
                          : _OptionState.dimmed,
                      onTap: answered ? null : () => onSelect(pos),
                    ),
                    const SizedBox(height: AppSpacing.s),
                  ],
                  if (answered) ...[
                    const SizedBox(height: AppSpacing.s),
                    _Feedback(
                      correct: isCorrect,
                      correctAnswer: options[question.correctIndex],
                      explanation: context.pickLang(
                        question.explanationTg,
                        question.explanationRu,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.m,
                0,
                AppSpacing.m,
                AppSpacing.m,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: answered ? onNext : null,
                  child: Text(isLast ? l10n.result : l10n.next),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _OptionState { idle, correct, wrong, dimmed }

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.letter,
    required this.text,
    required this.state,
    required this.onTap,
  });

  final String letter;
  final String text;
  final _OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.answerColors;
    final (background, border, icon) = switch (state) {
      _OptionState.idle => (
        scheme.surfaceContainerLow,
        scheme.outlineVariant,
        null,
      ),
      _OptionState.correct => (
        colors.correctBackground,
        colors.correct,
        Icons.check_circle_rounded,
      ),
      _OptionState.wrong => (
        colors.wrongBackground,
        colors.wrong,
        Icons.cancel_rounded,
      ),
      _OptionState.dimmed => (
        scheme.surfaceContainerLow,
        scheme.outlineVariant.withValues(alpha: 0.5),
        null,
      ),
    };
    final textColor = state == _OptionState.dimmed
        ? scheme.onSurface.withValues(alpha: 0.5)
        : scheme.onSurface;

    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.option),
        side: BorderSide(color: border, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: border.withValues(alpha: 0.2),
                  child: Text(
                    letter,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (icon != null) Icon(icon, color: border),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback({
    required this.correct,
    required this.correctAnswer,
    required this.explanation,
  });

  final bool correct;
  final String correctAnswer;
  final String explanation;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.answerColors;
    final textTheme = Theme.of(context).textTheme;
    final accent = correct ? colors.correct : colors.wrong;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: correct ? colors.correctBackground : colors.wrongBackground,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: accent,
              ),
              const SizedBox(width: AppSpacing.s),
              Text(
                correct ? l10n.correct : l10n.wrong,
                style: textTheme.titleMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (!correct) ...[
            const SizedBox(height: AppSpacing.s),
            Text(
              l10n.correctAnswerIs(correctAnswer),
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (explanation.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s),
            Text(
              '${l10n.explanation}: $explanation',
              style: textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.title,
    required this.result,
    required this.onRetry,
  });

  final String title;
  final Attempt result;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final colors = context.answerColors;
    final scheme = Theme.of(context).colorScheme;
    final mark = result.mark;
    final accent = switch (mark) {
      5 => colors.correct,
      4 => scheme.primary,
      3 => const Color(0xFFE09B00),
      _ => colors.wrong,
    };
    final message = switch (mark) {
      5 => l10n.markMessage5,
      4 => l10n.markMessage4,
      3 => l10n.markMessage3,
      _ => l10n.markMessage2,
    };

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: Text(title)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.result, style: textTheme.titleLarge),
                const SizedBox(height: AppSpacing.l),
                SizedBox(
                  width: 160,
                  height: 160,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: result.percent / 100,
                        strokeWidth: 12,
                        color: accent,
                        backgroundColor: accent.withValues(alpha: 0.15),
                      ),
                      Center(
                        child: Text(
                          '${result.percent}%',
                          style: textTheme.displaySmall?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.l),
                Text(
                  l10n.markN(mark),
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.scoreOf(result.correct, result.total),
                  style: textTheme.titleMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.replay_rounded),
                    label: Text(l10n.tryAgain),
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.go(Routes.studentHome),
                    child: Text(l10n.toHome),
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
