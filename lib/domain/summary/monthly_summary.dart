import '../model/transaction.dart';
import '../model/transaction_type.dart';

class MonthlySummary {
  const MonthlySummary({
    required this.year,
    required this.month,
    required this.totalIncomeMinor,
    required this.totalExpenseMinor,
    required this.expenseCategoryTotals,
    required this.expenseCategoryPercentages,
  });

  final int year;
  final int month;
  final int totalIncomeMinor;
  final int totalExpenseMinor;
  final Map<String, int> expenseCategoryTotals;
  final Map<String, double> expenseCategoryPercentages;

  int get balanceMinor => totalIncomeMinor - totalExpenseMinor;

  static MonthlySummary calculate({
    required Iterable<BookkeepingTransaction> transactions,
    required int year,
    required int month,
  }) {
    var totalIncomeMinor = 0;
    var totalExpenseMinor = 0;
    final expenseCategoryTotals = <String, int>{};

    for (final transaction in transactions) {
      if (!transaction.transactionDate.isInMonth(year, month)) {
        continue;
      }

      switch (transaction.type) {
        case TransactionType.income:
          totalIncomeMinor += transaction.amountMinor;
        case TransactionType.expense:
          totalExpenseMinor += transaction.amountMinor;
          expenseCategoryTotals.update(
            transaction.categoryId,
            (current) => current + transaction.amountMinor,
            ifAbsent: () => transaction.amountMinor,
          );
      }
    }

    final expenseCategoryPercentages = <String, double>{};
    if (totalExpenseMinor > 0) {
      for (final entry in expenseCategoryTotals.entries) {
        expenseCategoryPercentages[entry.key] = entry.value / totalExpenseMinor;
      }
    }

    return MonthlySummary(
      year: year,
      month: month,
      totalIncomeMinor: totalIncomeMinor,
      totalExpenseMinor: totalExpenseMinor,
      expenseCategoryTotals: Map<String, int>.unmodifiable(
        expenseCategoryTotals,
      ),
      expenseCategoryPercentages: Map<String, double>.unmodifiable(
        expenseCategoryPercentages,
      ),
    );
  }
}
