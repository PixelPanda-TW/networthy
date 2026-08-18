import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/domain/model/local_date.dart';
import 'package:networthy/domain/model/stock_account.dart';
import 'package:networthy/domain/model/stock_holding.dart';
import 'package:networthy/domain/model/stock_trade.dart';

void main() {
  final createdAt = DateTime.utc(2026, 8, 18, 12);

  test('calculates valuation trade cash amount', () {
    final trade = StockTrade.valuation(
      id: '00000000-0000-4000-8000-000000051101',
      stockAccountId: '00000000-0000-4000-8000-000000051102',
      cashAccountId: '00000000-0000-4000-8000-000000051103',
      side: StockTradeSide.buy,
      symbol: ' 2330 ',
      name: ' 台積電 ',
      quantityMicro: 1500000,
      priceMinor: 90000,
      tradeDate: LocalDate(2026, 8, 18),
      note: '定期買入',
      createdAtUtc: createdAt,
      updatedAtUtc: createdAt,
    );

    expect(trade.symbol, '2330');
    expect(trade.name, '台積電');
    expect(trade.accountMode, StockAccountMode.taiwanStock);
    expect(trade.currencyCode.wireValue, 'TWD');
    expect(trade.cashAmountMinor, 135000);
    expect(trade.quantityDisplay, '1.5');
  });

  test('calculates principal trade cash amount', () {
    final trade = StockTrade.principal(
      id: '00000000-0000-4000-8000-000000051104',
      stockAccountId: '00000000-0000-4000-8000-000000051105',
      cashAccountId: '00000000-0000-4000-8000-000000051106',
      side: StockTradeSide.sell,
      accountMode: StockAccountMode.usStock,
      symbol: 'VOO',
      name: 'Vanguard S&P 500 ETF',
      principalMinor: 250000,
      tradeDate: LocalDate(2026, 8, 18),
      note: null,
      createdAtUtc: createdAt,
      updatedAtUtc: createdAt,
    );

    expect(trade.cashAmountMinor, 250000);
    expect(trade.principalMinor, 250000);
    expect(trade.quantityMicro, isNull);
    expect(trade.priceMinor, isNull);
    expect(trade.currencyCode.wireValue, 'USD');
  });

  test('rejects invalid values and mode-specific fields', () {
    expect(
      () => StockTrade.valuation(
        id: '00000000-0000-4000-8000-000000051107',
        stockAccountId: '00000000-0000-4000-8000-000000051108',
        cashAccountId: '00000000-0000-4000-8000-000000051109',
        side: StockTradeSide.buy,
        symbol: '2330',
        name: '台積電',
        quantityMicro: 0,
        priceMinor: 90000,
        tradeDate: LocalDate(2026, 8, 18),
        note: null,
        createdAtUtc: createdAt,
        updatedAtUtc: createdAt,
      ),
      throwsA(isA<Exception>()),
    );
    expect(
      () => StockTrade.principal(
        id: '00000000-0000-4000-8000-000000051110',
        stockAccountId: '00000000-0000-4000-8000-000000051111',
        cashAccountId: '00000000-0000-4000-8000-000000051112',
        side: StockTradeSide.buy,
        accountMode: StockAccountMode.taiwanEtf,
        symbol: '0050',
        name: '元大台灣50',
        principalMinor: -1,
        tradeDate: LocalDate(2026, 8, 18),
        note: null,
        createdAtUtc: createdAt,
        updatedAtUtc: createdAt,
      ),
      throwsA(isA<Exception>()),
    );
    expect(
      () => StockTrade.valuation(
        id: '00000000-0000-4000-8000-000000051113',
        stockAccountId: '00000000-0000-4000-8000-000000051114',
        cashAccountId: '00000000-0000-4000-8000-000000051115',
        side: StockTradeSide.buy,
        symbol: '2330',
        name: '台積電',
        quantityMicro: StockHolding.quantityScale,
        priceMinor: 90000,
        tradeDate: LocalDate(2026, 8, 18),
        note: null,
        createdAtUtc: DateTime(2026, 8, 18),
        updatedAtUtc: createdAt,
      ),
      throwsA(isA<Exception>()),
    );
  });
}
