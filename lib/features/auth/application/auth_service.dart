import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Подключён ли Firebase: true, если в сборке есть
/// `android/app/google-services.json`. Подменяется в main().
final firebaseReadyProvider = Provider<bool>((ref) => false);

/// Текущий пользователь Firebase; `null` — не вошёл или Firebase не настроен.
final authUserProvider = StreamProvider<User?>(
  (ref) => ref.watch(firebaseReadyProvider)
      ? FirebaseAuth.instance.authStateChanges()
      : Stream.value(null),
);

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ready: ref.watch(firebaseReadyProvider)),
);

enum GoogleSignInResult { success, canceled, notConfigured, failed }

/// Вход и выход. Пока только Google; почта и пароль — на этапе 2.
class AuthService {
  AuthService({required this.ready});

  final bool ready;
  static bool _googleInitialized = false;

  User? get currentUser => ready ? FirebaseAuth.instance.currentUser : null;

  Future<GoogleSignInResult> signInWithGoogle() async {
    if (!ready) return GoogleSignInResult.notConfigured;
    try {
      final google = GoogleSignIn.instance;
      if (!_googleInitialized) {
        // Client ID берётся из google-services.json (default_web_client_id)
        await google.initialize();
        _googleInitialized = true;
      }
      final account = await google.authenticate();
      await FirebaseAuth.instance.signInWithCredential(
        GoogleAuthProvider.credential(idToken: account.authentication.idToken),
      );
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

  Future<void> signOut() async {
    if (!ready) return;
    if (_googleInitialized) await GoogleSignIn.instance.signOut();
    await FirebaseAuth.instance.signOut();
  }
}
