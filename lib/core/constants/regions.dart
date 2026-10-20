import '../l10n/l10n.dart';

/// Регионы Таджикистана. В Firestore хранится только код (`users.region`).
enum Region {
  dushanbe,
  sughd,
  khatlon,
  gbao,
  nrs;

  /// Код региона для Firestore.
  String get code => name;

  static Region? fromCode(String? code) {
    for (final r in values) {
      if (r.code == code) return r;
    }
    return null;
  }

  /// Название региона на текущем языке интерфейса.
  String label(AppLocalizations l10n) => switch (this) {
    Region.dushanbe => l10n.regionDushanbe,
    Region.sughd => l10n.regionSughd,
    Region.khatlon => l10n.regionKhatlon,
    Region.gbao => l10n.regionGbao,
    Region.nrs => l10n.regionNrs,
  };
}
