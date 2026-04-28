import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TutorialService {
  static const _key = 'home_tutorial_seen';
  final _storage = const FlutterSecureStorage();

  final showNow = ValueNotifier<bool>(false);

  Future<bool> shouldShowTutorial() async {
    final value = await _storage.read(key: _key);
    return value == null;
  }

  Future<void> markTutorialSeen() async {
    await _storage.write(key: _key, value: 'true');
  }

  Future<void> resetTutorial() async {
    await _storage.delete(key: _key);
    showNow.value = true;
  }
}
