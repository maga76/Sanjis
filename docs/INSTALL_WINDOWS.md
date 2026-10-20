# Установка всего необходимого на Windows (для новичка)

Делайте шаги по порядку. Каждую команду вводите в **PowerShell**
(Пуск → введите «PowerShell» → Enter). После изменения PATH
**закрывайте и заново открывайте** PowerShell — иначе изменения не увидятся.

> ⚠️ **Главное правило путей:** Flutter, Android SDK и сам проект должны лежать
> в папках **без русских букв и без пробелов**. Поэтому проект лежит в
> `C:\projects\sanjish`, а Flutter мы поставим в `C:\src\flutter`.

---

## Шаг 1. Android Studio и Android SDK

1. Скачайте Android Studio: <https://developer.android.com/studio> → «Download Android Studio».
2. Запустите установщик, везде «Next», галочка **Android Virtual Device** должна стоять.
3. При первом запуске появится мастер настройки: выберите **Standard** → «Next» → «Finish».
   Он скачает Android SDK (~3 ГБ, нужен интернет, может идти долго).
   SDK по умолчанию ставится в `C:\Users\Muhammad\AppData\Local\Android\Sdk` — это нормально.
4. На стартовом окне Android Studio: **More Actions → SDK Manager** →
   вкладка **SDK Tools** → поставьте галочку **Android SDK Command-line Tools (latest)** → «Apply» → «OK».
   (Без этого `flutter doctor` будет ругаться.)
5. Там же: **Plugins** (слева на стартовом окне) → вкладка Marketplace → найдите **Flutter** →
   «Install» (он сам предложит поставить **Dart**) → перезапустите Android Studio.

## Шаг 2. Git и Flutter SDK

1. Установите **Git for Windows**: <https://git-scm.com/download/win> (все настройки по умолчанию).
   Flutter без Git не работает.
2. Скачайте Flutter SDK (zip-архив, канал **stable**):
   <https://docs.flutter.dev/get-started/install/windows/mobile> → раздел «Download then install Flutter».
3. Создайте папку `C:\src` и распакуйте архив туда, чтобы получилось `C:\src\flutter\bin\flutter.bat`.
   ❌ Не кладите Flutter в `C:\Program Files` и в папки с русскими буквами.
4. Добавьте Flutter в PATH:
   - Пуск → введите «**Изменение переменных среды для вашей учётной записи**» → откройте.
   - В верхнем списке выберите **Path** → «Изменить» → «Создать» → впишите `C:\src\flutter\bin` → «ОК» → «ОК».
5. Откройте **новый** PowerShell и проверьте:
   ```powershell
   flutter --version
   flutter doctor
   ```

### Типичные ошибки `flutter doctor` и как их исправить

| Что пишет | Что делать |
|---|---|
| `'flutter' не является внутренней или внешней командой` | PATH не добавлен или PowerShell не перезапущен (шаг 2.4). |
| `cmdline-tools component is missing` | Шаг 1.4 — поставьте Android SDK Command-line Tools. |
| `Android license status unknown` | Выполните `flutter doctor --android-licenses` и на все вопросы нажимайте `y`. |
| `Unable to locate Android SDK` | `flutter config --android-sdk "C:\Users\Muhammad\AppData\Local\Android\Sdk"` |
| `Visual Studio not installed` | **Игнорируйте** — это нужно только для программ под Windows, не для Android. |
| `Cannot find Chrome` | **Игнорируйте** — это для веб-версии. |
| `Building with plugins requires symlink support` | Включите режим разработчика Windows: выполните `start ms-settings:developers` и включите «Режим разработчика». |

Достаточно, чтобы были зелёные галочки у **Flutter** и **Android toolchain**.

## Шаг 3. Первый запуск проекта (проверка этапа 1)

```powershell
cd C:\projects\sanjish
# Создаёт папку android/ (существующие файлы проекта не трогает)
flutter create . --org tj --project-name sanjish --platforms android
flutter pub get
flutter analyze
flutter test
```

`flutter analyze` должен написать `No issues found!`, `flutter test` — `All tests passed!`.
Затем подключите телефон или запустите эмулятор (шаг 5) и выполните `flutter run`.

## Шаг 4. Firebase CLI и FlutterFire CLI

> Этот шаг понадобится на **этапе 2**, но установить можно уже сейчас.

1. Установите **Node.js LTS**: <https://nodejs.org> (по умолчанию).
2. В новом PowerShell:
   ```powershell
   npm install -g firebase-tools
   firebase login
   ```
   Откроется браузер — войдите в свой Google-аккаунт и разрешите доступ.
   - Ошибка `выполнение сценариев отключено в этой системе` → выполните
     `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` (ответ `Y`) и повторите.
3. Установите FlutterFire CLI:
   ```powershell
   dart pub global activate flutterfire_cli
   ```
   Добавьте в PATH (так же, как в шаге 2.4) папку
   `C:\Users\Muhammad\AppData\Local\Pub\Cache\bin`, перезапустите PowerShell и проверьте `flutterfire --version`.

## Шаг 5. Создание проекта в Firebase Console

> Тоже для **этапа 2**. Команду `flutterfire configure` будем запускать вместе.

1. Откройте <https://console.firebase.google.com> → **Создать проект** → название `sanjish`.
   Google Analytics можно отключить.
2. **Build → Authentication → Get started** → вкладка **Sign-in method** → **Email/Password** → включить → «Save».
3. **Build → Firestore Database → Create database** → регион **europe-west** (ближайший к Таджикистану,
   изменить потом нельзя) → **Production mode** (правила напишем сами).
4. Подключение приложения к Firebase (на этапе 2):
   ```powershell
   cd C:\projects\sanjish
   flutterfire configure --platforms=android
   ```
   Выберите проект `sanjish`. Команда создаст `lib/firebase_options.dart` и `android/app/google-services.json`.

## Шаг 6. Запуск на телефоне и на эмуляторе

### На своём телефоне по USB (рекомендуется — быстрее эмулятора)
1. Телефон: **Настройки → О телефоне** → 7 раз нажмите на **Номер сборки**
   (на Xiaomi — «Версия MIUI/HyperOS») → появится «Вы стали разработчиком».
2. **Настройки → Для разработчиков** (иногда в «Расширенных настройках») →
   включите **Отладка по USB**. На Xiaomi также включите **Установка через USB**.
3. Подключите телефон кабелем, на телефоне нажмите **Разрешить** (поставьте «Всегда»).
   В шторке выберите режим USB «Передача файлов».
4. Проверка и запуск:
   ```powershell
   flutter devices
   flutter run
   ```
   Если телефон не виден: другой кабель (некоторые кабели только заряжают);
   для Samsung поставьте «Samsung USB Driver» с сайта Samsung.

### На эмуляторе
1. Android Studio → **More Actions → Virtual Device Manager → Create device** →
   **Pixel 6** → системный образ **API 34 (x86_64)** → скачать → «Finish» → ▶ запустить.
2. `flutter run`.
3. Если эмулятор не стартует: в BIOS должна быть включена виртуализация (Intel VT-x / AMD-V),
   а в Windows — компонент «Платформа низкоуровневой оболочки Windows»
   (Пуск → «Включение или отключение компонентов Windows»). Эмулятору нужно 8+ ГБ ОЗУ на компьютере.

## Шаг 7. Аккаунт админа

> Делается после этапа 2 (когда приложение подключено к Firebase).

1. Firebase Console → **Authentication → Users → Add user** → почта и пароль админа → «Add user».
2. В списке пользователей скопируйте **User UID** (длинная строка вида `a1B2c3...`).
3. **Firestore Database → Start collection** → Collection ID: `config` → «Next».
4. Document ID: `app`, поля:

   | Поле | Тип | Значение |
   |---|---|---|
   | `adminUid` | string | скопированный UID |
   | `imagesEnabled` | boolean | `false` |
   | `minAppVersion` | string | `0.1.0` |

5. «Save». Теперь при входе с этой почтой откроется админ-панель.

## Шаг 8. Сборка APK и установка на телефоны учеников

```powershell
cd C:\projects\sanjish
flutter build apk --release --split-per-abi
```

Готовые файлы — в папке `C:\projects\sanjish\build\app\outputs\flutter-apk\`:

| Файл | Для каких телефонов |
|---|---|
| `app-arm64-v8a-release.apk` | почти все телефоны последних 5–7 лет — **отдавайте этот** |
| `app-armeabi-v7a-release.apk` | очень старые / самые дешёвые телефоны (если первый не ставится) |
| `app-x86_64-release.apk` | только эмуляторы |

Если не знаете, какой нужен, соберите один общий файл (он больше по размеру):
`flutter build apk --release`.

**Как установить ученику:**
1. Отправьте APK через Telegram, по Bluetooth или скопируйте по USB.
2. На телефоне откройте файл → Android попросит разрешить «Установку из неизвестных источников»
   для приложения, из которого открыли файл (Telegram, «Файлы») → разрешите.
3. Если Google Play Protect предупреждает — «Подробнее» → «Всё равно установить».

> Обновления: новая версия ставится поверх старой, только если подписана **тем же ключом**.
> Постоянный ключ подписи настроим на этапе 7 — до этого при обновлении может понадобиться
> удалить старую версию.
