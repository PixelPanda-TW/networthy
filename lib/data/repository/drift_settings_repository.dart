import 'package:drift/drift.dart';

import '../../domain/model/app_settings.dart';
import '../../domain/repository/settings_repository.dart';
import '../database/networthy_database.dart';

class DriftSettingsRepository implements SettingsRepository {
  const DriftSettingsRepository(this._database);

  static const int _singleSettingsRowId = 1;

  final NetworthyDatabase _database;

  @override
  Future<AppSettings> load() async {
    final row =
        await (_database.select(_database.appSettingsRows)
              ..where((table) => table.id.equals(_singleSettingsRowId)))
            .getSingleOrNull();
    if (row == null) {
      return const AppSettings.defaults();
    }

    return AppSettings(
      onboardingCompleted: row.onboardingCompleted,
      biometricLockEnabled: row.biometricLockEnabled,
      currencyCode: row.currencyCode,
      lastExpenseCategoryId: row.lastExpenseCategoryId,
      lastIncomeCategoryId: row.lastIncomeCategoryId,
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    await _database
        .into(_database.appSettingsRows)
        .insertOnConflictUpdate(
          AppSettingsRowsCompanion(
            id: const Value(_singleSettingsRowId),
            onboardingCompleted: Value(settings.onboardingCompleted),
            biometricLockEnabled: Value(settings.biometricLockEnabled),
            currencyCode: Value(settings.currencyCode),
            lastExpenseCategoryId: Value(settings.lastExpenseCategoryId),
            lastIncomeCategoryId: Value(settings.lastIncomeCategoryId),
          ),
        );
  }
}
