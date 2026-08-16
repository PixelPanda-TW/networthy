import '../../application/settings/local_data_clearer.dart';
import 'clear_local_data.dart';

class ClearLocalDataAdapter implements LocalDataClearer {
  const ClearLocalDataAdapter(this._clearLocalData);

  final ClearLocalData _clearLocalData;

  @override
  Future<void> clear() => _clearLocalData.clear();
}

class NoOpLocalPreferencesStore implements LocalPreferencesStore {
  const NoOpLocalPreferencesStore();

  @override
  Future<void> clearRelatedPreferences() async {}
}
