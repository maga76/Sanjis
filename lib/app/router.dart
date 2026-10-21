import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/presentation/admin_import_screen.dart';
import '../features/admin/presentation/admin_question_edit_screen.dart';
import '../features/admin/presentation/admin_questions_screen.dart';
import '../features/admin/presentation/admin_shell.dart';
import '../features/admin/presentation/admin_stats_screen.dart';
import '../features/admin/presentation/admin_subjects_screen.dart';
import '../features/auth/application/auth_service.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/onboarding/presentation/language_select_screen.dart';
import '../features/onboarding/presentation/splash_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/student/presentation/mistakes_screen.dart';
import '../features/student/presentation/profile_edit_screen.dart';
import '../features/student/presentation/profile_screen.dart';
import '../features/student/presentation/student_home_screen.dart';
import '../features/student/presentation/student_shell.dart';
import '../features/student/presentation/subject_topics_screen.dart';
import '../features/student/presentation/test_screen.dart';
import 'routes.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Роутер приложения. Создаётся один раз.
/// Без входа пускает только на заставку, выбор языка, вход и регистрацию;
/// админ-панель — только админу.
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: Routes.splash,
    redirect: (context, state) {
      const public = {
        Routes.splash,
        Routes.language,
        Routes.login,
        Routes.register,
        Routes.forgotPassword,
      };
      final location = state.matchedLocation;
      final account = ref.read(authProvider);
      if (account == null) {
        return public.contains(location) ? null : Routes.login;
      }
      final home = account.isAdmin ? Routes.adminQuestions : Routes.studentHome;
      // Вошедшему незачем на экраны входа
      if (location == Routes.login ||
          location == Routes.register ||
          location == Routes.forgotPassword) {
        return home;
      }
      if (location.startsWith('/admin') && !account.isAdmin) return home;
      return null;
    },
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
        path: Routes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
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
                    builder: (context, state) => SubjectTopicsScreen(
                      subjectId: state.pathParameters['subjectId']!,
                    ),
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
                routes: [
                  GoRoute(
                    path: 'edit',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const ProfileEditScreen(),
                  ),
                ],
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
                routes: [
                  GoRoute(
                    path: 'import',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const AdminImportScreen(),
                  ),
                  GoRoute(
                    path: 'edit',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => AdminQuestionEditScreen(
                      questionId: state.uri.queryParameters['id'],
                      topicId: state.uri.queryParameters['topic'],
                    ),
                  ),
                ],
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
