import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/application/stock/execute_stock_trade_use_case.dart';
import 'package:networthy/application/stock/stock_trade_command.dart';
import 'package:networthy/application/stock/stock_trade_execution.dart';
import 'package:networthy/application/common/application_failure.dart';
import 'package:networthy/domain/ledger/ledger_transaction_builder.dart';
import 'package:networthy/domain/model/currency_code.dart';
import 'package:networthy/domain/model/ledger_transaction.dart';
import 'package:networthy/domain/model/local_date.dart';
import 'package:networthy/domain/model/stock_account.dart';
import 'package:networthy/domain/model/stock_trade.dart';
import 'package:networthy/domain/model/stock_holding.dart';
import 'package:networthy/domain/repository/account_repository.dart';
import 'package:networthy/domain/repository/stock_account_repository.dart';
import '../../presentation/test_app_harness.dart';

void main() {
  test('buy creates weighted holding and investment expense', () async {
    final stockAccounts = TestStockAccountRepository();
    final cashAccounts = TestAccountRepository(seedDefault: false);
    final holdings = TestStockHoldingRepository();
    final ledger = TestLedgerRepository();
    await stockAccounts.create(
      const CreateStockAccountRequest(
        id: '00000000-0000-4000-8000-000000053101',
        name: '台股',
        mode: StockAccountMode.taiwanStock,
      ),
    );
    await cashAccounts.create(
      const CreateAccountRequest(
        id: '00000000-0000-4000-8000-000000053102',
        name: '現金',
        currencyCode: CurrencyCode.twd,
        openingBalanceMinor: 1000000,
      ),
    );
    await ledger.save(
      LedgerTransactionBuilder.openingBalance(
        transactionId: '00000000-0000-4000-8000-000000053108',
        entryId: '00000000-0000-4000-8000-000000053109',
        account: cashAccounts.values['00000000-0000-4000-8000-000000053102']!,
        amountMinor: 1000000,
        transactionDate: LocalDate(2026, 8, 17),
        createdAtUtc: DateTime.utc(2026, 8, 17),
      ),
    );
    final executor = _RecordingExecutor();
    final result =
        await ExecuteStockTradeUseCase(
          stockAccounts: stockAccounts,
          cashAccounts: cashAccounts,
          holdings: holdings,
          ledger: ledger,
          executor: executor,
          clock: TestClock(DateTime.utc(2026, 8, 18)),
          idGenerator: TestIdGenerator([
        '00000000-0000-4000-8000-000000053103',
        '00000000-0000-4000-8000-000000053104',
        '00000000-0000-4000-8000-000000053105',
        '00000000-0000-4000-8000-000000053110',
          ]),
        ).execute(
          ExecuteStockTradeCommand(
            stockAccountId: '00000000-0000-4000-8000-000000053101',
            cashAccountId: '00000000-0000-4000-8000-000000053102',
            side: StockTradeSide.buy,
            symbol: '2330',
            name: '台積電',
            accountMode: StockAccountMode.taiwanStock,
            quantityMicro: 1000000,
            priceMinor: 90000,
            tradeDate: LocalDate(2026, 8, 18),
          ),
        );

    expect(result.failure, isNull);
    expect(executor.trade?.cashAmountMinor, 90000);
    expect(executor.holding?.quantityMicro, 1000000);
    expect(executor.holding?.averageCostMinor, 90000);
    expect(executor.ledger.transaction.type, LedgerTransactionType.expense);
    expect(executor.ledger.transaction.categoryId, 'expense.investment');
    expect(executor.ledger.entries.single.amountMinor, -90000);
  });

  test(
    'rejects mismatched currency and over-sell before persistence',
    () async {
      final stockAccounts = TestStockAccountRepository();
      final cashAccounts = TestAccountRepository(seedDefault: false);
      final holdings = TestStockHoldingRepository();
      final ledger = TestLedgerRepository();
      await stockAccounts.create(
        const CreateStockAccountRequest(
          id: '00000000-0000-4000-8000-000000053106',
          name: '美股',
          mode: StockAccountMode.usStock,
        ),
      );
      await cashAccounts.create(
        const CreateAccountRequest(
          id: '00000000-0000-4000-8000-000000053107',
          name: '台幣現金',
          currencyCode: CurrencyCode.twd,
          openingBalanceMinor: 1000000,
        ),
      );
      final executor = _RecordingExecutor();
      final useCase = ExecuteStockTradeUseCase(
        stockAccounts: stockAccounts,
        cashAccounts: cashAccounts,
        holdings: holdings,
        ledger: ledger,
        executor: executor,
        clock: TestClock(DateTime.utc(2026, 8, 18)),
        idGenerator: TestIdGenerator([]),
      );

      final result = await useCase.execute(
        ExecuteStockTradeCommand(
          stockAccountId: '00000000-0000-4000-8000-000000053106',
          cashAccountId: '00000000-0000-4000-8000-000000053107',
          side: StockTradeSide.buy,
          symbol: 'VOO',
          name: 'Vanguard S&P 500 ETF',
          accountMode: StockAccountMode.usStock,
          principalMinor: 500000,
          tradeDate: LocalDate(2026, 8, 18),
        ),
      );

      expect(result.failure?.type, ApplicationFailureType.validation);
      expect(executor.trade, isNull);
    },
  );
}

class _RecordingExecutor implements StockTradeAtomicExecutor {
  StockTrade? trade;
  StockHolding? holding;
  String? archiveId;
  late LedgerTransactionAggregate ledger;

  @override
  Future<void> execute({
    required StockTrade trade,
    required StockHolding? updatedHolding,
    required String? holdingToArchiveId,
    required LedgerTransactionAggregate ledger,
  }) async {
    this.trade = trade;
    holding = updatedHolding;
    archiveId = holdingToArchiveId;
    this.ledger = ledger;
  }
}
