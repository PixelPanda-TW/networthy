import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/data/database/networthy_database.dart';
import 'package:networthy/data/repository/drift_stock_trade_repository.dart';
import 'package:networthy/domain/model/local_date.dart';
import 'package:networthy/domain/model/stock_account.dart';
import 'package:networthy/domain/model/stock_trade.dart' as domain;

void main() {
  test('round-trips valuation and principal trades', () async {
    final database = NetworthyDatabase.inMemory();
    addTearDown(database.close);
    final repository = DriftStockTradeRepository(database);
    final valuation = domain.StockTrade.valuation(
      id: '00000000-0000-4000-8000-000000052101',
      stockAccountId: '00000000-0000-4000-8000-000000052102',
      cashAccountId: '00000000-0000-4000-8000-000000052103',
      side: domain.StockTradeSide.buy,
      symbol: '2330',
      name: '台積電',
      quantityMicro: 1000000,
      priceMinor: 90000,
      tradeDate: LocalDate(2026, 8, 18),
      note: '買入',
      createdAtUtc: DateTime.utc(2026, 8, 18, 1),
      updatedAtUtc: DateTime.utc(2026, 8, 18, 1),
    );
    final principal = domain.StockTrade.principal(
      id: '00000000-0000-4000-8000-000000052104',
      stockAccountId: '00000000-0000-4000-8000-000000052105',
      cashAccountId: '00000000-0000-4000-8000-000000052106',
      side: domain.StockTradeSide.sell,
      accountMode: StockAccountMode.usStock,
      symbol: 'VOO',
      name: 'Vanguard S&P 500 ETF',
      principalMinor: 300000,
      tradeDate: LocalDate(2026, 8, 19),
      note: null,
      createdAtUtc: DateTime.utc(2026, 8, 19, 1),
      updatedAtUtc: DateTime.utc(2026, 8, 19, 1),
    );

    await repository.save(valuation);
    await repository.save(principal);

    expect((await repository.findById(valuation.id))?.cashAmountMinor, 90000);
    expect((await repository.findById(principal.id))?.principalMinor, 300000);
    expect(
      (await repository.listByStockAccount(valuation.stockAccountId)).single.id,
      valuation.id,
    );
    expect((await repository.listLatest(limit: 1)).single.id, principal.id);
  });
}
