import 'package:drift/drift.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../database/app_database.dart';
import '../../data/models/app_user_model.dart';
import '../interceptor/api_client.dart';

abstract class IAppUserService {
  Future<void> createUser(AppUser user);
  Future<void> updateUser(AppUser user);
  Future<AppUser> updateFcmToken(AppUser appUser);
  Future<AppUser?> loadCurrentUser();
  Future<void> clearUser();
  Future<void> setEmailVerified(String userId);
  Future<AppUser> updateNotificationPrefs(Map<String, bool> prefs);
  AppUser? get currentAppUser;
}

class AppUserService implements IAppUserService {
  final AppDatabase _db;
  final ApiClient _apiClient;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  AppUserService(this._db, this._apiClient);
  
  AppUser? _currentAppUser;

  @override
  Future<void> createUser(AppUser user) async {
    await _db.into(_db.users).insert(
      UsersCompanion.insert(
        id: user.uid,
        username: user.username,
        email: user.email,
        photoUrl: Value(user.photoUrl),
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
        fcmToken: Value(user.fcmToken),
        hasCompletedSetup: Value(user.hasCompletedSetup),
        emailVerified: Value(user.emailVerified),
        paymentMethods: Value(user.paymentMethods),
      ),
      onConflict: DoUpdate((_) => UsersCompanion(
        username: Value(user.username),
        email: Value(user.email),
        photoUrl: Value(user.photoUrl),
        updatedAt: Value(user.updatedAt),
        fcmToken: Value(user.fcmToken),
        emailVerified: Value(user.emailVerified),
        hasCompletedSetup: Value(user.hasCompletedSetup),
      )),
    );
    final row = await (_db.select(_db.users)..where((t) => t.id.equals(user.uid))).getSingleOrNull();
    _currentAppUser = row != null ? AppUser.fromDb(row) : user;
  }

  @override
  Future<void> updateUser(AppUser user) async {
    final response = await _apiClient.dio.patch('/auth/profile', data: user.toJson());

    final serverData = response.data['user'] ?? response.data;
    final serverUser = AppUser.fromJson(serverData);

    await (_db.update(_db.users)..where((t) => t.id.equals(user.uid))).write(
      UsersCompanion(
        username: Value(serverUser.username),
        photoUrl: Value(serverUser.photoUrl),
        fcmToken: Value(serverUser.fcmToken),
        // On fait confiance aux valeurs locales pour ces champs critiques,
        // car le serveur peut ne pas les retourner correctement
        hasCompletedSetup: Value(user.hasCompletedSetup),
        emailVerified: Value(user.emailVerified),
        paymentMethods: Value(user.paymentMethods),
      ),
    );
    _currentAppUser = serverUser.copyWith(
      hasCompletedSetup: user.hasCompletedSetup,
      emailVerified: user.emailVerified,
      paymentMethods: user.paymentMethods,
    );
  }

  @override
  Future<AppUser?> loadCurrentUser() async {
    final row = await (_db.select(_db.users)..limit(1)).getSingleOrNull();
    if (row == null) return null;
    _currentAppUser = AppUser.fromDb(row);
    return _currentAppUser;
  }

  @override
  Future<void> clearUser() async {
    await _db.delete(_db.users).go();
    _currentAppUser = null;
  }

  @override
  Future<void> setEmailVerified(String userId) async {
    await (_db.update(_db.users)..where((t) => t.id.equals(userId))).write(
      const UsersCompanion(emailVerified: Value(true)),
    );
    _currentAppUser = _currentAppUser?.copyWith(emailVerified: true);
  }

  @override
  Future<AppUser> updateFcmToken(AppUser appUser) async {
    final fcmToken = await _firebaseMessaging.getToken();
    if (fcmToken == null) return appUser;

    await _apiClient.dio.patch('/auth/profile', data: {'fcmToken': fcmToken});

    final updated = appUser.copyWith(fcmToken: fcmToken);
    await (_db.update(_db.users)..where((t) => t.id.equals(appUser.uid))).write(
      UsersCompanion(fcmToken: Value(fcmToken)),
    );
    _currentAppUser = updated;
    return updated;
  }

  @override
  Future<AppUser> updateNotificationPrefs(Map<String, bool> prefs) async {
    final current = _currentAppUser!;
    await _apiClient.dio.patch('/auth/profile', data: {'notificationPrefs': prefs});
    final updated = current.copyWith(notificationPrefs: prefs);
    _currentAppUser = updated;
    return updated;
  }

  @override
  AppUser? get currentAppUser => _currentAppUser;
}