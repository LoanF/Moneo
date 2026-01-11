import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../data/enums/firebase_collection_enum.dart';
import '../../data/models/account_model.dart';
import '../../data/models/app_user_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/monthly_operation_model.dart';

abstract class IAppUserService {
  Future<AppUser?> getUserById(String uid);
  Future<void> createUser(AppUser user);
  Future<void> updateUser(AppUser user);
  Future<AppUser> updateFcmToken(AppUser appUser);
  
  Future<void> createAccount(String uid, Account account);
  Future<void> updateAccount(String uid, Account account);
  Future<void> deleteAccount(String uid, String accountId);
  Future<void> updateAccountsOrder(String uid, List<Account> accounts);
  Stream<List<Account>> getAccountsStream(String uid);

  Future<void> saveMonthlyOperation(String uid, MonthlyOperationModel operation);
  Future<void> deleteMonthlyOperation(String uid, String operationId);
  Stream<List<MonthlyOperationModel>> getMonthlyOperationsStream(String uid);
  Future<void> checkAndApplyMonthlyOperations(String uid);
  
  Future<QuerySnapshot<Map<String, dynamic>>> getTransactionsPaginated({
    required String uid,
    required String accountId,
    required int limit,
    DocumentSnapshot? startAfter,
    bool hideChecked = false,
  });
  
  Future<void> saveCategory(String uid, CategoryModel category);
  Future<void> deleteCategory(String uid, String categoryId);
  Stream<List<CategoryModel>> getCategoriesStream(String uid);

  Future<void> finalizeSetup(String uid, List<String> paymentMethods);
  AppUser? get currentAppUser;
}

class AppUserService implements IAppUserService {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  late final CollectionReference<AppUser> usersCollection = _firebaseFirestore
      .collection(FirestoreCollection.users.value)
      .withConverter<AppUser>(
    fromFirestore: (snapshot, _) => AppUser.fromJson(snapshot.data()!),
    toFirestore: (user, _) => user.toJson(),
  );

  AppUser? _currentAppUser;

  @override
  Future<AppUser?> getUserById(String uid) async {
    if (uid.isEmpty) return null;
    
    final doc = await usersCollection.doc(uid).get();
    _currentAppUser = doc.data();
    return _currentAppUser;
  }

  @override
  Future<void> createUser(AppUser user) async {
    user = await updateFcmToken(user);
    await usersCollection.doc(user.uid).set(user);
    _currentAppUser = user;
  }

  @override
  Future<void> updateUser(AppUser user) async {
    _currentAppUser ??= await getUserById(user.uid);

    if (_currentAppUser?.fcmToken == null) {
      user = await updateFcmToken(user);
    }

    if (_currentAppUser != null &&
        _currentAppUser!.toJson().toString() == user.toJson().toString()) {
      return;
    }

    await usersCollection.doc(user.uid).update(user.toJson());
  }

  @override
  Future<AppUser> updateFcmToken(AppUser appUser) async {
    final fcmToken = await _firebaseMessaging.getToken();
    if (fcmToken == null) return appUser;

    return AppUser(
      uid: appUser.uid,
      displayName: appUser.displayName,
      email: appUser.email,
      photoURL: appUser.photoURL,
      createdAt: appUser.createdAt,
      updatedAt: appUser.updatedAt,
      fcmToken: fcmToken,
    );
  }

  @override
  Future<void> createAccount(String uid, Account account) async {
    if (uid.isEmpty) return;
    
    await _firebaseFirestore
        .collection('users')
        .doc(uid)
        .collection('accounts')
        .doc(account.id)
        .set(account.toJson());
  }

  @override
  Future<void> updateAccount(String uid, Account account) async {
    if (uid.isEmpty) return;

    await _firebaseFirestore
        .collection('users')
        .doc(uid)
        .collection('accounts')
        .doc(account.id)
        .update(account.toJson());
  }

  @override
  Future<void> deleteAccount(String uid, String accountId) async {
    if (uid.isEmpty) return;

    await _firebaseFirestore
        .collection('users')
        .doc(uid)
        .collection('accounts')
        .doc(accountId)
        .delete();
  }

  @override
  Future<void> updateAccountsOrder(String uid, List<Account> accounts) async {
    final batch = _firebaseFirestore.batch();
    for (int i = 0; i < accounts.length; i++) {
      final docRef = _firebaseFirestore
          .collection('users')
          .doc(uid)
          .collection('accounts')
          .doc(accounts[i].id);
      batch.update(docRef, {'order': i});
    }
    await batch.commit();
  }
  
  @override
  Future<void> finalizeSetup(String uid, List<String> paymentMethods) async {
    if (uid.isEmpty) return;
    
    await _firebaseFirestore.collection('users').doc(uid).update({
      'hasCompletedSetup': true,
      'paymentMethods': paymentMethods,
      'updatedAt': Timestamp.now(),
    });
  }

  @override
  Stream<List<Account>> getAccountsStream(String uid) {
    if (uid.isEmpty) return Stream.value([]);

    return _firebaseFirestore
        .collection('users')
        .doc(uid)
        .collection('accounts')
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Account.fromJson(doc.data()))
        .toList());
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> getTransactionsPaginated({
    required String uid,
    required String accountId,
    required int limit,
    DocumentSnapshot? startAfter,
    bool hideChecked = false,
  }) async {
    Query<Map<String, dynamic>> query = _firebaseFirestore
        .collection('users')
        .doc(uid)
        .collection('accounts')
        .doc(accountId)
        .collection('transactions')
        .orderBy('date', descending: true);

    if (hideChecked) {
      query = query.where('isChecked', isEqualTo: false);
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return await query.limit(limit).get();
  }
  
  @override
  AppUser? get currentAppUser => _currentAppUser;

  @override
  Future<void> saveCategory(String uid, CategoryModel category) async {
    if (uid.isEmpty) return;
    
    await _firebaseFirestore
        .collection('users')
        .doc(uid)
        .collection('categories')
        .doc(category.id)
        .set(category.toJson());
  }

  @override
  Future<void> deleteCategory(String uid, String categoryId) async {
    if (uid.isEmpty) return;
    
    await _firebaseFirestore
        .collection('users')
        .doc(uid)
        .collection('categories')
        .doc(categoryId)
        .delete();
  }

  @override
  Stream<List<CategoryModel>> getCategoriesStream(String uid) {
    if (uid.isEmpty) return Stream.value([]);
    
    return _firebaseFirestore
        .collection('users')
        .doc(uid)
        .collection('categories')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => CategoryModel.fromJson(doc.data()))
        .toList());
  }

  @override
  Future<void> saveMonthlyOperation(String uid, MonthlyOperationModel operation) async {
    await _firebaseFirestore
        .collection('users')
        .doc(uid)
        .collection('monthly_operations')
        .doc(operation.id)
        .set(operation.toJson());
  }

  @override
  Stream<List<MonthlyOperationModel>> getMonthlyOperationsStream(String uid) {
    return _firebaseFirestore
        .collection('users')
        .doc(uid)
        .collection('monthly_operations')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => MonthlyOperationModel.fromJson(doc.data())).toList());
  }

  @override
  Future<void> deleteMonthlyOperation(String uid, String operationId) async {
    await _firebaseFirestore
        .collection('users')
        .doc(uid)
        .collection('monthly_operations')
        .doc(operationId)
        .delete();
  }

  @override
  Future<void> checkAndApplyMonthlyOperations(String uid) async {
    if (uid.isEmpty) return;

    final now = DateTime.now();
    final currentMonthStr = "${now.month}-${now.year}";

    final operationsSnapshot = await _firebaseFirestore
        .collection('users')
        .doc(uid)
        .collection('monthly_operations')
        .get();

    final operations = operationsSnapshot.docs
        .map((doc) => MonthlyOperationModel.fromJson(doc.data()))
        .toList();

    for (var op in operations) {
      if (op.lastAppliedMonth == currentMonthStr) continue;

      final amount = op.amounts[now.month - 1];
      if (amount <= 0) continue;

      final finalAmount = op.isExpense ? -amount : amount;
      final transactionId = "monthly_${op.id}_$currentMonthStr";

      final transactionRef = _firebaseFirestore
          .collection('users').doc(uid)
          .collection('accounts').doc(op.accountId)
          .collection('transactions').doc(transactionId);

      final accountRef = _firebaseFirestore
          .collection('users').doc(uid)
          .collection('accounts').doc(op.accountId);

      final monthlyOpRef = _firebaseFirestore
          .collection('users').doc(uid)
          .collection('monthly_operations').doc(op.id);

      await _firebaseFirestore.runTransaction((transaction) async {
        final accountSnap = await transaction.get(accountRef);

        transaction.set(transactionRef, {
          'id': transactionId,
          'title': op.title,
          'amount': finalAmount,
          'category': op.categoryId,
          'accountId': op.accountId,
          'date': Timestamp.fromDate(DateTime(now.year, now.month, 1)),
          'isChecked': false,
        });

        if (accountSnap.exists) {
          double currentBalance = (accountSnap.data()?['currentBalance'] ?? 0.0).toDouble();
          transaction.update(accountRef, {'currentBalance': currentBalance + finalAmount});
        }

        transaction.update(monthlyOpRef, {'lastAppliedMonth': currentMonthStr});
      });
    }
  }
}