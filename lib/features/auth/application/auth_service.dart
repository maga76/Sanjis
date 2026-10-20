import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/settings/app_settings.dart';
import '../../../data/models/account.dart';
import 'firebase_accounts.dart';
import 'local_accounts.dart';

/// Подключён ли Firebase: true, если в сборке есть
/// `android/app/google-services.json`. Подменяется в main().
/// С Firebase данные хранятся онлайн; без него — только на телефоне.
final firebaseReadyProvider = Provider<bool>((ref) => false);

/// Почты админов. Через Firebase админ входит через Google
/// (почта подтверждена); то же правило — в `firestore.rules`.
const kAdminEmails = {'safarov.m.9911@gmail.com'};

/// Текущий пользователь; `null` — никто не вошёл.
final authProvider = NotifierProvider<AuthController, Account?>(
  AuthController.new,
);

enum AuthError {
  emailInUse,
  userNotFound,
  wrongPassword,
  invalidCredentials,
  useGoogle,
  network,
  tooManyRequests,
  unknown,
}

enum GoogleSignInResult { success, canceled, failed }

/// Хранилище аккаунтов: на телефоне или в Firebase.
abstract interface class AccountsBackend {
  /// Текущий аккаунт, когда он уже известен.
  Account? get current;

  /// Завершается, когда стало известно, вошёл ли кто-то.
  Future<void> get ready;

  /// Смена текущего аккаунта (вход, выход, правка профиля).
  Stream<Account?> get changes;

  /// true — «Забыли пароль?» отправляет письмо; false — новый пароль
  /// задаётся сразу.
  bool get resetByEmail;

  Future<AuthError?> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required int grade,
    required String region,
    required String school,
  });

  Future<AuthError?> login(String email, String password);

  /// [newPassword] нужен, только если [resetByEmail] == false.
  Future<AuthError?> resetPassword(String email, {String? newPassword});

  Future<void> updateProfile(Account account);

  Future<GoogleSignInResult> signInWithGoogle();

  Future<void> logout();

  /// Все аккаунты — для статистики админа.
  Future<List<Account>> allAccounts();

  void dispose();
}

/// Вход, регистрация, профиль. Работает через [AccountsBackend].
class AuthController extends Notifier<Account?> {
  late AccountsBackend _backend;

  @override
  Account? build() {
    final backend = ref.watch(firebaseReadyProvider)
        ? FirebaseAccounts()
        : LocalAccounts(ref.watch(sharedPreferencesProvider));
    _backend = backend;
    final subscription = backend.changes.listen((a) => state = a);
    ref.onDispose(() {
      subscription.cancel();
      backend.dispose();
    });
    return backend.current;
  }

  Future<void> get ready => _backend.ready;
  bool get resetByEmail => _backend.resetByEmail;

  Future<AuthError?> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required int grade,
    required String region,
    required String school,
  }) => _sync(
    _backend.register(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
      grade: grade,
      region: region,
      school: school,
    ),
  );

  Future<AuthError?> login(String email, String password) =>
      _sync(_backend.login(email, password));

  Future<AuthError?> resetPassword(String email, {String? newPassword}) =>
      _backend.resetPassword(email, newPassword: newPassword);

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String school,
    required String region,
    required int grade,
  }) async {
    final account = state;
    if (account == null) return;
    await _backend.updateProfile(
      account.copyWith(
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        school: school.trim(),
        region: region,
        grade: grade,
      ),
    );
    state = _backend.current;
  }

  Future<GoogleSignInResult> signInWithGoogle() async {
    final result = await _backend.signInWithGoogle();
    state = _backend.current;
    return result;
  }

  Future<void> logout() async {
    await _backend.logout();
    state = null;
  }

  Future<List<Account>> allAccounts() => _backend.allAccounts();

  /// После входа сразу обновляет состояние, не дожидаясь события.
  Future<AuthError?> _sync(Future<AuthError?> action) async {
    final error = await action;
    if (error == null) state = _backend.current;
    return error;
  }
}
