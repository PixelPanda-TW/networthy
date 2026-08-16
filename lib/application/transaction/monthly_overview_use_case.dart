import '../../domain/model/transaction.dart';
import '../../domain/repository/transaction_repository.dart';
import '../../domain/summary/monthly_summary.dart';

class MonthlyOverview {
  const MonthlyOverview({
    required this.summary,
    required this.recentTransactions,
  });

  final MonthlySummary summary;
  final List<BookkeepingTransaction> recentTransactions;
}

class MonthlyOverviewUseCase {
  const MonthlyOverviewUseCase(this._transactions);

  final TransactionRepository _transactions;

  Future<MonthlyOverview> load({required int year, required int month}) async {
    final summary = await _transactions.monthlySummary(
      year: year,
      month: month,
    );
    final recent = await _transactions.latest(limit: 5);
    return MonthlyOverview(summary: summary, recentTransactions: recent);
  }
}
