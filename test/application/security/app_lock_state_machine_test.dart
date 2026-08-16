import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/application/security/app_lock_state_machine.dart';
import 'package:networthy/domain/model/app_settings.dart';

void main() {
  group('AppLockStateMachine', () {
    test('requires unlock on cold start when app lock is enabled', () {
      final decision = const AppLockStateMachine().onColdStart(
        const AppSettings(
          onboardingCompleted: true,
          biometricLockEnabled: true,
          currencyCode: 'TWD',
          lastExpenseCategoryId: null,
          lastIncomeCategoryId: null,
        ),
      );

      expect(decision.requiresUnlock, isTrue);
    });

    test('does not require unlock when app lock is disabled', () {
      final decision = const AppLockStateMachine().onColdStart(
        const AppSettings.defaults(),
      );

      expect(decision.requiresUnlock, isFalse);
    });

    test('requires unlock after resuming from background over 30 seconds', () {
      final machine = const AppLockStateMachine();
      final backgrounded = machine.onBackgrounded(DateTime.utc(2026, 8, 16, 1));

      final decision = backgrounded.onResumed(
        DateTime.utc(2026, 8, 16, 1, 0, 31),
        const AppSettings(
          onboardingCompleted: true,
          biometricLockEnabled: true,
          currencyCode: 'TWD',
          lastExpenseCategoryId: null,
          lastIncomeCategoryId: null,
        ),
      );

      expect(decision.requiresUnlock, isTrue);
    });

    test('does not require unlock after short background duration', () {
      final machine = const AppLockStateMachine();
      final backgrounded = machine.onBackgrounded(DateTime.utc(2026, 8, 16, 1));

      final decision = backgrounded.onResumed(
        DateTime.utc(2026, 8, 16, 1, 0, 30),
        const AppSettings(
          onboardingCompleted: true,
          biometricLockEnabled: true,
          currencyCode: 'TWD',
          lastExpenseCategoryId: null,
          lastIncomeCategoryId: null,
        ),
      );

      expect(decision.requiresUnlock, isFalse);
    });
  });
}
