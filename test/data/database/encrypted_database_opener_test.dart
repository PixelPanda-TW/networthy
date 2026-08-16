import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/data/database/encrypted_database_opener.dart';
import 'package:networthy/data/repository/drift_transaction_repository.dart';
import 'package:networthy/data/security/database_key.dart';
import 'package:networthy/data/security/database_key_errors.dart';
import 'package:networthy/data/security/database_key_store.dart';
import 'package:networthy/data/spike/encrypted_database_spike.dart';
import 'package:networthy/domain/model/local_date.dart';
import 'package:networthy/domain/model/transaction.dart';
import 'package:networthy/domain/model/transaction_type.dart';

void main() {
  group('EncryptedDatabaseOpener', () {
    test(
      'creates and reopens an encrypted database with the stored key',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'networthy-opener-',
        );
        addTearDown(() => tempDir.delete(recursive: true));
        final databasePath = '${tempDir.path}/networthy.db';
        final secrets = InMemorySecretStore();
        final keyStore = SecureDatabaseKeyStore(secrets: secrets);

        final firstDatabase = await EncryptedDatabaseOpener(
          databasePath: databasePath,
          keyStore: keyStore,
        ).open();
        addTearDown(firstDatabase.close);
        await DriftTransactionRepository(firstDatabase).save(_expense());
        await firstDatabase.close();

        final reopenedDatabase = await EncryptedDatabaseOpener(
          databasePath: databasePath,
          keyStore: keyStore,
        ).open();
        addTearDown(reopenedDatabase.close);

        final transaction = await DriftTransactionRepository(
          reopenedDatabase,
        ).findById('00000000-0000-4000-8000-000000000201');
        expect(transaction?.amountMinor, 4200);
        expect(
          await secrets.read(SecureDatabaseKeyStore.defaultStorageKey),
          isNotNull,
        );
      },
    );

    test(
      'rejects an existing encrypted database when the stored key is wrong',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'networthy-wrong-key-',
        );
        addTearDown(() => tempDir.delete(recursive: true));
        final databasePath = '${tempDir.path}/networthy.db';

        final correctSecrets = InMemorySecretStore();
        final correctStore = SecureDatabaseKeyStore(secrets: correctSecrets);
        final createdDatabase = await EncryptedDatabaseOpener(
          databasePath: databasePath,
          keyStore: correctStore,
        ).open();
        addTearDown(createdDatabase.close);
        await DriftTransactionRepository(createdDatabase).save(_expense());
        await createdDatabase.close();

        final wrongSecrets = InMemorySecretStore();
        await wrongSecrets.write(
          key: SecureDatabaseKeyStore.defaultStorageKey,
          value: DatabaseKey.fromBytes(
            List<int>.filled(DatabaseKey.byteLength, 9),
          ).encodeForStorage(),
        );

        expect(
          () => EncryptedDatabaseOpener(
            databasePath: databasePath,
            keyStore: SecureDatabaseKeyStore(secrets: wrongSecrets),
          ).open(),
          throwsA(isA<EncryptedSqliteWrongKeyException>()),
        );
      },
    );

    test(
      'does not create a replacement key for an existing database',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'networthy-missing-key-',
        );
        addTearDown(() => tempDir.delete(recursive: true));
        final databasePath = '${tempDir.path}/networthy.db';

        final originalDatabase = await EncryptedDatabaseOpener(
          databasePath: databasePath,
          keyStore: SecureDatabaseKeyStore(secrets: InMemorySecretStore()),
        ).open();
        addTearDown(originalDatabase.close);
        await DriftTransactionRepository(originalDatabase).save(_expense());
        await originalDatabase.close();

        expect(
          () => EncryptedDatabaseOpener(
            databasePath: databasePath,
            keyStore: SecureDatabaseKeyStore(secrets: InMemorySecretStore()),
          ).open(),
          throwsA(isA<DatabaseKeyMissingException>()),
        );
      },
    );
  });
}

BookkeepingTransaction _expense() {
  return BookkeepingTransaction.create(
    id: '00000000-0000-4000-8000-000000000201',
    type: TransactionType.expense,
    amountMinor: 4200,
    categoryId: 'expense.food',
    transactionDate: LocalDate(2026, 8, 16),
    createdAtUtc: DateTime.utc(2026, 8, 16, 1),
    updatedAtUtc: DateTime.utc(2026, 8, 16, 1),
  );
}

class InMemorySecretStore implements KeyValueSecretStore {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }

  @override
  Future<String?> read(String key) async {
    return _values[key];
  }

  @override
  Future<void> write({required String key, required String value}) async {
    _values[key] = value;
  }
}
