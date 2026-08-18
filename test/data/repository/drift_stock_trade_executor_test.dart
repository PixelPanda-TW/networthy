import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/data/database/networthy_database.dart';
import 'package:networthy/data/repository/drift_account_repository.dart';
import 'package:networthy/data/repository/drift_ledger_repository.dart';
import 'package:networthy/data/repository/drift_stock_account_repository.dart';
import 'package:networthy/data/repository/drift_stock_holding_repository.dart';
import 'package:networthy/data/repository/drift_stock_trade_executor.dart';
import 'package:networthy/data/repository/drift_stock_trade_repository.dart';
import 'package:networthy/domain/ledger/ledger_transaction_builder.dart';
import 'package:networthy/domain/model/currency_code.dart';
import 'package:networthy/domain/model/local_date.dart';
import 'package:networthy/domain/model/stock_account.dart';
import 'package:networthy/domain/model/stock_holding.dart' as domain;
import 'package:networthy/domain/model/stock_trade.dart' as domain_trade;
import 'package:networthy/domain/repository/account_repository.dart';
import 'package:networthy/domain/repository/stock_account_repository.dart';

void main() {
  test('writes trade, holding, and ledger in one executor operation', () async {
    final database = NetworthyDatabase.inMemory();
    addTearDown(database.close);
    final cashAccounts = DriftAccountRepository(database);
    final stockAccounts = DriftStockAccountRepository(database);
    await cashAccounts.create(
      const CreateAccountRequest(
        id: '00000000-0000-4000-8000-000000054101',
        name: '現金',
        currencyCode: CurrencyCode.twd,
        openingBalanceMinor: 0,
      ),
    );
    await stockAccounts.create(
      const CreateStockAccountRequest(
        id: '00000000-0000-4000-8000-000000054102',
        name: '台股',
        mode: StockAccountMode.taiwanStock,
      ),
    );
    final trade = domain_trade.StockTrade.valuation(
      id: '00000000-0000-4000-8000-000000054103',
      stockAccountId: '00000000-0000-4000-8000-000000054102',
      cashAccountId: '00000000-0000-4000-8000-000000054101',
      side: domain_trade.StockTradeSide.buy,
      symbol: '2330',
      name: '台積電',
      quantityMicro: 1000000,
      priceMinor: 90000,
      tradeDate: LocalDate(2026, 8, 18),
      note: null,
      createdAtUtc: DateTime.utc(2026, 8, 18),
      updatedAtUtc: DateTime.utc(2026, 8, 18),
    );
    final holding = domain.StockHolding.valuation(
      id: '00000000-0000-4000-8000-000000054104',
      accountId: trade.stockAccountId,
      symbol: trade.symbol,
      name: trade.name,
      accountMode: StockAccountMode.taiwanStock,
      quantityMicro: 1000000,
      averageCostMinor: 90000,
      currentPriceMinor: 90000,
      isArchived: false,
      createdAtUtc: trade.createdAtUtc,
      updatedAtUtc: trade.updatedAtUtc,
    );
    final cashAccount = await cashAccounts.findById(trade.cashAccountId);
    final ledger = LedgerTransactionBuilder.expense(
      transactionId: '00000000-0000-4000-8000-000000054105',
      entryId: '00000000-0000-4000-8000-000000054106',
      account: cashAccount!,
      amountMinor: trade.cashAmountMinor,
      categoryId: 'expense.investment',
      transactionDate: trade.tradeDate,
      note: null,
      createdAtUtc: trade.createdAtUtc,
    );

    await DriftStockTradeExecutor(database).execute(
      trade: trade,
      updatedHolding: holding,
      holdingToArchiveId: null,
      ledger: ledger,
    );

    expect(
      (await DriftStockTradeRepository(database).findById(trade.id))?.symbol,
      '2330',
    );
    expect(
      (await DriftStockHoldingRepository(
        database,
      ).findById(holding.id))?.quantityMicro,
      1000000,
    );
    expect(
      (await DriftLedgerRepository(
        database,
      ).findRecordById(ledger.transaction.id))?.entries.single.amountMinor,
      -90000,
    );
  });
}
