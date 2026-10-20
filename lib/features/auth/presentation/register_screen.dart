import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/regions.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/language_switch.dart';
import '../application/auth_service.dart';
import 'login_screen.dart';

/// Регистрация ученика: аккаунт создаётся на телефоне, сразу выполняется вход.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _password2 = TextEditingController();
  final _school = TextEditingController();
  int? _grade;
  Region? _region;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [
      _firstName,
      _lastName,
      _email,
      _password,
      _password2,
      _school,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final error = await ref
        .read(authProvider.notifier)
        .register(
          firstName: _firstName.text,
          lastName: _lastName.text,
          email: _email.text,
          password: _password.text,
          grade: _grade!,
          region: _region!.code,
          school: _school.text,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(authErrorText(error, context.l10n))),
        );
      return;
    }
    context.go(Routes.studentHome);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const gap = SizedBox(height: AppSpacing.m);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.register),
        actions: const [
          LanguageSwitch(),
          SizedBox(width: AppSpacing.m),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _firstName,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: l10n.firstName),
                  validator: (v) => Validators.required(v, l10n),
                ),
                gap,
                TextFormField(
                  controller: _lastName,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: l10n.lastName),
                  validator: (v) => Validators.required(v, l10n),
                ),
                gap,
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.email,
                    helperText: l10n.parentsEmailHint,
                    helperMaxLines: 2,
                  ),
                  validator: (v) => Validators.email(v, l10n),
                ),
                gap,
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: l10n.password),
                  validator: (v) => Validators.password(v, l10n),
                ),
                gap,
                TextFormField(
                  controller: _password2,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: l10n.repeatPassword),
                  validator: (v) =>
                      v != _password.text ? l10n.passwordsDontMatch : null,
                ),
                gap,
                DropdownButtonFormField<int>(
                  initialValue: _grade,
                  decoration: InputDecoration(labelText: l10n.grade),
                  items: [
                    for (final g in AppConstants.grades)
                      DropdownMenuItem(value: g, child: Text(l10n.gradeN(g))),
                  ],
                  onChanged: (v) => setState(() => _grade = v),
                  validator: (v) => v == null ? l10n.fieldRequired : null,
                ),
                gap,
                DropdownButtonFormField<Region>(
                  initialValue: _region,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l10n.region),
                  items: [
                    for (final r in Region.values)
                      DropdownMenuItem(
                        value: r,
                        child: Text(
                          r.label(l10n),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => _region = v),
                  validator: (v) => v == null ? l10n.fieldRequired : null,
                ),
                gap,
                TextFormField(
                  controller: _school,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(labelText: l10n.school),
                  validator: (v) => Validators.required(v, l10n),
                ),
                const SizedBox(height: AppSpacing.l),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: Text(l10n.register),
                ),
                const SizedBox(height: AppSpacing.s),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(l10n.haveAccount),
                    TextButton(
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go(Routes.login),
                      child: Text(l10n.login),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
