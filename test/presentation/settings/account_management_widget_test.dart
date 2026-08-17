import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/presentation/settings/account_management_page.dart';

import '../test_app_harness.dart';

void main() {
  testWidgets('creates renames and archives an account with opening balance', (
    tester,
  ) async {
    final accounts = TestAccountRepository(seedDefault: false);
    final ledger = TestLedgerRepository();

    await tester.pumpWidget(
      testMaterialApp(
        AccountManagementPage(
          accounts: accounts,
          ledger: ledger,
          clock: TestClock(DateTime.utc(2026, 8, 17, 1)),
          idGenerator: TestIdGenerator([
            '00000000-0000-4000-8000-000000036001',
            '00000000-0000-4000-8000-000000036002',
            '00000000-0000-4000-8000-000000036003',
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('帳戶管理'), findsOneWidget);

    await tester.tap(find.text('新增帳戶'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('account-name-field')), '玉山台幣');
    await tester.enterText(
      find.byKey(const Key('opening-balance-field')),
      '1000',
    );
    await tester.tap(find.text('儲存'));
    await tester.pumpAndSettle();

    expect(find.text('玉山台幣'), findsOneWidget);
    expect(find.text('NT\$1,000'), findsOneWidget);
    expect((await ledger.accountBalances()).single.balanceMinor, 1000);

    await tester.tap(find.byTooltip('重新命名 玉山台幣'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('account-name-field')), '玉山薪轉');
    await tester.tap(find.text('儲存'));
    await tester.pumpAndSettle();

    expect(find.text('玉山薪轉'), findsOneWidget);

    await tester.tap(find.byTooltip('封存 玉山薪轉'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('封存'));
    await tester.pumpAndSettle();

    expect(find.text('玉山薪轉'), findsNothing);
    expect((await accounts.listActive()), isEmpty);
  });
}
