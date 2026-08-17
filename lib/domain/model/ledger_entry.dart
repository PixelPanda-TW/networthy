import 'currency_code.dart';
import 'domain_validation.dart';

class LedgerEntry {
  const LedgerEntry._({
    required this.id,
    required this.transactionId,
    required this.accountId,
    required this.amountMinor,
    required this.currencyCode,
    required this.createdAtUtc,
  });

  final String id;
  final String transactionId;
  final String accountId;
  final int amountMinor;
  final CurrencyCode currencyCode;
  final DateTime createdAtUtc;

  factory LedgerEntry.create({
    required String id,
    required String transactionId,
    required String accountId,
    required int amountMinor,
    required CurrencyCode currencyCode,
    required DateTime createdAtUtc,
    bool allowZeroAmount = false,
  }) {
    _validateUuid(id, 'Ledger entry id');
    _validateUuid(transactionId, 'Ledger transaction id');
    _validateUuid(accountId, 'Account id');
    if (!allowZeroAmount && amountMinor == 0) {
      throw const DomainValidationException('Ledger entry amount is required.');
    }
    _validateUtcTimestamp(createdAtUtc, 'createdAtUtc');

    return LedgerEntry._(
      id: id,
      transactionId: transactionId,
      accountId: accountId,
      amountMinor: amountMinor,
      currencyCode: currencyCode,
      createdAtUtc: createdAtUtc,
    );
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
