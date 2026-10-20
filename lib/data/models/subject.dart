/// Предмет (коллекция `subjects` в Firestore).
class Subject {
  const Subject({
    required this.id,
    required this.nameTg,
    required this.nameRu,
    required this.icon,
    required this.color,
    required this.grades,
    required this.order,
    this.isActive = true,
  });

  final String id;
  final String nameTg;
  final String nameRu;

  /// Имя Material-иконки, например `calculate`.
  final String icon;

  /// Цвет в формате `#RRGGBB`.
  final String color;

  /// В каких классах есть предмет.
  final List<int> grades;
  final int order;
  final bool isActive;

  bool availableFor(int grade) => isActive && grades.contains(grade);

  int get minGrade => grades.reduce((a, b) => a < b ? a : b);
  int get maxGrade => grades.reduce((a, b) => a > b ? a : b);
}
