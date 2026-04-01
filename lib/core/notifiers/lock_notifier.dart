import 'package:flutter/material.dart';
import '../services/biometric_service.dart';

class LockNotifier extends ChangeNotifier {
  final BiometricService _biometricService;

  bool _isLocked = false;
  bool _biometricEnabled = false;
  int _autoLockMinutes = 5;
  bool _initialized = false;

  LockNotifier(this._biometricService);

  bool get isLocked => _isLocked;
  bool get biometricEnabled => _biometricEnabled;
  int get autoLockMinutes => _autoLockMinutes;
  bool get initialized => _initialized;

  Future<void> initialize() async {
    _biometricEnabled = await _biometricService.isBiometricEnabled();
    _autoLockMinutes = await _biometricService.getAutoLockMinutes();
    if (_biometricEnabled) {
      _isLocked = true;
    }
    _initialized = true;
    notifyListeners();
  }

  Future<bool> authenticate() async {
    final success = await _biometricService.authenticate();
    if (success) {
      _isLocked = false;
      notifyListeners();
    }
    return success;
  }

  void lock() {
    if (_biometricEnabled && !_isLocked) {
      _isLocked = true;
      notifyListeners();
    }
  }

  void unlock() {
    if (_isLocked) {
      _isLocked = false;
      notifyListeners();
    }
  }

  void checkAutoLock(DateTime? lastBackgroundTime) {
    if (!_biometricEnabled || _autoLockMinutes == 0 || lastBackgroundTime == null) return;
    final elapsed = DateTime.now().difference(lastBackgroundTime);
    if (elapsed.inMinutes >= _autoLockMinutes) {
      lock();
    }
  }

  Future<bool> setBiometricEnabled(bool enabled) async {
    if (enabled) {
      final available = await _biometricService.isAvailable();
      if (!available) return false;
      final success = await _biometricService.authenticate();
      if (!success) return false;
    }
    _biometricEnabled = enabled;
    await _biometricService.setBiometricEnabled(enabled);
    if (!enabled) _isLocked = false;
    notifyListeners();
    return true;
  }

  Future<void> setAutoLockMinutes(int minutes) async {
    _autoLockMinutes = minutes;
    await _biometricService.setAutoLockMinutes(minutes);
    notifyListeners();
  }
}
