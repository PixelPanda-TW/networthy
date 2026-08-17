import '../../domain/model/ledger_transaction.dart';
import '../../domain/model/local_date.dart';
import '../../domain/model/transaction_type.dart';
import '../../domain/repository/ledger_repository.dart';
import '../common/application_failure.dart';

class LedgerIncomeExpenseCommand {
  const LedgerIncomeExpenseCommand({
    required this.type,
    required this.accountId,
    required this.amountMinor,
    required this.categoryId,
    required this.transactionDate,
    this.note,
  });

  final TransactionType type;
  final String accountId;
  final int amountMinor;
  final String categoryId;
  final LocalDate transactionDate;
  final String? note;
}

class EditLedgerIncomeExpenseCommand {
  const EditLedgerIncomeExpenseCommand({
    required this.id,
    required this.type,
    required this.accountId,
    required this.amountMinor,
    required this.categoryId,
    required this.transactionDate,
    this.note,
  });

  final String id;
  final TransactionType type;
  final String accountId;
  final int amountMinor;
  final String categoryId;
  final LocalDate transactionDate;
  final String? note;
}

class TransferCommand {
  const TransferCommand({
    required this.sourceAccountId,
    required this.targetAccountId,
    required this.amountMinor,
    required this.transactionDate,
    this.note,
  });

  final String sourceAccountId;
  final String targetAccountId;
  final int amountMinor;
  final LocalDate transactionDate;
  final String? note;
}

class DeleteLedgerRecordCommand {
  const DeleteLedgerRecordCommand({required this.id, required this.confirmed});

  final String id;
  final bool confirmed;
}

class LedgerCommandResult {
  const LedgerCommandResult.success(this.record) : failure = null;

  const LedgerCommandResult.failure(this.failure) : record = null;

  final LedgerRecord? record;
  final ApplicationFailure? failure;
}

class DeleteLedgerRecordResult {
  const DeleteLedgerRecordResult.success() : failure = null;

  const DeleteLedgerRecordResult.failure(this.failure);

  final ApplicationFailure? failure;
}

extension LedgerTransactionTypeFromTransactionType on TransactionType {
  LedgerTransactionType get ledgerType {
    switch (this) {
      case TransactionType.income:
        return LedgerTransactionType.income;
      case TransactionType.expense:
        return LedgerTransactionType.expense;
    }
  }
}
