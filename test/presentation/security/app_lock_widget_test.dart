import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/application/security/device_authenticator.dart';
import 'package:networthy/domain/model/app_settings.dart';
import 'package:networthy/presentation/app/networthy_app.dart';

import '../test_app_harness.dart';

void main() {
  testWidgets('shows lock screen on cold start when app lock is enabled', (
    tester,
  ) async {
    final authenticator = TestDeviceAuthenticator(authenticateResults: [true]);

    await _pumpLockedApp(tester, authenticator);

    expect(find.text('已鎖定'), findsOneWidget);

    await tester.tap(find.text('解鎖'));
    await tester.pumpAndSettle();

    expect(find.text('已鎖定'), findsNothing);
    expect(find.text('總覽'), findsWidgets);
  });

  testWidgets('failed auth stays on lock screen and allows retry', (
    tester,
  ) async {
    final authenticator = TestDeviceAuthenticator(
      authenticateResults: [false, true],
    );

    await _pumpLockedApp(tester, authenticator);

    await tester.tap(find.text('解鎖'));
    await tester.pumpAndSettle();

    expect(find.text('已鎖定'), findsOneWidget);
    expect(find.text('驗證失敗，請再試一次。'), findsOneWidget);

    await tester.tap(find.text('解鎖'));
    await tester.pumpAndSettle();

    expect(find.text('已鎖定'), findsNothing);
  });

  testWidgets('privacy overlay hides content while backgrounded', (
    tester,
  ) async {
    await _pumpLockedApp(
      tester,
      TestDeviceAuthenticator(authenticateResults: [true]),
      lockEnabled: false,
    );

    expect(find.text('總覽'), findsWidgets);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pumpAndSettle();

    expect(find.text('隱私保護中'), findsOneWidget);
    expect(find.text('總覽'), findsNothing);
  });

  testWidgets('resume after over 30 seconds requires unlock', (tester) async {
    final clock = TestClock(DateTime.utc(2026, 8, 16, 1));
    final authenticator = TestDeviceAuthenticator(authenticateResults: [true]);

    await tester.pumpWidget(
      NetworthyApp(
        transactions: TestTransactionRepository(),
        settings: _settings(lockEnabled: true),
        categories: TestCategoryRepository(),
        clock: clock,
        idGenerator: TestIdGenerator(['00000000-0000-4000-8000-000000000901']),
        authenticator: authenticator,
        initialDate: DateTime(2026, 8, 16),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('解鎖'));
    await tester.pumpAndSettle();
    expect(find.text('已鎖定'), findsNothing);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    clock.current = DateTime.utc(2026, 8, 16, 1, 0, 31);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.text('已鎖定'), findsOneWidget);
  });
}

Future<void> _pumpLockedApp(
  WidgetTester tester,
  TestDeviceAuthenticator authenticator, {
  bool lockEnabled = true,
}) async {
  await tester.pumpWidget(
    NetworthyApp(
      transactions: TestTransactionRepository(),
      settings: _settings(lockEnabled: lockEnabled),
      categories: TestCategoryRepository(),
      clock: TestClock(DateTime.utc(2026, 8, 16, 1)),
      idGenerator: TestIdGenerator(['00000000-0000-4000-8000-000000000900']),
      authenticator: authenticator,
      initialDate: DateTime(2026, 8, 16),
    ),
  );
  await tester.pumpAndSettle();
}

TestSettingsRepository _settings({required bool lockEnabled}) {
  return TestSettingsRepository(
    AppSettings(
      onboardingCompleted: true,
      biometricLockEnabled: lockEnabled,
      currencyCode: 'TWD',
      lastExpenseCategoryId: null,
      lastIncomeCategoryId: null,
    ),
  );
}

class TestDeviceAuthenticator implements DeviceAuthenticator {
  TestDeviceAuthenticator({
    this.supported = true,
    this.enrolled = true,
    required List<bool> authenticateResults,
  }) : _authenticateResults = authenticateResults;

  final bool supported;
  final bool enrolled;
  final List<bool> _authenticateResults;
  int authenticateCallCount = 0;

  @override
  Future<bool> canAuthenticate() async => supported && enrolled;

  @override
  Future<bool> isDeviceSupported() async => supported;

  @override
  Future<bool> hasEnrolledCredentials() async => enrolled;

  @override
  Future<bool> authenticate({required String reason}) async {
    authenticateCallCount += 1;
    return _authenticateResults.removeAt(0);
  }
}
