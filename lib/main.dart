import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/settings/app_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Настройки читаем до запуска UI, чтобы сразу показать нужный язык и тему.
  final prefs = await SharedPreferences.getInstance();

  // Firebase будет инициализироваться здесь на этапе 2.

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const SanjishApp(),
    ),
  );
}
