import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_service.dart';

/// Фильтр класса на главной. По умолчанию — класс ученика из профиля,
/// меняет только показ предметов, а не сам профиль.
class GradeFilter extends Notifier<int> {
  @override
  int build() => ref.watch(authProvider)?.grade ?? 5;

  void select(int grade) => state = grade;
}

final gradeFilterProvider = NotifierProvider<GradeFilter, int>(GradeFilter.new);
