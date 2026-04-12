import 'package:flutter/foundation.dart' hide Category;
import 'package:uuid/uuid.dart';
import '../../core/di.dart';
import '../../core/repositories/bank_account_repository.dart';
import '../../core/repositories/category_repository.dart';
import '../../core/repositories/monthly_payment_repository.dart';
import '../../core/repositories/transaction_repository.dart';
import '../../core/services/auth_service.dart';
import '../../data/models/models.dart';
import 'common_view_model.dart';

class HomeViewModel extends CommonViewModel {
  final TransactionRepository _transactionRepo;
  final BankAccountRepository _accountRepo;
  final CategoryRepository _categoryRepo;
  final MonthlyPaymentRepository _monthlyRepo;
  final _uuid = const Uuid();

  List<BankAccount> _accounts = [];
  List<Transaction> _transactions = [];
  List<Category> _categories = [];
  List<MonthlyPayment> _monthlyPayments = [];
  BankAccount? _selectedAccount;
  bool _hideChecked = true;

  HomeViewModel(this._transactionRepo, this._accountRepo, this._categoryRepo, this._monthlyRepo);

  List<BankAccount> get accounts => _accounts;
  List<Transaction> get transactions => _transactions;
  List<Category> get categories => _categories;
  List<MonthlyPayment> get monthlyPayments => _monthlyPayments;
  BankAccount? get selectedAccount => _selectedAccount;
  bool get hideChecked => _hideChecked;

  String get uid => getIt<IAuthService>().currentUser?.uid ?? '';

  double get totalBalance => _accounts.fold(0, (sum, acc) => sum + acc.balance);

  List<Transaction> get filteredTransactions {
    if (_hideChecked) return _transactions.where((t) => !t.isChecked).toList();
    return _transactions;
  }

  Future<void> init() async {
    isLoading = true;
    notifyListeners();
    try {
      await _loadAll();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadAll() async {
    final results = await Future.wait([
      _accountRepo.fetchAccounts(),
      _categoryRepo.fetchCategories(),
      _monthlyRepo.fetchMonthlyPayments(),
    ]);
    _accounts = results[0] as List<BankAccount>;
    _categories = results[1] as List<Category>;
    _monthlyPayments = results[2] as List<MonthlyPayment>;

    if (_accounts.isNotEmpty) {
      final id = _selectedAccount?.id;
      _selectedAccount = id != null
          ? _accounts.firstWhere((a) => a.id == id, orElse: () => _accounts.first)
          : _accounts.first;
      await _loadTransactions();
    } else {
      _selectedAccount = null;
      _transactions = [];
    }
  }

  Future<void> _loadTransactions() async {
    if (_selectedAccount == null) return;
    _transactions = await _transactionRepo.fetchTransactions(accountId: _selectedAccount!.id);
  }

  Future<void> _refreshAccounts() async {
    _accounts = await _accountRepo.fetchAccounts();
    if (_selectedAccount != null) {
      _selectedAccount = _accounts.firstWhere(
        (a) => a.id == _selectedAccount!.id,
        orElse: () => _accounts.isNotEmpty ? _accounts.first : _selectedAccount!,
      );
    }
  }

  void selectAccount(BankAccount account) {
    _selectedAccount = account;
    _transactions = [];
    notifyListeners();
    _loadTransactions().then((_) => notifyListeners());
  }

  // ── Transactions ──────────────────────────────────────────────────────────

  Future<void> addTransaction({
    required String title,
    required double amount,
    required String type,
    String? categoryId,
    DateTime? date,
  }) async {
    if (_selectedAccount == null) return;
    final t = Transaction(
      id: _uuid.v4(),
      amount: amount,
      type: type,
      accountId: _selectedAccount!.id,
      categoryId: categoryId,
      date: date ?? DateTime.now(),
      note: title,
    );
    await _transactionRepo.addTransaction(t);
    await Future.wait([_loadTransactions(), _refreshAccounts()]);
    notifyListeners();
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await _transactionRepo.updateTransaction(transaction);
    await Future.wait([_loadTransactions(), _refreshAccounts()]);
    notifyListeners();
  }

  Future<void> toggleCheckTransaction(Transaction transaction) async {
    await _transactionRepo.updateTransaction(transaction.copyWith(isChecked: !transaction.isChecked));
    await _loadTransactions();
    notifyListeners();
  }

  Future<void> deleteTransaction(Transaction transaction) async {
    await _transactionRepo.deleteTransaction(transaction.id);
    await Future.wait([_loadTransactions(), _refreshAccounts()]);
    notifyListeners();
  }

  Future<void> addTransfer({
    required BankAccount sourceAccount,
    required BankAccount targetAccount,
    required double amount,
    String? title,
  }) async {
    final date = DateTime.now();
    final note = title ?? 'Transfert';

    await Future.wait([
      _transactionRepo.addTransaction(Transaction(
        id: _uuid.v4(),
        amount: -amount,
        type: 'transfer',
        accountId: sourceAccount.id,
        date: date,
        note: '$note → ${targetAccount.name}',
      )),
      _transactionRepo.addTransaction(Transaction(
        id: _uuid.v4(),
        amount: amount,
        type: 'transfer',
        accountId: targetAccount.id,
        date: date,
        note: '$note ← ${sourceAccount.name}',
      )),
    ]);
    await Future.wait([_loadTransactions(), _refreshAccounts()]);
    notifyListeners();
  }

  // ── Accounts ──────────────────────────────────────────────────────────────

  Future<void> createAccount({required String name, required double balance}) async {
    await _accountRepo.createAccount(id: _uuid.v4(), name: name, balance: balance);
    await _refreshAccounts();
    notifyListeners();
  }

  Future<void> updateAccount(BankAccount account, {required String name, required double balance}) async {
    await _accountRepo.updateAccount(account.id, name: name, balance: balance);
    await _refreshAccounts();
    notifyListeners();
  }

  Future<void> deleteAccount(BankAccount account) async {
    await _accountRepo.deleteAccount(account.id);
    if (_selectedAccount?.id == account.id) _selectedAccount = null;
    await _loadAll();
    notifyListeners();
  }

  // ── Categories ────────────────────────────────────────────────────────────

  Future<void> saveCategory({
    String? id,
    required String name,
    required String iconCode,
    required int colorValue,
    String? parentId,
  }) async {
    final category = Category(
      id: id ?? _uuid.v4(),
      name: name,
      iconCode: iconCode,
      colorValue: colorValue,
      userId: uid,
      parentId: parentId,
    );
    await _categoryRepo.createCategory(category);
    _categories = await _categoryRepo.fetchCategories();
    notifyListeners();
  }

  Future<void> deleteCategory(Category category) async {
    await _categoryRepo.deleteCategory(category.id);
    _categories = await _categoryRepo.fetchCategories();
    notifyListeners();
  }

  // ── Monthly Payments ──────────────────────────────────────────────────────

  Future<void> saveMonthlyPayment({
    String? id,
    required String name,
    required double amount,
    required String type,
    required int dayOfMonth,
    required String accountId,
    String? categoryId,
  }) async {
    await _monthlyRepo.createMonthlyPayment(
      id: id ?? _uuid.v4(),
      name: name,
      amount: amount,
      type: type,
      dayOfMonth: dayOfMonth,
      accountId: accountId,
      categoryId: categoryId,
    );
    _monthlyPayments = await _monthlyRepo.fetchMonthlyPayments();
    notifyListeners();
  }

  Future<void> deleteMonthlyPayment(String id) async {
    await _monthlyRepo.deleteMonthlyPayment(id);
    _monthlyPayments = await _monthlyRepo.fetchMonthlyPayments();
    notifyListeners();
  }

  void toggleHideChecked() {
    _hideChecked = !_hideChecked;
    notifyListeners();
  }

  void clear() {
    _accounts = [];
    _transactions = [];
    _categories = [];
    _monthlyPayments = [];
    _selectedAccount = null;
    notifyListeners();
  }
}
