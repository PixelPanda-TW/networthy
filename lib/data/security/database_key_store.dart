import 'dart:math';

import 'database_key.dart';
import 'database_key_errors.dart';

abstract interface class DatabaseKeyStore {
  Future<DatabaseKey> loadOrCreate({required bool databaseExists});

  Future<DatabaseKey> loadExisting();

  Future<void> delete();
}

abstract interface class KeyValueSecretStore {
  Future<String?> read(String key);

  Future<void> write({required String key, required String value});

  Future<void> delete(String key);
}

class SecureDatabaseKeyStore implements DatabaseKeyStore {
  SecureDatabaseKeyStore({
    required KeyValueSecretStore secrets,
    Random? random,
    String storageKey = defaultStorageKey,
  }) : _secrets = secrets,
       _random = random ?? Random.secure(),
       _storageKey = storageKey;

  static const String defaultStorageKey = 'networthy.database.encryption_key';

  final KeyValueSecretStore _secrets;
  final Random _random;
  final String _storageKey;

  @override
  Future<DatabaseKey> loadOrCreate({required bool databaseExists}) async {
    final existing = await _readStoredKey();
    if (existing != null) {
      return existing;
    }

    if (databaseExists) {
      throw const DatabaseKeyMissingException();
    }

    final key = _generateKey();
    await _secrets.write(key: _storageKey, value: key.encodeForStorage());
    return key;
  }

  @override
  Future<DatabaseKey> loadExisting() async {
    final existing = await _readStoredKey();
    if (existing == null) {
      throw const DatabaseKeyMissingException();
    }

    return existing;
  }

  @override
  Future<void> delete() async {
    await _secrets.delete(_storageKey);
  }

  DatabaseKey _generateKey() {
    return DatabaseKey.fromBytes(
      List<int>.generate(DatabaseKey.byteLength, (_) => _random.nextInt(256)),
    );
  }

  Future<DatabaseKey?> _readStoredKey() async {
    final encoded = await _secrets.read(_storageKey);
    if (encoded == null) {
      return null;
    }

    try {
      return DatabaseKey.decodeFromStorage(encoded);
    } on FormatException {
      throw const DatabaseKeyInvalidException();
    } on ArgumentError {
      throw const DatabaseKeyInvalidException();
    }
  }
}
