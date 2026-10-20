import 'package:flutter_test/flutter_test.dart';
import 'package:sanjish/data/models/attempt.dart';
import 'package:sanjish/data/seed/default_subjects.dart';
import 'package:sanjish/data/seed/demo_questions.dart';

void main() {
  test('У каждого предмета есть темы для каждого его класса', () {
    for (final subject in defaultSubjects) {
      for (final grade in subject.grades) {
        expect(
          topicsFor(subject.id, grade),
          isNotEmpty,
          reason: '${subject.id}, класс $grade',
        );
      }
    }
  });

  test('Вопросы корректны: 2–6 вариантов, без повторов, id уникальны', () {
    final ids = <String>{};
    for (final topic in demoTopics) {
      // 5 основных + 5 дополнительных: ловит опечатку в id темы у доп. вопросов
      expect(topic.questions, hasLength(10), reason: topic.id);
      for (final q in topic.questions) {
        expect(ids.add(q.id), isTrue, reason: 'повтор id ${q.id}');
        expect(q.optionCount, inInclusiveRange(2, 6), reason: q.id);
        expect(q.optionsRu.length, q.optionsTg.length, reason: q.id);
        expect(q.optionsTg.toSet().length, q.optionCount, reason: q.id);
        expect(q.optionsRu.toSet().length, q.optionCount, reason: q.id);
        expect(q.correctIndex, inInclusiveRange(0, q.optionCount - 1));
      }
    }
  });

  test('Оценка по проценту', () {
    expect(Attempt.markFor(100), 5);
    expect(Attempt.markFor(85), 5);
    expect(Attempt.markFor(80), 4);
    expect(Attempt.markFor(60), 3);
    expect(Attempt.markFor(40), 2);
  });
}
