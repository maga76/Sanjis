import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/subject_style.dart';
import '../../../core/utils/validators.dart';
import '../../../data/content.dart';
import '../../../data/models/question.dart';
import '../../../data/models/subject.dart';
import '../../../data/seed/default_subjects.dart';

/// Предметы и темы (админ): добавление, переименование и удаление тем.
class AdminSubjectsScreen extends ConsumerWidget {
  const AdminSubjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final content = ref.watch(contentProvider);
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
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.m,
                  AppSpacing.m,
                  AppSpacing.s,
                  AppSpacing.xs,
                ),
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
                        IconButton(
                          tooltip: l10n.newTopic,
                          onPressed: () => _editTopic(context, ref, subject),
                          icon: const Icon(Icons.add_rounded),
                        ),
                      ],
                    ),
                    for (final topic in content.topicsOf(subject.id))
                      ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.only(left: 4),
                        leading: const Icon(Icons.topic_outlined, size: 20),
                        title: Text(
                          context.pickLang(topic.nameTg, topic.nameRu),
                        ),
                        subtitle: Text(
                          '${l10n.gradeRange(topic.minGrade, topic.maxGrade)}'
                          ' · ${l10n.questionsCount(topic.questions.length)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: l10n.editTopic,
                              onPressed: () =>
                                  _editTopic(context, ref, subject, topic),
                              icon: const Icon(Icons.edit_outlined, size: 20),
                            ),
                            IconButton(
                              tooltip: l10n.delete,
                              onPressed: () =>
                                  _deleteTopic(context, ref, topic),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
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

  Future<void> _deleteTopic(
    BuildContext context,
    WidgetRef ref,
    Topic topic,
  ) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.pickLang(topic.nameTg, topic.nameRu)),
        content: Text(l10n.deleteTopicConfirm),
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
    if (ok == true) {
      await ref.read(contentProvider.notifier).deleteTopic(topic.id);
    }
  }

  Future<void> _editTopic(
    BuildContext context,
    WidgetRef ref,
    Subject subject, [
    Topic? topic,
  ]) async {
    final result = await showDialog<Topic>(
      context: context,
      builder: (_) => _TopicDialog(subject: subject, topic: topic),
    );
    if (result != null) {
      await ref.read(contentProvider.notifier).saveTopic(result);
    }
  }
}

/// Диалог темы: название на двух языках и классы.
class _TopicDialog extends StatefulWidget {
  const _TopicDialog({required this.subject, this.topic});

  final Subject subject;
  final Topic? topic;

  @override
  State<_TopicDialog> createState() => _TopicDialogState();
}

class _TopicDialogState extends State<_TopicDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameTg = TextEditingController(text: widget.topic?.nameTg);
  late final _nameRu = TextEditingController(text: widget.topic?.nameRu);
  late int _from = widget.topic?.minGrade ?? widget.subject.minGrade;
  late int _to = widget.topic?.maxGrade ?? widget.subject.maxGrade;

  @override
  void dispose() {
    _nameTg.dispose();
    _nameRu.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final topic = widget.topic;
    Navigator.of(context).pop(
      Topic(
        id: topic?.id ?? ContentController.newId(widget.subject.id),
        subjectId: widget.subject.id,
        nameTg: _nameTg.text.trim(),
        nameRu: _nameRu.text.trim(),
        minGrade: _from,
        maxGrade: _to,
        questions: const [],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final grades = widget.subject.grades;
    DropdownButtonFormField<int> gradeField(
      String label,
      int value,
      ValueChanged<int> onChanged,
    ) => DropdownButtonFormField<int>(
      // Ключ обновляет поле, когда второе поле поправило это значение
      key: ValueKey('$label-$value'),
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final g in grades) DropdownMenuItem(value: g, child: Text('$g')),
      ],
      onChanged: (v) => setState(() => onChanged(v!)),
    );

    return AlertDialog(
      title: Text(widget.topic == null ? l10n.newTopic : l10n.editTopic),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameTg,
                decoration: InputDecoration(labelText: l10n.topicNameTg),
                validator: (v) => Validators.required(v, l10n),
              ),
              const SizedBox(height: AppSpacing.s),
              TextFormField(
                controller: _nameRu,
                decoration: InputDecoration(labelText: l10n.topicNameRu),
              ),
              const SizedBox(height: AppSpacing.s),
              Row(
                children: [
                  Expanded(
                    child: gradeField(l10n.fromGrade, _from, (v) {
                      _from = v;
                      if (_to < v) _to = v;
                    }),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: gradeField(l10n.toGrade, _to, (v) {
                      _to = v;
                      if (_from > v) _from = v;
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.save)),
      ],
    );
  }
}
