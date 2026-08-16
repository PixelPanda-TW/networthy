import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/domain/model/app_settings.dart';

void main() {
  test('uses V1 default settings', () {
    const settings = AppSettings.defaults();

    expect(settings.biometricLockEnabled, isFalse);
    expect(settings.currencyCode, 'TWD');
    expect(settings.lastExpenseCategoryId, isNull);
    expect(settings.lastIncomeCategoryId, isNull);
    expect(settings.onboardingCompleted, isFalse);
  });
}
