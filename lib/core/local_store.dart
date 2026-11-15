import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Petit magasin clé → JSON sur disque : dernier état connu (pour ouvrir l'app hors-ligne),
/// file d'attente des opérations à envoyer, préférences propres à l'appareil.
abstract class LocalStore {
  Future<Object?> read(String key);
  Future<void> write(String key, Object? value);
  Future<void> clear();
}

class FileLocalStore implements LocalStore {
  FileLocalStore([this._directory]);
  Directory? _directory;

  Future<Directory> _dir() async {
    final dir = _directory ??= Directory(
      '${(await getApplicationSupportDirectory()).path}/moneo',
    );
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  Future<File> _file(String key) async => File(
    '${(await _dir()).path}/${key.replaceAll(RegExp(r'[^\w.-]'), '_')}.json',
  );

  @override
  Future<Object?> read(String key) async {
    try {
      final file = await _file(key);
      if (!file.existsSync()) return null;
      return jsonDecode(await file.readAsString());
    } catch (_) {
      return null; // fichier corrompu : on repart du serveur
    }
  }

  @override
  Future<void> write(String key, Object? value) async {
    final file = await _file(key);
    if (value == null) {
      if (file.existsSync()) file.deleteSync();
      return;
    }
    // Écriture atomique : un arrêt brutal ne laisse jamais un fichier à moitié écrit.
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(jsonEncode(value), flush: true);
    await temp.rename(file.path);
  }

  @override
  Future<void> clear() async {
    final dir = await _dir();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  }
}

class MemoryLocalStore implements LocalStore {
  final Map<String, String> _data = {};

  @override
  Future<Object?> read(String key) async =>
      _data[key] == null ? null : jsonDecode(_data[key]!);

  @override
  Future<void> write(String key, Object? value) async =>
      value == null ? _data.remove(key) : _data[key] = jsonEncode(value);

  @override
  Future<void> clear() async => _data.clear();
}
