import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/data/database/networthy_database.dart';
import 'package:networthy/data/repository/drift_ledger_repository.dart';
import 'package:networthy/domain/ledger/ledger_transaction_builder.dart';
import 'package:networthy/domain/model/account.dart';
import 'package:networthy/domain/model/currency_code.dart';
import 'package:networthy/domain/model/local_date.dart';

import '../../domain/repository/ledger_repository_contract_test.dart';

void main() {
  ledgerRepositoryContract(
    createRepository: () async {
      final database = NetworthyDatabase.inMemory();
      addTearDown(database.close);
      return DriftLedgerRepository(database);
    },
  );

  test('persists transfer record and balances after reload', () async {
    final database = NetworthyDatabase.inMemory();
    addTearDown(database.close);
    final repository = DriftLedgerRepository(database);
    final bank = _account(
      id: '00000000-0000-4000-8000-000000032101',
      name: '玉山台幣',
    );
    final cash = _account(
      id: '00000000-0000-4000-8000-000000032102',
      name: '現金 TWD',
    );
    await repository.save(
      LedgerTransactionBuilder.transfer(
        transactionId: '00000000-0000-4000-8000-000000032103',
        sourceEntryId: '00000000-0000-4000-8000-000000032104',
        targetEntryId: '00000000-0000-4000-8000-000000032105',
        source: bank,
        target: cash,
        amountMinor: 1000,
        transactionDate: LocalDate(2026, 8, 17),
        note: '領現',
        createdAtUtc: DateTime.utc(2026, 8, 17, 1),
      ),
    );

    final reloaded = DriftLedgerRepository(database);
    final record = await reloaded.findRecordById(
      '00000000-0000-4000-8000-000000032103',
    );

    expect(record?.entries.map((entry) => entry.amountMinor), [-1000, 1000]);
    expect(
      (await reloaded.accountBalances()).map((balance) => balance.balanceMinor),
      [-1000, 1000],
    );
  });
}

CashAccount _account({required String id, required String name}) {
  return CashAccount.create(
    id: id,
    name: name,
    currencyCode: CurrencyCode.twd,
    isArchived: false,
    createdAtUtc: DateTime.utc(2026, 8, 17, 1),
    updatedAtUtc: DateTime.utc(2026, 8, 17, 1),
  );
}
