import 'package:drift/drift.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../database/app_database.dart';
import '../../data/models/app_user_model.dart';

abstract class IAppUserService {
  Future<void> createUser(AppUser user);
  Future<void> updateUser(AppUser user);
  Future<AppUser> updateFcmToken(AppUser appUser);
  AppUser? get currentAppUser;
}

class AppUserService implements IAppUserService {
  final AppDatabase _db;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  AppUserService(this._db);

  AppUser? _currentAppUser;

  @override
  Future<void> createUser(AppUser user) async {
    await _db.into(_db.users).insertOnConflictUpdate(
      UsersCompanion.insert(
        id: user.uid,
        displayName: user.displayName,
        email: user.email,
        photoUrl: Value(user.photoURL),
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
        fcmToken: Value(user.fcmToken),
        hasCompletedSetup: Value(user.hasCompletedSetup),
        paymentMethods: Value(user.paymentMethods),
      ),
    );
    _currentAppUser = user;
  }

  @override
  Future<void> updateUser(AppUser user) async {
    await (_db.update(_db.users)..where((t) => t.id.equals(user.uid))).write(
      UsersCompanion(
        displayName: Value(user.displayName),
        photoUrl: Value(user.photoURL),
        fcmToken: Value(user.fcmToken),
        hasCompletedSetup: Value(user.hasCompletedSetup),
        paymentMethods: Value(user.paymentMethods),
        updatedAt: Value(DateTime.now()),
      ),
    );
    _currentAppUser = user;
  }

  @override
  Future<AppUser> updateFcmToken(AppUser appUser) async {
    final fcmToken = await _firebaseMessaging.getToken();
    if (fcmToken == null) return appUser;

    final updated = appUser.copyWith(fcmToken: fcmToken);
    await updateUser(updated);
    return updated;
  }

  @override
  AppUser? get currentAppUser => _currentAppUser;
}