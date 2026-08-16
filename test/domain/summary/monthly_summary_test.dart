import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/domain/model/local_date.dart';
import 'package:networthy/domain/model/transaction.dart';
import 'package:networthy/domain/model/transaction_type.dart';
import 'package:networthy/domain/summary/monthly_summary.dart';

void main() {
  test('calculates monthly income expense balance and expense categories', () {
    final transactions = <BookkeepingTransaction>[
      transaction(
        id: '00000000-0000-4000-8000-000000000101',
        type: TransactionType.income,
        amountMinor: 50000,
        categoryId: 'income.salary',
        date: LocalDate(2026, 8, 1),
      ),
      transaction(
        id: '00000000-0000-4000-8000-000000000102',
        type: TransactionType.expense,
        amountMinor: 1200,
        categoryId: 'expense.food',
        date: LocalDate(2026, 8, 2),
      ),
      transaction(
        id: '00000000-0000-4000-8000-000000000103',
        type: TransactionType.expense,
        amountMinor: 800,
        categoryId: 'expense.transport',
        date: LocalDate(2026, 8, 31),
      ),
      transaction(
        id: '00000000-0000-4000-8000-000000000104',
        type: TransactionType.expense,
        amountMinor: 9999,
        categoryId: 'expense.food',
        date: LocalDate(2026, 9, 1),
      ),
    ];

    final summary = MonthlySummary.calculate(
      transactions: transactions,
      year: 2026,
      month: 8,
    );

    expect(summary.totalIncomeMinor, 50000);
    expect(summary.totalExpenseMinor, 2000);
    expect(summary.balanceMinor, 48000);
    expect(summary.expenseCategoryTotals['expense.food'], 1200);
    expect(summary.expenseCategoryTotals['expense.transport'], 800);
    expect(summary.expenseCategoryPercentages['expense.food'], 0.6);
    expect(summary.expenseCategoryPercentages['expense.transport'], 0.4);
  });

  test('returns zero percentages when there are no monthly expenses', () {
    final summary = MonthlySummary.calculate(
      transactions: <BookkeepingTransaction>[
        transaction(
          id: '00000000-0000-4000-8000-000000000105',
          type: TransactionType.income,
          amountMinor: 1000,
          categoryId: 'income.bonus',
          date: LocalDate(2026, 8, 14),
        ),
      ],
      year: 2026,
      month: 8,
    );

    expect(summary.totalIncomeMinor, 1000);
    expect(summary.totalExpenseMinor, 0);
    expect(summary.balanceMinor, 1000);
    expect(summary.expenseCategoryTotals, isEmpty);
    expect(summary.expenseCategoryPercentages, isEmpty);
  });

  test('includes leap day only in its local calendar month', () {
    final summary = MonthlySummary.calculate(
      transactions: <BookkeepingTransaction>[
        transaction(
          id: '00000000-0000-4000-8000-000000000106',
          type: TransactionType.expense,
          amountMinor: 366,
          categoryId: 'expense.other',
          date: LocalDate(2024, 2, 29),
        ),
      ],
      year: 2024,
      month: 2,
    );

    final marchSummary = MonthlySummary.calculate(
      transactions: <BookkeepingTransaction>[
        transaction(
          id: '00000000-0000-4000-8000-000000000106',
          type: TransactionType.expense,
          amountMinor: 366,
          categoryId: 'expense.other',
          date: LocalDate(2024, 2, 29),
        ),
      ],
      year: 2024,
      month: 3,
    );

    expect(summary.totalExpenseMinor, 366);
    expect(marchSummary.totalExpenseMinor, 0);
  });
}

BookkeepingTransaction transaction({
  required String id,
  required TransactionType type,
  required int amountMinor,
  required String categoryId,
  required LocalDate date,
}) {
  return BookkeepingTransaction.create(
    id: id,
    type: type,
    amountMinor: amountMinor,
    categoryId: categoryId,
    transactionDate: date,
    createdAtUtc: DateTime.utc(2026, 8, 14),
    updatedAtUtc: DateTime.utc(2026, 8, 14),
  );
}
