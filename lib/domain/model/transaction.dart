import 'category.dart';
import 'domain_validation.dart';
import 'local_date.dart';
import 'transaction_type.dart';

class BookkeepingTransaction {
  const BookkeepingTransaction._({
    required this.id,
    required this.type,
    required this.amountMinor,
    required this.currencyCode,
    required this.categoryId,
    required this.transactionDate,
    required this.note,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });

  static const int maxAmountMinor = 999999999;
  static const String v1CurrencyCode = 'TWD';
  static const int maxNoteCodePoints = 100;

  final String id;
  final TransactionType type;
  final int amountMinor;
  final String currencyCode;
  final String categoryId;
  final LocalDate transactionDate;
  final String? note;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;

  factory BookkeepingTransaction.create({
    required String id,
    required TransactionType type,
    required int amountMinor,
    required String categoryId,
    required LocalDate transactionDate,
    required DateTime createdAtUtc,
    required DateTime updatedAtUtc,
    String currencyCode = v1CurrencyCode,
    String? note,
  }) {
    _validateId(id);
    _validateAmount(amountMinor);
    _validateCurrency(currencyCode);
    _validateCategory(categoryId: categoryId, type: type);
    _validateNote(note);
    _validateUtcTimestamp(createdAtUtc, 'createdAtUtc');
    _validateUtcTimestamp(updatedAtUtc, 'updatedAtUtc');

    return BookkeepingTransaction._(
      id: id,
      type: type,
      amountMinor: amountMinor,
      currencyCode: currencyCode,
      categoryId: categoryId,
      transactionDate: transactionDate,
      note: note,
      createdAtUtc: createdAtUtc,
      updatedAtUtc: updatedAtUtc,
    );
  }

  static void _validateId(String id) {
    final uuidPattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    );
    if (!uuidPattern.hasMatch(id)) {
      throw const DomainValidationException(
        'Transaction id must be a UUID string.',
      );
    }
  }

  static void _validateAmount(int amountMinor) {
    if (amountMinor <= 0) {
      throw const DomainValidationException('Amount must be greater than 0.');
    }
    if (amountMinor > maxAmountMinor) {
      throw const DomainValidationException('Amount exceeds V1 limit.');
    }
  }

  static void _validateCurrency(String currencyCode) {
    if (currencyCode != v1CurrencyCode) {
      throw const DomainValidationException('V1 only supports TWD.');
    }
  }

  static void _validateCategory({
    required String categoryId,
    required TransactionType type,
  }) {
    if (!CategoryCatalog.isCompatible(categoryId: categoryId, type: type)) {
      throw const DomainValidationException(
        'Category must be compatible with transaction type.',
      );
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

  static void _validateUtcTimestamp(DateTime timestamp, String fieldName) {
    if (!timestamp.isUtc) {
      throw DomainValidationException('$fieldName must be UTC.');
    }
  }
}
