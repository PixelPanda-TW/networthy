import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/application/common/application_failure.dart';
import 'package:networthy/application/stock/stock_holding_command.dart';
import 'package:networthy/application/stock/stock_holding_use_cases.dart';
import 'package:networthy/domain/model/stock_account.dart';
import 'package:networthy/domain/repository/stock_account_repository.dart';
import 'package:networthy/domain/repository/stock_holding_repository.dart';

import '../../presentation/test_app_harness.dart';

void main() {
  test(
    'valuation holding can be saved only under Taiwan stock account',
    () async {
      final accounts = TestStockAccountRepository();
      final holdings = TestStockHoldingRepository();
      final account = await accounts.create(
        const CreateStockAccountRequest(
          id: '00000000-0000-4000-8000-000000044101',
          name: '台股券商',
          mode: StockAccountMode.taiwanStock,
        ),
      );

      final result =
          await SaveValuationStockHoldingUseCase(
            accounts: accounts,
            holdings: holdings,
            idGenerator: TestIdGenerator([
              '00000000-0000-4000-8000-000000044102',
            ]),
            clock: TestClock(DateTime.utc(2026, 8, 18)),
          ).execute(
            SaveValuationStockHoldingCommand(
              accountId: account.id,
              symbol: '2330',
              name: '台積電',
              quantityMicro: 1000000,
              averageCostMinor: 60000,
              currentPriceMinor: 65000,
            ),
          );

      expect(result.failure, isNull);
      expect(result.holding?.marketValueMinor, 65000);

      final usAccount = await accounts.create(
        const CreateStockAccountRequest(
          id: '00000000-0000-4000-8000-000000044103',
          name: '美股券商',
          mode: StockAccountMode.usStock,
        ),
      );
      final invalid =
          await SaveValuationStockHoldingUseCase(
            accounts: accounts,
            holdings: holdings,
            idGenerator: TestIdGenerator([
              '00000000-0000-4000-8000-000000044104',
            ]),
            clock: TestClock(DateTime.utc(2026, 8, 18)),
          ).execute(
            SaveValuationStockHoldingCommand(
              accountId: usAccount.id,
              symbol: 'VOO',
              name: 'VOO',
              quantityMicro: 1000000,
              averageCostMinor: 10000,
              currentPriceMinor: 11000,
            ),
          );
      expect(invalid.failure?.type, ApplicationFailureType.validation);
    },
  );

  test(
    'principal holding supports ETF and US accounts but rejects archived',
    () async {
      final accounts = TestStockAccountRepository();
      final holdings = TestStockHoldingRepository();
      final etf = await accounts.create(
        const CreateStockAccountRequest(
          id: '00000000-0000-4000-8000-000000044105',
          name: 'ETF 帳戶',
          mode: StockAccountMode.taiwanEtf,
        ),
      );
      final result =
          await SavePrincipalStockHoldingUseCase(
            accounts: accounts,
            holdings: holdings,
            idGenerator: TestIdGenerator([
              '00000000-0000-4000-8000-000000044106',
            ]),
            clock: TestClock(DateTime.utc(2026, 8, 18)),
          ).execute(
            SavePrincipalStockHoldingCommand(
              accountId: etf.id,
              symbol: '0050',
              name: '元大台灣50',
              principalMinor: 100000,
            ),
          );
      expect(result.failure, isNull);

      await accounts.archive(etf.id);
      final archived =
          await SavePrincipalStockHoldingUseCase(
            accounts: accounts,
            holdings: holdings,
            idGenerator: TestIdGenerator([
              '00000000-0000-4000-8000-000000044107',
            ]),
            clock: TestClock(DateTime.utc(2026, 8, 18)),
          ).execute(
            SavePrincipalStockHoldingCommand(
              accountId: etf.id,
              symbol: '0050',
              name: '元大台灣50',
              principalMinor: 200000,
            ),
          );
      expect(archived.failure?.type, ApplicationFailureType.validation);
    },
  );

  test('archive holding hides it from active list', () async {
    final accounts = TestStockAccountRepository();
    final holdings = TestStockHoldingRepository();
    final account = await accounts.create(
      const CreateStockAccountRequest(
        id: '00000000-0000-4000-8000-000000044108',
        name: '美股券商',
        mode: StockAccountMode.usStock,
      ),
    );
    final saved = await holdings.savePrincipal(
      SavePrincipalHoldingRequest(
        id: '00000000-0000-4000-8000-000000044109',
        accountId: account.id,
        symbol: 'VOO',
        name: 'VOO',
        accountMode: StockAccountMode.usStock,
        principalMinor: 100000,
      ),
    );
    final result = await ArchiveStockHoldingUseCase(
      holdings,
    ).execute(ArchiveStockHoldingCommand(id: saved.id));

    expect(result.failure, isNull);
    expect(await holdings.listActiveByAccount(account.id), isEmpty);
  });
}
