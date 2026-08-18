import 'domain_validation.dart';
import 'stock_account.dart';

enum StockHoldingTrackingMode { valuation, principal }

class StockHolding {
  const StockHolding._({
    required this.id,
    required this.accountId,
    required this.symbol,
    required this.name,
    required this.accountMode,
    required this.trackingMode,
    required this.quantityMicro,
    required this.averageCostMinor,
    required this.currentPriceMinor,
    required this.principalMinor,
    required this.isArchived,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });

  static const int maxSymbolCodePoints = 20;
  static const int maxNameCodePoints = 60;
  static const int quantityScale = 1000000;

  final String id;
  final String accountId;
  final String symbol;
  final String name;
  final StockAccountMode accountMode;
  final StockHoldingTrackingMode trackingMode;
  final int? quantityMicro;
  final int? averageCostMinor;
  final int? currentPriceMinor;
  final int? principalMinor;
  final bool isArchived;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;

  factory StockHolding.valuation({
    required String id,
    required String accountId,
    required String symbol,
    required String name,
    required StockAccountMode accountMode,
    required int quantityMicro,
    required int averageCostMinor,
    required int currentPriceMinor,
    required bool isArchived,
    required DateTime createdAtUtc,
    required DateTime updatedAtUtc,
  }) {
    if (accountMode != StockAccountMode.taiwanStock) {
      throw const DomainValidationException(
        'Valuation holdings require a Taiwan stock account.',
      );
    }
    _validatePositive(quantityMicro, 'Quantity');
    _validateNonNegative(averageCostMinor, 'Average cost');
    _validateNonNegative(currentPriceMinor, 'Current price');
    return _create(
      id: id,
      accountId: accountId,
      symbol: symbol,
      name: name,
      accountMode: accountMode,
      trackingMode: StockHoldingTrackingMode.valuation,
      quantityMicro: quantityMicro,
      averageCostMinor: averageCostMinor,
      currentPriceMinor: currentPriceMinor,
      principalMinor: null,
      isArchived: isArchived,
      createdAtUtc: createdAtUtc,
      updatedAtUtc: updatedAtUtc,
    );
  }

  factory StockHolding.principal({
    required String id,
    required String accountId,
    required String symbol,
    required String name,
    required StockAccountMode accountMode,
    required int principalMinor,
    required bool isArchived,
    required DateTime createdAtUtc,
    required DateTime updatedAtUtc,
  }) {
    if (accountMode == StockAccountMode.taiwanStock) {
      throw const DomainValidationException(
        'Principal holdings require a principal-mode stock account.',
      );
    }
    _validateNonNegative(principalMinor, 'Principal');
    return _create(
      id: id,
      accountId: accountId,
      symbol: symbol,
      name: name,
      accountMode: accountMode,
      trackingMode: StockHoldingTrackingMode.principal,
      quantityMicro: null,
      averageCostMinor: null,
      currentPriceMinor: null,
      principalMinor: principalMinor,
      isArchived: isArchived,
      createdAtUtc: createdAtUtc,
      updatedAtUtc: updatedAtUtc,
    );
  }

  static StockHolding _create({
    required String id,
    required String accountId,
    required String symbol,
    required String name,
    required StockAccountMode accountMode,
    required StockHoldingTrackingMode trackingMode,
    required int? quantityMicro,
    required int? averageCostMinor,
    required int? currentPriceMinor,
    required int? principalMinor,
    required bool isArchived,
    required DateTime createdAtUtc,
    required DateTime updatedAtUtc,
  }) {
    _validateUuid(id, 'Stock holding id');
    _validateUuid(accountId, 'Stock account id');
    final normalizedSymbol = _validateText(
      symbol,
      fieldName: 'Stock symbol',
      maxCodePoints: maxSymbolCodePoints,
    );
    final normalizedName = _validateText(
      name,
      fieldName: 'Stock holding name',
      maxCodePoints: maxNameCodePoints,
    );
    _validateUtcTimestamp(createdAtUtc, 'createdAtUtc');
    _validateUtcTimestamp(updatedAtUtc, 'updatedAtUtc');

    return StockHolding._(
      id: id,
      accountId: accountId,
      symbol: normalizedSymbol,
      name: normalizedName,
      accountMode: accountMode,
      trackingMode: trackingMode,
      quantityMicro: quantityMicro,
      averageCostMinor: averageCostMinor,
      currentPriceMinor: currentPriceMinor,
      principalMinor: principalMinor,
      isArchived: isArchived,
      createdAtUtc: createdAtUtc,
      updatedAtUtc: updatedAtUtc,
    );
  }

  String? get quantityDisplay {
    final quantity = quantityMicro;
    if (quantity == null) {
      return null;
    }
    final whole = quantity ~/ quantityScale;
    final fraction = (quantity % quantityScale).toString().padLeft(6, '0');
    final trimmedFraction = fraction.replaceFirst(RegExp(r'0+$'), '');
    if (trimmedFraction.isEmpty) {
      return whole.toString();
    }
    return '$whole.$trimmedFraction';
  }

  int? get costMinor {
    final quantity = quantityMicro;
    final averageCost = averageCostMinor;
    if (quantity == null || averageCost == null) {
      return null;
    }
    return (quantity * averageCost / quantityScale).round();
  }

  int? get marketValueMinor {
    final quantity = quantityMicro;
    final currentPrice = currentPriceMinor;
    if (quantity == null || currentPrice == null) {
      return null;
    }
    return (quantity * currentPrice / quantityScale).round();
  }

  int? get unrealizedGainLossMinor {
    final marketValue = marketValueMinor;
    final cost = costMinor;
    if (marketValue == null || cost == null) {
      return null;
    }
    return marketValue - cost;
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

String _validateText(
  String value, {
  required String fieldName,
  required int maxCodePoints,
}) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw DomainValidationException('$fieldName is required.');
  }
  if (normalized.runes.length > maxCodePoints) {
    throw DomainValidationException(
      '$fieldName exceeds $maxCodePoints code points.',
    );
  }
  return normalized;
}

void _validatePositive(int value, String fieldName) {
  if (value <= 0) {
    throw DomainValidationException('$fieldName must be greater than 0.');
  }
}

void _validateNonNegative(int value, String fieldName) {
  if (value < 0) {
    throw DomainValidationException('$fieldName must not be negative.');
  }
}

void _validateUtcTimestamp(DateTime timestamp, String fieldName) {
  if (!timestamp.isUtc) {
    throw DomainValidationException('$fieldName must be UTC.');
  }
}
