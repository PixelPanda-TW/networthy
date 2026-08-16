import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/data/database/networthy_database.dart';
import 'package:networthy/data/repository/drift_transaction_repository.dart';
import 'package:networthy/domain/model/local_date.dart';
import 'package:networthy/domain/model/transaction.dart';
import 'package:networthy/domain/model/transaction_type.dart';
import 'package:networthy/domain/repository/transaction_repository.dart';

void main() {
  group('DriftTransactionRepository', () {
    test('creates reads updates and deletes a transaction', () async {
      final database = NetworthyDatabase.inMemory();
      addTearDown(database.close);
      final repository = DriftTransactionRepository(database);

      final original = BookkeepingTransaction.create(
        id: '00000000-0000-4000-8000-000000000101',
        type: TransactionType.expense,
        amountMinor: 12500,
        categoryId: 'expense.food',
        transactionDate: LocalDate(2026, 8, 16),
        note: '午餐',
        createdAtUtc: DateTime.utc(2026, 8, 16, 1),
        updatedAtUtc: DateTime.utc(2026, 8, 16, 1),
      );

      await repository.save(original);

      final created = await repository.findById(original.id);
      expect(created?.amountMinor, 12500);
      expect(created?.note, '午餐');

      final updated = BookkeepingTransaction.create(
        id: original.id,
        type: TransactionType.expense,
        amountMinor: 18800,
        categoryId: 'expense.shopping',
        transactionDate: LocalDate(2026, 8, 17),
        note: '補貨',
        createdAtUtc: original.createdAtUtc,
        updatedAtUtc: DateTime.utc(2026, 8, 17, 2),
      );

      await repository.save(updated);

      final readBack = await repository.findById(original.id);
      expect(readBack?.amountMinor, 18800);
      expect(readBack?.categoryId, 'expense.shopping');
      expect(readBack?.transactionDate, LocalDate(2026, 8, 17));

      await repository.delete(original.id);

      expect(await repository.findById(original.id), isNull);
    });

    test('filters by month and type', () async {
      final database = NetworthyDatabase.inMemory();
      addTearDown(database.close);
      final repository = DriftTransactionRepository(database);

      await repository.save(
        _transaction(
          id: '00000000-0000-4000-8000-000000000102',
          type: TransactionType.expense,
          amountMinor: 100,
          categoryId: 'expense.food',
          date: LocalDate(2026, 8, 1),
          createdAtUtc: DateTime.utc(2026, 8, 1, 1),
        ),
      );
      await repository.save(
        _transaction(
          id: '00000000-0000-4000-8000-000000000103',
          type: TransactionType.income,
          amountMinor: 900,
          categoryId: 'income.salary',
          date: LocalDate(2026, 8, 2),
          createdAtUtc: DateTime.utc(2026, 8, 2, 1),
        ),
      );
      await repository.save(
        _transaction(
          id: '00000000-0000-4000-8000-000000000104',
          type: TransactionType.expense,
          amountMinor: 300,
          categoryId: 'expense.transport',
          date: LocalDate(2026, 9, 1),
          createdAtUtc: DateTime.utc(2026, 9, 1, 1),
        ),
      );

      final augustExpenses = await repository.list(
        const TransactionQuery(
          year: 2026,
          month: 8,
          type: TransactionType.expense,
        ),
      );

      expect(augustExpenses.map((transaction) => transaction.id), [
        '00000000-0000-4000-8000-000000000102',
      ]);
    });

    test('returns latest five by transaction date then created time', () async {
      final database = NetworthyDatabase.inMemory();
      addTearDown(database.close);
      final repository = DriftTransactionRepository(database);
      const ids = [
        '00000000-0000-4000-8000-000000000105',
        '00000000-0000-4000-8000-000000000106',
        '00000000-0000-4000-8000-000000000107',
        '00000000-0000-4000-8000-000000000108',
        '00000000-0000-4000-8000-000000000109',
        '00000000-0000-4000-8000-000000000110',
      ];

      for (var index = 0; index < 6; index += 1) {
        await repository.save(
          _transaction(
            id: ids[index],
            type: TransactionType.expense,
            amountMinor: 100 + index,
            categoryId: 'expense.food',
            date: LocalDate(2026, 8, 10 + index),
            createdAtUtc: DateTime.utc(2026, 8, 10 + index, 1),
          ),
        );
      }

      final latest = await repository.latest(limit: 5);

      expect(latest.map((transaction) => transaction.amountMinor), [
        105,
        104,
        103,
        102,
        101,
      ]);
    });

    test('updates monthly summary after deleting a transaction', () async {
      final database = NetworthyDatabase.inMemory();
      addTearDown(database.close);
      final repository = DriftTransactionRepository(database);

      await repository.save(
        _transaction(
          id: '00000000-0000-4000-8000-000000000111',
          type: TransactionType.expense,
          amountMinor: 400,
          categoryId: 'expense.food',
          date: LocalDate(2026, 8, 5),
          createdAtUtc: DateTime.utc(2026, 8, 5, 1),
        ),
      );
      await repository.save(
        _transaction(
          id: '00000000-0000-4000-8000-000000000112',
          type: TransactionType.expense,
          amountMinor: 600,
          categoryId: 'expense.food',
          date: LocalDate(2026, 8, 6),
          createdAtUtc: DateTime.utc(2026, 8, 6, 1),
        ),
      );

      expect(
        (await repository.monthlySummary(
          year: 2026,
          month: 8,
        )).totalExpenseMinor,
        1000,
      );

      await repository.delete('00000000-0000-4000-8000-000000000112');

      final summary = await repository.monthlySummary(year: 2026, month: 8);
      expect(summary.totalExpenseMinor, 400);
      expect(summary.expenseCategoryTotals, {'expense.food': 400});
    });
  });
}

BookkeepingTransaction _transaction({
  required String id,
  required TransactionType type,
  required int amountMinor,
  required String categoryId,
  required LocalDate date,
  required DateTime createdAtUtc,
}) {
  return BookkeepingTransaction.create(
    id: id,
    type: type,
    amountMinor: amountMinor,
    categoryId: categoryId,
    transactionDate: date,
    createdAtUtc: createdAtUtc,
    updatedAtUtc: createdAtUtc.add(const Duration(minutes: 1)),
  );
}
