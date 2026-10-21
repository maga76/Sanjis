import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/settings/app_settings.dart';
import '../features/auth/application/auth_service.dart';
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

/// Последняя ошибка записи в базу — админ-панель показывает её.
final syncErrorProvider = NotifierProvider<SyncError, SyncFailure?>(
  SyncError.new,
);

enum SyncFailure { noAccess, network }

class SyncError extends Notifier<SyncFailure?> {
  @override
  SyncFailure? build() => null;

  void report(Object error) =>
      state = error is FirebaseException && error.code == 'permission-denied'
      ? SyncFailure.noAccess
      : SyncFailure.network;

  void clear() => state = null;
}

final contentProvider = NotifierProvider<ContentController, Content>(
  ContentController.new,
);

/// Правки админа поверх демо-данных: новые и изменённые темы/вопросы
/// и id удалённых. С Firebase — в Firestore (`topics`, `questions`,
/// `deleted`), и правки сразу видят все ученики; без него — на телефоне.
class ContentController extends Notifier<Content> {
  static const _kTopics = 'content.topics';
  static const _kQuestions = 'content.questions';
  static const _kDeleted = 'content.deleted';

  late List<Topic> _customTopics;
  late List<Question> _customQuestions;
  late Set<String> _deleted;

  bool get _online => ref.read(firebaseReadyProvider);
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  Content build() {
    if (ref.watch(firebaseReadyProvider)) {
      _customTopics = [];
      _customQuestions = [];
      _deleted = {};
      // Читать базу можно только после входа
      if (ref.watch(authProvider.select((a) => a != null))) _listen();
      return _merge();
    }
    final prefs = ref.watch(sharedPreferencesProvider);
    _customTopics = _decode(prefs.getStringList(_kTopics), Topic.fromJson);
    _customQuestions = _decode(
      prefs.getStringList(_kQuestions),
      Question.fromJson,
    );
    _deleted = {...?prefs.getStringList(_kDeleted)};
    return _merge();
  }

  void _listen() {
    final subscriptions = <String, StreamSubscription<Object?>>{};
    final retries = <Timer>[];
    var disposed = false;

    // После ошибки (нет доступа, нет сети) подписка закрывается —
    // переподключаемся через 15 секунд
    void watch(
      String collection,
      void Function(List<QueryDocumentSnapshot<Map<String, dynamic>>>) apply,
    ) {
      subscriptions[collection] = _db
          .collection(collection)
          .snapshots()
          .listen(
            (snapshot) {
              apply(snapshot.docs);
              state = _merge();
            },
            onError: (Object e) {
              debugPrint('$collection: $e');
              if (disposed) return;
              retries.add(
                Timer(const Duration(seconds: 15), () {
                  if (!disposed) watch(collection, apply);
                }),
              );
            },
          );
    }

    watch('topics', (docs) {
      _customTopics = [for (final d in docs) Topic.fromJson(d.data())];
    });
    watch('questions', (docs) {
      _customQuestions = [for (final d in docs) Question.fromJson(d.data())];
    });
    watch('deleted', (docs) => _deleted = {for (final d in docs) d.id});

    ref.onDispose(() {
      disposed = true;
      for (final s in subscriptions.values) {
        s.cancel();
      }
      for (final t in retries) {
        t.cancel();
      }
    });
  }

  /// Без await: без интернета Firestore отправит изменения позже,
  /// а на экране они видны сразу. Если база отказала — сообщаем админу.
  void _commit(WriteBatch batch) => unawaited(
    batch.commit().catchError((Object e) {
      debugPrint('Контент: $e');
      ref.read(syncErrorProvider.notifier).report(e);
    }),
  );

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

  static var _idCounter = 0;

  /// Уникальный id: время + счётчик (при импорте вопросы создаются
  /// в одну и ту же микросекунду).
  static String newId(String prefix) =>
      '$prefix.${DateTime.now().microsecondsSinceEpoch}${_idCounter++}';

  Future<void> saveQuestion(Question question) async {
    if (_online) {
      return _commit(
        _db.batch()..set(
          _db.collection('questions').doc(question.id),
          question.toJson(),
        ),
      );
    }
    _customQuestions = [
      for (final q in _customQuestions)
        if (q.id != question.id) q,
      question,
    ];
    await _save();
  }

  /// Добавляет сразу много вопросов (импорт) — одной записью.
  Future<void> saveQuestions(List<Question> questions) async {
    if (questions.isEmpty) return;
    if (_online) {
      final batch = _db.batch();
      for (final q in questions) {
        batch.set(_db.collection('questions').doc(q.id), q.toJson());
      }
      return _commit(batch);
    }
    final ids = {for (final q in questions) q.id};
    _customQuestions = [
      for (final q in _customQuestions)
        if (!ids.contains(q.id)) q,
      ...questions,
    ];
    await _save();
  }

  Future<void> deleteQuestion(String id) async {
    if (_online) {
      final batch = _db.batch()..delete(_db.collection('questions').doc(id));
      if (demoQuestionsById.containsKey(id)) {
        batch.set(_db.collection('deleted').doc(id), {'at': DateTime.now()});
      }
      return _commit(batch);
    }
    _customQuestions = [
      for (final q in _customQuestions)
        if (q.id != id) q,
    ];
    if (demoQuestionsById.containsKey(id)) _deleted.add(id);
    await _save();
  }

  Future<void> saveTopic(Topic topic) async {
    if (_online) {
      return _commit(
        _db.batch()
          ..set(_db.collection('topics').doc(topic.id), topic.toJson()),
      );
    }
    _customTopics = [
      for (final t in _customTopics)
        if (t.id != topic.id) t,
      topic,
    ];
    await _save();
  }

  /// Удаляет тему вместе с её вопросами.
  Future<void> deleteTopic(String id) async {
    if (_online) {
      final batch = _db.batch()..delete(_db.collection('topics').doc(id));
      for (final q in _customQuestions) {
        if (q.topicId == id) {
          batch.delete(_db.collection('questions').doc(q.id));
        }
      }
      if (demoTopicsById.containsKey(id)) {
        batch.set(_db.collection('deleted').doc(id), {'at': DateTime.now()});
      }
      return _commit(batch);
    }
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
