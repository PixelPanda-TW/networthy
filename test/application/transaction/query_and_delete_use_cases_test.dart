import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/application/common/application_failure.dart';
import 'package:networthy/application/transaction/delete_transaction_use_case.dart';
import 'package:networthy/application/transaction/list_transactions_use_case.dart';
import 'package:networthy/application/transaction/monthly_overview_use_case.dart';
import 'package:networthy/domain/model/local_date.dart';
import 'package:networthy/domain/model/transaction.dart';
import 'package:networthy/domain/model/transaction_type.dart';
import 'package:networthy/domain/repository/transaction_repository.dart';
import 'package:networthy/domain/summary/monthly_summary.dart';

void main() {
  group('query and delete use cases', () {
    test('delete requires explicit confirmation', () async {
      final repository = FakeTransactionRepository();

      final result = await DeleteTransactionUseCase(repository).execute(
        const DeleteTransactionRequest(
          id: '00000000-0000-4000-8000-000000000501',
          confirmed: false,
        ),
      );

      expect(result.failure?.type, ApplicationFailureType.validation);
      expect(repository.deletedIds, isEmpty);
    });

    test('delete removes a transaction when confirmed', () async {
      final repository = FakeTransactionRepository();

      final result = await DeleteTransactionUseCase(repository).execute(
        const DeleteTransactionRequest(
          id: '00000000-0000-4000-8000-000000000501',
          confirmed: true,
        ),
      );

      expect(result.failure, isNull);
      expect(repository.deletedIds, ['00000000-0000-4000-8000-000000000501']);
    });

    test(
      'monthly overview returns summary and latest five transactions',
      () async {
        final repository = FakeTransactionRepository(
          transactions: [
            _transaction(
              id: '00000000-0000-4000-8000-000000000502',
              type: TransactionType.expense,
              amountMinor: 300,
              categoryId: 'expense.food',
            ),
            _transaction(
              id: '00000000-0000-4000-8000-000000000503',
              type: TransactionType.income,
              amountMinor: 1000,
              categoryId: 'income.salary',
            ),
          ],
        );

        final overview = await MonthlyOverviewUseCase(
          repository,
        ).load(year: 2026, month: 8);

        expect(overview.summary.balanceMinor, 700);
        expect(overview.recentTransactions, hasLength(2));
        expect(repository.latestLimit, 5);
      },
    );

    test('list forwards month and type filters', () async {
      final repository = FakeTransactionRepository();

      await ListTransactionsUseCase(repository).list(
        const TransactionQuery(
          year: 2026,
          month: 8,
          type: TransactionType.expense,
        ),
      );

      expect(repository.lastQuery?.year, 2026);
      expect(repository.lastQuery?.month, 8);
      expect(repository.lastQuery?.type, TransactionType.expense);
    });
  });
}

BookkeepingTransaction _transaction({
  required String id,
  required TransactionType type,
  required int amountMinor,
  required String categoryId,
}) {
  return BookkeepingTransaction.create(
    id: id,
    type: type,
    amountMinor: amountMinor,
    categoryId: categoryId,
    transactionDate: LocalDate(2026, 8, 16),
    createdAtUtc: DateTime.utc(2026, 8, 16, 1),
    updatedAtUtc: DateTime.utc(2026, 8, 16, 1),
  );
}

class FakeTransactionRepository implements TransactionRepository {
  FakeTransactionRepository({List<BookkeepingTransaction>? transactions})
    : transactions = transactions ?? <BookkeepingTransaction>[];

  final List<BookkeepingTransaction> transactions;
  final List<String> deletedIds = <String>[];
  TransactionQuery? lastQuery;
  int? latestLimit;

  @override
  Future<void> delete(String id) async {
    deletedIds.add(id);
  }

  @override
  Future<BookkeepingTransaction?> findById(String id) async => null;

  @override
  Future<List<BookkeepingTransaction>> latest({required int limit}) async {
    latestLimit = limit;
    return transactions.take(limit).toList(growable: false);
  }

  @override
  Future<List<BookkeepingTransaction>> list(TransactionQuery query) async {
    lastQuery = query;
    return transactions;
  }

  @override
  Future<MonthlySummary> monthlySummary({
    required int year,
    required int month,
  }) async {
    return MonthlySummary.calculate(
      transactions: transactions,
      year: year,
      month: month,
    );
  }

  @override
  Future<void> save(BookkeepingTransaction transaction) async {}
}
