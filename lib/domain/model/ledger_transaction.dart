import 'category.dart';
import 'domain_validation.dart';
import 'local_date.dart';
import 'transaction_type.dart';

enum LedgerTransactionType { income, expense, transfer, openingBalance }

class LedgerTransaction {
  const LedgerTransaction._({
    required this.id,
    required this.type,
    required this.categoryId,
    required this.transactionDate,
    required this.note,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });

  static const int maxNoteCodePoints = 100;

  final String id;
  final LedgerTransactionType type;
  final String? categoryId;
  final LocalDate transactionDate;
  final String? note;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;

  factory LedgerTransaction.create({
    required String id,
    required LedgerTransactionType type,
    required String? categoryId,
    required LocalDate transactionDate,
    required String? note,
    required DateTime createdAtUtc,
    required DateTime updatedAtUtc,
  }) {
    _validateUuid(id, 'Ledger transaction id');
    _validateCategory(type: type, categoryId: categoryId);
    _validateNote(note);
    _validateUtcTimestamp(createdAtUtc, 'createdAtUtc');
    _validateUtcTimestamp(updatedAtUtc, 'updatedAtUtc');

    return LedgerTransaction._(
      id: id,
      type: type,
      categoryId: categoryId,
      transactionDate: transactionDate,
      note: note,
      createdAtUtc: createdAtUtc,
      updatedAtUtc: updatedAtUtc,
    );
  }

  static void _validateCategory({
    required LedgerTransactionType type,
    required String? categoryId,
  }) {
    switch (type) {
      case LedgerTransactionType.income:
        if (categoryId == null ||
            !CategoryCatalog.isCompatible(
              categoryId: categoryId,
              type: TransactionType.income,
            )) {
          throw const DomainValidationException(
            'Income category must be compatible with income type.',
          );
        }
      case LedgerTransactionType.expense:
        if (categoryId == null ||
            !CategoryCatalog.isCompatible(
              categoryId: categoryId,
              type: TransactionType.expense,
            )) {
          throw const DomainValidationException(
            'Expense category must be compatible with expense type.',
          );
        }
      case LedgerTransactionType.transfer:
      case LedgerTransactionType.openingBalance:
        if (categoryId != null) {
          throw const DomainValidationException(
            'Category must be empty for transfer and opening balance.',
          );
        }
    }
  }

  static void _validateNote(String? note) {
    if (note == null) {
      return;
    }
    if (note.runes.length > maxNoteCodePoints) {
      throw const DomainValidationException('Note exceeds 100 code points.');
    }
  }
}

void _validateUuid(String id, String fieldName) {
  final uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );
  if (!uuidPattern.hasMatch(id)) {
    throw DomainValidationException('$fieldName must be a UUID string.');
  }
}

void _validateUtcTimestamp(DateTime timestamp, String fieldName) {
  if (!timestamp.isUtc) {
    throw DomainValidationException('$fieldName must be UTC.');
  }
}
