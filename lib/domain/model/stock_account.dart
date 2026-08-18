import 'currency_code.dart';
import 'domain_validation.dart';

enum StockAccountMode {
  taiwanStock('taiwanStock', '台股個股', CurrencyCode.twd),
  taiwanEtf('taiwanEtf', '台股 ETF', CurrencyCode.twd),
  usStock('usStock', '美股', CurrencyCode.usd);

  const StockAccountMode(this.wireValue, this.displayName, this.currencyCode);

  final String wireValue;
  final String displayName;
  final CurrencyCode currencyCode;

  static StockAccountMode fromWireValue(String value) {
    for (final mode in StockAccountMode.values) {
      if (mode.wireValue == value) {
        return mode;
      }
    }
    throw DomainValidationException('Unsupported stock account mode: $value.');
  }
}

class StockAccount {
  const StockAccount._({
    required this.id,
    required this.name,
    required this.mode,
    required this.currencyCode,
    required this.isArchived,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });

  static const int maxNameCodePoints = 30;

  final String id;
  final String name;
  final StockAccountMode mode;
  final CurrencyCode currencyCode;
  final bool isArchived;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;

  factory StockAccount.create({
    required String id,
    required String name,
    required StockAccountMode mode,
    required CurrencyCode currencyCode,
    required bool isArchived,
    required DateTime createdAtUtc,
    required DateTime updatedAtUtc,
  }) {
    _validateUuid(id, 'Stock account id');
    final normalizedName = _validateName(name);
    if (currencyCode != mode.currencyCode) {
      throw const DomainValidationException(
        'Stock account currency must match mode.',
      );
    }
    _validateUtcTimestamp(createdAtUtc, 'createdAtUtc');
    _validateUtcTimestamp(updatedAtUtc, 'updatedAtUtc');

    return StockAccount._(
      id: id,
      name: normalizedName,
      mode: mode,
      currencyCode: currencyCode,
      isArchived: isArchived,
      createdAtUtc: createdAtUtc,
      updatedAtUtc: updatedAtUtc,
    );
  }

  static String _validateName(String name) {
    final normalized = name.trim();
    if (normalized.isEmpty) {
      throw const DomainValidationException('Stock account name is required.');
    }
    if (normalized.runes.length > maxNameCodePoints) {
      throw const DomainValidationException(
        'Stock account name exceeds 30 code points.',
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
