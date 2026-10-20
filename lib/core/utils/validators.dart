import '../constants/app_constants.dart';
import '../l10n/l10n.dart';

/// Проверки полей форм. Возвращают текст ошибки или null.
class Validators {
  const Validators._();

  static final _emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? required(String? v, AppLocalizations l10n) =>
      (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null;

  static String? email(String? v, AppLocalizations l10n) {
    if (v == null || v.trim().isEmpty) return l10n.fieldRequired;
    return _emailRegExp.hasMatch(v.trim()) ? null : l10n.invalidEmail;
  }

  static String? password(String? v, AppLocalizations l10n) {
    if (v == null || v.isEmpty) return l10n.fieldRequired;
    return v.length < AppConstants.minPasswordLength
        ? l10n.passwordTooShort
        : null;
  }
}
