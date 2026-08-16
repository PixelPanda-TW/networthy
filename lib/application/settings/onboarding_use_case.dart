import '../../domain/model/app_settings.dart';
import '../../domain/repository/settings_repository.dart';

class CompleteOnboardingUseCase {
  const CompleteOnboardingUseCase(this._settings);

  final SettingsRepository _settings;

  Future<void> execute() async {
    final current = await _settings.load();
    await _settings.save(
      AppSettings(
        onboardingCompleted: true,
        biometricLockEnabled: current.biometricLockEnabled,
        currencyCode: current.currencyCode,
        lastExpenseCategoryId: current.lastExpenseCategoryId,
        lastIncomeCategoryId: current.lastIncomeCategoryId,
      ),
    );
  }
}
