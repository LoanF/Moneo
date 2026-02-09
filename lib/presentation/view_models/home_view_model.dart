import 'dart:async';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/app_database.dart';
import '../../core/repositories/category_repository.dart';
import '../../core/repositories/transaction_repository.dart';
import '../../core/repositories/bank_account_repository.dart';
import 'common_view_model.dart';

class HomeViewModel extends CommonViewModel {
  final TransactionRepository _transactionRepo;
  final BankAccountRepository _accountRepo;
  final CategoryRepository _categoryRepo;
  final _uuid = const Uuid();

  List<BankAccount> _accounts = [];
  List<Transaction> _transactions = [];
  List<Category> _categories = [];
  BankAccount? _selectedAccount;

  bool _hideChecked = true;

  StreamSubscription? _accountsSub;
  StreamSubscription? _transactionsSub;
  StreamSubscription? _categoriesSub;

  HomeViewModel(this._transactionRepo, this._accountRepo, this._categoryRepo);
  
  List<BankAccount> get accounts => _accounts;
  List<Transaction> get transactions => _transactions;
  List<Category> get categories => _categories;
  BankAccount? get selectedAccount => _selectedAccount;
  bool get hideChecked => _hideChecked;

  double get totalBalance => _accounts.fold(0, (sum, acc) => sum + acc.balance);

  Future<void> init() async {
    isLoading = true;

    _categoriesSub?.cancel();
    _categoriesSub = _categoryRepo.watchCategories().listen((list) {
      _categories = list;
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

  @override
  void dispose() {
    _accountsSub?.cancel();
    _transactionsSub?.cancel();
    super.dispose();
  }
}