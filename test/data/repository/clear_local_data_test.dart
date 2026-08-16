import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/data/repository/clear_local_data.dart';
import 'package:networthy/data/security/database_key_store.dart';

void main() {
  test('removes database files key and related preferences', () async {
    final tempDir = await Directory.systemTemp.createTemp('networthy-clear-');
    addTearDown(() => tempDir.delete(recursive: true));
    final databasePath = '${tempDir.path}/networthy.db';
    final files = [
      File(databasePath),
      File('$databasePath-wal'),
      File('$databasePath-shm'),
      File('$databasePath-journal'),
    ];
    for (final file in files) {
      await file.writeAsString('local data');
    }
    final secrets = InMemorySecretStore();
    final keyStore = SecureDatabaseKeyStore(secrets: secrets);
    await keyStore.loadOrCreate(databaseExists: false);
    final preferences = InMemoryLocalPreferencesStore();
    preferences.values['networthy.onboarding_seen'] = true;

    await ClearLocalData(
      databasePath: databasePath,
      keyStore: keyStore,
      preferences: preferences,
    ).clear();

    for (final file in files) {
      expect(await file.exists(), isFalse);
    }
    expect(
      await secrets.read(SecureDatabaseKeyStore.defaultStorageKey),
      isNull,
    );
    expect(preferences.values, isEmpty);
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

class InMemoryLocalPreferencesStore implements LocalPreferencesStore {
  final Map<String, Object?> values = <String, Object?>{};

  @override
  Future<void> clearRelatedPreferences() async {
    values.clear();
  }
}
