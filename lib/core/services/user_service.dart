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
        displayName: user.displayName,
        email: user.email,
        photoUrl: Value(user.photoURL),
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
        fcmToken: Value(user.fcmToken),
        hasCompletedSetup: Value(user.hasCompletedSetup),
        paymentMethods: Value(user.paymentMethods),
      ),
      onConflict: DoUpdate((_) => UsersCompanion(
        displayName: Value(user.displayName),
        email: Value(user.email),
        photoUrl: Value(user.photoURL),
        updatedAt: Value(user.updatedAt),
        fcmToken: Value(user.fcmToken),
        // hasCompletedSetup et paymentMethods intentionnellement exclus :
        // la valeur en DB est toujours prioritaire sur la réponse de l'API de login
      )),
    );
    // Recharge depuis la DB pour refléter l'état réel (hasCompletedSetup préservé)
    _currentAppUser = await loadCurrentUser() ?? user;
  }

  @override
  Future<void> updateUser(AppUser user) async {
    final response = await _apiClient.dio.patch('/auth/profile', data: user.toJson());

    final serverData = response.data['user'] ?? response.data;
    final serverUser = AppUser.fromJson(serverData);

    await (_db.update(_db.users)..where((t) => t.id.equals(user.uid))).write(
      UsersCompanion(
        displayName: Value(serverUser.displayName),
        photoUrl: Value(serverUser.photoURL),
        fcmToken: Value(serverUser.fcmToken),
        // On fait confiance aux valeurs locales pour ces champs critiques,
        // car le serveur peut ne pas les retourner correctement
        hasCompletedSetup: Value(user.hasCompletedSetup),
        paymentMethods: Value(user.paymentMethods),
      ),
    );
    _currentAppUser = serverUser.copyWith(
      hasCompletedSetup: user.hasCompletedSetup,
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