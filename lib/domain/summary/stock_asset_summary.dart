import '../model/currency_code.dart';
import '../model/stock_account.dart';
import '../model/stock_holding.dart';

class StockAssetSummary {
  const StockAssetSummary({
    required this.taiwanStockMarketValueMinor,
    required this.taiwanStockUnrealizedGainLossMinor,
    required this.principalByCurrency,
  });

  final int taiwanStockMarketValueMinor;
  final int taiwanStockUnrealizedGainLossMinor;
  final Map<CurrencyCode, int> principalByCurrency;

  factory StockAssetSummary.calculate(Iterable<StockHolding> holdings) {
    var taiwanStockMarketValueMinor = 0;
    var taiwanStockUnrealizedGainLossMinor = 0;
    final principalByCurrency = <CurrencyCode, int>{};

    for (final holding in holdings.where((holding) => !holding.isArchived)) {
      switch (holding.accountMode) {
        case StockAccountMode.taiwanStock:
          taiwanStockMarketValueMinor += holding.marketValueMinor ?? 0;
          taiwanStockUnrealizedGainLossMinor +=
              holding.unrealizedGainLossMinor ?? 0;
        case StockAccountMode.taiwanEtf:
        case StockAccountMode.usStock:
          final principal = holding.principalMinor ?? 0;
          final currency = holding.accountMode.currencyCode;
          principalByCurrency.update(
            currency,
            (current) => current + principal,
            ifAbsent: () => principal,
          );
      }
    }

    return StockAssetSummary(
      taiwanStockMarketValueMinor: taiwanStockMarketValueMinor,
      taiwanStockUnrealizedGainLossMinor: taiwanStockUnrealizedGainLossMinor,
      principalByCurrency: Map<CurrencyCode, int>.unmodifiable(
        principalByCurrency,
      ),
    );
  }
}
