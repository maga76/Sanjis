# Вход через Google — настройка Firebase (10 минут)

Код входа уже в приложении. Чтобы кнопка «Ворид шудан бо Google» заработала,
нужен ваш проект Firebase. Пока его нет, приложение работает, а кнопка
показывает «Вуруд бо Google ҳоло танзим нашудааст».

## 1. Создать проект
1. Откройте <https://console.firebase.google.com> и войдите своим Google-аккаунтом.
2. **Create a project** → имя `Sanjish` → Google Analytics можно выключить → **Create**.

## 2. Добавить Android-приложение
1. На главной проекта нажмите значок **Android**.
2. **Android package name:** `tj.sanjish`
3. **App nickname:** `Sanjish`
4. **Debug signing certificate SHA-1** — для этого компьютера:

   ```
   5C:9F:C3:EE:B1:1B:40:9B:91:35:CB:ED:7A:03:5C:7C:6F:79:FC:F0
   ```

   Если собираете на другом компьютере, SHA-1 там свой:
   `keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android`
5. **Register app** → **Download google-services.json**.
6. Положите файл сюда: `C:\projects\sanjish\android\app\google-services.json`.
   Остальные шаги мастера («Add Firebase SDK») пропустите — уже сделано.

## 3. Включить вход через Google
1. Слева **Build → Authentication** → **Get started**.
2. Вкладка **Sign-in method** → **Google** → **Enable**.
3. Выберите **Support email** (ваша почта) → **Save**.

## 4. Скачать google-services.json ещё раз
После включения Google-входа в файле появляется нужный ключ (`client_type: 3`).
**Project settings** (шестерёнка) → ваше Android-приложение → снова скачайте
`google-services.json` и замените им файл из шага 2.

## 5. Запустить
```powershell
cd C:\projects\sanjish
flutter run
```

## Если не получается
| Что видно | Причина |
|---|---|
| «Вуруд бо Google ҳоло танзим нашудааст» | Нет `android/app/google-services.json` или сборка старая — перезапустите `flutter run` |
| «Бо Google ворид шудан нашуд» | Не добавлен SHA-1 (шаг 2.4) или файл скачан до включения Google (шаг 4) |

Файл `google-services.json` в git не попадает (он в `.gitignore`).
Для release-сборки на этапе 7 нужно будет добавить ещё SHA-1 ключа подписи.
