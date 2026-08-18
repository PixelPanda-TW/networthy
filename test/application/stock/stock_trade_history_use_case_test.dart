import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/application/stock/stock_trade_history_use_case.dart';
import 'package:networthy/domain/model/local_date.dart';
import 'package:networthy/domain/model/stock_account.dart';
import 'package:networthy/domain/model/stock_trade.dart';
import 'package:networthy/domain/repository/stock_trade_repository.dart';

void main() {
  test('returns repository latest trades', () async {
    final repository = _FakeStockTradeRepository();
    final result = await StockTradeHistoryUseCase(repository).latest(limit: 2);

    expect(result.failure, isNull);
    expect(result.trades, hasLength(2));
    expect(result.trades.first.id, '00000000-0000-4000-8000-000000055101');
  });
}

class _FakeStockTradeRepository implements StockTradeRepository {
  @override
  Future<StockTrade?> findById(String id) async => null;

  @override
  Future<List<StockTrade>> listByStockAccount(String stockAccountId) async {
    return const [];
  }

  @override
  Future<List<StockTrade>> listLatest({required int limit}) async {
    return [
      StockTrade.principal(
        id: '00000000-0000-4000-8000-000000055101',
        stockAccountId: '00000000-0000-4000-8000-000000055102',
        cashAccountId: '00000000-0000-4000-8000-000000055103',
        side: StockTradeSide.buy,
        accountMode: StockAccountMode.usStock,
        symbol: 'VOO',
        name: 'Vanguard S&P 500 ETF',
        principalMinor: 300000,
        tradeDate: LocalDate(2026, 8, 18),
        note: null,
        createdAtUtc: DateTime.utc(2026, 8, 18),
        updatedAtUtc: DateTime.utc(2026, 8, 18),
      ),
      StockTrade.principal(
        id: '00000000-0000-4000-8000-000000055104',
        stockAccountId: '00000000-0000-4000-8000-000000055105',
        cashAccountId: '00000000-0000-4000-8000-000000055106',
        side: StockTradeSide.sell,
        accountMode: StockAccountMode.taiwanEtf,
        symbol: '0050',
        name: '元大台灣50',
        principalMinor: 100000,
        tradeDate: LocalDate(2026, 8, 17),
        note: null,
        createdAtUtc: DateTime.utc(2026, 8, 17),
        updatedAtUtc: DateTime.utc(2026, 8, 17),
      ),
    ].take(limit).toList();
  }

  @override
  Future<void> save(StockTrade trade) async {}
}
