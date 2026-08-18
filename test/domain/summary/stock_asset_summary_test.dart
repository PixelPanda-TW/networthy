import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/domain/model/currency_code.dart';
import 'package:networthy/domain/model/stock_account.dart';
import 'package:networthy/domain/model/stock_holding.dart';
import 'package:networthy/domain/summary/stock_asset_summary.dart';

void main() {
  test('groups valuation market value and principal by account mode', () {
    final summary = StockAssetSummary.calculate([
      StockHolding.valuation(
        id: '00000000-0000-4000-8000-000000040201',
        accountId: '00000000-0000-4000-8000-000000040202',
        symbol: '2330',
        name: '台積電',
        accountMode: StockAccountMode.taiwanStock,
        quantityMicro: 2000000,
        averageCostMinor: 60000,
        currentPriceMinor: 65000,
        isArchived: false,
        createdAtUtc: DateTime.utc(2026, 8, 17, 1),
        updatedAtUtc: DateTime.utc(2026, 8, 17, 1),
      ),
      StockHolding.principal(
        id: '00000000-0000-4000-8000-000000040203',
        accountId: '00000000-0000-4000-8000-000000040204',
        symbol: 'VOO',
        name: 'Vanguard S&P 500 ETF',
        accountMode: StockAccountMode.usStock,
        principalMinor: 500000,
        isArchived: false,
        createdAtUtc: DateTime.utc(2026, 8, 17, 1),
        updatedAtUtc: DateTime.utc(2026, 8, 17, 1),
      ),
    ]);

    expect(summary.taiwanStockMarketValueMinor, 130000);
    expect(summary.taiwanStockUnrealizedGainLossMinor, 10000);
    expect(summary.principalByCurrency[CurrencyCode.usd], 500000);
  });
}
