import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/data/security/database_key.dart';
import 'package:networthy/data/security/database_key_errors.dart';
import 'package:networthy/data/security/database_key_store.dart';
import 'package:networthy/data/spike/encrypted_database_spike.dart';
import 'package:networthy/data/spike/encrypted_database_spike_result.dart';

void main() {
  test(
    'run reports missingKey when database exists and key is absent',
    () async {
      final spike = EncryptedDatabaseSpike(
        databaseExists: () async => true,
        keyStore: ThrowingDatabaseKeyStore(),
        probe: RecordingProbe(),
      );

      final result = await spike.run();

      expect(result.status, EncryptedDatabaseSpikeStatus.missingKey);
    },
  );

  test(
    'run reports providerValidationFailed without sensitive details',
    () async {
      final spike = EncryptedDatabaseSpike(
        databaseExists: () async => false,
        keyStore: FixedDatabaseKeyStore(),
        probe: ThrowingProbe(),
      );

      final result = await spike.run();

      expect(
        result.status,
        EncryptedDatabaseSpikeStatus.providerValidationFailed,
      );
      expect(result.safeMessage, isNot(contains('secret')));
    },
  );

  test(
    'run reports success when key and provider validation succeed',
    () async {
      final probe = RecordingProbe();
      final spike = EncryptedDatabaseSpike(
        databaseExists: () async => false,
        keyStore: FixedDatabaseKeyStore(),
        probe: probe,
      );

      final result = await spike.run();

      expect(result.status, EncryptedDatabaseSpikeStatus.success);
      expect(probe.validated, isTrue);
    },
  );

  test(
    'sqlite3 multiple ciphers probe creates reopens and rejects wrong key',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'networthy_sqlite3mc_probe_',
      );
      addTearDown(() async {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      });
      final databasePath = '${directory.path}/probe.db';
      final key = DatabaseKey.fromBytes(List<int>.filled(32, 11));
      final probe = Sqlite3MultipleCiphersProbe(databasePath: databasePath);

      await probe.validate(key);

      expect(File(databasePath).existsSync(), isTrue);
    },
  );
}

class ThrowingDatabaseKeyStore implements DatabaseKeyStore {
  @override
  Future<void> delete() async {}

  @override
  Future<DatabaseKey> loadExisting() async {
    throw const DatabaseKeyMissingException();
  }

  @override
  Future<DatabaseKey> loadOrCreate({required bool databaseExists}) async {
    throw const DatabaseKeyMissingException();
  }
}

class FixedDatabaseKeyStore implements DatabaseKeyStore {
  final DatabaseKey key = DatabaseKey.fromBytes(List<int>.filled(32, 7));

  @override
  Future<void> delete() async {}

  @override
  Future<DatabaseKey> loadExisting() async {
    return key;
  }

  @override
  Future<DatabaseKey> loadOrCreate({required bool databaseExists}) async {
    return key;
  }
}

class RecordingProbe implements EncryptedSqliteProbe {
  bool validated = false;

  @override
  Future<void> validate(DatabaseKey key) async {
    validated = true;
  }
}

class ThrowingProbe implements EncryptedSqliteProbe {
  @override
  Future<void> validate(DatabaseKey key) async {
    throw const EncryptedSqliteProviderException('secret provider failure');
  }
}
