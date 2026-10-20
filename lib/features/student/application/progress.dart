import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/settings/app_settings.dart';
import '../../../data/models/attempt.dart';

/// Прогресс ученика: пройденные тесты и вопросы с ошибками.
/// Пока Firebase не подключён, хранится локально в SharedPreferences.
@immutable
class Progress {
  const Progress({required this.attempts, required this.mistakeIds});

  /// Новые — первыми.
  final List<Attempt> attempts;

  /// Вопросы, на которые ученик ответил неправильно и ещё не исправил.
  /// Новые — первыми.
  final List<String> mistakeIds;

  int get testsCount => attempts.length;
  int get answersCount => attempts.fold(0, (sum, a) => sum + a.total);
  int get correctCount => attempts.fold(0, (sum, a) => sum + a.correct);

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
  static const _kAttempts = 'progress.attempts';
  static const _kMistakes = 'progress.mistakes';

  /// Сколько последних попыток хранить.
  static const _maxAttempts = 100;

  @override
  Progress build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final attempts = <Attempt>[];
    for (final raw in prefs.getStringList(_kAttempts) ?? const <String>[]) {
      try {
        attempts.add(Attempt.fromJson(jsonDecode(raw) as Map<String, Object?>));
      } on Object {
        // Повреждённую запись пропускаем, остальные показываем
      }
    }
    return Progress(
      attempts: attempts,
      mistakeIds: prefs.getStringList(_kMistakes) ?? const [],
    );
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

    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setStringList(_kAttempts, [
      for (final a in state.attempts) jsonEncode(a.toJson()),
    ]);
    await prefs.setStringList(_kMistakes, state.mistakeIds);
  }
}

final progressProvider = NotifierProvider<ProgressController, Progress>(
  ProgressController.new,
);
