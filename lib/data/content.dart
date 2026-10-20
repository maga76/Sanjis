import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/settings/app_settings.dart';
import 'models/question.dart';
import 'seed/demo_questions.dart';

/// Темы и вопросы, которые видит ученик: демо-данные плюс правки админа.
class Content {
  Content(this.topics)
    : topicsById = {for (final t in topics) t.id: t},
      questionsById = {
        for (final t in topics)
          for (final q in t.questions) q.id: q,
      };

  final List<Topic> topics;
  final Map<String, Topic> topicsById;
  final Map<String, Question> questionsById;

  /// Все темы предмета.
  List<Topic> topicsOf(String subjectId) => [
    for (final t in topics)
      if (t.subjectId == subjectId) t,
  ];

  /// Темы предмета для класса.
  List<Topic> topicsFor(String subjectId, int grade) => [
    for (final t in topics)
      if (t.subjectId == subjectId && t.availableFor(grade)) t,
  ];
}

final contentProvider = NotifierProvider<ContentController, Content>(
  ContentController.new,
);

/// Правки админа хранятся на телефоне поверх демо-данных:
/// новые и изменённые темы/вопросы и id удалённых.
class ContentController extends Notifier<Content> {
  static const _kTopics = 'content.topics';
  static const _kQuestions = 'content.questions';
  static const _kDeleted = 'content.deleted';

  late List<Topic> _customTopics;
  late List<Question> _customQuestions;
  late Set<String> _deleted;

  @override
  Content build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    _customTopics = _decode(prefs.getStringList(_kTopics), Topic.fromJson);
    _customQuestions = _decode(
      prefs.getStringList(_kQuestions),
      Question.fromJson,
    );
    _deleted = {...?prefs.getStringList(_kDeleted)};
    return _merge();
  }

  static List<T> _decode<T>(
    List<String>? raw,
    T Function(Map<String, Object?>) fromJson,
  ) {
    final result = <T>[];
    for (final item in raw ?? const <String>[]) {
      try {
        result.add(fromJson(jsonDecode(item) as Map<String, Object?>));
      } on Object {
        // Повреждённую запись пропускаем
      }
    }
    return result;
  }

  Content _merge() {
    final customTopics = {for (final t in _customTopics) t.id: t};
    final customQuestions = {for (final q in _customQuestions) q.id: q};

    // Демо-темы (с переименованием админом) и новые темы
    final metas = [
      for (final t in demoTopics) customTopics[t.id] ?? t,
      for (final t in _customTopics)
        if (!demoTopicsById.containsKey(t.id)) t,
    ].where((t) => !_deleted.contains(t.id));

    return Content([
      for (final meta in metas)
        meta.withQuestions([
          // Демо-вопросы (изменённые админом заменяются)
          for (final q in demoTopicsById[meta.id]?.questions ?? <Question>[])
            if (!_deleted.contains(q.id)) customQuestions[q.id] ?? q,
          // Новые вопросы темы
          for (final q in _customQuestions)
            if (q.topicId == meta.id &&
                !demoQuestionsById.containsKey(q.id) &&
                !_deleted.contains(q.id))
              q,
        ]),
    ]);
  }

  static String newId(String prefix) =>
      '$prefix.${DateTime.now().microsecondsSinceEpoch}';

  Future<void> saveQuestion(Question question) async {
    _customQuestions = [
      for (final q in _customQuestions)
        if (q.id != question.id) q,
      question,
    ];
    await _save();
  }

  Future<void> deleteQuestion(String id) async {
    _customQuestions = [
      for (final q in _customQuestions)
        if (q.id != id) q,
    ];
    if (demoQuestionsById.containsKey(id)) _deleted.add(id);
    await _save();
  }

  Future<void> saveTopic(Topic topic) async {
    _customTopics = [
      for (final t in _customTopics)
        if (t.id != topic.id) t,
      topic,
    ];
    await _save();
  }

  /// Удаляет тему вместе с её вопросами.
  Future<void> deleteTopic(String id) async {
    _customTopics = [
      for (final t in _customTopics)
        if (t.id != id) t,
    ];
    _customQuestions = [
      for (final q in _customQuestions)
        if (q.topicId != id) q,
    ];
    if (demoTopicsById.containsKey(id)) _deleted.add(id);
    await _save();
  }

  Future<void> _save() async {
    state = _merge();
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setStringList(_kTopics, [
      for (final t in _customTopics) jsonEncode(t.toJson()),
    ]);
    await prefs.setStringList(_kQuestions, [
      for (final q in _customQuestions) jsonEncode(q.toJson()),
    ]);
    await prefs.setStringList(_kDeleted, [..._deleted]);
  }
}
