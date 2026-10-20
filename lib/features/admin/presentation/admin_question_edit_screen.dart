import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/answer_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/validators.dart';
import '../../../data/content.dart';
import '../../../data/models/question.dart';
import '../../../data/seed/default_subjects.dart';

/// Создание и редактирование вопроса: предмет, тема, текст на двух языках,
/// 2–6 вариантов с правильным, объяснение.
class AdminQuestionEditScreen extends ConsumerStatefulWidget {
  const AdminQuestionEditScreen({super.key, this.questionId, this.topicId});

  /// `null` — новый вопрос.
  final String? questionId;

  /// Тема по умолчанию для нового вопроса.
  final String? topicId;

  @override
  ConsumerState<AdminQuestionEditScreen> createState() =>
      _AdminQuestionEditScreenState();
}

class _AdminQuestionEditScreenState
    extends ConsumerState<AdminQuestionEditScreen> {
  static const _minOptions = 2;
  static const _maxOptions = 6;

  final _formKey = GlobalKey<FormState>();
  late final Question? _original;
  late String _subjectId;
  String? _topicId;
  late final _textTg = TextEditingController(text: _original?.textTg);
  late final _textRu = TextEditingController(text: _original?.textRu);
  late final _explainTg = TextEditingController(text: _original?.explanationTg);
  late final _explainRu = TextEditingController(text: _original?.explanationRu);
  final _optionsTg = <TextEditingController>[];
  final _optionsRu = <TextEditingController>[];
  int _correct = 0;

  @override
  void initState() {
    super.initState();
    final content = ref.read(contentProvider);
    _original = content.questionsById[widget.questionId];
    final topic =
        content.topicsById[_original?.topicId ?? widget.topicId] ??
        content.topics.firstOrNull;
    _topicId = topic?.id;
    _subjectId = topic?.subjectId ?? defaultSubjects.first.id;

    final original = _original;
    if (original == null) {
      _addOption();
      _addOption();
      _addOption();
      _addOption();
    } else {
      for (var i = 0; i < original.optionCount; i++) {
        _optionsTg.add(TextEditingController(text: original.optionsTg[i]));
        _optionsRu.add(
          TextEditingController(
            // Совпадает с таджикским — значит, отдельного перевода нет
            text: original.optionsRu[i] == original.optionsTg[i]
                ? ''
                : original.optionsRu[i],
          ),
        );
      }
      _correct = original.correctIndex;
    }
  }

  void _addOption() {
    _optionsTg.add(TextEditingController());
    _optionsRu.add(TextEditingController());
  }

  void _removeOption(int i) => setState(() {
    _optionsTg.removeAt(i).dispose();
    _optionsRu.removeAt(i).dispose();
    if (_correct == i) {
      _correct = 0;
    } else if (_correct > i) {
      _correct--;
    }
  });

  @override
  void dispose() {
    for (final c in [
      _textTg,
      _textRu,
      _explainTg,
      _explainRu,
      ..._optionsTg,
      ..._optionsRu,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = context.l10n;
    String? orNull(String s) => s.trim().isEmpty ? null : s.trim();
    final optionsTg = [for (final c in _optionsTg) c.text.trim()];
    final question = Question(
      id: _original?.id ?? ContentController.newId('q'),
      topicId: _topicId!,
      textTg: _textTg.text.trim(),
      textRu: _textRu.text.trim(),
      optionsTg: optionsTg,
      optionsRu: [
        for (var i = 0; i < optionsTg.length; i++)
          orNull(_optionsRu[i].text) ?? optionsTg[i],
      ],
      correctIndex: _correct,
      explanationTg: orNull(_explainTg.text),
      explanationRu: orNull(_explainRu.text),
    );
    await ref.read(contentProvider.notifier).saveQuestion(question);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.saved)));
    context.pop();
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteQuestionConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref.read(contentProvider.notifier).deleteQuestion(_original!.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.deleted)));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final content = ref.watch(contentProvider);
    final topics = content.topicsOf(_subjectId);
    final subjects = [...defaultSubjects]
      ..sort((a, b) => a.order.compareTo(b.order));
    const gap = SizedBox(height: AppSpacing.m);

    return Scaffold(
      appBar: AppBar(
        title: Text(_original == null ? l10n.newQuestion : l10n.editQuestion),
        actions: [
          if (_original != null)
            IconButton(
              tooltip: l10n.delete,
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.m),
            children: [
              DropdownButtonFormField<String>(
                initialValue: _subjectId,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.subject),
                items: [
                  for (final s in subjects)
                    DropdownMenuItem(
                      value: s.id,
                      child: Text(context.pickLang(s.nameTg, s.nameRu)),
                    ),
                ],
                onChanged: (v) => setState(() {
                  _subjectId = v!;
                  _topicId = content.topicsOf(v).firstOrNull?.id;
                }),
              ),
              gap,
              DropdownButtonFormField<String>(
                // Ключ сбрасывает поле при смене предмета
                key: ValueKey(_subjectId),
                initialValue: _topicId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.topic,
                  helperText: topics.isEmpty ? l10n.noTopicsYet : null,
                ),
                items: [
                  for (final t in topics)
                    DropdownMenuItem(
                      value: t.id,
                      child: Text(
                        '${context.pickLang(t.nameTg, t.nameRu)} '
                        '(${t.minGrade}–${t.maxGrade})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) => setState(() => _topicId = v),
                validator: (v) => v == null ? l10n.fieldRequired : null,
              ),
              gap,
              TextFormField(
                controller: _textTg,
                maxLines: null,
                decoration: InputDecoration(labelText: l10n.questionTextTg),
                validator: (v) => Validators.required(v, l10n),
              ),
              gap,
              TextFormField(
                controller: _textRu,
                maxLines: null,
                decoration: InputDecoration(labelText: l10n.questionTextRu),
              ),
              const SizedBox(height: AppSpacing.l),
              Text(l10n.answerOptions, style: textTheme.titleMedium),
              Text(
                l10n.markCorrectHint,
                style: textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              for (var i = 0; i < _optionsTg.length; i++)
                _OptionEditor(
                  key: ObjectKey(_optionsTg[i]),
                  index: i,
                  tg: _optionsTg[i],
                  ru: _optionsRu[i],
                  correct: i == _correct,
                  onMarkCorrect: () => setState(() => _correct = i),
                  onRemove: _optionsTg.length > _minOptions
                      ? () => _removeOption(i)
                      : null,
                ),
              if (_optionsTg.length < _maxOptions)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(_addOption),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l10n.addOption),
                  ),
                ),
              const SizedBox(height: AppSpacing.m),
              TextFormField(
                controller: _explainTg,
                maxLines: null,
                decoration: InputDecoration(labelText: l10n.explanationTg),
              ),
              gap,
              TextFormField(
                controller: _explainRu,
                maxLines: null,
                decoration: InputDecoration(labelText: l10n.explanationRu),
              ),
              const SizedBox(height: AppSpacing.l),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_rounded),
                label: Text(l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionEditor extends StatelessWidget {
  const _OptionEditor({
    super.key,
    required this.index,
    required this.tg,
    required this.ru,
    required this.correct,
    required this.onMarkCorrect,
    required this.onRemove,
  });

  final int index;
  final TextEditingController tg;
  final TextEditingController ru;
  final bool correct;
  final VoidCallback onMarkCorrect;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.answerColors;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(
          color: correct ? colors.correct : scheme.outlineVariant,
          width: correct ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, AppSpacing.s),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              tooltip: l10n.markCorrect,
              onPressed: onMarkCorrect,
              icon: Icon(
                correct
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: correct ? colors.correct : scheme.onSurfaceVariant,
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  TextFormField(
                    controller: tg,
                    decoration: InputDecoration(
                      labelText: l10n.optionN(
                        String.fromCharCode(0x41 + index),
                      ),
                    ),
                    validator: (v) => Validators.required(v, l10n),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: ru,
                    decoration: InputDecoration(
                      labelText: l10n.optionRuHint,
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: l10n.delete,
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
