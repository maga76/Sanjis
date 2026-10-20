import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/regions.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/validators.dart';
import '../../auth/application/auth_service.dart';

/// Редактирование профиля: имя, фамилия, класс, регион, школа.
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _account = ref.read(authProvider);
  late final _firstName = TextEditingController(text: _account?.firstName);
  late final _lastName = TextEditingController(text: _account?.lastName);
  late final _school = TextEditingController(text: _account?.school);
  late int? _grade = _account?.grade;
  late Region? _region = Region.fromCode(_account?.region);

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _school.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authProvider.notifier)
        .updateProfile(
          firstName: _firstName.text,
          lastName: _lastName.text,
          school: _school.text,
          region: _region!.code,
          grade: _grade!,
        );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const gap = SizedBox(height: AppSpacing.m);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.editProfile)),
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
                  decoration: InputDecoration(labelText: l10n.firstName),
                  validator: (v) => Validators.required(v, l10n),
                ),
                gap,
                TextFormField(
                  controller: _lastName,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(labelText: l10n.lastName),
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
                  decoration: InputDecoration(labelText: l10n.school),
                ),
                const SizedBox(height: AppSpacing.l),
                FilledButton(onPressed: _save, child: Text(l10n.save)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
