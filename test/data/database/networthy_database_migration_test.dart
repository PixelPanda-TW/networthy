import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/data/database/networthy_database.dart';
import 'package:networthy/data/repository/drift_transaction_repository.dart';
import 'package:networthy/domain/model/local_date.dart';
import 'package:networthy/domain/model/transaction.dart';
import 'package:networthy/domain/model/transaction_type.dart';

void main() {
  test('baseline migration preserves existing schema version 1 data', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'networthy-migration-',
    );
    addTearDown(() => tempDir.delete(recursive: true));
    final databaseFile = File('${tempDir.path}/networthy.db');

    final originalDatabase = NetworthyDatabase(NativeDatabase(databaseFile));
    addTearDown(originalDatabase.close);
    await DriftTransactionRepository(originalDatabase).save(
      BookkeepingTransaction.create(
        id: '00000000-0000-4000-8000-000000000301',
        type: TransactionType.expense,
        amountMinor: 777,
        categoryId: 'expense.food',
        transactionDate: LocalDate(2026, 8, 16),
        createdAtUtc: DateTime.utc(2026, 8, 16, 1),
        updatedAtUtc: DateTime.utc(2026, 8, 16, 1),
      ),
    );
    await originalDatabase.close();

    final reopenedDatabase = NetworthyDatabase(NativeDatabase(databaseFile));
    addTearDown(reopenedDatabase.close);
    final transaction = await DriftTransactionRepository(
      reopenedDatabase,
    ).findById('00000000-0000-4000-8000-000000000301');

    expect(transaction?.amountMinor, 777);
  });
}
