import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../data/models/account.dart';
import 'auth_service.dart';

/// Аккаунты в Firebase: вход — Firebase Auth, профиль — `users/{uid}`
/// в Firestore. Работает и без интернета: Firestore хранит копию на телефоне.
class FirebaseAccounts implements AccountsBackend {
  FirebaseAccounts() {
    _authSubscription = _auth.authStateChanges().listen(_onUser);
  }

  static bool _googleInitialized = false;

  final _auth = FirebaseAuth.instance;
  final _users = FirebaseFirestore.instance.collection('users');
  final _changes = StreamController<Account?>.broadcast();
  final _ready = Completer<void>();
  late final StreamSubscription<User?> _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _docSubscription;
  Account? _current;

  @override
  Account? get current => _current;

  /// Без интернета и без копии профиля ждём не дольше 5 секунд.
  @override
  Future<void> get ready =>
      _ready.future.timeout(const Duration(seconds: 5), onTimeout: () {});

  @override
  Stream<Account?> get changes => _changes.stream;

  @override
  bool get resetByEmail => true;

  static String _normalize(String email) => email.trim().toLowerCase();

  /// Админ — почта из [kAdminEmails], подтверждённая (вход через Google).
  static bool _isAdmin(String email, bool verified) =>
      verified && kAdminEmails.contains(_normalize(email));

  static Account _fromData(
    String uid,
    Map<String, dynamic> data, {
    required bool verified,
  }) {
    final email = data['email'] as String? ?? '';
    return Account(
      id: uid,
      firstName: data['firstName'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      email: email,
      role: _isAdmin(email, verified) ? UserRole.admin : UserRole.student,
      createdAt:
          DateTime.tryParse(data['createdAt'] as String? ?? '') ??
          DateTime.now(),
      school: data['school'] as String?,
      region: data['region'] as String?,
      grade: (data['grade'] as num?)?.toInt(),
    );
  }

  static Map<String, Object?> _toData(Account a) => {
    'firstName': a.firstName,
    'lastName': a.lastName,
    'email': a.email,
    'createdAt': a.createdAt.toIso8601String(),
    'school': a.school,
    'region': a.region,
    'grade': a.grade,
  };

  void _emit(Account? account) {
    _current = account;
    _changes.add(account);
    if (!_ready.isCompleted) _ready.complete();
  }

  void _onUser(User? user) {
    _docSubscription?.cancel();
    if (user == null) {
      _emit(null);
      return;
    }
    _docSubscription = _users
        .doc(user.uid)
        .snapshots()
        .listen(
          (doc) {
            final data = doc.data();
            if (data != null) {
              _emit(_fromData(user.uid, data, verified: user.emailVerified));
            } else if (!doc.metadata.isFromCache) {
              // Профиля нет на сервере (например, прервали регистрацию)
              _createProfile(user);
            }
          },
          onError: (Object e) {
            debugPrint('Профиль: $e');
            if (!_ready.isCompleted) _ready.complete();
          },
        );
  }

  /// Профиль из данных Google-аккаунта или почты.
  Future<Account> _createProfile(User user, {String? fallbackName}) async {
    final names = (user.displayName ?? fallbackName ?? '').trim().split(
      RegExp(r'\s+'),
    );
    final account = Account(
      id: user.uid,
      firstName: names.first,
      lastName: names.skip(1).join(' '),
      email: _normalize(user.email ?? ''),
      role: _isAdmin(user.email ?? '', user.emailVerified)
          ? UserRole.admin
          : UserRole.student,
      createdAt: DateTime.now(),
    );
    await _users.doc(user.uid).set(_toData(account));
    return account;
  }

  Future<Account> _loadOrCreate(User user, {String? fallbackName}) async {
    try {
      final doc = await _users.doc(user.uid).get();
      final data = doc.data();
      return data != null
          ? _fromData(user.uid, data, verified: user.emailVerified)
          : await _createProfile(user, fallbackName: fallbackName);
    } on FirebaseException catch (e) {
      // База недоступна (нет сети или прав) — вход всё равно состоялся,
      // профиль подтянется, когда база ответит
      debugPrint('Профиль: ${e.code} ${e.message}');
      return _fromData(user.uid, {
        'email': user.email ?? '',
        'firstName': (user.displayName ?? fallbackName ?? '').split(' ').first,
      }, verified: user.emailVerified);
    }
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
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: _normalize(email),
        password: password,
      );
      final user = credential.user!;
      final account = Account(
        id: user.uid,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: _normalize(email),
        role: UserRole.student,
        createdAt: DateTime.now(),
        grade: grade,
        region: region,
        school: school.trim(),
      );
      await _users.doc(user.uid).set(_toData(account));
      _emit(account);
      return null;
    } on FirebaseAuthException catch (e) {
      return _error(e);
    }
  }

  @override
  Future<AuthError?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: _normalize(email),
        password: password,
      );
      _emit(await _loadOrCreate(credential.user!));
      return null;
    } on FirebaseAuthException catch (e) {
      return _error(e);
    }
  }

  @override
  Future<AuthError?> resetPassword(String email, {String? newPassword}) async {
    try {
      await _auth.sendPasswordResetEmail(email: _normalize(email));
      return null;
    } on FirebaseAuthException catch (e) {
      return _error(e);
    }
  }

  @override
  Future<void> updateProfile(Account account) async {
    _emit(account);
    // Без await: без интернета запись уйдёт на сервер позже
    unawaited(
      _users
          .doc(account.id)
          .set(_toData(account), SetOptions(merge: true))
          .catchError((Object e) => debugPrint('Профиль: $e')),
    );
  }

  @override
  Future<GoogleSignInResult> signInWithGoogle() async {
    if (kIsWeb) return _signInWithGoogleWeb();
    try {
      final google = GoogleSignIn.instance;
      if (!_googleInitialized) {
        // Client ID берётся из google-services.json (default_web_client_id)
        await google.initialize();
        _googleInitialized = true;
      }
      final googleAccount = await google.authenticate();
      final credential = await _auth.signInWithCredential(
        GoogleAuthProvider.credential(
          idToken: googleAccount.authentication.idToken,
        ),
      );
      _emit(
        await _loadOrCreate(
          credential.user!,
          fallbackName: googleAccount.displayName,
        ),
      );
      return GoogleSignInResult.success;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return GoogleSignInResult.canceled;
      }
      debugPrint('Google Sign-In: ${e.code} ${e.description}');
      return GoogleSignInResult.failed;
    } on FirebaseException catch (e) {
      debugPrint('Firebase: ${e.code} ${e.message}');
      return GoogleSignInResult.failed;
    }
  }

  /// В браузере — окно входа Google от Firebase.
  Future<GoogleSignInResult> _signInWithGoogleWeb() async {
    try {
      final credential = await _auth.signInWithPopup(GoogleAuthProvider());
      _emit(await _loadOrCreate(credential.user!));
      return GoogleSignInResult.success;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request') {
        return GoogleSignInResult.canceled;
      }
      debugPrint('Google (веб): ${e.code} ${e.message}');
      return GoogleSignInResult.failed;
    }
  }

  @override
  Future<void> logout() async {
    if (!kIsWeb && _googleInitialized) await GoogleSignIn.instance.signOut();
    await _auth.signOut();
    _emit(null);
  }

  @override
  Future<List<Account>> allAccounts() async {
    final snapshot = await _users.get();
    return [
      for (final doc in snapshot.docs)
        // Админа узнаём по почте: Google-почта всегда подтверждена
        _fromData(doc.id, doc.data(), verified: true),
    ];
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _docSubscription?.cancel();
    _changes.close();
  }

  static AuthError _error(FirebaseAuthException e) {
    debugPrint('Firebase Auth: ${e.code} ${e.message}');
    return switch (e.code) {
      'email-already-in-use' => AuthError.emailInUse,
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' ||
      'invalid-email' => AuthError.invalidCredentials,
      'network-request-failed' => AuthError.network,
      'too-many-requests' => AuthError.tooManyRequests,
      _ => AuthError.unknown,
    };
  }
}
