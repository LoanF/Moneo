import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';

import '../core/api_client.dart';
import '../core/config.dart';
import '../firebase_options.dart';
import 'providers.dart';

/// Connexion Google : renvoie le jeton d'identité à transmettre à l'API, ou `null` si l'utilisateur annule.
class GoogleAuth {
  Future<void>? _ready;

  Future<String?> idToken() async {
    try {
      await (_ready ??= GoogleSignIn.instance.initialize(
        serverClientId: AppConfig.googleServerClientId,
      ));
      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: const ['email', 'profile'],
      );
      final token = account.authentication.idToken;
      if (token == null) {
        throw const ApiException(
          'Google n’a pas renvoyé d’identité. Réessayez.',
        );
      }
      return token;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      _ready = null;
      throw const ApiException(
        'La connexion Google a échoué. Réessayez ou utilisez votre email.',
      );
    }
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }
}

final googleAuthProvider = Provider<GoogleAuth>((ref) => GoogleAuth());

/// Déverrouillage par empreinte, visage ou code de l'appareil.
class Biometrics {
  final _auth = LocalAuthentication();

  Future<bool> get available async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Déverrouillez Moneo pour consulter vos comptes',
        options: const AuthenticationOptions(stickyAuth: true),
      );
    } catch (_) {
      return false;
    }
  }
}

final biometricsProvider = Provider<Biometrics>((ref) => Biometrics());

enum PushStatus { unavailable, notAsked, denied, enabled }

/// Notifications push. La permission n'est jamais demandée au lancement :
/// seulement quand l'utilisateur active les notifications.
class PushService {
  PushService(this.ref);
  final Ref ref;
  bool? _firebaseReady;

  Future<bool> _init() async {
    if (_firebaseReady != null) return _firebaseReady!;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      return _firebaseReady = true;
    } catch (_) {
      // Firebase non configuré sur cette version : l'app fonctionne sans push.
      return _firebaseReady = false;
    }
  }

  Future<PushStatus> status() async {
    if (!await _init()) return PushStatus.unavailable;
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    return switch (settings.authorizationStatus) {
      AuthorizationStatus.authorized ||
      AuthorizationStatus.provisional => PushStatus.enabled,
      AuthorizationStatus.denied => PushStatus.denied,
      _ => PushStatus.notAsked,
    };
  }

  /// Demande la permission puis enregistre l'appareil auprès de l'API.
  Future<PushStatus> enable() async {
    if (!await _init()) return PushStatus.unavailable;
    await FirebaseMessaging.instance.requestPermission();
    final current = await status();
    if (current == PushStatus.enabled) await sync();
    return current;
  }

  /// Si la permission est déjà accordée, transmet le jeton courant (appelé à chaque ouverture de session).
  Future<void> sync() async {
    try {
      if (await status() != PushStatus.enabled) return;
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await ref.read(apiProvider).registerDevice({
          'fcmToken': token,
          ...deviceInfo(),
        });
      }
    } catch (_) {
      /* le push est un confort : son échec ne doit rien bloquer */
    }
  }

  Future<void> disable() async {
    try {
      await ref.read(apiProvider).registerDevice({'fcmToken': null});
    } catch (_) {}
  }
}

final pushServiceProvider = Provider<PushService>(PushService.new);
