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

  Map<String, Object?> toJson() => {
    'id': id,
    'topicId': topicId,
    'textTg': textTg,
    'textRu': textRu,
    'optionsTg': optionsTg,
    'optionsRu': optionsRu,
    'correctIndex': correctIndex,
    'explanationTg': explanationTg,
    'explanationRu': explanationRu,
  };

  factory Question.fromJson(Map<String, Object?> json) => Question(
    id: json['id'] as String,
    topicId: json['topicId'] as String,
    textTg: json['textTg'] as String? ?? '',
    textRu: json['textRu'] as String? ?? '',
    optionsTg: [...(json['optionsTg'] as List).cast<String>()],
    optionsRu: [...(json['optionsRu'] as List).cast<String>()],
    correctIndex: json['correctIndex'] as int,
    explanationTg: json['explanationTg'] as String?,
    explanationRu: json['explanationRu'] as String?,
  );
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

  Topic withQuestions(List<Question> questions) => Topic(
    id: id,
    subjectId: subjectId,
    nameTg: nameTg,
    nameRu: nameRu,
    minGrade: minGrade,
    maxGrade: maxGrade,
    questions: questions,
  );

  /// Без вопросов — они хранятся отдельно.
  Map<String, Object?> toJson() => {
    'id': id,
    'subjectId': subjectId,
    'nameTg': nameTg,
    'nameRu': nameRu,
    'minGrade': minGrade,
    'maxGrade': maxGrade,
  };

  factory Topic.fromJson(Map<String, Object?> json) => Topic(
    id: json['id'] as String,
    subjectId: json['subjectId'] as String,
    nameTg: json['nameTg'] as String? ?? '',
    nameRu: json['nameRu'] as String? ?? '',
    minGrade: json['minGrade'] as int,
    maxGrade: json['maxGrade'] as int,
    questions: const [],
  );
}
