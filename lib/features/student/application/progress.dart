import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/settings/app_settings.dart';
import '../../../data/models/attempt.dart';
import '../../auth/application/auth_service.dart';

/// Прогресс ученика: пройденные тесты и вопросы с ошибками.
/// С Firebase — в Firestore (`users/{uid}/attempts`, поле `mistakeIds`),
/// без него — на телефоне. У каждого аккаунта свой.
@immutable
class Progress {
  const Progress({required this.attempts, required this.mistakeIds});

  /// Новые — первыми.
  final List<Attempt> attempts;

  /// Вопросы, на которые ученик ответил неправильно и ещё не исправил.
  /// Новые — первыми.
  final List<String> mistakeIds;

  int get testsCount => attempts.length;
  int get answersCount => attempts.fold(0, (n, a) => n + a.total);
  int get correctCount => attempts.fold(0, (n, a) => n + a.correct);

  /// Точность по всем ответам, 0–100.
  int get accuracy =>
      answersCount == 0 ? 0 : (correctCount * 100 / answersCount).round();

  /// Лучший результат по теме в процентах или `null`, если тему не проходили.
  int? bestPercentFor(String topicId) {
    int? best;
    for (final a in attempts) {
      if (a.topicId == topicId && (best == null || a.percent > best)) {
        best = a.percent;
      }
    }
    return best;
  }
}

class ProgressController extends Notifier<Progress> {
  static String _kAttempts(String uid) => 'progress.$uid.attempts';
  static String _kMistakes(String uid) => 'progress.$uid.mistakes';

  /// Общая статистика по вопросам для админа: id → [ответов, ошибок].
  static const _kQuestionStats = 'stats.questions';

  /// Сколько последних попыток хранить.
  static const _maxAttempts = 100;

  String? get _uid => ref.read(authProvider)?.id;

  bool get _online => ref.read(firebaseReadyProvider);

  @override
  Progress build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final uid = ref.watch(authProvider.select((a) => a?.id));
    if (uid == null) return const Progress(attempts: [], mistakeIds: []);
    if (ref.watch(firebaseReadyProvider)) {
      _listen(uid);
      return const Progress(attempts: [], mistakeIds: []);
    }
    return Progress(
      attempts: attemptsOf(prefs, uid),
      mistakeIds: prefs.getStringList(_kMistakes(uid)) ?? const [],
    );
  }

  void _listen(String uid) {
    final user = FirebaseFirestore.instance.collection('users').doc(uid);
    final attempts = user
        .collection('attempts')
        .orderBy('finishedAt', descending: true)
        .limit(_maxAttempts)
        .snapshots()
        .listen(
          (snapshot) => state = Progress(
            attempts: [
              for (final doc in snapshot.docs) Attempt.fromJson(doc.data()),
            ],
            mistakeIds: state.mistakeIds,
          ),
          onError: (Object e) => debugPrint('Попытки: $e'),
        );
    final mistakes = user.snapshots().listen(
      (doc) => state = Progress(
        attempts: state.attempts,
        mistakeIds: [...?(doc.data()?['mistakeIds'] as List?)?.cast<String>()],
      ),
      onError: (Object e) => debugPrint('Ошибки: $e'),
    );
    ref.onDispose(() {
      attempts.cancel();
      mistakes.cancel();
    });
  }

  /// Попытки любого аккаунта — для статистики админа.
  static List<Attempt> attemptsOf(SharedPreferences prefs, String uid) {
    final attempts = <Attempt>[];
    for (final raw
        in prefs.getStringList(_kAttempts(uid)) ?? const <String>[]) {
      try {
        attempts.add(Attempt.fromJson(jsonDecode(raw) as Map<String, Object?>));
      } on Object {
        // Повреждённую запись пропускаем, остальные показываем
      }
    }
    return attempts;
  }

  /// id вопроса → (сколько раз отвечали, сколько раз ошиблись).
  static Map<String, (int, int)> questionStats(SharedPreferences prefs) {
    try {
      final raw = jsonDecode(prefs.getString(_kQuestionStats) ?? '{}') as Map;
      return {
        for (final MapEntry(:key, :value) in raw.entries)
          key as String: ((value as List)[0] as int, value[1] as int),
      };
    } on Object {
      return {};
    }
  }

  /// Сохраняет пройденный тест. [answers] — id вопроса → ответ верный.
  Future<void> recordTest({
    required String subjectId,
    required String? topicId,
    required Map<String, bool> answers,
  }) async {
    final attempt = Attempt(
      subjectId: subjectId,
      topicId: topicId,
      correct: answers.values.where((ok) => ok).length,
      total: answers.length,
      finishedAt: DateTime.now(),
    );

    final wrong = [
      for (final e in answers.entries)
        if (!e.value) e.key,
    ];
    final mistakes = [
      ...wrong,
      // Исправленные ошибки уходят из списка
      for (final id in state.mistakeIds)
        if (!answers.containsKey(id)) id,
    ];

    state = Progress(
      attempts: [attempt, ...state.attempts].take(_maxAttempts).toList(),
      mistakeIds: mistakes,
    );

    final uid = _uid;
    if (uid == null) return;
    if (_online) {
      _saveOnline(uid, attempt, answers);
      return;
    }
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setStringList(_kAttempts(uid), [
      for (final a in state.attempts) jsonEncode(a.toJson()),
    ]);
    await prefs.setStringList(_kMistakes(uid), state.mistakeIds);

    final stats = questionStats(prefs);
    for (final MapEntry(key: id, value: ok) in answers.entries) {
      final (asked, wrong) = stats[id] ?? (0, 0);
      stats[id] = (asked + 1, wrong + (ok ? 0 : 1));
    }
    await prefs.setString(
      _kQuestionStats,
      jsonEncode({
        for (final MapEntry(:key, value: (a, w)) in stats.entries) key: [a, w],
      }),
    );
  }

  /// Без await: без интернета Firestore отправит запись позже.
  void _saveOnline(String uid, Attempt attempt, Map<String, bool> answers) {
    final db = FirebaseFirestore.instance;
    final user = db.collection('users').doc(uid);
    final batch = db.batch()
      ..set(user.collection('attempts').doc(), attempt.toJson())
      ..set(user, {'mistakeIds': state.mistakeIds}, SetOptions(merge: true));
    for (final MapEntry(key: id, value: ok) in answers.entries) {
      batch.set(db.collection('questionStats').doc(id), {
        'asked': FieldValue.increment(1),
        'wrong': FieldValue.increment(ok ? 0 : 1),
      }, SetOptions(merge: true));
    }
    unawaited(
      batch.commit().catchError((Object e) => debugPrint('Результат: $e')),
    );
  }
}

final progressProvider = NotifierProvider<ProgressController, Progress>(
  ProgressController.new,
);
