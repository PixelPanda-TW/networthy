import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import '../security/database_key.dart';
import '../security/database_key_errors.dart';
import '../security/database_key_store.dart';
import 'encrypted_database_spike_result.dart';

typedef DatabaseExists = Future<bool> Function();

abstract interface class EncryptedSqliteProbe {
  Future<void> validate(DatabaseKey key);
}

class EncryptedSqliteProviderException implements Exception {
  const EncryptedSqliteProviderException(this.safeMessage);

  final String safeMessage;

  @override
  String toString() {
    return 'EncryptedSqliteProviderException';
  }
}

class EncryptedSqliteWrongKeyException implements Exception {
  const EncryptedSqliteWrongKeyException();

  @override
  String toString() {
    return 'EncryptedSqliteWrongKeyException';
  }
}

class EncryptedDatabaseSpike {
  const EncryptedDatabaseSpike({
    required DatabaseExists databaseExists,
    required DatabaseKeyStore keyStore,
    required EncryptedSqliteProbe probe,
  }) : _databaseExists = databaseExists,
       _keyStore = keyStore,
       _probe = probe;

  final DatabaseExists _databaseExists;
  final DatabaseKeyStore _keyStore;
  final EncryptedSqliteProbe _probe;

  Future<EncryptedDatabaseSpikeResult> run() async {
    try {
      final exists = await _databaseExists();
      final key = await _keyStore.loadOrCreate(databaseExists: exists);
      await _probe.validate(key);
      return const EncryptedDatabaseSpikeResult(
        status: EncryptedDatabaseSpikeStatus.success,
        safeMessage: 'Encrypted database spike completed.',
      );
    } on DatabaseKeyMissingException {
      return const EncryptedDatabaseSpikeResult(
        status: EncryptedDatabaseSpikeStatus.missingKey,
        safeMessage:
            'Local data cannot be unlocked because its key is missing.',
      );
    } on EncryptedSqliteWrongKeyException {
      return const EncryptedDatabaseSpikeResult(
        status: EncryptedDatabaseSpikeStatus.wrongKeyRejected,
        safeMessage: 'Encrypted database rejected an incorrect key.',
      );
    } on EncryptedSqliteProviderException {
      return const EncryptedDatabaseSpikeResult(
        status: EncryptedDatabaseSpikeStatus.providerValidationFailed,
        safeMessage: 'Encrypted database provider validation failed.',
      );
    }
  }
}

Future<bool> databaseFileExists(String path) async {
  return File(path).exists();
}

class Sqlite3MultipleCiphersProbe implements EncryptedSqliteProbe {
  const Sqlite3MultipleCiphersProbe({
    required this.databasePath,
    this.marker = _defaultMarker,
  });

  static const String _defaultMarker =
      'NETWORTHY_ENCRYPTION_SPIKE_MARKER_DO_NOT_LOG';

  final String databasePath;
  final String marker;

  @override
  Future<void> validate(DatabaseKey key) async {
    final databaseFile = File(databasePath);
    databaseFile.parent.createSync(recursive: true);

    _createAndReadWithKey(databasePath, key, marker);
    _readExistingWithKey(databasePath, key, marker);
    _verifyWrongKeyRejected(databasePath, marker);
  }

  void _createAndReadWithKey(
    String path,
    DatabaseKey key,
    String expectedMarker,
  ) {
    final database = sqlite3.open(path);
    try {
      _applyKey(database, key);
      _verifyCipherProvider(database);
      database.execute(
        'create table if not exists spike_marker (id integer primary key, marker text not null)',
      );
      database.execute('delete from spike_marker');
      final statement = database.prepare(
        'insert into spike_marker (id, marker) values (?, ?)',
      );
      try {
        statement.execute(<Object?>[1, expectedMarker]);
      } finally {
        statement.close();
      }
      final rows = database.select(
        'select marker from spike_marker where id = ?',
        <Object?>[1],
      );
      if (rows.single['marker'] != expectedMarker) {
        throw const EncryptedSqliteProviderException(
          'Encrypted database marker round trip failed.',
        );
      }
    } on SqliteException {
      throw const EncryptedSqliteProviderException(
        'Encrypted database create/read validation failed.',
      );
    } finally {
      database.close();
    }
  }

  void _readExistingWithKey(
    String path,
    DatabaseKey key,
    String expectedMarker,
  ) {
    final database = sqlite3.open(path);
    try {
      _applyKey(database, key);
      _verifyCipherProvider(database);
      final rows = database.select(
        'select marker from spike_marker where id = ?',
        <Object?>[1],
      );
      if (rows.single['marker'] != expectedMarker) {
        throw const EncryptedSqliteProviderException(
          'Encrypted database reopen validation failed.',
        );
      }
    } on SqliteException {
      throw const EncryptedSqliteProviderException(
        'Encrypted database reopen validation failed.',
      );
    } finally {
      database.close();
    }
  }

  void _verifyWrongKeyRejected(String path, String expectedMarker) {
    final wrongKey = DatabaseKey.fromBytes(List<int>.filled(32, 0));
    final database = sqlite3.open(path);
    try {
      _applyKey(database, wrongKey);
      final rows = database.select(
        'select marker from spike_marker where id = ?',
        <Object?>[1],
      );
      if (rows.isNotEmpty && rows.single['marker'] == expectedMarker) {
        throw const EncryptedSqliteProviderException(
          'Encrypted database accepted an incorrect key.',
        );
      }
      throw const EncryptedSqliteProviderException(
        'Encrypted database wrong-key validation was inconclusive.',
      );
    } on SqliteException {
      return;
    } finally {
      database.close();
    }
  }

  void _applyKey(Database database, DatabaseKey key) {
    database.execute("pragma key = \"x'${key.hexForSqlitePragma()}'\"");
  }

  void _verifyCipherProvider(Database database) {
    if (_hasRows(database, 'pragma cipher_version')) {
      return;
    }

    if (_hasRows(database, 'pragma cipher')) {
      return;
    }

    throw const EncryptedSqliteProviderException(
      'Encrypted SQLite cipher provider is unavailable.',
    );
  }

  bool _hasRows(Database database, String sql) {
    try {
      return database.select(sql).isNotEmpty;
    } on SqliteException {
      return false;
    }
  }
}
