import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';

import '../security/database_key.dart';
import '../security/database_key_store.dart';
import '../spike/encrypted_database_spike.dart';
import 'networthy_database.dart';

class EncryptedDatabaseOpener {
  const EncryptedDatabaseOpener({
    required this.databasePath,
    required DatabaseKeyStore keyStore,
  }) : _keyStore = keyStore;

  final String databasePath;
  final DatabaseKeyStore _keyStore;

  Future<NetworthyDatabase> open() async {
    final file = File(databasePath);
    final databaseExists = await file.exists();
    final key = await _keyStore.loadOrCreate(databaseExists: databaseExists);
    await file.parent.create(recursive: true);

    final database = NetworthyDatabase(
      NativeDatabase(
        file,
        setup: (sqliteDatabase) => _setupEncryptedDatabase(sqliteDatabase, key),
      ),
    );

    try {
      await database.customSelect('select 1').get();
      return database;
    } on SqliteException {
      await database.close();
      throw const EncryptedSqliteWrongKeyException();
    } on DriftWrappedException {
      await database.close();
      throw const EncryptedSqliteWrongKeyException();
    }
  }

  void _setupEncryptedDatabase(Database database, DatabaseKey key) {
    database.execute("pragma key = \"x'${key.hexForSqlitePragma()}'\"");
    _verifyCipherProvider(database);
    database.select('select count(*) from sqlite_schema');
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
