import '../l10n/l10n.dart';

/// Форматирование дат вручную: пакет intl не знает локаль `tg`,
/// поэтому названия месяцев берутся из ARB-файлов.
class DateFormatter {
  const DateFormatter._();

  /// «15 октябри 2026» / «15 октября 2026».
  static String date(DateTime d, AppLocalizations l10n) {
    final months = l10n.monthsGenitive.split(',');
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  /// «15 октябри 2026, 09:05».
  static String dateTime(DateTime d, AppLocalizations l10n) =>
      '${date(d, l10n)}, ${_two(d.hour)}:${_two(d.minute)}';

  /// «15.10.2026» — короткий вид для таблиц и списков.
  static String short(DateTime d) =>
      '${_two(d.day)}.${_two(d.month)}.${d.year}';

  static String _two(int v) => v.toString().padLeft(2, '0');
}
