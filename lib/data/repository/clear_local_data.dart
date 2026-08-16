import 'dart:io';

import '../security/database_key_store.dart';

abstract interface class LocalPreferencesStore {
  Future<void> clearRelatedPreferences();
}

class ClearLocalData {
  const ClearLocalData({
    required this.databasePath,
    required DatabaseKeyStore keyStore,
    required LocalPreferencesStore preferences,
  }) : _keyStore = keyStore,
       _preferences = preferences;

  final String databasePath;
  final DatabaseKeyStore _keyStore;
  final LocalPreferencesStore _preferences;

  Future<void> clear() async {
    await _deleteIfExists(File(databasePath));
    await _deleteIfExists(File('$databasePath-wal'));
    await _deleteIfExists(File('$databasePath-shm'));
    await _deleteIfExists(File('$databasePath-journal'));
    await _keyStore.delete();
    await _preferences.clearRelatedPreferences();
  }

  Future<void> _deleteIfExists(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }
}
