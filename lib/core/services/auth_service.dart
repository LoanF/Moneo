import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:moneo/core/services/sync_service.dart';
import 'package:moneo/data/constants/assets.dart';
import 'package:moneo/data/models/app_user_model.dart';
import '../di.dart';
import 'user_service.dart';

abstract class IAuthService {
  Stream<AppUser?> get authStateChanges;

  Future<void> signInWithEmail(String email, String password);

  Future<void> signInWithGoogle();

  Future<void> signOut();

  Future<void> register(String username, String email, String password);

  AppUser? get currentUser;

  void dispose();
}

class AuthService implements IAuthService {
  final Dio _dio = Dio(BaseOptions(baseUrl: AppAssets.apiUrl));
  final _storage = const FlutterSecureStorage();
  final IAppUserService _appUserService;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // Stocke le Future d'initialisation pour éviter les appels parallèles
  Future<void>? _googleSignInInitFuture;

  final _authStreamController = StreamController<AppUser?>.broadcast();

  AuthService(this._appUserService) {
    _checkInitialAuth();
    _googleSignInInitFuture = _initializeGoogleSignIn();
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      await _googleSignIn.initialize(
        serverClientId: AppAssets.googleServerClientId,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize Google Sign-In: $e');
      }
      // Réinitialiser pour permettre une nouvelle tentative
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
      // Charge l'utilisateur depuis la DB locale au lieu du cache mémoire vide
      final user = await _appUserService.loadCurrentUser();
      _authStreamController.add(user);
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
        data: {
          'email': email.trim().toLowerCase(),
          'password': password.trim(),
        },
      );

      await _handleAuthResponse(response.data);
    } on DioException catch (e) {
      throw e.response?.data['error'] ?? 'Erreur de connexion';
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      await _ensureGoogleSignInInitialized();

      final GoogleSignInAccount account = await _googleSignIn.authenticate(
        scopeHint: ['email', 'profile'],
      );

      final GoogleSignInAuthentication auth = account.authentication;
      final String? idToken = auth.idToken;

      if (idToken == null) {
        throw 'ID Token introuvable';
      }

      final response = await _dio.post(
        '/auth/google',
        data: {'idToken': idToken},
      );

      await _handleAuthResponse(response.data);
    } on DioException catch (e) {
      throw e.response?.data['error'] ?? 'Erreur de connexion Google';
    } catch (e) {
      if (kDebugMode) print('Google Sign-In error: $e');
      rethrow;
    }
  }

  @override
  Future<void> register(String username, String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'username': username.trim(),
          'email': email.trim().toLowerCase(),
          'password': password.trim(),
        },
      );

      await _handleAuthResponse(response.data);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data != null && data['errors'] != null) {
        throw data['errors'][0]['msg'];
      }
      if (data != null && data['error'] != null) {
        throw data['error'];
      }
      throw 'Une erreur réseau est survenue.';
    }
  }

  Future<void> _handleAuthResponse(dynamic data) async {
    final accessToken = data['accessToken'];
    final refreshToken = data['refreshToken'];

    if (accessToken == null || refreshToken == null) {
      throw 'Réponse serveur invalide : tokens manquants';
    }

    await _storage.write(key: 'accessToken', value: accessToken as String);
    await _storage.write(key: 'refreshToken', value: refreshToken as String);

    final apiUser = AppUser.fromJson(data['user'] ?? {});
    await _appUserService.createUser(apiUser);

    // On émet l'user tel qu'il est réellement en DB après createUser,
    // ce qui préserve hasCompletedSetup si l'user existait déjà
    var user = _appUserService.currentAppUser ?? apiUser;
    user = await _appUserService.updateFcmToken(user);

    final syncService = getIt<SyncService>();
    await syncService.bootstrapData();
    syncService.startSync();

    _authStreamController.add(user);
  }

  @override
  Future<void> signOut() async {
    getIt<SyncService>().stopSync();
    await _storage.deleteAll();
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    _authStreamController.add(null);
  }

  @override
  AppUser? get currentUser => _appUserService.currentAppUser;

  @override
  void dispose() {
    _authStreamController.close();
  }
}
