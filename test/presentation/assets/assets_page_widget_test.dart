import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/domain/model/app_settings.dart';
import 'package:networthy/domain/model/stock_account.dart';
import 'package:networthy/domain/repository/stock_account_repository.dart';
import 'package:networthy/presentation/app/networthy_app.dart';

import '../test_app_harness.dart';

void main() {
  testWidgets(
    'bottom navigation order includes assets between overview and records',
    (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      final navigation = find.byType(NavigationBar);
      expect(navigation, findsOneWidget);
      final labels = tester
          .widgetList<NavigationDestination>(
            find.descendant(
              of: navigation,
              matching: find.byType(NavigationDestination),
            ),
          )
          .map((destination) => destination.label)
          .toList();
      expect(labels, ['總覽', '資產', '紀錄', '設定']);
    },
  );

  testWidgets('creates and renames a Taiwan stock account', (tester) async {
    final accounts = TestStockAccountRepository();
    await tester.pumpWidget(_app(accounts: accounts));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('開啟資產頁'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('新增股票帳戶'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('stock-account-name-field')),
      '台股券商',
    );
    await tester.tap(find.text('儲存'));
    await tester.pumpAndSettle();

    expect(find.text('台股券商'), findsOneWidget);
    await tester.tap(find.byTooltip('重新命名 台股券商'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('stock-account-name-field')),
      '新台股券商',
    );
    await tester.tap(find.text('儲存'));
    await tester.pumpAndSettle();

    expect(find.text('新台股券商'), findsOneWidget);
  });

  testWidgets('creates valuation and principal holdings and archives one', (
    tester,
  ) async {
    final accounts = TestStockAccountRepository();
    final holdings = TestStockHoldingRepository();
    await accounts.create(
      const CreateStockAccountRequest(
        id: '00000000-0000-4000-8000-000000045001',
        name: 'ETF 帳戶',
        mode: StockAccountMode.taiwanEtf,
      ),
    );
    await tester.pumpWidget(_app(accounts: accounts, holdings: holdings));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('開啟資產頁'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('新增持倉 台股 ETF'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('stock-symbol-field')), '0050');
    await tester.enterText(find.byKey(const Key('stock-name-field')), '元大台灣50');
    await tester.enterText(
      find.byKey(const Key('stock-principal-field')),
      '100000',
    );
    await tester.tap(find.text('儲存'));
    await tester.pumpAndSettle();

    expect(holdings.values, hasLength(1));
    expect(find.textContaining('0050'), findsOneWidget);
    await tester.tap(find.byTooltip('封存 0050'));
    await tester.pumpAndSettle();
    expect(find.textContaining('0050'), findsNothing);
  });
}

NetworthyApp _app({
  TestStockAccountRepository? accounts,
  TestStockHoldingRepository? holdings,
}) {
  return NetworthyApp(
    transactions: TestTransactionRepository(),
    accounts: TestAccountRepository(),
    ledger: TestLedgerRepository(),
    stockAccounts: accounts ?? TestStockAccountRepository(),
    stockHoldings: holdings ?? TestStockHoldingRepository(),
    settings: TestSettingsRepository(
      const AppSettings(
        onboardingCompleted: true,
        biometricLockEnabled: false,
        currencyCode: 'TWD',
        lastExpenseCategoryId: null,
        lastIncomeCategoryId: null,
      ),
    ),
    categories: TestCategoryRepository(),
    clock: TestClock(DateTime.utc(2026, 8, 18)),
    idGenerator: TestIdGenerator([
      '00000000-0000-4000-8000-000000045002',
      '00000000-0000-4000-8000-000000045003',
      '00000000-0000-4000-8000-000000045004',
    ]),
    initialDate: DateTime(2026, 8, 18),
  );
}
