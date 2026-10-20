import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/settings/app_settings.dart';
import 'features/auth/application/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Настройки читаем до запуска UI, чтобы сразу показать нужный язык и тему.
  final prefs = await SharedPreferences.getInstance();

  // Без google-services.json Firebase не настроен — приложение работает,
  // но вход через Google недоступен.
  var firebaseReady = false;
  try {
    await Firebase.initializeApp();
    // Копия базы на телефоне: без интернета всё открывается и сохраняется,
    // а при появлении сети досылается. Размер не ограничиваем, чтобы
    // вопросы и результаты не вытеснялись из кеша.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    firebaseReady = true;
  } on Object catch (e) {
    debugPrint('Firebase не настроен: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        firebaseReadyProvider.overrideWithValue(firebaseReady),
      ],
      child: const SanjishApp(),
    ),
  );
}
