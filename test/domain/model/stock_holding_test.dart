import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/domain/model/domain_validation.dart';
import 'package:networthy/domain/model/stock_account.dart';
import 'package:networthy/domain/model/stock_holding.dart';

void main() {
  test(
    'valuation holding calculates cost market value and unrealized gain',
    () {
      final holding = StockHolding.valuation(
        id: '00000000-0000-4000-8000-000000040101',
        accountId: '00000000-0000-4000-8000-000000040102',
        symbol: '2330',
        name: '台積電',
        accountMode: StockAccountMode.taiwanStock,
        quantityMicro: 1500000,
        averageCostMinor: 60000,
        currentPriceMinor: 65000,
        isArchived: false,
        createdAtUtc: DateTime.utc(2026, 8, 17, 1),
        updatedAtUtc: DateTime.utc(2026, 8, 17, 1),
      );

      expect(holding.quantityDisplay, '1.5');
      expect(holding.costMinor, 90000);
      expect(holding.marketValueMinor, 97500);
      expect(holding.unrealizedGainLossMinor, 7500);
    },
  );

  test('principal holding stores principal without valuation fields', () {
    final holding = StockHolding.principal(
      id: '00000000-0000-4000-8000-000000040103',
      accountId: '00000000-0000-4000-8000-000000040104',
      symbol: 'VOO',
      name: 'Vanguard S&P 500 ETF',
      accountMode: StockAccountMode.usStock,
      principalMinor: 500000,
      isArchived: false,
      createdAtUtc: DateTime.utc(2026, 8, 17, 1),
      updatedAtUtc: DateTime.utc(2026, 8, 17, 1),
    );

    expect(holding.principalMinor, 500000);
    expect(holding.marketValueMinor, isNull);
    expect(holding.unrealizedGainLossMinor, isNull);
  });

  test('rejects invalid mode-specific values', () {
    expect(
      () => StockHolding.valuation(
        id: '00000000-0000-4000-8000-000000040105',
        accountId: '00000000-0000-4000-8000-000000040106',
        symbol: '0050',
        name: '元大台灣50',
        accountMode: StockAccountMode.taiwanEtf,
        quantityMicro: 1000000,
        averageCostMinor: 10000,
        currentPriceMinor: 12000,
        isArchived: false,
        createdAtUtc: DateTime.utc(2026, 8, 17, 1),
        updatedAtUtc: DateTime.utc(2026, 8, 17, 1),
      ),
      throwsA(isA<DomainValidationException>()),
    );

    expect(
      () => StockHolding.principal(
        id: '00000000-0000-4000-8000-000000040107',
        accountId: '00000000-0000-4000-8000-000000040108',
        symbol: '2330',
        name: '台積電',
        accountMode: StockAccountMode.taiwanStock,
        principalMinor: 100000,
        isArchived: false,
        createdAtUtc: DateTime.utc(2026, 8, 17, 1),
        updatedAtUtc: DateTime.utc(2026, 8, 17, 1),
      ),
      throwsA(isA<DomainValidationException>()),
    );
  });
}
