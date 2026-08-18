import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/domain/model/app_settings.dart';
import 'package:networthy/domain/model/stock_account.dart';
import 'package:networthy/domain/repository/stock_holding_repository.dart';
import 'package:networthy/presentation/app/networthy_app.dart';

import '../test_app_harness.dart';

void main() {
  testWidgets('overview displays stock asset summaries separately from cash', (
    tester,
  ) async {
    final holdings = TestStockHoldingRepository();
    await holdings.saveValuation(
      const SaveValuationHoldingRequest(
        id: '00000000-0000-4000-8000-000000046001',
        accountId: '00000000-0000-4000-8000-000000046002',
        symbol: '2330',
        name: '台積電',
        accountMode: StockAccountMode.taiwanStock,
        quantityMicro: 1000000,
        averageCostMinor: 60000,
        currentPriceMinor: 65000,
      ),
    );
    await holdings.savePrincipal(
      const SavePrincipalHoldingRequest(
        id: '00000000-0000-4000-8000-000000046003',
        accountId: '00000000-0000-4000-8000-000000046004',
        symbol: '0050',
        name: '元大台灣50',
        accountMode: StockAccountMode.taiwanEtf,
        principalMinor: 100000,
      ),
    );
    await holdings.savePrincipal(
      const SavePrincipalHoldingRequest(
        id: '00000000-0000-4000-8000-000000046005',
        accountId: '00000000-0000-4000-8000-000000046006',
        symbol: 'VOO',
        name: 'Vanguard S&P 500 ETF',
        accountMode: StockAccountMode.usStock,
        principalMinor: 200000,
      ),
    );

    await tester.pumpWidget(
      NetworthyApp(
        transactions: TestTransactionRepository(),
        accounts: TestAccountRepository(),
        ledger: TestLedgerRepository(),
        stockHoldings: holdings,
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
        idGenerator: TestIdGenerator(['00000000-0000-4000-8000-000000046007']),
        initialDate: DateTime(2026, 8, 18),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('股票資產'), findsOneWidget);
    expect(find.text('台股個股市值 NT\$65,000'), findsOneWidget);
    expect(find.text('台股 ETF 本金 NT\$100,000'), findsOneWidget);
    expect(find.text('美股本金 US\$200,000'), findsOneWidget);
    expect(find.text('現金 NT\$0'), findsNothing);
  });

  testWidgets('overview hides stock section when all holdings are archived', (
    tester,
  ) async {
    final holdings = TestStockHoldingRepository();
    final holding = await holdings.savePrincipal(
      const SavePrincipalHoldingRequest(
        id: '00000000-0000-4000-8000-000000046008',
        accountId: '00000000-0000-4000-8000-000000046009',
        symbol: 'VOO',
        name: 'VOO',
        accountMode: StockAccountMode.usStock,
        principalMinor: 200000,
      ),
    );
    await holdings.archive(holding.id);

    await tester.pumpWidget(
      NetworthyApp(
        transactions: TestTransactionRepository(),
        accounts: TestAccountRepository(),
        ledger: TestLedgerRepository(),
        stockHoldings: holdings,
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
        idGenerator: TestIdGenerator(['00000000-0000-4000-8000-000000046010']),
        initialDate: DateTime(2026, 8, 18),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('股票資產'), findsNothing);
  });
}
