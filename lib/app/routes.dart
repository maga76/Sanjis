/// Пути экранов приложения в одном месте.
class Routes {
  const Routes._();

  static const splash = '/';
  static const language = '/language';
  static const login = '/login';
  static const register = '/register';
  static const settings = '/settings';

  // Ученик
  static const studentHome = '/student/home';
  static const studentMistakes = '/student/mistakes';
  static const studentProfile = '/student/profile';

  /// Классы предмета: `/student/home/subject/math`.
  static const studentSubject = 'subject/:subjectId';
  static String subject(String subjectId) => '$studentHome/subject/$subjectId';

  /// Темы предмета в классе: `/student/home/subject/math/grade/5`.
  static const studentSubjectGrade = 'grade/:grade';
  static String subjectGrade(String subjectId, int grade) =>
      '${subject(subjectId)}/grade/$grade';

  /// Тест: по теме, по всем темам предмета или по ошибкам.
  static const test = '/test';
  static String testFor({
    required String subjectId,
    String? topicId,
    int? grade,
  }) => Uri(
    path: test,
    queryParameters: {
      'subject': subjectId,
      'topic': ?topicId,
      'grade': ?grade?.toString(),
    },
  ).toString();
  static String get testMistakes =>
      Uri(path: test, queryParameters: {'mode': 'mistakes'}).toString();

  // Админ
  static const adminQuestions = '/admin/questions';
  static const adminSubjects = '/admin/subjects';
  static const adminStats = '/admin/stats';
  static const adminSettings = '/admin/settings';
}
