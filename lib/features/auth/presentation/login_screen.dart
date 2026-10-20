import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/notebook_header.dart';
import '../../../core/widgets/language_switch.dart';
import '../application/auth_service.dart';

/// Экран входа: почта и пароль; через Google — если подключён Firebase.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _googleBusy = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final auth = ref.read(authProvider.notifier);
    final error = await auth.login(_email.text, _password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      _showError(authErrorText(error, context.l10n));
      return;
    }
    _goHome();
  }

  void _goHome() {
    final account = ref.read(authProvider);
    context.go(
      account?.isAdmin ?? false ? Routes.adminQuestions : Routes.studentHome,
    );
  }

  void _showError(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  Future<void> _signInWithGoogle() async {
    final l10n = context.l10n;
    setState(() => _googleBusy = true);
    final result = await ref.read(authProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    setState(() => _googleBusy = false);
    switch (result) {
      case GoogleSignInResult.success:
        _goHome();
      case GoogleSignInResult.canceled:
        break;
      case GoogleSignInResult.failed:
        _showError(l10n.googleSignInFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Синяя шапка: переключатель языка, логотип, название
            NotebookHeader(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.m,
                AppSpacing.s,
                AppSpacing.m,
                AppSpacing.l,
              ),
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerRight,
                    child: LanguageSwitch(onDark: true),
                  ),
                  const AppLogo(size: 84, onDark: true),
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    l10n.appName,
                    style: textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    l10n.appTagline,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.welcomeBack,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.loginSubtitle,
                        style: textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.l),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        decoration: InputDecoration(
                          labelText: l10n.email,
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                        validator: (v) => Validators.email(v, l10n),
                      ),
                      const SizedBox(height: AppSpacing.m),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: l10n.password,
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (v) => Validators.password(v, l10n),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => context.push(Routes.forgotPassword),
                          child: Text(l10n.forgotPassword),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s),
                      FilledButton(
                        onPressed: _busy ? null : _submit,
                        child: Text(l10n.login),
                      ),
                      if (ref.watch(firebaseReadyProvider)) ...[
                        const SizedBox(height: AppSpacing.m),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.s,
                              ),
                              child: Text(l10n.orDivider),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.m),
                        OutlinedButton.icon(
                          onPressed: _googleBusy ? null : _signInWithGoogle,
                          icon: _googleBusy
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const _GoogleMark(),
                          label: Text(l10n.signInWithGoogle),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.m),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(l10n.noAccount),
                          TextButton(
                            onPressed: () => context.push(Routes.register),
                            child: Text(l10n.register),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Буква «G» в цветах Google вместо картинки-ассета.
class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const SweepGradient(
        colors: [
          Color(0xFF4285F4),
          Color(0xFF34A853),
          Color(0xFFFBBC05),
          Color(0xFFEA4335),
          Color(0xFF4285F4),
        ],
      ).createShader(bounds),
      child: const Text(
        'G',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Текст ошибки входа или регистрации.
String authErrorText(AuthError error, AppLocalizations l10n) => switch (error) {
  AuthError.emailInUse => l10n.errEmailInUse,
  AuthError.userNotFound => l10n.errUserNotFound,
  AuthError.wrongPassword => l10n.errWrongPassword,
  AuthError.useGoogle => l10n.errUseGoogle,
  AuthError.invalidCredentials => l10n.errInvalidCredentials,
  AuthError.network => l10n.errNetwork,
  AuthError.tooManyRequests => l10n.errTooMany,
  AuthError.unknown => l10n.errorGeneric,
};
