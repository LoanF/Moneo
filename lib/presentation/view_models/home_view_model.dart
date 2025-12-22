import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/user_service.dart';
import '../../data/models/account_model.dart';
import '../../data/models/transaction_model.dart';
import 'common_view_model.dart';

class HomeViewModel extends CommonViewModel {
  final IAppUserService _userService;

  List<Account> _accounts = [];
  List<TransactionModel> _transactions = [];
  Account? _selectedAccount;

  StreamSubscription? _accountsSub;
  StreamSubscription? _transactionsSub;

  HomeViewModel(this._userService);

  List<Account> get accounts => _accounts;
  List<TransactionModel> get transactions => _transactions;
  Account? get selectedAccount => _selectedAccount;

  double get totalBalance => _accounts.fold(0, (sumaccount, acc) => sumaccount + acc.currentBalance);

  void init(String uid) {
    isLoading = true;
    _accountsSub?.cancel();

    _accountsSub = _userService.getAccountsStream(uid).listen((accountsList) {
      _accounts = accountsList;

      if (_selectedAccount == null && _accounts.isNotEmpty) {
        selectAccount(uid, _accounts.first);
      } else if (_selectedAccount != null) {
        _selectedAccount = _accounts.firstWhere((a) => a.id == _selectedAccount!.id);
      }

      isLoading = false;
    });
  }

  void selectAccount(String uid, Account account) {
    _selectedAccount = account;
    notifyListeners();

    _transactionsSub?.cancel();
    _transactionsSub = _userService.getTransactionsStream(uid, account.id).listen((transList) {
      _transactions = transList;
      notifyListeners();
    });
  }

  Future<void> addTransaction({
    required String uid,
    required String accountId,
    required String title,
    required double amount,
    required String category,
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
        date: DateTime.now(),
      );

      await transactionRef.set(newTransaction.toJson());

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
  }) async {
    isLoading = true;
    try {
      final firestore = FirebaseFirestore.instance;

      final sourceAccRef = firestore.collection('users').doc(uid).collection('accounts').doc(sourceAccountId);
      final targetAccRef = firestore.collection('users').doc(uid).collection('accounts').doc(targetAccountId);
      
      await firestore.runTransaction((transaction) async {
        final sourceSnap = await transaction.get(sourceAccRef);
        final targetSnap = await transaction.get(targetAccRef);

        if (!sourceSnap.exists || !targetSnap.exists) {
          throw Exception("Un des comptes n'existe pas");
        }

        final sourceBalance = (sourceSnap.data()?['currentBalance'] ?? 0.0).toDouble();
        final targetBalance = (targetSnap.data()?['currentBalance'] ?? 0.0).toDouble();
        final sourceName = sourceSnap.data()?['name'] ?? "Compte source";
        final targetName = targetSnap.data()?['name'] ?? "Compte destination";

        transaction.update(sourceAccRef, {'currentBalance': sourceBalance - amount});
        transaction.update(targetAccRef, {'currentBalance': targetBalance + amount});

        final sourceTransRef = sourceAccRef.collection('transactions').doc();
        transaction.set(sourceTransRef, {
          'id': sourceTransRef.id,
          'title': "Transfert vers $targetName ${title != 'Transfert' ? '- $title' : ''}",
          'amount': -amount,
          'accountId': sourceAccountId,
          'date': Timestamp.now(),
          'category': 'Transfert',
        });

        final targetTransRef = targetAccRef.collection('transactions').doc();
        transaction.set(targetTransRef, {
          'id': targetTransRef.id,
          'title': "Transfert de $sourceName ${title != 'Transfert' ? '- $title' : ''}",
          'amount': amount,
          'accountId': targetAccountId,
          'date': Timestamp.now(),
          'category': 'Transfert',
        });
      });
    } catch (e) {
      errorMessage = "Erreur lors du transfert : $e";
    } finally {
      isLoading = false;
    }
  }

  Future<void> deleteTransaction(String uid, String accountId, TransactionModel transaction) async {
    try {
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
      errorMessage = "Erreur lors de la suppression : $e";
      notifyListeners();
    }
  }

  Future<void> toggleCheckTransaction(String uid, String accountId, String transactionId, bool isChecked) async {
    try {
      await FirebaseFirestore.instance
          .collection('users').doc(uid)
          .collection('accounts').doc(accountId)
          .collection('transactions').doc(transactionId)
          .update({'isChecked': !isChecked});
    } catch (e) {
      errorMessage = "Erreur lors du pointage : $e";
    }
  }
  
  @override
  void dispose() {
    _accountsSub?.cancel();
    _transactionsSub?.cancel();
    super.dispose();
  }
}