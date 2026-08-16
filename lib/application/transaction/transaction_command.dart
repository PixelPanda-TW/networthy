import '../../domain/model/local_date.dart';
import '../../domain/model/transaction.dart';
import '../../domain/model/transaction_type.dart';
import '../common/application_failure.dart';

class TransactionCommand {
  const TransactionCommand({
    required this.type,
    required this.amountMinor,
    required this.categoryId,
    required this.transactionDate,
    this.note,
  });

  final TransactionType type;
  final int amountMinor;
  final String categoryId;
  final LocalDate transactionDate;
  final String? note;
}

class TransactionCommandResult {
  const TransactionCommandResult.success(this.transaction) : failure = null;

  const TransactionCommandResult.failure(this.failure) : transaction = null;

  final BookkeepingTransaction? transaction;
  final ApplicationFailure? failure;
}
