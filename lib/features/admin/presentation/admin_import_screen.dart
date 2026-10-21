import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/answer_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/l10n/l10n.dart';
import '../../../data/content.dart';
import '../../../data/seed/default_subjects.dart';
import '../application/question_import.dart';

/// Импорт вопросов из готового текста: вставили тест — приложение нашло
/// вопросы и правильные ответы, перевело на русский, админ проверил
/// и добавил в тему.
class AdminImportScreen extends ConsumerStatefulWidget {
  const AdminImportScreen({super.key});

  @override
  ConsumerState<AdminImportScreen> createState() => _AdminImportScreenState();
}

class _AdminImportScreenState extends ConsumerState<AdminImportScreen> {
  final _text = TextEditingController();
  late String _subjectId;
  String? _topicId;
  bool _busy = false;

  /// Найденные вопросы; правильный ответ можно поправить нажатием.
  List<ImportedQuestion>? _found;
  final _selected = <int>{};
  ImportMode? _mode;

  @override
  void initState() {
    super.initState();
    final first = ref.read(contentProvider).topics.firstOrNull;
    _subjectId = first?.subjectId ?? defaultSubjects.first.id;
    _topicId = first?.id;
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) return;
    setState(() {
      _text.text = text;
      _found = null;
    });
  }

  Future<void> _find() async {
    if (_text.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    final result = await ref.read(questionImportProvider).parse(_text.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _found = result.questions;
      _mode = result.mode;
      _selected
        ..clear()
        ..addAll([
          for (final (i, q) in result.questions.indexed)
            if (q.isValid) i,
        ]);
    });
  }

  void _markCorrect(int index, int option) => setState(() {
    final q = _found![index];
    _found![index] = ImportedQuestion(
      textTg: q.textTg,
      textRu: q.textRu,
      optionsTg: q.optionsTg,
      optionsRu: q.optionsRu,
      correctIndex: option,
      explanationTg: q.explanationTg,
      explanationRu: q.explanationRu,
    );
    _selected.add(index);
  });

  Future<void> _add() async {
    final topicId = _topicId;
    final found = _found;
    if (topicId == null || found == null) return;
    final l10n = context.l10n;
    final questions = [
      for (final i in _selected.toList()..sort())
        if (found[i].isValid) found[i].toQuestion(topicId),
    ];
    await ref.read(contentProvider.notifier).saveQuestions(questions);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(l10n.importDone(questions.length))),
      );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final content = ref.watch(contentProvider);
    final topics = content.topicsOf(_subjectId);
    final subjects = [...defaultSubjects]
      ..sort((a, b) => a.order.compareTo(b.order));
    final useAi = ref.watch(questionImportProvider).useAi;
    final found = _found;
    final count = found == null
        ? 0
        : _selected.where((i) => found[i].isValid).length;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.importQuestions)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.m,
          AppSpacing.s,
          AppSpacing.m,
          AppSpacing.xl,
        ),
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
          const SizedBox(height: AppSpacing.m),
          DropdownButtonFormField<String>(
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
          ),
          const SizedBox(height: AppSpacing.l),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.importPasteLabel,
                  style: textTheme.titleMedium,
                ),
              ),
              TextButton.icon(
                onPressed: _paste,
                icon: const Icon(Icons.content_paste_rounded, size: 18),
                label: Text(l10n.pasteFromClipboard),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _text,
            minLines: 8,
            maxLines: 16,
            keyboardType: TextInputType.multiline,
            onChanged: (_) {
              if (_found != null) setState(() => _found = null);
            },
            decoration: InputDecoration(
              hintText: l10n.importExample,
              hintMaxLines: 8,
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            l10n.importTip,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          FilledButton.icon(
            onPressed: _busy ? null : _find,
            icon: _busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(useAi ? Icons.translate_rounded : Icons.search_rounded),
            label: Text(
              _busy
                  ? l10n.importWorking
                  : useAi
                  ? l10n.findAndTranslate
                  : l10n.findQuestions,
            ),
          ),
          if (found != null) ...[
            const SizedBox(height: AppSpacing.l),
            if (found.isEmpty)
              Text(l10n.importNoneFound, style: textTheme.bodyLarge)
            else ...[
              Text(l10n.importFound(found.length), style: textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                _mode == ImportMode.ai
                    ? l10n.importTranslated
                    : l10n.importNoAi,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              for (final (i, q) in found.indexed)
                _PreviewCard(
                  number: i + 1,
                  question: q,
                  selected: _selected.contains(i),
                  onSelected: (v) => setState(
                    () => v ? _selected.add(i) : _selected.remove(i),
                  ),
                  onMarkCorrect: (option) => _markCorrect(i, option),
                ),
            ],
          ],
        ],
      ),
      bottomNavigationBar: count > 0
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
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: _topicId == null ? null : _add,
                  icon: const Icon(Icons.playlist_add_check_rounded),
                  label: Text(l10n.importAdd(count)),
                ),
              ),
            )
          : null,
    );
  }
}

/// Найденный вопрос: галочка «добавить», текст на двух языках и варианты.
/// Нажатие на вариант делает его правильным.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.number,
    required this.question,
    required this.selected,
    required this.onSelected,
    required this.onMarkCorrect,
  });

  final int number;
  final ImportedQuestion question;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final ValueChanged<int> onMarkCorrect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.answerColors;
    final q = question;
    final muted = textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, AppSpacing.m, AppSpacing.m),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: selected && q.isValid,
              onChanged: q.isValid ? (v) => onSelected(v ?? false) : null,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$number. ${q.textTg}',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (q.isTranslated) ...[
                      const SizedBox(height: 2),
                      Text(q.textRu, style: muted),
                    ],
                    const SizedBox(height: AppSpacing.s),
                    for (final (j, option) in q.optionsTg.indexed)
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => onMarkCorrect(j),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                j == q.correctIndex
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                size: 20,
                                color: j == q.correctIndex
                                    ? colors.correct
                                    : scheme.outline,
                              ),
                              const SizedBox(width: AppSpacing.s),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    text: option,
                                    style: j == q.correctIndex
                                        ? TextStyle(
                                            color: colors.correct,
                                            fontWeight: FontWeight.w700,
                                          )
                                        : null,
                                    children: [
                                      if (j < q.optionsRu.length &&
                                          q.optionsRu[j].isNotEmpty &&
                                          q.optionsRu[j] != option)
                                        TextSpan(
                                          text: '\n${q.optionsRu[j]}',
                                          style: muted,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (!q.hasAnswer) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.importNoAnswer,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.wrong,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
