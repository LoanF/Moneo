import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/repositories/category_repository.dart';
import '../../core/repositories/transaction_repository.dart';
import '../../core/services/realtime_service.dart';
import '../../core/utils/error_handler.dart';
import '../../data/models/models.dart';

class MonthlyStats {
  final DateTime month;
  final double income;
  final double expense;
  const MonthlyStats({required this.month, required this.income, required this.expense});
}

class StatsViewModel extends ChangeNotifier {
  final TransactionRepository _transactionRepo;
  final CategoryRepository _categoryRepo;
  final RealtimeService _realtimeService;

  StreamSubscription<RealtimeEvent>? _realtimeSub;
  bool _realtimeSetup = false;

  DateTime _selectedMonth;
  List<Transaction> _allTransactions = [];
  List<Transaction> _monthTransactions = [];
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  StatsViewModel(this._transactionRepo, this._categoryRepo, this._realtimeService)
      : _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime get selectedMonth => _selectedMonth;
  bool get canGoNext => _selectedMonth.isBefore(DateTime(DateTime.now().year, DateTime.now().month));

  Future<void> init() async {
    if (!_realtimeSetup) {
      _realtimeSetup = true;
      _realtimeSub?.cancel();
      _realtimeSub = _realtimeService.events.listen((event) {
        if (event.model == 'Transaction') _reload();
      });
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _categories = await _categoryRepo.fetchCategories();
      _allTransactions = await _transactionRepo.fetchTransactions(limit: 2000);
      _refreshMonthTransactions();
    } catch (e) {
      _errorMessage = handleError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _reload() async {
    try {
      _allTransactions = await _transactionRepo.fetchTransactions(limit: 2000);
      _refreshMonthTransactions();
      notifyListeners();
    } catch (_) {}
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
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
        orElse: () => const Category(
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
        income: monthTxs.where((t) => t.type == 'income').fold(0.0, (s, t) => s + t.amount),
        expense: monthTxs.where((t) => t.type == 'expense').fold(0.0, (s, t) => s + t.amount.abs()),
      ));
    }
    return result;
  }
}
