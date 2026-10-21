import 'package:flutter_test/flutter_test.dart';
import 'package:sanjish/features/admin/application/question_import.dart';

void main() {
  test('Нумерация, звёздочка, строка «Ҷавоб», объяснение', () {
    final questions = QuestionImport.parseBasic('''
1. Пойтахти Тоҷикистон кадом шаҳр аст?
а) Хуҷанд
б) Душанбе *
в) Бохтар
г) Кӯлоб

2) 7 × 8 = ?
a) 54
b) 56
c) 64
Ҷавоб: b
Шарҳ: 7 × 8 = 56
''');
    expect(questions, hasLength(2));
    expect(questions[0].textTg, 'Пойтахти Тоҷикистон кадом шаҳр аст?');
    expect(questions[0].optionsTg, ['Хуҷанд', 'Душанбе', 'Бохтар', 'Кӯлоб']);
    expect(questions[0].correctIndex, 1);
    expect(questions[1].textTg, '7 × 8 = ?');
    expect(questions[1].correctIndex, 1);
    expect(questions[1].explanationTg, '7 × 8 = 56');
    expect(questions.every((q) => q.isValid), isTrue);
  });

  test('Без пометки правильного ответа — вопрос не готов', () {
    final questions = QuestionImport.parseBasic('''
Офтоб чист?
а) Ситора
б) Сайёра
''');
    expect(questions, hasLength(1));
    expect(questions.single.hasAnswer, isFalse);
    expect(questions.single.isValid, isFalse);
  });

  test('Строки из Excel: заголовок пропускается, ответ буквой или номером', () {
    final questions = QuestionImport.parseBasic(
      'Савол\tA\tB\tC\tҶавоб\n'
      '2 + 2 = ?\t3\t4\t5\tб\n'
      'Пули Тоҷикистон?\tСомонӣ\tРубл\tСум\t1\n',
    );
    expect(questions, hasLength(2));
    expect(questions[0].optionsTg, ['3', '4', '5']);
    expect(questions[0].correctIndex, 1);
    expect(questions[1].correctIndex, 0);
  });

  test('Вариант «C++» не считается отмеченным', () {
    final questions = QuestionImport.parseBasic('''
1. Забони барномасозӣ?
а) C++
б) Python *
''');
    expect(questions.single.optionsTg, ['C++', 'Python']);
    expect(questions.single.correctIndex, 1);
  });
}
