import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../app/settings/app_settings.dart';
import '../../../data/models/account.dart';

/// Подключён ли Firebase: true, если в сборке есть
/// `android/app/google-services.json`. Подменяется в main().
/// Нужен только для входа через Google.
final firebaseReadyProvider = Provider<bool>((ref) => false);

/// Текущий пользователь; `null` — никто не вошёл.
final authProvider = NotifierProvider<AuthController, Account?>(
  AuthController.new,
);

/// Все аккаунты на телефоне (для статистики админа).
final accountsProvider = Provider<List<Account>>((ref) {
  ref.watch(authProvider);
  return ref.read(authProvider.notifier).accounts;
});

enum AuthError { emailInUse, userNotFound, wrongPassword, useGoogle }

enum GoogleSignInResult { success, canceled, failed }

/// Аккаунты хранятся на телефоне: регистрация, вход по почте и паролю,
/// новый пароль, вход через Google (если подключён Firebase).
class AuthController extends Notifier<Account?> {
  static const _kAccounts = 'auth.accounts';
  static const _kCurrent = 'auth.currentId';

  /// Админ по умолчанию — создаётся при первом запуске.
  static const defaultAdminEmail = 'admin@sanjish.tj';
  static const defaultAdminPassword = 'admin123';

  static bool _googleInitialized = false;

  final _random = Random.secure();
  late List<Account> _accounts;

  List<Account> get accounts => List.unmodifiable(_accounts);

  @override
  Account? build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    _accounts = [];
    for (final raw in prefs.getStringList(_kAccounts) ?? const <String>[]) {
      try {
        _accounts.add(
          Account.fromJson(jsonDecode(raw) as Map<String, Object?>),
        );
      } on Object {
        // Повреждённую запись пропускаем
      }
    }
    if (!_accounts.any((a) => a.isAdmin)) {
      _accounts.add(
        _newAccount(
          firstName: 'Админ',
          lastName: '',
          email: defaultAdminEmail,
          password: defaultAdminPassword,
          role: UserRole.admin,
        ),
      );
      _saveAccounts();
    }
    final currentId = prefs.getString(_kCurrent);
    return _accounts.where((a) => a.id == currentId).firstOrNull;
  }

  static String normalizeEmail(String email) => email.trim().toLowerCase();

  Account? _byEmail(String email) {
    final e = normalizeEmail(email);
    return _accounts.where((a) => a.email == e).firstOrNull;
  }

  Future<AuthError?> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required int grade,
    required String region,
    required String school,
  }) async {
    if (_byEmail(email) != null) return AuthError.emailInUse;
    final account = _newAccount(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: email,
      password: password,
      role: UserRole.student,
      grade: grade,
      region: region,
      school: school.trim(),
    );
    _accounts.add(account);
    await _saveAccounts();
    await _setCurrent(account);
    return null;
  }

  Future<AuthError?> login(String email, String password) async {
    final account = _byEmail(email);
    if (account == null) return AuthError.userNotFound;
    if (account.passwordHash == null) return AuthError.useGoogle;
    if (_hash(password, account.salt!) != account.passwordHash) {
      return AuthError.wrongPassword;
    }
    await _setCurrent(account);
    return null;
  }

  /// Новый пароль по почте. Сервера нет, поэтому письмо не отправляется —
  /// пароль меняется сразу на телефоне.
  Future<AuthError?> resetPassword(String email, String newPassword) async {
    final account = _byEmail(email);
    if (account == null) return AuthError.userNotFound;
    final salt = _newSalt();
    await _replace(
      account.copyWith(passwordHash: _hash(newPassword, salt), salt: salt),
    );
    return null;
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String school,
    required String region,
    required int grade,
  }) async {
    final account = state;
    if (account == null) return;
    await _replace(
      account.copyWith(
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        school: school.trim(),
        region: region,
        grade: grade,
      ),
    );
  }

  Future<GoogleSignInResult> signInWithGoogle() async {
    if (!ref.read(firebaseReadyProvider)) return GoogleSignInResult.failed;
    try {
      final google = GoogleSignIn.instance;
      if (!_googleInitialized) {
        // Client ID берётся из google-services.json (default_web_client_id)
        await google.initialize();
        _googleInitialized = true;
      }
      final googleAccount = await google.authenticate();
      final result = await FirebaseAuth.instance.signInWithCredential(
        GoogleAuthProvider.credential(
          idToken: googleAccount.authentication.idToken,
        ),
      );
      final user = result.user!;
      final email = user.email ?? googleAccount.email;
      var account = _byEmail(email);
      if (account == null) {
        final names = (user.displayName ?? googleAccount.displayName ?? '')
            .trim()
            .split(RegExp(r'\s+'));
        account = Account(
          id: _newId(),
          firstName: names.first,
          lastName: names.skip(1).join(' '),
          email: normalizeEmail(email),
          role: UserRole.student,
          createdAt: DateTime.now(),
        );
        _accounts.add(account);
        await _saveAccounts();
      }
      await _setCurrent(account);
      return GoogleSignInResult.success;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return GoogleSignInResult.canceled;
      }
      debugPrint('Google Sign-In: ${e.code} ${e.description}');
      return GoogleSignInResult.failed;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth: ${e.code} ${e.message}');
      return GoogleSignInResult.failed;
    }
  }

  Future<void> logout() async {
    if (ref.read(firebaseReadyProvider)) {
      if (_googleInitialized) await GoogleSignIn.instance.signOut();
      await FirebaseAuth.instance.signOut();
    }
    state = null;
    await ref.read(sharedPreferencesProvider).remove(_kCurrent);
  }

  Account _newAccount({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required UserRole role,
    int? grade,
    String? region,
    String? school,
  }) {
    final salt = _newSalt();
    return Account(
      id: _newId(),
      firstName: firstName,
      lastName: lastName,
      email: normalizeEmail(email),
      role: role,
      createdAt: DateTime.now(),
      passwordHash: _hash(password, salt),
      salt: salt,
      grade: grade,
      region: region,
      school: school,
    );
  }

  Future<void> _replace(Account account) async {
    _accounts = [for (final a in _accounts) a.id == account.id ? account : a];
    await _saveAccounts();
    if (state?.id == account.id) state = account;
  }

  Future<void> _setCurrent(Account account) async {
    state = account;
    await ref.read(sharedPreferencesProvider).setString(_kCurrent, account.id);
  }

  Future<void> _saveAccounts() =>
      ref.read(sharedPreferencesProvider).setStringList(_kAccounts, [
        for (final a in _accounts) jsonEncode(a.toJson()),
      ]);

  String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch}${_random.nextInt(1 << 20)}';

  String _newSalt() =>
      base64Url.encode(List.generate(16, (_) => _random.nextInt(256)));

  static String _hash(String password, String salt) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();
}
