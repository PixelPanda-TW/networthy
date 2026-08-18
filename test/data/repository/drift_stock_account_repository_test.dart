import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/data/database/networthy_database.dart';
import 'package:networthy/data/repository/drift_stock_account_repository.dart';
import 'package:networthy/domain/model/stock_account.dart';
import 'package:networthy/domain/repository/stock_account_repository.dart';

void main() {
  test(
    'persisted stock accounts survive reload and archive hides them',
    () async {
      final tempDir = await Directory.systemTemp.createTemp('networthy-stock-');
      addTearDown(() => tempDir.delete(recursive: true));
      final databaseFile = File('${tempDir.path}/networthy.db');

      final firstDatabase = NetworthyDatabase(NativeDatabase(databaseFile));
      final firstRepository = DriftStockAccountRepository(firstDatabase);
      final account = await firstRepository.create(
        const CreateStockAccountRequest(
          id: '00000000-0000-4000-8000-000000042001',
          name: '美股券商',
          mode: StockAccountMode.usStock,
        ),
      );
      await firstDatabase.close();

      final secondDatabase = NetworthyDatabase(NativeDatabase(databaseFile));
      addTearDown(secondDatabase.close);
      final secondRepository = DriftStockAccountRepository(secondDatabase);
      final restored = await secondRepository.findById(account.id);

      expect(restored?.mode, StockAccountMode.usStock);
      expect(restored?.currencyCode.wireValue, 'USD');

      await secondRepository.archive(account.id);
      expect(await secondRepository.listActive(), isEmpty);
      expect(await secondRepository.listAll(), hasLength(1));
    },
  );

  test('rejects duplicate active names only within the same mode', () async {
    final database = NetworthyDatabase.inMemory();
    addTearDown(database.close);
    final repository = DriftStockAccountRepository(database);

    await repository.create(
      const CreateStockAccountRequest(
        id: '00000000-0000-4000-8000-000000042002',
        name: '投資帳戶',
        mode: StockAccountMode.taiwanStock,
      ),
    );

    expect(
      () => repository.create(
        const CreateStockAccountRequest(
          id: '00000000-0000-4000-8000-000000042003',
          name: '投資帳戶',
          mode: StockAccountMode.taiwanStock,
        ),
      ),
      throwsA(isA<StockAccountRepositoryException>()),
    );
  });
}
