import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/presentation/admin_questions_screen.dart';
import '../features/admin/presentation/admin_shell.dart';
import '../features/admin/presentation/admin_stats_screen.dart';
import '../features/admin/presentation/admin_subjects_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/onboarding/presentation/language_select_screen.dart';
import '../features/onboarding/presentation/splash_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/student/presentation/mistakes_screen.dart';
import '../features/student/presentation/profile_screen.dart';
import '../features/student/presentation/student_home_screen.dart';
import '../features/student/presentation/student_shell.dart';
import '../features/student/presentation/subject_screen.dart';
import '../features/student/presentation/subject_topics_screen.dart';
import '../features/student/presentation/test_screen.dart';
import 'routes.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Роутер приложения. Создаётся один раз.
/// Проверка входа и роли (redirect) появится на этапе 2.
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: Routes.splash,
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.language,
        builder: (context, state) => const LanguageSelectScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: Routes.settings,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      // Тест открывается поверх нижней навигации
      GoRoute(
        path: Routes.test,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final params = state.uri.queryParameters;
          return TestScreen(
            subjectId: params['subject'],
            topicId: params['topic'],
            grade: int.tryParse(params['grade'] ?? ''),
            mistakes: params['mode'] == 'mistakes',
          );
        },
      ),

      // Интерфейс ученика: 3 вкладки, у каждой свой стек экранов
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => StudentShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.studentHome,
                builder: (context, state) => const StudentHomeScreen(),
                routes: [
                  GoRoute(
                    path: Routes.studentSubject,
                    builder: (context, state) => SubjectScreen(
                      subjectId: state.pathParameters['subjectId']!,
                    ),
                    routes: [
                      GoRoute(
                        path: Routes.studentSubjectGrade,
                        builder: (context, state) => SubjectTopicsScreen(
                          subjectId: state.pathParameters['subjectId']!,
                          grade:
                              int.tryParse(state.pathParameters['grade']!) ?? 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.studentMistakes,
                builder: (context, state) => const MistakesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.studentProfile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Интерфейс админа: 4 вкладки
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AdminShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.adminQuestions,
                builder: (context, state) => const AdminQuestionsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.adminSubjects,
                builder: (context, state) => const AdminSubjectsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.adminStats,
                builder: (context, state) => const AdminStatsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.adminSettings,
                builder: (context, state) =>
                    const SettingsScreen(embedded: true),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
