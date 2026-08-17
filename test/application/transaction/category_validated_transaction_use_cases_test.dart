import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/application/transaction/add_transaction_use_case.dart';
import 'package:networthy/application/transaction/edit_transaction_use_case.dart';
import 'package:networthy/application/transaction/transaction_command.dart';
import 'package:networthy/domain/model/local_date.dart';
import 'package:networthy/domain/model/transaction.dart';
import 'package:networthy/domain/model/transaction_type.dart';

import '../../presentation/test_app_harness.dart';

void main() {
  test('add rejects unknown category', () async {
    final categories = TestCategoryRepository(seedBuiltIns: false);
    final transactions = TestTransactionRepository();

    final result = await AddTransactionUseCase(
      transactions: transactions,
      settings: TestSettingsRepository(),
      categories: categories,
      clock: TestClock(DateTime.utc(2026, 8, 16, 1)),
      idGenerator: TestIdGenerator(['00000000-0000-4000-8000-000000000401']),
    ).execute(_command(categoryId: 'missing'));

    expect(result.failure?.safeMessage, '請選擇有效分類。');
    expect(transactions.values, isEmpty);
  });

  test('edit rejects archived category', () async {
    final categories = TestCategoryRepository();
    await categories.archive('expense.food');
    final transactions = TestTransactionRepository();
    await transactions.save(
      BookkeepingTransaction.create(
        id: '00000000-0000-4000-8000-000000000402',
        type: TransactionType.expense,
        amountMinor: 100,
        categoryId: 'expense.transport',
        transactionDate: LocalDate(2026, 8, 16),
        createdAtUtc: DateTime.utc(2026, 8, 16, 1),
        updatedAtUtc: DateTime.utc(2026, 8, 16, 1),
      ),
    );

    final result =
        await EditTransactionUseCase(
          transactions: transactions,
          settings: TestSettingsRepository(),
          categories: categories,
          clock: TestClock(DateTime.utc(2026, 8, 16, 2)),
        ).execute(
          id: '00000000-0000-4000-8000-000000000402',
          command: _command(categoryId: 'expense.food'),
        );

    expect(result.failure?.safeMessage, '請選擇有效分類。');
  });
}

TransactionCommand _command({required String categoryId}) {
  return TransactionCommand(
    type: TransactionType.expense,
    amountMinor: 100,
    categoryId: categoryId,
    transactionDate: LocalDate(2026, 8, 16),
    note: null,
  );
}
