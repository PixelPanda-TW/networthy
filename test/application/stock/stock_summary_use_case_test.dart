import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/application/stock/stock_summary_use_case.dart';
import 'package:networthy/domain/model/currency_code.dart';
import 'package:networthy/domain/model/stock_account.dart';
import 'package:networthy/domain/repository/stock_holding_repository.dart';

import '../../presentation/test_app_harness.dart';

void main() {
  test(
    'loads valuation and principal summaries excluding archived holdings',
    () async {
      final holdings = TestStockHoldingRepository();
      await holdings.saveValuation(
        const SaveValuationHoldingRequest(
          id: '00000000-0000-4000-8000-000000044201',
          accountId: '00000000-0000-4000-8000-000000044202',
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
          id: '00000000-0000-4000-8000-000000044203',
          accountId: '00000000-0000-4000-8000-000000044204',
          symbol: '0050',
          name: '元大台灣50',
          accountMode: StockAccountMode.taiwanEtf,
          principalMinor: 100000,
        ),
      );
      await holdings.savePrincipal(
        const SavePrincipalHoldingRequest(
          id: '00000000-0000-4000-8000-000000044204',
          accountId: '00000000-0000-4000-8000-000000044205',
          symbol: 'VOO',
          name: 'Vanguard S&P 500 ETF',
          accountMode: StockAccountMode.usStock,
          principalMinor: 200000,
        ),
      );
      final archived = await holdings.savePrincipal(
        const SavePrincipalHoldingRequest(
          id: '00000000-0000-4000-8000-000000044206',
          accountId: '00000000-0000-4000-8000-000000044207',
          symbol: 'VOO',
          name: 'VOO',
          accountMode: StockAccountMode.usStock,
          principalMinor: 300000,
        ),
      );
      await holdings.archive(archived.id);

      final result = await LoadStockAssetSummaryUseCase(holdings).execute();

      expect(result.failure, isNull);
      expect(result.summary?.taiwanStockMarketValueMinor, 65000);
      expect(result.summary?.taiwanStockUnrealizedGainLossMinor, 5000);
      expect(result.summary?.principalByCurrency[CurrencyCode.twd], 100000);
      expect(result.summary?.principalByCurrency[CurrencyCode.usd], 200000);
    },
  );
}
