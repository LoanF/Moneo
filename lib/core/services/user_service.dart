import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../data/models/app_user_model.dart';
import '../interceptor/api_client.dart';

abstract class IAppUserService {
  Future<void> createUser(AppUser user);
  Future<void> updateUser(AppUser user);
  Future<String> uploadAvatar(File imageFile);
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
  Future<String> uploadAvatar(File imageFile) async {
    final header = await imageFile.openRead(0, 12).fold<List<int>>([], (acc, c) => acc..addAll(c));
    final mime = _detectMimeFromBytes(header);
    if (mime == null) throw Exception('Format non supporté. Utilisez JPEG, PNG ou WebP.');
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(imageFile.path, contentType: DioMediaType.parse(mime)),
    });
    final response = await _apiClient.dio.post('/auth/upload-avatar', data: formData);
    return response.data['url'] as String;
  }

  String? _detectMimeFromBytes(List<int> b) {
    if (b.length < 4) { return null; }
    if (b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) { return 'image/jpeg'; }
    if (b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47) { return 'image/png'; }
    if (b.length >= 12 && b[0] == 0x52 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x46 &&
        b[8] == 0x57 && b[9] == 0x45 && b[10] == 0x42 && b[11] == 0x50) { return 'image/webp'; }
    return null;
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
