import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/validators.dart';
import '../application/auth_service.dart';
import 'login_screen.dart';

/// «Забыли пароль?»: почта аккаунта и новый пароль.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _password2 = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _password2.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = context.l10n;
    setState(() => _busy = true);
    final error = await ref
        .read(authProvider.notifier)
        .resetPassword(_email.text, _password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    if (error != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(authErrorText(error, l10n))),
      );
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(l10n.passwordChanged)));
    context.canPop() ? context.pop() : context.go(Routes.login);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const gap = SizedBox(height: AppSpacing.m);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.forgotPassword)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.resetPasswordHint,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.l),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: l10n.email),
                  validator: (v) => Validators.email(v, l10n),
                ),
                gap,
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: l10n.newPassword),
                  validator: (v) => Validators.password(v, l10n),
                ),
                gap,
                TextFormField(
                  controller: _password2,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(labelText: l10n.repeatPassword),
                  validator: (v) =>
                      v != _password.text ? l10n.passwordsDontMatch : null,
                ),
                const SizedBox(height: AppSpacing.l),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: Text(l10n.save),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
