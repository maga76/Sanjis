import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Фильтр класса на главной. Меняет только показ предметов,
/// а не класс в профиле. Пока профиля нет — по умолчанию 5 класс.
class GradeFilter extends Notifier<int> {
  @override
  int build() => 5;

  void select(int grade) => state = grade;
}

final gradeFilterProvider = NotifierProvider<GradeFilter, int>(GradeFilter.new);
