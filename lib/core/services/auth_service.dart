import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:moneo/data/constants/assets.dart';
import 'package:moneo/data/models/app_user_model.dart';
import '../di.dart';
import '../interceptor/api_client.dart';
import '../notifiers/lock_notifier.dart';
import 'user_service.dart';

abstract class IAuthService {
  Stream<AppUser?> get authStateChanges;
  Future<void> signInWithEmail(String email, String password);
  Future<void> signInWithGoogle();
  Future<void> signOut();
  Future<void> register(String username, String email, String password);
  Future<void> forgotPassword(String email);
  Future<void> resetPassword(String email, String code, String newPassword);
  Future<void> verifyEmail(String code);
  Future<void> resendVerification();
  Future<void> deleteAccount();
  AppUser? get currentUser;
  void dispose();
}

class AuthService implements IAuthService {
  final Dio _dio = Dio(BaseOptions(baseUrl: AppAssets.apiUrl));
  final _storage = const FlutterSecureStorage();
  final IAppUserService _appUserService;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Future<void>? _googleSignInInitFuture;
  final _authStreamController = StreamController<AppUser?>.broadcast();

  AuthService(this._appUserService) {
    _checkInitialAuth();
    _googleSignInInitFuture = _initializeGoogleSignIn();
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      await _googleSignIn.initialize(serverClientId: AppAssets.googleServerClientId);
    } catch (e) {
      if (kDebugMode) print('Failed to initialize Google Sign-In: $e');
      _googleSignInInitFuture = null;
    }
  }

  Future<void> _ensureGoogleSignInInitialized() async {
    _googleSignInInitFuture ??= _initializeGoogleSignIn();
    await _googleSignInInitFuture;
  }

  Future<void> _checkInitialAuth() async {
    final token = await _storage.read(key: 'accessToken');
    if (token != null) {
      try {
        final response = await getIt<ApiClient>().dio.get('/auth/me');
        final apiUser = AppUser.fromJson(response.data);
        await _appUserService.createUser(apiUser);
        try {
          await _appUserService.updateFcmToken(apiUser);
        } catch (_) {}
        _authStreamController.add(_appUserService.currentAppUser ?? apiUser);
      } on DioException catch (e) {
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          await _storage.deleteAll();
        }
        _authStreamController.add(null);
      } catch (_) {
        await _storage.deleteAll();
        _authStreamController.add(null);
      }
    } else {
      _authStreamController.add(null);
    }
  }

  @override
  Stream<AppUser?> get authStateChanges => _authStreamController.stream;

  @override
  Future<void> signInWithEmail(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email.trim().toLowerCase(), 'password': password},
      );
      await _handleAuthResponse(response.data);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map) throw data['error'] ?? 'Erreur de connexion';
      throw 'Erreur de connexion';
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      await _ensureGoogleSignInInitialized();
      final GoogleSignInAccount account = await _googleSignIn.authenticate(scopeHint: ['email', 'profile']);
      final GoogleSignInAuthentication auth = account.authentication;
      final String? idToken = auth.idToken;
      if (idToken == null) throw 'ID Token introuvable';
      final response = await _dio.post('/auth/google', data: {'idToken': idToken});
      await _handleAuthResponse(response.data);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) throw 'Connexion Google annulée';
      throw 'Erreur de connexion Google';
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map) throw data['error'] ?? 'Erreur de connexion Google';
      throw 'Erreur de connexion Google';
    } catch (e) {
      if (kDebugMode) print('Google Sign-In error: $e');
      rethrow;
    }
  }

  @override
  Future<void> register(String username, String email, String password) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'username': username.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
      });
      await _handleAuthResponse(response.data);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map) {
        if (data['errors'] is List && (data['errors'] as List).isNotEmpty) {
          final firstError = (data['errors'] as List)[0];
          throw firstError is Map ? (firstError['msg'] ?? 'Erreur') : firstError.toString();
        }
        if (data['error'] != null) throw data['error'];
      }
      throw 'Une erreur réseau est survenue.';
    }
  }

  Future<void> _handleAuthResponse(dynamic data) async {
    final accessToken = data['accessToken'];
    final refreshToken = data['refreshToken'];
    if (accessToken == null || refreshToken == null) throw 'Réponse serveur invalide : tokens manquants';

    await _storage.write(key: 'accessToken', value: accessToken as String);
    await _storage.write(key: 'refreshToken', value: refreshToken as String);

    final apiUser = AppUser.fromJson(data['user'] ?? {});
    await _appUserService.createUser(apiUser);

    var user = _appUserService.currentAppUser ?? apiUser;
    try {
      user = await _appUserService.updateFcmToken(user);
    } catch (e) {
      if (kDebugMode) print('updateFcmToken failed (non-blocking): $e');
    }

    getIt<LockNotifier>().unlock();
    _authStreamController.add(user);
  }

  @override
  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post('/auth/forgot-password', data: {'email': email.trim().toLowerCase()});
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map) throw data['error'] ?? 'Erreur lors de la demande';
      throw 'Erreur lors de la demande';
    }
  }

  @override
  Future<void> resetPassword(String email, String code, String newPassword) async {
    try {
      await _dio.post('/auth/reset-password', data: {
        'email': email.trim().toLowerCase(),
        'code': code,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map) throw data['error'] ?? 'Code invalide ou expiré';
      throw 'Code invalide ou expiré';
    }
  }

  @override
  Future<void> verifyEmail(String code) async {
    try {
      await getIt<ApiClient>().dio.post('/auth/verify-email', data: {'code': code});
      final user = _appUserService.currentAppUser;
      if (user != null) {
        await _appUserService.setEmailVerified(user.uid);
        _authStreamController.add(_appUserService.currentAppUser);
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map) throw data['error'] ?? 'Code invalide';
      throw 'Code invalide';
    }
  }

  @override
  Future<void> resendVerification() async {
    try {
      await getIt<ApiClient>().dio.post('/auth/resend-verification');
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map) throw data['error'] ?? 'Erreur lors du renvoi';
      throw 'Erreur lors du renvoi';
    }
  }

  @override
  Future<void> signOut() async {
    _appUserService.clearUser();
    _authStreamController.add(null);
    getIt<ApiClient>().dio.post('/auth/logout').ignore();
    _storage.delete(key: 'accessToken').catchError((_) {});
    _storage.delete(key: 'refreshToken').catchError((_) {});
    _googleSignIn.signOut().catchError((_) {});
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await getIt<ApiClient>().dio.delete('/auth/me');
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map) throw data['error'] ?? 'Erreur lors de la suppression';
      throw 'Erreur lors de la suppression';
    }
    await Future.wait([
      _storage.delete(key: 'accessToken'),
      _storage.delete(key: 'refreshToken'),
      _googleSignIn.signOut().catchError((_) {}),
    ]);
    await _appUserService.clearUser();
    _authStreamController.add(null);
  }

  @override
  AppUser? get currentUser => _appUserService.currentAppUser;

  @override
  void dispose() {
    _authStreamController.close();
  }
}
