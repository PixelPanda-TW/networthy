import 'currency_code.dart';
import 'domain_validation.dart';

class CashAccount {
  const CashAccount._({
    required this.id,
    required this.name,
    required this.currencyCode,
    required this.isArchived,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });

  static const int maxNameCodePoints = 30;

  final String id;
  final String name;
  final CurrencyCode currencyCode;
  final bool isArchived;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;

  factory CashAccount.create({
    required String id,
    required String name,
    required CurrencyCode currencyCode,
    required bool isArchived,
    required DateTime createdAtUtc,
    required DateTime updatedAtUtc,
  }) {
    _validateUuid(id, 'Account id');
    final normalizedName = _validateName(name);
    _validateUtcTimestamp(createdAtUtc, 'createdAtUtc');
    _validateUtcTimestamp(updatedAtUtc, 'updatedAtUtc');

    return CashAccount._(
      id: id,
      name: normalizedName,
      currencyCode: currencyCode,
      isArchived: isArchived,
      createdAtUtc: createdAtUtc,
      updatedAtUtc: updatedAtUtc,
    );
  }

  static String _validateName(String name) {
    final normalized = name.trim();
    if (normalized.isEmpty) {
      throw const DomainValidationException('Account name is required.');
    }
    if (normalized.runes.length > maxNameCodePoints) {
      throw const DomainValidationException(
        'Account name exceeds 30 code points.',
      );
    }
    return normalized;
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
