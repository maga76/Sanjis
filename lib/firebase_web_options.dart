import 'package:firebase_core/firebase_core.dart';

/// Настройки Firebase для веб-версии (Firebase Console → Project settings →
/// Your apps → Sanjish Web). На Android вместо них — google-services.json.
/// Значения не секретные: их видит любой браузер, открывший сайт.
const webFirebaseOptions = FirebaseOptions(
  apiKey: 'AIzaSyDpG8UuXgufFfMZbwryfurlUJlDQzh9R3U',
  authDomain: 'sanjish-d6c42.firebaseapp.com',
  projectId: 'sanjish-d6c42',
  storageBucket: 'sanjish-d6c42.firebasestorage.app',
  messagingSenderId: '358924932543',
  appId: '1:358924932543:web:c85e22e08ffb9e4e3a7d0a',
  measurementId: 'G-EDSQFVPGHF',
);
