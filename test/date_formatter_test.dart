import 'package:flutter_test/flutter_test.dart';
import 'package:sanjish/core/l10n/l10n.dart';
import 'package:sanjish/core/utils/date_formatter.dart';

void main() {
  final date = DateTime(2026, 10, 5, 9, 7);

  test('Дата на таджикском — месяцы из ARB, без intl', () {
    final l10n = lookupAppLocalizations(kTajik);
    expect(DateFormatter.date(date, l10n), '5 октябри 2026');
    expect(DateFormatter.dateTime(date, l10n), '5 октябри 2026, 09:07');
  });

  test('Дата на русском', () {
    final l10n = lookupAppLocalizations(kRussian);
    expect(DateFormatter.date(date, l10n), '5 октября 2026');
  });

  test('В обоих языках ровно 12 месяцев', () {
    for (final locale in kSupportedLocales) {
      final months = lookupAppLocalizations(locale).monthsGenitive.split(',');
      expect(months, hasLength(12), reason: locale.languageCode);
    }
  });

  test('Короткий формат', () {
    expect(DateFormatter.short(date), '05.10.2026');
  });
}
