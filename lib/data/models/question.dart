/// Вопрос теста (коллекция `questions` в Firestore).
class Question {
  const Question({
    required this.id,
    required this.topicId,
    required this.textTg,
    required this.textRu,
    required this.optionsTg,
    required this.optionsRu,
    required this.correctIndex,
    this.explanationTg,
    this.explanationRu,
  });

  final String id;
  final String topicId;
  final String textTg;
  final String textRu;

  /// Варианты ответа (2–6). Списки на двух языках одной длины.
  final List<String> optionsTg;
  final List<String> optionsRu;

  /// Индекс правильного варианта в списках `options...`.
  final int correctIndex;

  final String? explanationTg;
  final String? explanationRu;

  int get optionCount => optionsTg.length;
}

/// Тема внутри предмета (коллекция `topics` в Firestore).
class Topic {
  const Topic({
    required this.id,
    required this.subjectId,
    required this.nameTg,
    required this.nameRu,
    required this.minGrade,
    required this.maxGrade,
    required this.questions,
  });

  final String id;
  final String subjectId;
  final String nameTg;
  final String nameRu;

  /// Для каких классов тема (включительно).
  final int minGrade;
  final int maxGrade;

  final List<Question> questions;

  bool availableFor(int grade) => grade >= minGrade && grade <= maxGrade;
}
