import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/domain/model/app_settings.dart';
import 'package:networthy/presentation/app/networthy_app.dart';

import '../security/app_lock_widget_test.dart';
import '../test_app_harness.dart';

void main() {
  testWidgets('main flows render under common enlarged text scaling', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: NetworthyApp(
          transactions: TestTransactionRepository(),
          settings: TestSettingsRepository(
            const AppSettings(
              onboardingCompleted: true,
              biometricLockEnabled: false,
              currencyCode: 'TWD',
              lastExpenseCategoryId: null,
              lastIncomeCategoryId: null,
            ),
          ),
          clock: TestClock(DateTime.utc(2026, 8, 16, 1)),
          idGenerator: TestIdGenerator([
            '00000000-0000-4000-8000-000000008101',
          ]),
          authenticator: TestDeviceAuthenticator(authenticateResults: [true]),
          initialDate: DateTime(2026, 8, 16),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await tester.tap(find.bySemanticsLabel('新增一筆記帳'));
    await tester.pumpAndSettle();
    expect(find.text('新增記帳'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('開啟紀錄頁'));
    await tester.pumpAndSettle();
    expect(find.text('紀錄'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('開啟設定頁'));
    await tester.pumpAndSettle();
    expect(find.text('設定'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
