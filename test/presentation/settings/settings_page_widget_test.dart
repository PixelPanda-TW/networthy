import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/domain/model/app_settings.dart';
import 'package:networthy/presentation/app/networthy_app.dart';

import '../security/app_lock_widget_test.dart';
import '../test_app_harness.dart';

void main() {
  testWidgets('settings page shows app version and offline privacy copy', (
    tester,
  ) async {
    await _pumpApp(tester, TestDeviceAuthenticator(authenticateResults: []));

    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();

    expect(find.text('版本 0.1.0'), findsOneWidget);
    expect(find.textContaining('資料只儲存在這台裝置'), findsOneWidget);
    expect(find.textContaining('解除安裝或清除 App 資料'), findsOneWidget);
  });

  testWidgets('enables and disables app lock after supported device check', (
    tester,
  ) async {
    final settings = _settings(lockEnabled: false);

    await _pumpApp(
      tester,
      TestDeviceAuthenticator(authenticateResults: [], supported: true),
      settings: settings,
    );
    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('App 鎖定'));
    await tester.pumpAndSettle();

    expect(settings.value.biometricLockEnabled, isTrue);

    await tester.tap(find.text('App 鎖定'));
    await tester.pumpAndSettle();

    expect(settings.value.biometricLockEnabled, isFalse);
  });

  testWidgets('unsupported or unenrolled device preserves app lock setting', (
    tester,
  ) async {
    final settings = _settings(lockEnabled: false);

    await _pumpApp(
      tester,
      TestDeviceAuthenticator(
        authenticateResults: [],
        supported: false,
        enrolled: false,
      ),
      settings: settings,
    );
    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('App 鎖定'));
    await tester.pumpAndSettle();

    expect(settings.value.biometricLockEnabled, isFalse);
    expect(find.text('此裝置尚未設定可用的系統驗證。'), findsOneWidget);
  });

  testWidgets('settings opens category management', (tester) async {
    await _pumpApp(tester, TestDeviceAuthenticator(authenticateResults: []));

    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('分類管理'));
    await tester.pumpAndSettle();

    expect(find.text('支出分類'), findsOneWidget);
  });
}

Future<void> _pumpApp(
  WidgetTester tester,
  TestDeviceAuthenticator authenticator, {
  TestSettingsRepository? settings,
}) async {
  await tester.pumpWidget(
    NetworthyApp(
      transactions: TestTransactionRepository(),
      accounts: TestAccountRepository(),
      ledger: TestLedgerRepository(),
      settings: settings ?? _settings(lockEnabled: false),
      categories: TestCategoryRepository(),
      clock: TestClock(DateTime.utc(2026, 8, 16, 1)),
      idGenerator: TestIdGenerator(['00000000-0000-4000-8000-000000000911']),
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
