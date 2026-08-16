import '../model/transaction.dart';
import '../model/transaction_type.dart';
import '../summary/monthly_summary.dart';

class TransactionQuery {
  const TransactionQuery({this.year, this.month, this.type});

  final int? year;
  final int? month;
  final TransactionType? type;
}

abstract interface class TransactionRepository {
  Future<void> save(BookkeepingTransaction transaction);

  Future<BookkeepingTransaction?> findById(String id);

  Future<List<BookkeepingTransaction>> list(TransactionQuery query);

  Future<List<BookkeepingTransaction>> latest({required int limit});

  Future<MonthlySummary> monthlySummary({
    required int year,
    required int month,
  });

  Future<void> delete(String id);
}
