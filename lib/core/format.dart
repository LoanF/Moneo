import 'package:intl/intl.dart';

/// Mise en forme des montants et des dates, en français.
abstract final class Fmt {
  static final _money = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: '€',
    decimalDigits: 2,
  );
  static final _plain = NumberFormat.decimalPatternDigits(
    locale: 'fr_FR',
    decimalDigits: 2,
  );
  static final _compact = NumberFormat.compactCurrency(
    locale: 'fr_FR',
    symbol: '€',
    decimalDigits: 0,
  );
  static final _iso = DateFormat('yyyy-MM-dd');
  static final _dayMonth = DateFormat('d MMM', 'fr_FR');
  static final _full = DateFormat('EEEE d MMMM', 'fr_FR');
  static final _fullYear = DateFormat('d MMMM y', 'fr_FR');
  static final _month = DateFormat('MMMM y', 'fr_FR');
  static final _monthShort = DateFormat('MMM', 'fr_FR');

  /// `−68,01 €`. Le signe moins typographique se lit mieux que le trait d'union.
  static String money(double value) =>
      _money.format(value).replaceFirst('-', '−');

  /// `+1 500,00 €` pour une entrée, `−68,01 €` pour une sortie.
  static String signed(double value) =>
      value > 0 ? '+${_money.format(value)}' : money(value);

  /// `68,01` sans devise (colonnes débit / crédit).
  static String plain(double value) => _plain.format(value);

  static String compact(double value) =>
      _compact.format(value).replaceFirst('-', '−');

  static String iso(DateTime date) => _iso.format(date);
  static String today() => iso(DateTime.now());
  static DateTime parse(String iso) => DateTime.parse(iso);

  /// `Aujourd’hui`, `Hier`, sinon `jeudi 14 novembre` (avec l'année si elle diffère).
  static String dayLabel(String iso) {
    final date = parse(iso);
    final now = DateTime.now();
    final diff = DateTime(
      date.year,
      date.month,
      date.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff == 0) return 'Aujourd’hui';
    if (diff == -1) return 'Hier';
    if (diff == 1) return 'Demain';
    final label = date.year == now.year
        ? _full.format(date)
        : _fullYear.format(date);
    return label[0].toUpperCase() + label.substring(1);
  }

  static String shortDate(String iso) => _dayMonth.format(parse(iso));
  static String longDate(String iso) => _fullYear.format(parse(iso));

  /// `Novembre 2026` à partir de `2026-11` ou d'une date.
  static String month(String isoOrPeriod) {
    final label = _month.format(
      DateTime.parse(isoOrPeriod.length == 7 ? '$isoOrPeriod-01' : isoOrPeriod),
    );
    return label[0].toUpperCase() + label.substring(1);
  }

  static String monthShort(String period) =>
      _monthShort.format(DateTime.parse('$period-01')).replaceAll('.', '');

  static const monthNames = [
    'Janvier',
    'Février',
    'Mars',
    'Avril',
    'Mai',
    'Juin',
    'Juillet',
    'Août',
    'Septembre',
    'Octobre',
    'Novembre',
    'Décembre',
  ];

  /// Lit un montant saisi à la française (`1 234,56`) ou à l'anglaise (`1234.56`).
  static double? parseAmount(String input) {
    final cleaned = input
        .replaceAll(RegExp(r'[\s  €]'), '')
        .replaceAll(',', '.');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  /// Saisie rapide de date, comme dans le classeur : `14` → le 14 du mois courant,
  /// `14/3` → 14 mars de l'année courante, `14/03/25` ou `14/03/2025` → date complète.
  /// Renvoie `null` si la date n'existe pas (31 juin).
  static DateTime? parseQuickDate(String input, {DateTime? now}) {
    final ref = now ?? DateTime.now();
    final parts = input
        .trim()
        .split(RegExp(r'[/.\-\s]+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty || parts.length > 3) return null;
    final numbers = parts.map(int.tryParse).toList();
    if (numbers.contains(null)) return null;
    final day = numbers[0]!;
    final month = numbers.length > 1 ? numbers[1]! : ref.month;
    var year = numbers.length > 2 ? numbers[2]! : ref.year;
    if (year < 100) year += 2000;
    final date = DateTime(year, month, day);
    return date.year == year && date.month == month && date.day == day
        ? date
        : null;
  }

  static String relative(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'À l’instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} j';
    return _dayMonth.format(date);
  }
}
