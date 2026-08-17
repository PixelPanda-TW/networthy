import '../model/account.dart';
import '../model/domain_validation.dart';
import '../model/ledger_entry.dart';
import '../model/ledger_transaction.dart';
import '../model/local_date.dart';

class LedgerTransactionAggregate {
  const LedgerTransactionAggregate({
    required this.transaction,
    required this.entries,
  });

  final LedgerTransaction transaction;
  final List<LedgerEntry> entries;
}

class LedgerTransactionBuilder {
  const LedgerTransactionBuilder._();

  static LedgerTransactionAggregate income({
    required String transactionId,
    required String entryId,
    required CashAccount account,
    required int amountMinor,
    required String categoryId,
    required LocalDate transactionDate,
    required String? note,
    required DateTime createdAtUtc,
  }) {
    _validateActiveAccount(account);
    _validatePositiveAmount(amountMinor);
    return _singleEntryAggregate(
      transactionId: transactionId,
      entryId: entryId,
      type: LedgerTransactionType.income,
      account: account,
      amountMinor: amountMinor,
      categoryId: categoryId,
      transactionDate: transactionDate,
      note: note,
      createdAtUtc: createdAtUtc,
    );
  }

  static LedgerTransactionAggregate expense({
    required String transactionId,
    required String entryId,
    required CashAccount account,
    required int amountMinor,
    required String categoryId,
    required LocalDate transactionDate,
    required String? note,
    required DateTime createdAtUtc,
  }) {
    _validateActiveAccount(account);
    _validatePositiveAmount(amountMinor);
    return _singleEntryAggregate(
      transactionId: transactionId,
      entryId: entryId,
      type: LedgerTransactionType.expense,
      account: account,
      amountMinor: -amountMinor,
      categoryId: categoryId,
      transactionDate: transactionDate,
      note: note,
      createdAtUtc: createdAtUtc,
    );
  }

  static LedgerTransactionAggregate transfer({
    required String transactionId,
    required String sourceEntryId,
    required String targetEntryId,
    required CashAccount source,
    required CashAccount target,
    required int amountMinor,
    required LocalDate transactionDate,
    required String? note,
    required DateTime createdAtUtc,
  }) {
    _validateActiveAccount(source);
    _validateActiveAccount(target);
    _validatePositiveAmount(amountMinor);
    if (source.id == target.id) {
      throw const DomainValidationException(
        'Transfer source and target accounts must be different.',
      );
    }
    if (source.currencyCode != target.currencyCode) {
      throw const DomainValidationException(
        'v0.3.0 only supports same-currency transfers.',
      );
    }

    final transaction = LedgerTransaction.create(
      id: transactionId,
      type: LedgerTransactionType.transfer,
      categoryId: null,
      transactionDate: transactionDate,
      note: note,
      createdAtUtc: createdAtUtc,
      updatedAtUtc: createdAtUtc,
    );
    return LedgerTransactionAggregate(
      transaction: transaction,
      entries: [
        LedgerEntry.create(
          id: sourceEntryId,
          transactionId: transactionId,
          accountId: source.id,
          amountMinor: -amountMinor,
          currencyCode: source.currencyCode,
          createdAtUtc: createdAtUtc,
        ),
        LedgerEntry.create(
          id: targetEntryId,
          transactionId: transactionId,
          accountId: target.id,
          amountMinor: amountMinor,
          currencyCode: target.currencyCode,
          createdAtUtc: createdAtUtc,
        ),
      ],
    );
  }

  static LedgerTransactionAggregate openingBalance({
    required String transactionId,
    required String entryId,
    required CashAccount account,
    required int amountMinor,
    required LocalDate transactionDate,
    required DateTime createdAtUtc,
  }) {
    final transaction = LedgerTransaction.create(
      id: transactionId,
      type: LedgerTransactionType.openingBalance,
      categoryId: null,
      transactionDate: transactionDate,
      note: null,
      createdAtUtc: createdAtUtc,
      updatedAtUtc: createdAtUtc,
    );
    return LedgerTransactionAggregate(
      transaction: transaction,
      entries: [
        LedgerEntry.create(
          id: entryId,
          transactionId: transactionId,
          accountId: account.id,
          amountMinor: amountMinor,
          currencyCode: account.currencyCode,
          createdAtUtc: createdAtUtc,
          allowZeroAmount: true,
        ),
      ],
    );
  }

  static LedgerTransactionAggregate _singleEntryAggregate({
    required String transactionId,
    required String entryId,
    required LedgerTransactionType type,
    required CashAccount account,
    required int amountMinor,
    required String categoryId,
    required LocalDate transactionDate,
    required String? note,
    required DateTime createdAtUtc,
  }) {
    final transaction = LedgerTransaction.create(
      id: transactionId,
      type: type,
      categoryId: categoryId,
      transactionDate: transactionDate,
      note: note,
      createdAtUtc: createdAtUtc,
      updatedAtUtc: createdAtUtc,
    );
    return LedgerTransactionAggregate(
      transaction: transaction,
      entries: [
        LedgerEntry.create(
          id: entryId,
          transactionId: transactionId,
          accountId: account.id,
          amountMinor: amountMinor,
          currencyCode: account.currencyCode,
          createdAtUtc: createdAtUtc,
        ),
      ],
    );
  }

  static void _validateActiveAccount(CashAccount account) {
    if (account.isArchived) {
      throw const DomainValidationException('Account is archived.');
    }
  }

  static void _validatePositiveAmount(int amountMinor) {
    if (amountMinor <= 0) {
      throw const DomainValidationException('Amount must be greater than 0.');
    }
  }
}
