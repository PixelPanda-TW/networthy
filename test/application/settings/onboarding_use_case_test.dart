import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/application/settings/onboarding_use_case.dart';
import 'package:networthy/domain/model/app_settings.dart';
import 'package:networthy/domain/repository/settings_repository.dart';

void main() {
  test(
    'complete onboarding preserves settings and marks onboarding completed',
    () async {
      final repository = FakeSettingsRepository(
        const AppSettings(
          onboardingCompleted: false,
          biometricLockEnabled: true,
          currencyCode: 'TWD',
          lastExpenseCategoryId: 'expense.food',
          lastIncomeCategoryId: 'income.salary',
        ),
      );

      await CompleteOnboardingUseCase(repository).execute();

      expect(repository.saved.onboardingCompleted, isTrue);
      expect(repository.saved.biometricLockEnabled, isTrue);
      expect(repository.saved.lastExpenseCategoryId, 'expense.food');
      expect(repository.saved.lastIncomeCategoryId, 'income.salary');
    },
  );
}

class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository(this.saved);

  AppSettings saved;

  @override
  Future<AppSettings> load() async => saved;

  @override
  Future<void> save(AppSettings settings) async {
    saved = settings;
  }
}
