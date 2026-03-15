import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import '../../core/database/app_database.dart';

class MonthlyStats {
  final DateTime month;
  final double income;
  final double expense;
  const MonthlyStats({required this.month, required this.income, required this.expense});
}

class StatsViewModel extends ChangeNotifier {
  final AppDatabase _db;

  DateTime _selectedMonth;
  List<Transaction> _allTransactions = [];
  List<Transaction> _monthTransactions = [];
  List<Category> _categories = [];
  bool _isLoading = false;

  StatsViewModel(this._db)
      : _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  bool get isLoading => _isLoading;
  DateTime get selectedMonth => _selectedMonth;
  bool get canGoNext => _selectedMonth.isBefore(DateTime(DateTime.now().year, DateTime.now().month));

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    _categories = await _db.select(_db.categories).get();

    // Charge 8 mois de données pour couvrir le graphique 6 mois + navigation
    final start = DateTime(_selectedMonth.year, _selectedMonth.month - 7);
    _allTransactions = await (_db.select(_db.transactions)
          ..where((t) => t.date.isBiggerOrEqualValue(start))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();

    _refreshMonthTransactions();
    _isLoading = false;
    notifyListeners();
  }

  void _refreshMonthTransactions() {
    final start = DateTime(_selectedMonth.year, _selectedMonth.month);
    final end = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    _monthTransactions = _allTransactions
        .where((t) => !t.date.isBefore(start) && t.date.isBefore(end))
        .toList();
  }

  void previousMonth() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    init();
  }

  void nextMonth() {
    if (!canGoNext) return;
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    _refreshMonthTransactions();
    notifyListeners();
  }

  double get totalIncome => _monthTransactions
      .where((t) => t.type == 'income')
      .fold(0.0, (s, t) => s + t.amount);

  double get totalExpense => _monthTransactions
      .where((t) => t.type == 'expense')
      .fold(0.0, (s, t) => s + t.amount.abs());

  double get netBalance => totalIncome - totalExpense;

  double get savingsRate => totalIncome > 0
      ? ((totalIncome - totalExpense) / totalIncome * 100).clamp(0.0, 100.0)
      : 0.0;

  int get transactionCount =>
      _monthTransactions.where((t) => t.type != 'transfer').length;

  double get avgExpense {
    final expenses = _monthTransactions.where((t) => t.type == 'expense').toList();
    if (expenses.isEmpty) return 0;
    return expenses.fold(0.0, (s, t) => s + t.amount.abs()) / expenses.length;
  }

  Transaction? get biggestExpense {
    final expenses = _monthTransactions.where((t) => t.type == 'expense').toList();
    if (expenses.isEmpty) return null;
    return expenses.reduce((a, b) => a.amount.abs() > b.amount.abs() ? a : b);
  }

  List<MapEntry<Category, double>> get categoryBreakdown {
    final Map<String, double> byCategory = {};
    for (final t in _monthTransactions.where((t) => t.type == 'expense')) {
      final catId = t.categoryId ?? '__other__';
      byCategory[catId] = (byCategory[catId] ?? 0) + t.amount.abs();
    }

    final result = <MapEntry<Category, double>>[];
    for (final entry in byCategory.entries) {
      final cat = _categories.firstWhere(
        (c) => c.id == entry.key,
        orElse: () => Category(
          id: '__other__',
          name: 'Autre',
          iconCode: 'help_outline',
          colorValue: 0xFF8A8A8A,
          userId: '',
        ),
      );
      result.add(MapEntry(cat, entry.value));
    }
    result.sort((a, b) => b.value.compareTo(a.value));
    return result.take(5).toList();
  }

  List<MonthlyStats> get last6MonthsStats {
    final result = <MonthlyStats>[];
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(_selectedMonth.year, _selectedMonth.month - i);
      final start = DateTime(month.year, month.month);
      final end = DateTime(month.year, month.month + 1);
      final monthTxs = _allTransactions
          .where((t) => !t.date.isBefore(start) && t.date.isBefore(end))
          .toList();
      result.add(MonthlyStats(
        month: month,
        income: monthTxs
            .where((t) => t.type == 'income')
            .fold(0.0, (s, t) => s + t.amount),
        expense: monthTxs
            .where((t) => t.type == 'expense')
            .fold(0.0, (s, t) => s + t.amount.abs()),
      ));
    }
    return result;
  }
}
