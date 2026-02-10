import 'dart:async';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/app_database.dart';
import '../../core/di.dart';
import '../../core/repositories/category_repository.dart';
import '../../core/repositories/monthly_payment_repository.dart';
import '../../core/repositories/transaction_repository.dart';
import '../../core/repositories/bank_account_repository.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/monthly_processor.dart';
import 'common_view_model.dart';

class HomeViewModel extends CommonViewModel {
  final TransactionRepository _transactionRepo;
  final BankAccountRepository _accountRepo;
  final CategoryRepository _categoryRepo;
  final MonthlyPaymentRepository _monthlyRepo;
  final MonthlyProcessor _monthlyProcessor;
  final _uuid = const Uuid();

  List<BankAccount> _accounts = [];
  List<Transaction> _transactions = [];
  List<Category> _categories = [];
  List<MonthlyPayment> _monthlyPayments = [];
  BankAccount? _selectedAccount;

  bool _hideChecked = true;

  StreamSubscription? _accountsSub;
  StreamSubscription? _transactionsSub;
  StreamSubscription? _categoriesSub;
  StreamSubscription? _monthlyPaymentsSub;

  HomeViewModel(this._transactionRepo, this._accountRepo, this._categoryRepo, this._monthlyRepo, this._monthlyProcessor);
  
  List<BankAccount> get accounts => _accounts;
  List<Transaction> get transactions => _transactions;
  List<Category> get categories => _categories;
  List<MonthlyPayment> get monthlyPayments => _monthlyPayments;
  BankAccount? get selectedAccount => _selectedAccount;
  bool get hideChecked => _hideChecked;

  double get totalBalance => _accounts.fold(0, (sum, acc) => sum + acc.balance);

  final uid = getIt<IAuthService>().currentUser?.uid ?? "";
  

  Future<void> init() async {
    isLoading = true;
    
    _categoriesSub?.cancel();
    _categoriesSub = _categoryRepo.watchCategories().listen((list) {
      _categories = list;
      notifyListeners();
    });

    _monthlyPaymentsSub?.cancel();
    _monthlyPaymentsSub = _monthlyRepo.watchMonthlyPayments().listen((list) {
      _monthlyPayments = list;
      notifyListeners();
    });
    
    _accountsSub?.cancel();
    _accountsSub = _accountRepo.watchAccounts().listen((accountsList) {
      _accounts = accountsList;

      if (_accounts.isNotEmpty) {
        if (_selectedAccount == null) {
          selectAccount(_accounts.first);
        } else {
          _selectedAccount = _accounts.firstWhere(
                  (a) => a.id == _selectedAccount!.id,
              orElse: () => _accounts.first
          );
        }
      }
      isLoading = false;
      notifyListeners();
    });

    await _monthlyProcessor.checkAndApply();
  }

  Future<void> createAccount({required String name, required double balance}) async {
    final id = _uuid.v4();
    await _accountRepo.createAccount(BankAccountsCompanion.insert(
      id: id,
      name: name,
      balance: Value(balance),
    ));
  }

  Future<void> updateAccount(BankAccount account, {required String name, required double balance}) async {
    await _accountRepo.updateAccount(
      account.id,
      BankAccountsCompanion(
        name: Value(name),
        balance: Value(balance),
      ),
    );
  }

  Future<void> deleteAccount(BankAccount account) async {
    if (_selectedAccount?.id == account.id) {
      _selectedAccount = null;
    }
    await _accountRepo.deleteAccount(account.id);
  }
  
  void selectAccount(BankAccount account) {
    _selectedAccount = account;

    _transactionsSub?.cancel();
    _transactionsSub = _transactionRepo.watchTransactions(account.id).listen((list) {
      _transactions = list;
      notifyListeners();
    });
  }

  Future<void> addTransaction({
    required String title,
    required double amount,
    required String type,
    String? categoryId,
    DateTime? date,
  }) async {
    if (_selectedAccount == null) return;

    final id = _uuid.v4();

    await _transactionRepo.addTransaction(TransactionsCompanion.insert(
      id: id,
      amount: amount,
      type: type,
      accountId: _selectedAccount!.id,
      categoryId: Value(categoryId),
      date: date ?? DateTime.now(),
      note: Value(title),
    ));
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await _transactionRepo.updateTransaction(
        transaction.id,
        TransactionsCompanion(
            amount: Value(transaction.amount),
            type: Value(transaction.type),
            note: Value(transaction.note),
            categoryId: Value(transaction.categoryId),
            date: Value(transaction.date),
            isChecked: Value(transaction.isChecked)
        )
    );
  }
  
  Future<void> toggleCheckTransaction(Transaction transaction) async {
    await _transactionRepo.updateTransaction(
        transaction.id,
        TransactionsCompanion(isChecked: Value(!transaction.isChecked))
    );
  }

  Future<void> deleteTransaction(Transaction transaction) async {
    await _transactionRepo.deleteTransaction(transaction.id);
  }

  Future<void> addTransfer({
    required BankAccount sourceAccount,
    required BankAccount targetAccount,
    required double amount,
    String? title,
  }) async {
    final date = DateTime.now();

    await _transactionRepo.addTransaction(TransactionsCompanion.insert(
      id: _uuid.v4(),
      amount: -amount,
      type: 'transfer',
      accountId: sourceAccount.id,
      date: date,
      note: Value(title ?? "Transfert vers ${targetAccount.name}"),
    ));

    await _transactionRepo.addTransaction(TransactionsCompanion.insert(
      id: _uuid.v4(),
      amount: amount,
      type: 'transfer',
      accountId: targetAccount.id,
      date: date,
      note: Value(title ?? "Transfert de ${sourceAccount.name}"),
    ));
  }

  Future<void> createCategory({
    required String name,
    required int iconCode,
    required int colorValue,
    String? parentId,
  }) async {
    final id = _uuid.v4();
    
    await _categoryRepo.upsertCategories([
      Category(
        id: id,
        name: name,
        iconCode: iconCode,
        colorValue: colorValue,
        userId: uid,
        parentId: parentId,
      )
    ]);
  }

  Future<void> saveCategory({
    String? id,
    required String name,
    required int iconCode,
    required int colorValue,
    String? parentId,
  }) async {
    final finalId = id ?? _uuid.v4();
    final currentUid = getIt<IAuthService>().currentUser?.uid ?? "";

    final companion = CategoriesCompanion(
      id: Value(finalId),
      name: Value(name),
      iconCode: Value(iconCode),
      colorValue: Value(colorValue),
      userId: Value(currentUid),
      parentId: Value(parentId),
    );

    await _categoryRepo.createCategory(companion);
  }

  Future<void> deleteCategory(Category category) async {
    await (_categoryRepo.deleteCategory(category.id));
  }

  Future<void> saveMonthlyPayment({
    String? id,
    required String name,
    required double amount,
    required String type,
    required int dayOfMonth,
    required String accountId,
    String? categoryId,
  }) async {
    final finalId = id ?? _uuid.v4();

    await _monthlyRepo.createMonthlyPayment(MonthlyPaymentsCompanion.insert(
      id: finalId,
      name: name,
      amount: amount,
      type: type,
      dayOfMonth: dayOfMonth,
      accountId: accountId,
      categoryId: Value(categoryId),
    ));
  }

  Future<void> deleteMonthlyPayment(String id) async {
    await _monthlyRepo.deleteMonthlyPayment(id);
  }
  
  void toggleHideChecked() {
    _hideChecked = !_hideChecked;
    notifyListeners();
  }

  List<Transaction> get filteredTransactions {
    if (_hideChecked) {
      return _transactions.where((t) => !t.isChecked).toList();
    }
    return _transactions;
  }

  void clear() {
    _accounts = [];
    _transactions = [];
    _categories = [];
    _selectedAccount = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _accountsSub?.cancel();
    _transactionsSub?.cancel();
    super.dispose();
  }
}