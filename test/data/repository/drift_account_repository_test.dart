import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/data/database/networthy_database.dart';
import 'package:networthy/data/repository/drift_account_repository.dart';
import 'package:networthy/domain/model/currency_code.dart';
import 'package:networthy/domain/repository/account_repository.dart';

import '../../domain/repository/account_repository_contract_test.dart';

void main() {
  accountRepositoryContract(
    createRepository: () async {
      final database = NetworthyDatabase.inMemory();
      addTearDown(database.close);
      return DriftAccountRepository(database);
    },
  );

  test('renames and archives persisted account after reload', () async {
    final database = NetworthyDatabase.inMemory();
    addTearDown(database.close);
    final repository = DriftAccountRepository(database);
    final account = await repository.create(
      const CreateAccountRequest(
        id: '00000000-0000-4000-8000-000000032001',
        name: '玉山台幣',
        currencyCode: CurrencyCode.twd,
        openingBalanceMinor: 0,
      ),
    );

    final reloaded = DriftAccountRepository(database);
    await reloaded.rename(id: account.id, name: '玉山薪轉');
    await reloaded.archive(account.id);

    expect(await reloaded.displayNameFor(account.id), '玉山薪轉');
    expect((await reloaded.findById(account.id))?.isArchived, isTrue);
    expect((await reloaded.listActive()).map((item) => item.id), isEmpty);
  });
}
