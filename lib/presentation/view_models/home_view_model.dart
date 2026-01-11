import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/user_service.dart';
import '../../data/models/account_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_model.dart';
import 'common_view_model.dart';

class HomeViewModel extends CommonViewModel {
  final IAppUserService _userService;

  List<Account> _accounts = [];
  List<TransactionModel> _transactions = [];
  List<CategoryModel> _categories = [];
  Account? _selectedAccount;
  
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _hideChecked = true;
  
  StreamSubscription? _accountsSub;
  StreamSubscription? _categoriesSub;

  HomeViewModel(this._userService);

  List<Account> get accounts => _accounts;
  List<TransactionModel> get transactions => _transactions;
  List<CategoryModel> get categories => _categories;
  Account? get selectedAccount => _selectedAccount;
  bool get hideChecked => _hideChecked;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  
  double get totalBalance => _accounts.fold(0, (sumaccount, acc) => sumaccount + acc.currentBalance);

  Future<void> init(String uid) async {
    if (uid.isEmpty) return;
    
    isLoading = true;
    
    try {
      await _userService.checkAndApplyMonthlyOperations(uid);
    } catch (e) {
      errorMessage = "Erreur lors de l'application des mensualités";
    }

    _accountsSub?.cancel();
    _categoriesSub?.cancel();

    _accountsSub = _userService.getAccountsStream(uid).listen((accountsList) {
      _accounts = accountsList;
      if (_accounts.isNotEmpty) {
        if (_selectedAccount == null) {
          selectAccount(uid, _accounts.first);
        } else {
          _selectedAccount = _accounts.firstWhere((a) => a.id == _selectedAccount!.id);
          isLoading = false;
          notifyListeners();
        }
      } else {
        isLoading = false;
        notifyListeners();
      }
    });

    _categoriesSub = _userService.getCategoriesStream(uid).listen((cats) {
      _categories = cats;
      notifyListeners();
    });
  }

  Future<void> selectAccount(String uid, Account account) async {
    _selectedAccount = account;
    _transactions = [];
    _lastDocument = null;
    _hasMore = true;
    notifyListeners();
    await loadTransactions(uid);
  }

  Future<void> loadTransactions(String uid) async {
    if (!_hasMore || _isLoadingMore || _selectedAccount == null) return;

    if (_transactions.isEmpty && isLoading && _lastDocument != null) return;

    if (_transactions.isEmpty) {
      isLoading = true;
    } else {
      _isLoadingMore = true;
    }
    notifyListeners();

    try {
      final snapshot = await _userService.getTransactionsPaginated(
        uid: uid,
        accountId: _selectedAccount!.id,
        limit: 20,
        startAfter: _lastDocument,
        hideChecked: _hideChecked,
      );

      if (snapshot.docs.length < 20) {
        _hasMore = false;
      }

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        final newTransactions = snapshot.docs
            .map((doc) => TransactionModel.fromJson(doc.data()))
            .toList();
        
        final existingIds = _transactions.map((t) => t.id).toSet();
        final uniqueNewOnes = newTransactions.where((t) => !existingIds.contains(t.id)).toList();

        _transactions.addAll(uniqueNewOnes);
      }
    } catch (e) {
      errorMessage = "Erreur de chargement : $e";
    } finally {
      isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> toggleHideChecked(String uid) async {
    _hideChecked = !_hideChecked;
    _transactions = [];
    _lastDocument = null;
    _hasMore = true;
    await loadTransactions(uid);
  }

  Future<void> toggleCheckTransaction(String uid, String accountId, TransactionModel transaction) async {
    try {
      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        final newStatus = !transaction.isChecked;

        await FirebaseFirestore.instance
            .collection('users').doc(uid)
            .collection('accounts').doc(accountId)
            .collection('transactions').doc(transaction.id)
            .update({'isChecked': newStatus});

        if (_hideChecked && newStatus) {
          _transactions.removeAt(index);
        } else {
          _transactions[index].isChecked = newStatus;
        }
        notifyListeners();
      }
    } catch (e) {
      errorMessage = "Erreur lors du pointage : $e";
    }
  }

  Future<void> deleteTransaction(String uid, String accountId, TransactionModel transaction) async {
    try {
      _transactions.removeWhere((t) => t.id == transaction.id);
      notifyListeners();
      
      final firestore = FirebaseFirestore.instance;
      final accountRef = firestore.collection('users').doc(uid).collection('accounts').doc(accountId);

      await firestore.runTransaction((dbTransaction) async {
        final snapshot = await dbTransaction.get(accountRef);
        if (snapshot.exists) {
          double currentBalance = (snapshot.data()?['currentBalance'] ?? 0.0).toDouble();
          dbTransaction.update(accountRef, {'currentBalance': currentBalance - transaction.amount});
        }
        dbTransaction.delete(accountRef.collection('transactions').doc(transaction.id));
      });
    } catch (e) {
      errorMessage = "Erreur de suppression : $e";
      await loadTransactions(uid);
    }
  }

  Future<void> addTransaction({
    required String uid,
    required String accountId,
    required String title,
    required double amount,
    required String category,
    DateTime? date,
  }) async {
    try {
      final transactionRef = FirebaseFirestore.instance
          .collection('users').doc(uid)
          .collection('accounts').doc(accountId)
          .collection('transactions').doc();

      final newTransaction = TransactionModel(
        id: transactionRef.id,
        title: title,
        amount: amount,
        category: category,
        accountId: accountId,
        date: date ?? DateTime.now(),
      );

      await transactionRef.set(newTransaction.toJson());

      if (_selectedAccount?.id == accountId) {
        _transactions.insert(0, newTransaction);
        notifyListeners();
      }

      final accountRef = FirebaseFirestore.instance
          .collection('users').doc(uid)
          .collection('accounts').doc(accountId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(accountRef);
        if (snapshot.exists) {
          double currentBalance = (snapshot.data()?['currentBalance'] ?? 0.0).toDouble();
          transaction.update(accountRef, {'currentBalance': currentBalance + amount});
        }
      });
    } catch (e) {
      errorMessage = "Erreur lors de l'ajout : $e";
      notifyListeners();
    }
  }

  Future<void> addTransfer({
    required String uid,
    required String sourceAccountId,
    required String targetAccountId,
    required String title,
    required double amount,
    DateTime? date,
  }) async {
    isLoading = true;
    try {
      final firestore = FirebaseFirestore.instance;
      final dateToSave = date ?? DateTime.now();
      
      final sourceAccRef = firestore.collection('users').doc(uid).collection('accounts').doc(sourceAccountId);
      final targetAccRef = firestore.collection('users').doc(uid).collection('accounts').doc(targetAccountId);
      
      await firestore.runTransaction((transaction) async {
        final sourceSnap = await transaction.get(sourceAccRef);
        final targetSnap = await transaction.get(targetAccRef);

        if (!sourceSnap.exists || !targetSnap.exists) throw Exception("Comptes introuvables");

        final sourceName = sourceSnap.data()?['name'] ?? "Source";
        final targetName = targetSnap.data()?['name'] ?? "Dest.";

        final sourceTransRef = sourceAccRef.collection('transactions').doc();
        final targetTransRef = targetAccRef.collection('transactions').doc();
        
        final sourceTrans = TransactionModel(
          id: sourceTransRef.id,
          title: "Transfert vers $targetName ${title != 'Transfert' ? '- $title' : ''}",
          amount: -amount,
          accountId: sourceAccountId,
          date: dateToSave,
          category: 'Transfert',
        );

        final targetTrans = TransactionModel(
          id: targetTransRef.id,
          title: "Transfert de $sourceName ${title != 'Transfert' ? '- $title' : ''}",
          amount: amount,
          accountId: targetAccountId,
          date: dateToSave,
          category: 'Transfert',
        );
        
        transaction.set(sourceTransRef, sourceTrans.toJson());
        transaction.set(targetTransRef, targetTrans.toJson());

        transaction.update(sourceAccRef, {'currentBalance': (sourceSnap.data()?['currentBalance'] ?? 0.0) - amount});
        transaction.update(targetAccRef, {'currentBalance': (targetSnap.data()?['currentBalance'] ?? 0.0) + amount});

        if (_selectedAccount?.id == sourceAccountId) {
          _transactions.insert(0, sourceTrans);
        } else if (_selectedAccount?.id == targetAccountId) {
          _transactions.insert(0, targetTrans);
        }
      });
    } catch (e) {
      errorMessage = "Erreur lors du transfert : $e";
    } finally {
      isLoading = false;
    }
  }

  List<TransactionModel> get filteredTransactions {
    if (_hideChecked) {
      return _transactions.where((t) => !t.isChecked).toList();
    }
    return _transactions;
  }

  void clear() {
    _accountsSub?.cancel();
    _categoriesSub?.cancel();
    _accountsSub = null;
    _categoriesSub = null;
    _accounts = [];
    _transactions = [];
    _categories = [];
    _selectedAccount = null;
    _lastDocument = null;
    _hasMore = true;
    _hideChecked = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _accountsSub?.cancel();
    _categoriesSub?.cancel();
    super.dispose();
  }
}