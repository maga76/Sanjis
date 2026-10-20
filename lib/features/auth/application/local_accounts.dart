import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/account.dart';
import 'auth_service.dart';

/// Аккаунты на телефоне — когда Firebase не подключён (и в тестах).
/// Пароль хранится только в виде хеша с солью.
class LocalAccounts implements AccountsBackend {
  LocalAccounts(this._prefs) {
    for (final raw in _prefs.getStringList(_kAccounts) ?? const <String>[]) {
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
    final currentId = _prefs.getString(_kCurrent);
    _current = _accounts.where((a) => a.id == currentId).firstOrNull;
  }

  static const _kAccounts = 'auth.accounts';
  static const _kCurrent = 'auth.currentId';

  /// Админ по умолчанию — создаётся при первом запуске.
  static const defaultAdminEmail = 'admin@sanjish.tj';
  static const defaultAdminPassword = 'admin123';

  final SharedPreferences _prefs;
  final _random = Random.secure();
  final _accounts = <Account>[];
  final _changes = StreamController<Account?>.broadcast();
  Account? _current;

  @override
  Account? get current => _current;

  @override
  Future<void> get ready => Future.value();

  @override
  Stream<Account?> get changes => _changes.stream;

  @override
  bool get resetByEmail => false;

  static String normalizeEmail(String email) => email.trim().toLowerCase();

  Account? _byEmail(String email) {
    final e = normalizeEmail(email);
    return _accounts.where((a) => a.email == e).firstOrNull;
  }

  @override
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

  @override
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

  /// Сервера нет, поэтому письмо не отправляется — пароль меняется сразу.
  @override
  Future<AuthError?> resetPassword(String email, {String? newPassword}) async {
    final account = _byEmail(email);
    if (account == null) return AuthError.userNotFound;
    final salt = _newSalt();
    await _replace(
      account.copyWith(passwordHash: _hash(newPassword!, salt), salt: salt),
    );
    return null;
  }

  @override
  Future<void> updateProfile(Account account) => _replace(account);

  /// Без Firebase вход через Google недоступен (кнопка скрыта).
  @override
  Future<GoogleSignInResult> signInWithGoogle() async =>
      GoogleSignInResult.failed;

  @override
  Future<void> logout() async {
    _current = null;
    _changes.add(null);
    await _prefs.remove(_kCurrent);
  }

  @override
  Future<List<Account>> allAccounts() async => List.unmodifiable(_accounts);

  @override
  void dispose() => _changes.close();

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
    final i = _accounts.indexWhere((a) => a.id == account.id);
    if (i >= 0) _accounts[i] = account;
    await _saveAccounts();
    if (_current?.id == account.id) {
      _current = account;
      _changes.add(account);
    }
  }

  Future<void> _setCurrent(Account account) async {
    _current = account;
    _changes.add(account);
    await _prefs.setString(_kCurrent, account.id);
  }

  Future<void> _saveAccounts() => _prefs.setStringList(_kAccounts, [
    for (final a in _accounts) jsonEncode(a.toJson()),
  ]);

  String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch}${_random.nextInt(1 << 20)}';

  String _newSalt() =>
      base64Url.encode(List.generate(16, (_) => _random.nextInt(256)));

  static String _hash(String password, String salt) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();
}
