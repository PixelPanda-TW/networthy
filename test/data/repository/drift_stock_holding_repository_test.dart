import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/data/database/networthy_database.dart';
import 'package:networthy/data/repository/drift_stock_holding_repository.dart';
import 'package:networthy/domain/model/stock_account.dart';
import 'package:networthy/domain/repository/stock_holding_repository.dart';

void main() {
  test(
    'persisted valuation holding survives reload and calculates values',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'networthy-holding-',
      );
      addTearDown(() => tempDir.delete(recursive: true));
      final databaseFile = File('${tempDir.path}/networthy.db');

      final firstDatabase = NetworthyDatabase(NativeDatabase(databaseFile));
      final firstRepository = DriftStockHoldingRepository(firstDatabase);
      await firstRepository.saveValuation(
        const SaveValuationHoldingRequest(
          id: '00000000-0000-4000-8000-000000042101',
          accountId: '00000000-0000-4000-8000-000000042102',
          symbol: '2330',
          name: '台積電',
          accountMode: StockAccountMode.taiwanStock,
          quantityMicro: 1500000,
          averageCostMinor: 60000,
          currentPriceMinor: 65000,
        ),
      );
      await firstDatabase.close();

      final secondDatabase = NetworthyDatabase(NativeDatabase(databaseFile));
      addTearDown(secondDatabase.close);
      final repository = DriftStockHoldingRepository(secondDatabase);
      final restored = await repository.findById(
        '00000000-0000-4000-8000-000000042101',
      );

      expect(restored?.quantityMicro, 1500000);
      expect(restored?.marketValueMinor, 97500);
      expect(restored?.unrealizedGainLossMinor, 7500);
    },
  );

  test(
    'persists principal holdings and filters active rows by account',
    () async {
      final database = NetworthyDatabase.inMemory();
      addTearDown(database.close);
      final repository = DriftStockHoldingRepository(database);

      final holding = await repository.savePrincipal(
        const SavePrincipalHoldingRequest(
          id: '00000000-0000-4000-8000-000000042103',
          accountId: '00000000-0000-4000-8000-000000042104',
          symbol: 'VOO',
          name: 'Vanguard S&P 500 ETF',
          accountMode: StockAccountMode.usStock,
          principalMinor: 500000,
        ),
      );
      await repository.savePrincipal(
        const SavePrincipalHoldingRequest(
          id: '00000000-0000-4000-8000-000000042105',
          accountId: '00000000-0000-4000-8000-000000042106',
          symbol: '0050',
          name: '元大台灣50',
          accountMode: StockAccountMode.taiwanEtf,
          principalMinor: 100000,
        ),
      );

      expect(
        await repository.listActiveByAccount(holding.accountId),
        hasLength(1),
      );
      await repository.archive(holding.id);
      expect(await repository.listActiveByAccount(holding.accountId), isEmpty);
      expect(
        await repository.listAllByAccount(holding.accountId),
        hasLength(1),
      );
      expect(await repository.listAllActive(), hasLength(1));
    },
  );
}
