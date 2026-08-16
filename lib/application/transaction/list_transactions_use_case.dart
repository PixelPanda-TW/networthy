import '../../domain/model/transaction.dart';
import '../../domain/repository/transaction_repository.dart';

class ListTransactionsUseCase {
  const ListTransactionsUseCase(this._transactions);

  final TransactionRepository _transactions;

  Future<List<BookkeepingTransaction>> list(TransactionQuery query) {
    return _transactions.list(query);
  }
}
