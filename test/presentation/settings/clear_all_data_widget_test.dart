import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/application/settings/local_data_clearer.dart';
import 'package:networthy/domain/model/app_settings.dart';
import 'package:networthy/presentation/app/networthy_app.dart';

import '../security/app_lock_widget_test.dart';
import '../test_app_harness.dart';

void main() {
  testWidgets('clear all data requires double confirmation', (tester) async {
    final clearer = TestLocalDataClearer();

    await _pumpApp(
      tester,
      clearer: clearer,
      authenticator: TestDeviceAuthenticator(authenticateResults: []),
    );
    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('清除所有資料'));
    await tester.pumpAndSettle();
    expect(find.text('第一次確認'), findsOneWidget);

    await tester.tap(find.text('繼續'));
    await tester.pumpAndSettle();
    expect(find.text('最後確認'), findsOneWidget);

    expect(clearer.clearCount, 0);
  });

  testWidgets('clear all data authenticates when app lock is enabled', (
    tester,
  ) async {
    final clearer = TestLocalDataClearer();
    final settings = _settings(lockEnabled: true);
    final authenticator = TestDeviceAuthenticator(
      authenticateResults: [true, true],
    );

    await _pumpApp(
      tester,
      settings: settings,
      clearer: clearer,
      authenticator: authenticator,
    );
    await tester.tap(find.text('解鎖'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('清除所有資料'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('繼續'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('清除'));
    await tester.pumpAndSettle();

    expect(clearer.clearCount, 1);
    expect(authenticator.authenticateCallCount, 2);
    expect(find.text('資料只存在這台裝置'), findsOneWidget);
  });

  testWidgets('clear all data returns to first-use onboarding state', (
    tester,
  ) async {
    final settings = _settings(lockEnabled: false);

    await _pumpApp(
      tester,
      settings: settings,
      clearer: TestLocalDataClearer(),
      authenticator: TestDeviceAuthenticator(authenticateResults: []),
    );
    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('清除所有資料'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('繼續'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('清除'));
    await tester.pumpAndSettle();

    expect(settings.value.onboardingCompleted, isFalse);
    expect(find.text('資料只存在這台裝置'), findsOneWidget);
  });
}

Future<void> _pumpApp(
  WidgetTester tester, {
  TestSettingsRepository? settings,
  required TestLocalDataClearer clearer,
  required TestDeviceAuthenticator authenticator,
}) async {
  await tester.pumpWidget(
    NetworthyApp(
      transactions: TestTransactionRepository(),
      settings: settings ?? _settings(lockEnabled: false),
      clock: TestClock(DateTime.utc(2026, 8, 16, 1)),
      idGenerator: TestIdGenerator(['00000000-0000-4000-8000-000000000921']),
      authenticator: authenticator,
      localDataClearer: clearer,
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

class TestLocalDataClearer implements LocalDataClearer {
  int clearCount = 0;

  @override
  Future<void> clear() async {
    clearCount += 1;
  }
}
