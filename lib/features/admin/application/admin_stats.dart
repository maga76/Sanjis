import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/settings/app_settings.dart';
import '../../../data/models/account.dart';
import '../../../data/models/attempt.dart';
import '../../auth/application/auth_service.dart';
import '../../student/application/progress.dart';

/// Данные для статистики админа.
class AdminStatsData {
  const AdminStatsData({
    required this.students,
    required this.attempts,
    required this.questionStats,
  });

  final List<Account> students;
  final List<Attempt> attempts;

  /// id вопроса → (сколько раз отвечали, сколько раз ошиблись).
  final Map<String, (int, int)> questionStats;
}

/// С Firebase — по всем ученикам из Firestore, без него — по аккаунтам
/// на этом телефоне. Обновляется при каждом открытии экрана.
final adminStatsProvider = FutureProvider.autoDispose<AdminStatsData>((
  ref,
) async {
  final accounts = await ref.read(authProvider.notifier).allAccounts();
  final students = [
    for (final a in accounts)
      if (!a.isAdmin) a,
  ];

  if (ref.watch(firebaseReadyProvider)) {
    final db = FirebaseFirestore.instance;
    final attempts = await db.collectionGroup('attempts').get();
    final stats = await db.collection('questionStats').get();
    return AdminStatsData(
      students: students,
      attempts: [for (final d in attempts.docs) Attempt.fromJson(d.data())],
      questionStats: {
        for (final d in stats.docs)
          d.id: (
            (d.data()['asked'] as num? ?? 0).toInt(),
            (d.data()['wrong'] as num? ?? 0).toInt(),
          ),
      },
    );
  }

  final prefs = ref.watch(sharedPreferencesProvider);
  // Пересчёт после каждого пройденного теста
  ref.watch(progressProvider);
  return AdminStatsData(
    students: students,
    attempts: [
      for (final a in accounts) ...ProgressController.attemptsOf(prefs, a.id),
    ],
    questionStats: ProgressController.questionStats(prefs),
  );
});
