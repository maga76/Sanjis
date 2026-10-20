/// Пройденный тест (коллекция `attempts` в Firestore).
class Attempt {
  const Attempt({
    required this.subjectId,
    required this.topicId,
    required this.correct,
    required this.total,
    required this.finishedAt,
  });

  final String subjectId;

  /// `null` — тест по всем темам предмета или по ошибкам.
  final String? topicId;
  final int correct;
  final int total;
  final DateTime finishedAt;

  /// Процент правильных ответов, 0–100.
  int get percent => total == 0 ? 0 : (correct * 100 / total).round();

  /// Школьная оценка 2–5 по проценту правильных ответов.
  int get mark => markFor(percent);

  static int markFor(int percent) {
    if (percent >= 85) return 5;
    if (percent >= 65) return 4;
    if (percent >= 45) return 3;
    return 2;
  }

  Map<String, Object?> toJson() => {
    'subjectId': subjectId,
    'topicId': topicId,
    'correct': correct,
    'total': total,
    'finishedAt': finishedAt.toIso8601String(),
  };

  factory Attempt.fromJson(Map<String, Object?> json) => Attempt(
    subjectId: json['subjectId'] as String,
    topicId: json['topicId'] as String?,
    correct: json['correct'] as int,
    total: json['total'] as int,
    finishedAt: DateTime.parse(json['finishedAt'] as String),
  );
}
