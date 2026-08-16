class AppSettings {
  const AppSettings({
    required this.biometricLockEnabled,
    required this.currencyCode,
    required this.lastExpenseCategoryId,
    required this.lastIncomeCategoryId,
    required this.onboardingCompleted,
  });

  const AppSettings.defaults()
    : biometricLockEnabled = false,
      currencyCode = 'TWD',
      lastExpenseCategoryId = null,
      lastIncomeCategoryId = null,
      onboardingCompleted = false;

  final bool biometricLockEnabled;
  final String currencyCode;
  final String? lastExpenseCategoryId;
  final String? lastIncomeCategoryId;
  final bool onboardingCompleted;
}
