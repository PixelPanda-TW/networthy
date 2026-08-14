import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/data/security/database_key_errors.dart';
import 'package:networthy/data/security/database_key_store.dart';

void main() {
  test(
    'loadOrCreate creates and stores a 256-bit key when database is absent',
    () async {
      final secrets = InMemorySecretStore();
      final store = SecureDatabaseKeyStore(secrets: secrets);

      final key = await store.loadOrCreate(databaseExists: false);

      expect(key.bytes, hasLength(32));
      expect(
        await secrets.read(SecureDatabaseKeyStore.defaultStorageKey),
        isNotNull,
      );
    },
  );

  test('loadOrCreate reuses an existing stored key', () async {
    final secrets = InMemorySecretStore();
    final store = SecureDatabaseKeyStore(secrets: secrets);

    final first = await store.loadOrCreate(databaseExists: false);
    final second = await store.loadOrCreate(databaseExists: true);

    expect(second.hexForSqlitePragma(), first.hexForSqlitePragma());
  });

  test(
    'loadOrCreate does not replace a missing key for an existing database',
    () async {
      final store = SecureDatabaseKeyStore(secrets: InMemorySecretStore());

      expect(
        () => store.loadOrCreate(databaseExists: true),
        throwsA(isA<DatabaseKeyMissingException>()),
      );
    },
  );

  test('loadExisting throws when no key is stored', () async {
    final store = SecureDatabaseKeyStore(secrets: InMemorySecretStore());

    expect(store.loadExisting, throwsA(isA<DatabaseKeyMissingException>()));
  });
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
