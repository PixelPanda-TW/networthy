import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/domain/model/local_date.dart';
import 'package:networthy/domain/model/transaction.dart';
import 'package:networthy/domain/model/transaction_type.dart';
import 'package:networthy/domain/summary/monthly_summary.dart';

void main() {
  test(
    'monthly overview aggregation stays under one second for 10000 rows',
    () {
      final transactions = List<BookkeepingTransaction>.generate(10000, (
        index,
      ) {
        final isExpense = index.isEven;
        final day = (index % 28) + 1;
        return BookkeepingTransaction.create(
          id: _uuidFor(index),
          type: isExpense ? TransactionType.expense : TransactionType.income,
          amountMinor: (index % 5000) + 1,
          categoryId: isExpense ? 'expense.food' : 'income.salary',
          transactionDate: LocalDate(2026, 8, day),
          note: 'row-$index',
          createdAtUtc: DateTime.utc(2026, 8, day, 1),
          updatedAtUtc: DateTime.utc(2026, 8, day, 1),
        );
      }, growable: false);

      final stopwatch = Stopwatch()..start();
      final summary = MonthlySummary.calculate(
        transactions: transactions,
        year: 2026,
        month: 8,
      );
      stopwatch.stop();

      expect(summary.totalExpenseMinor, greaterThan(0));
      expect(summary.totalIncomeMinor, greaterThan(0));
      expect(
        stopwatch.elapsed,
        lessThan(const Duration(seconds: 1)),
        reason:
            'Homepage monthly aggregation must stay below the M8 1 second gate '
            'for 10,000 local transactions.',
      );
    },
  );
}

String _uuidFor(int index) {
  final suffix = index.toRadixString(16).padLeft(12, '0');
  return '00000000-0000-4000-8000-$suffix';
}
