import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/data/database/networthy_database.dart';
import 'package:networthy/data/repository/drift_settings_repository.dart';
import 'package:networthy/domain/model/app_settings.dart';

void main() {
  group('DriftSettingsRepository', () {
    test('loads default settings when no row has been saved', () async {
      final database = NetworthyDatabase.inMemory();
      addTearDown(database.close);
      final repository = DriftSettingsRepository(database);

      final settings = await repository.load();

      expect(settings.onboardingCompleted, isFalse);
      expect(settings.biometricLockEnabled, isFalse);
      expect(settings.currencyCode, 'TWD');
      expect(settings.lastExpenseCategoryId, isNull);
      expect(settings.lastIncomeCategoryId, isNull);
    });

    test('saves and reloads app settings', () async {
      final database = NetworthyDatabase.inMemory();
      addTearDown(database.close);
      final repository = DriftSettingsRepository(database);

      await repository.save(
        const AppSettings(
          onboardingCompleted: true,
          biometricLockEnabled: true,
          currencyCode: 'TWD',
          lastExpenseCategoryId: 'expense.food',
          lastIncomeCategoryId: 'income.salary',
        ),
      );

      final settings = await repository.load();

      expect(settings.onboardingCompleted, isTrue);
      expect(settings.biometricLockEnabled, isTrue);
      expect(settings.currencyCode, 'TWD');
      expect(settings.lastExpenseCategoryId, 'expense.food');
      expect(settings.lastIncomeCategoryId, 'income.salary');
    });
  });
}
