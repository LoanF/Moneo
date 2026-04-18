import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();
  final _storage = const FlutterSecureStorage();

  static const _biometricEnabledKey = 'biometric_enabled';
  static const _autoLockMinutesKey = 'auto_lock_minutes';

  Future<bool> isAvailable() async {
    final canCheck = await _auth.canCheckBiometrics;
    final isSupported = await _auth.isDeviceSupported();
    return canCheck && isSupported;
  }

  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Veuillez vous authentifier pour accéder à Moneo',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) =>
      _storage.write(key: _biometricEnabledKey, value: enabled.toString());

  Future<int> getAutoLockMinutes() async {
    final value = await _storage.read(key: _autoLockMinutesKey);
    return int.tryParse(value ?? '') ?? 5;
  }

  Future<void> setAutoLockMinutes(int minutes) =>
      _storage.write(key: _autoLockMinutesKey, value: minutes.toString());
}
