import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/domain/model/stock_account.dart';
import 'package:networthy/domain/repository/stock_holding_repository.dart';

void main() {}

void stockHoldingRepositoryContract({
  required Future<StockHoldingRepository> Function() createRepository,
}) {
  test('saves and edits valuation holdings', () async {
    final repository = await createRepository();
    final saved = await repository.saveValuation(
      const SaveValuationHoldingRequest(
        id: '00000000-0000-4000-8000-000000041101',
        accountId: '00000000-0000-4000-8000-000000041102',
        symbol: '2330',
        name: '台積電',
        accountMode: StockAccountMode.taiwanStock,
        quantityMicro: 1500000,
        averageCostMinor: 60000,
        currentPriceMinor: 65000,
      ),
    );

    expect(saved.quantityMicro, 1500000);
    final edited = await repository.saveValuation(
      const SaveValuationHoldingRequest(
        id: '00000000-0000-4000-8000-000000041101',
        accountId: '00000000-0000-4000-8000-000000041102',
        symbol: '2330',
        name: '台積電',
        accountMode: StockAccountMode.taiwanStock,
        quantityMicro: 2000000,
        averageCostMinor: 61000,
        currentPriceMinor: 66000,
      ),
    );

    expect(edited.quantityMicro, 2000000);
    expect(
      (await repository.listActiveByAccount(saved.accountId)),
      hasLength(1),
    );
  });

  test('saves and edits principal holdings', () async {
    final repository = await createRepository();
    final saved = await repository.savePrincipal(
      const SavePrincipalHoldingRequest(
        id: '00000000-0000-4000-8000-000000041103',
        accountId: '00000000-0000-4000-8000-000000041104',
        symbol: 'VOO',
        name: 'Vanguard S&P 500 ETF',
        accountMode: StockAccountMode.usStock,
        principalMinor: 500000,
      ),
    );

    final edited = await repository.savePrincipal(
      const SavePrincipalHoldingRequest(
        id: '00000000-0000-4000-8000-000000041103',
        accountId: '00000000-0000-4000-8000-000000041104',
        symbol: 'VOO',
        name: 'Vanguard S&P 500 ETF',
        accountMode: StockAccountMode.usStock,
        principalMinor: 600000,
      ),
    );

    expect(saved.principalMinor, 500000);
    expect(edited.principalMinor, 600000);
  });

  test(
    'archives holdings and filters active and all lists by account',
    () async {
      final repository = await createRepository();
      final active = await repository.savePrincipal(
        const SavePrincipalHoldingRequest(
          id: '00000000-0000-4000-8000-000000041105',
          accountId: '00000000-0000-4000-8000-000000041106',
          symbol: '0050',
          name: '元大台灣50',
          accountMode: StockAccountMode.taiwanEtf,
          principalMinor: 100000,
        ),
      );
      await repository.savePrincipal(
        const SavePrincipalHoldingRequest(
          id: '00000000-0000-4000-8000-000000041107',
          accountId: '00000000-0000-4000-8000-000000041108',
          symbol: 'VOO',
          name: 'Vanguard S&P 500 ETF',
          accountMode: StockAccountMode.usStock,
          principalMinor: 200000,
        ),
      );

      await repository.archive(active.id);

      expect(await repository.listActiveByAccount(active.accountId), isEmpty);
      expect(await repository.listAllByAccount(active.accountId), hasLength(1));
      expect(await repository.listAllActive(), hasLength(1));
    },
  );
}
