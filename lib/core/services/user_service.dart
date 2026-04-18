import 'package:firebase_messaging/firebase_messaging.dart';
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
  final ApiClient _apiClient;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  AppUserService(this._apiClient);

  AppUser? _currentAppUser;

  @override
  Future<void> createUser(AppUser user) async {
    _currentAppUser = user;
  }

  @override
  Future<void> updateUser(AppUser user) async {
    final response = await _apiClient.dio.patch('/auth/profile', data: user.toJson());
    final serverData = response.data['user'] ?? response.data;
    final serverUser = AppUser.fromJson(serverData);
    _currentAppUser = serverUser.copyWith(
      hasCompletedSetup: user.hasCompletedSetup,
      emailVerified: user.emailVerified,
      paymentMethods: user.paymentMethods,
    );
  }

  @override
  Future<AppUser?> loadCurrentUser() async {
    return _currentAppUser;
  }

  @override
  Future<void> clearUser() async {
    _currentAppUser = null;
  }

  @override
  Future<void> setEmailVerified(String userId) async {
    _currentAppUser = _currentAppUser?.copyWith(emailVerified: true);
  }

  @override
  Future<AppUser> updateFcmToken(AppUser appUser) async {
    final fcmToken = await _firebaseMessaging.getToken();
    if (fcmToken == null) return appUser;
    await _apiClient.dio.patch('/auth/profile', data: {'fcmToken': fcmToken});
    final updated = appUser.copyWith(fcmToken: fcmToken);
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
