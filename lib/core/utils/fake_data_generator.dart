import 'dart:math';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';

class FakeDataGenerator {
  final AppDatabase _db;
  final _uuid = const Uuid();
  final _rng = Random();

  FakeDataGenerator(this._db);

  Future<void> generate() async {
    final accounts = await _db.select(_db.bankAccounts).get();
    final categories = await _db.select(_db.categories).get();

    if (accounts.isEmpty) return;

    // Catégories par type (dépenses vs revenus par nom)
    final expenseCategories = categories
        .where((c) => c.parentId == null)
        .where((c) => !['Salaire', 'Épargne'].contains(c.name))
        .toList();
    final subCategories = categories.where((c) => c.parentId != null).toList();
    final incomeCategories =
        categories.where((c) => ['Salaire', 'Épargne'].contains(c.name)).toList();

    final allExpenseCats = [...expenseCategories, ...subCategories];

    final now = DateTime.now();
    final toInsert = <TransactionsCompanion>[];

    for (int monthOffset = 5; monthOffset >= 0; monthOffset--) {
      final month = DateTime(now.year, now.month - monthOffset);
      final daysInMonth =
          DateTime(month.year, month.month + 1, 0).day;
      final isCurrentMonth = monthOffset == 0;
      final maxDay = isCurrentMonth ? now.day : daysInMonth;

      // ── Revenus (1-2 par mois) ──────────────────────────────────────
      final salaire = 1800 + _rng.nextInt(600);
      final salaryAccount = accounts[_rng.nextInt(accounts.length)];
      final salaryCat = incomeCategories.isNotEmpty
          ? incomeCategories.firstWhere((c) => c.name == 'Salaire',
              orElse: () => incomeCategories.first)
          : null;

      toInsert.add(_tx(
        accountId: salaryAccount.id,
        amount: salaire.toDouble(),
        type: 'income',
        note: 'Salaire ${_monthName(month.month)}',
        categoryId: salaryCat?.id,
        date: DateTime(month.year, month.month, 1 + _rng.nextInt(3)),
      ));

      if (_rng.nextBool()) {
        final extraAmount = 50 + _rng.nextInt(300);
        toInsert.add(_tx(
          accountId: salaryAccount.id,
          amount: extraAmount.toDouble(),
          type: 'income',
          note: _pick(_extraIncomes),
          categoryId: salaryCat?.id,
          date: DateTime(month.year, month.month, 5 + _rng.nextInt(20)),
        ));
      }

      // ── Dépenses (10-18 par mois) ───────────────────────────────────
      final nbExpenses = 10 + _rng.nextInt(9);
      for (int i = 0; i < nbExpenses; i++) {
        final account = accounts[_rng.nextInt(accounts.length)];
        final day = 1 + _rng.nextInt(maxDay);
        final catEntry = allExpenseCats.isNotEmpty
            ? allExpenseCats[_rng.nextInt(allExpenseCats.length)]
            : null;

        final entry = _expenseForCategory(catEntry?.name ?? '');
        toInsert.add(_tx(
          accountId: account.id,
          amount: -entry.amount,
          type: 'expense',
          note: entry.label,
          categoryId: catEntry?.id,
          date: DateTime(month.year, month.month, day),
        ));
      }
    }

    // Insertion en batch (local seulement, sans API)
    await _db.batch((batch) {
      batch.insertAll(_db.transactions, toInsert, mode: InsertMode.insertOrIgnore);
    });
  }

  Future<void> clear() async {
    await _db.delete(_db.transactions).go();
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  TransactionsCompanion _tx({
    required String accountId,
    required double amount,
    required String type,
    required String note,
    required DateTime date,
    String? categoryId,
  }) {
    return TransactionsCompanion.insert(
      id: _uuid.v4(),
      amount: amount,
      type: type,
      accountId: accountId,
      note: Value(note),
      categoryId: Value(categoryId),
      date: date,
    );
  }

  _ExpenseEntry _expenseForCategory(String categoryName) {
    switch (categoryName) {
      case 'Alimentation':
        return _ExpenseEntry(_pick(_alimentation), 20 + _rng.nextDouble() * 80);
      case 'Courses':
        return _ExpenseEntry(_pick(_courses), 15 + _rng.nextDouble() * 85);
      case 'Restaurants':
        return _ExpenseEntry(_pick(_restaurants), 12 + _rng.nextDouble() * 55);
      case 'Transport':
        return _ExpenseEntry(_pick(_transport), 10 + _rng.nextDouble() * 60);
      case 'Carburant':
        return _ExpenseEntry('Carburant', 40 + _rng.nextDouble() * 60);
      case 'Voyage':
        return _ExpenseEntry(_pick(_voyage), 80 + _rng.nextDouble() * 300);
      case 'Logement':
        return _ExpenseEntry(_pick(_logement), 100 + _rng.nextDouble() * 700);
      case 'Santé':
        return _ExpenseEntry(_pick(_sante), 15 + _rng.nextDouble() * 80);
      case 'Shopping':
        return _ExpenseEntry(_pick(_shopping), 20 + _rng.nextDouble() * 150);
      case 'Vêtements':
        return _ExpenseEntry(_pick(_vetements), 25 + _rng.nextDouble() * 120);
      case 'Loisirs':
        return _ExpenseEntry(_pick(_loisirs), 10 + _rng.nextDouble() * 80);
      case 'Sport':
        return _ExpenseEntry(_pick(_sport), 15 + _rng.nextDouble() * 60);
      default:
        return _ExpenseEntry(_pick(_divers), 10 + _rng.nextDouble() * 100);
    }
  }

  T _pick<T>(List<T> list) => list[_rng.nextInt(list.length)];

  String _monthName(int month) {
    const names = [
      '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
    ];
    return names[month];
  }

  // ─── Listes de libellés ────────────────────────────────────────────────────

  static const _alimentation = ['Supermarché', 'Boulangerie', 'Marché', 'Épicerie'];
  static const _courses = ['Carrefour', 'Leclerc', 'Lidl', 'Auchan', 'Intermarché', 'Monoprix'];
  static const _restaurants = ['Restaurant midi', 'Pizza', 'Sushi', 'Brasserie', 'Fast food', 'Kebab'];
  static const _transport = ['Ticket de métro', 'Pass Navigo', 'Uber', 'Taxi', 'Bus'];
  static const _voyage = ['Train', 'Avion', 'Hôtel', 'Airbnb', 'Location voiture'];
  static const _logement = ['Loyer', 'Électricité', 'Internet', 'Eau', 'Assurance habitation'];
  static const _sante = ['Pharmacie', 'Médecin', 'Dentiste', 'Mutuelle', 'Opticien'];
  static const _shopping = ['Amazon', 'Fnac', 'Ikea', 'Décathlon', 'Zara'];
  static const _vetements = ['H&M', 'Zara', 'Uniqlo', 'Nike', 'Adidas'];
  static const _loisirs = ['Cinéma', 'Netflix', 'Spotify', 'Concert', 'Musée', 'Jeu vidéo'];
  static const _sport = ['Salle de sport', 'Cours de sport', 'Équipement sportif'];
  static const _divers = ['Achat divers', 'Abonnement', 'Frais bancaires', 'Cadeau'];
  static const _extraIncomes = ['Prime', 'Remboursement', 'Vente', 'Freelance', 'Allocation'];
}

class _ExpenseEntry {
  final String label;
  final double amount;
  const _ExpenseEntry(this.label, this.amount);
}
