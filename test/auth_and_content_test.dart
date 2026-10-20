import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanjish/app/settings/app_settings.dart';
import 'package:sanjish/data/content.dart';
import 'package:sanjish/data/models/question.dart';
import 'package:sanjish/features/auth/application/auth_service.dart';
import 'package:sanjish/features/auth/application/local_accounts.dart';
import 'package:sanjish/features/student/application/progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container([
  Map<String, Object> prefs = const {},
]) async {
  SharedPreferences.setMockInitialValues(prefs);
  final instance = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(instance)],
  );
  addTearDown(container.dispose);
  return container;
}

Future<AuthError?> _register(ProviderContainer c, String email) => c
    .read(authProvider.notifier)
    .register(
      firstName: 'Али',
      lastName: 'Валиев',
      email: email,
      password: 'secret1',
      grade: 7,
      region: 'sughd',
      school: '№1',
    );

void main() {
  group('Аккаунты', () {
    test('Админ по умолчанию входит, никто не вошёл при старте', () async {
      final c = await _container();
      final auth = c.read(authProvider.notifier);
      expect(c.read(authProvider), isNull);
      expect(
        await auth.login(
          LocalAccounts.defaultAdminEmail,
          LocalAccounts.defaultAdminPassword,
        ),
        isNull,
      );
      expect(c.read(authProvider)!.isAdmin, isTrue);
    });

    test('Регистрация, повтор почты, выход и вход', () async {
      final c = await _container();
      final auth = c.read(authProvider.notifier);

      expect(await _register(c, ' Ali@Mail.TJ '), isNull);
      expect(c.read(authProvider)!.email, 'ali@mail.tj');
      expect(c.read(authProvider)!.isAdmin, isFalse);
      expect(await _register(c, 'ali@mail.tj'), AuthError.emailInUse);

      await auth.logout();
      expect(c.read(authProvider), isNull);
      expect(
        await auth.login('ali@mail.tj', 'wrong!'),
        AuthError.wrongPassword,
      );
      expect(await auth.login('no@mail.tj', 'secret1'), AuthError.userNotFound);
      expect(await auth.login('ALI@mail.tj', 'secret1'), isNull);
    });

    test('Новый пароль заменяет старый', () async {
      final c = await _container();
      final auth = c.read(authProvider.notifier);
      await _register(c, 'ali@mail.tj');
      await auth.logout();

      expect(
        await auth.resetPassword('ali@mail.tj', newPassword: 'newpass'),
        isNull,
      );
      expect(
        await auth.login('ali@mail.tj', 'secret1'),
        AuthError.wrongPassword,
      );
      expect(await auth.login('ali@mail.tj', 'newpass'), isNull);
    });

    test('Аккаунты и вход сохраняются после перезапуска', () async {
      final c = await _container();
      await _register(c, 'ali@mail.tj');
      final prefs = c.read(sharedPreferencesProvider);

      final restarted = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(restarted.dispose);
      expect(restarted.read(authProvider)?.email, 'ali@mail.tj');
      expect(restarted.read(authProvider)?.grade, 7);
    });

    test('У каждого ученика свой прогресс', () async {
      final c = await _container();
      final auth = c.read(authProvider.notifier);
      await _register(c, 'a@mail.tj');
      await c
          .read(progressProvider.notifier)
          .recordTest(
            subjectId: 'math',
            topicId: 'math.mul_div',
            answers: {'math.mul_div.1': true, 'math.mul_div.2': false},
          );
      expect(c.read(progressProvider).testsCount, 1);
      expect(c.read(progressProvider).mistakeIds, ['math.mul_div.2']);

      await auth.logout();
      await _register(c, 'b@mail.tj');
      expect(c.read(progressProvider).testsCount, 0);
    });
  });

  group('Правки админа', () {
    test('Новый вопрос появляется в теме', () async {
      final c = await _container();
      final before = c.read(contentProvider).topicsById['math.mul_div']!;
      await c
          .read(contentProvider.notifier)
          .saveQuestion(
            const Question(
              id: 'q.new',
              topicId: 'math.mul_div',
              textTg: '2 × 2 = ?',
              textRu: '2 × 2 = ?',
              optionsTg: ['4', '5'],
              optionsRu: ['4', '5'],
              correctIndex: 0,
            ),
          );
      final after = c.read(contentProvider).topicsById['math.mul_div']!;
      expect(after.questions.length, before.questions.length + 1);
      expect(after.questions.last.id, 'q.new');
    });

    test('Изменение и удаление демо-вопроса', () async {
      final c = await _container();
      final content = c.read(contentProvider.notifier);
      final original = c.read(contentProvider).questionsById['math.mul_div.1']!;

      await content.saveQuestion(
        Question(
          id: original.id,
          topicId: original.topicId,
          textTg: 'Нав',
          textRu: 'Новый',
          optionsTg: original.optionsTg,
          optionsRu: original.optionsRu,
          correctIndex: 1,
        ),
      );
      expect(c.read(contentProvider).questionsById[original.id]!.textTg, 'Нав');

      await content.deleteQuestion(original.id);
      expect(c.read(contentProvider).questionsById[original.id], isNull);
    });

    test('Тема: добавление для класса и удаление', () async {
      final c = await _container();
      final content = c.read(contentProvider.notifier);
      await content.saveTopic(
        const Topic(
          id: 'math.new',
          subjectId: 'math',
          nameTg: 'Касрҳо',
          nameRu: 'Дроби',
          minGrade: 5,
          maxGrade: 6,
          questions: [],
        ),
      );
      final ids = [
        for (final t in c.read(contentProvider).topicsFor('math', 5)) t.id,
      ];
      expect(ids, contains('math.new'));
      expect(c.read(contentProvider).topicsFor('math', 2), hasLength(1));

      await content.deleteTopic('math.add_sub');
      expect(c.read(contentProvider).topicsById['math.add_sub'], isNull);
      expect(c.read(contentProvider).questionsById['math.add_sub.1'], isNull);
    });
  });
}
