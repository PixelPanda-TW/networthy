import 'currency_code.dart';
import 'domain_validation.dart';
import 'local_date.dart';
import 'stock_account.dart';
import 'stock_holding.dart';

enum StockTradeSide {
  buy('buy'),
  sell('sell');

  const StockTradeSide(this.wireValue);

  final String wireValue;
}

class StockTrade {
  const StockTrade._({
    required this.id,
    required this.stockAccountId,
    required this.cashAccountId,
    required this.side,
    required this.symbol,
    required this.name,
    required this.accountMode,
    required this.currencyCode,
    required this.quantityMicro,
    required this.priceMinor,
    required this.principalMinor,
    required this.tradeDate,
    required this.note,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });

  static const int maxSymbolCodePoints = StockHolding.maxSymbolCodePoints;
  static const int maxNameCodePoints = StockHolding.maxNameCodePoints;

  final String id;
  final String stockAccountId;
  final String cashAccountId;
  final StockTradeSide side;
  final String symbol;
  final String name;
  final StockAccountMode accountMode;
  final CurrencyCode currencyCode;
  final int? quantityMicro;
  final int? priceMinor;
  final int? principalMinor;
  final LocalDate tradeDate;
  final String? note;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;

  factory StockTrade.valuation({
    required String id,
    required String stockAccountId,
    required String cashAccountId,
    required StockTradeSide side,
    required String symbol,
    required String name,
    required int quantityMicro,
    required int priceMinor,
    required LocalDate tradeDate,
    required String? note,
    required DateTime createdAtUtc,
    required DateTime updatedAtUtc,
  }) {
    if (quantityMicro <= 0) {
      throw const DomainValidationException(
        'Trade quantity must be greater than 0.',
      );
    }
    if (priceMinor <= 0) {
      throw const DomainValidationException(
        'Trade price must be greater than 0.',
      );
    }
    return _create(
      id: id,
      stockAccountId: stockAccountId,
      cashAccountId: cashAccountId,
      side: side,
      symbol: symbol,
      name: name,
      accountMode: StockAccountMode.taiwanStock,
      currencyCode: CurrencyCode.twd,
      quantityMicro: quantityMicro,
      priceMinor: priceMinor,
      principalMinor: null,
      tradeDate: tradeDate,
      note: note,
      createdAtUtc: createdAtUtc,
      updatedAtUtc: updatedAtUtc,
    );
  }

  factory StockTrade.principal({
    required String id,
    required String stockAccountId,
    required String cashAccountId,
    required StockTradeSide side,
    required StockAccountMode accountMode,
    required String symbol,
    required String name,
    required int principalMinor,
    required LocalDate tradeDate,
    required String? note,
    required DateTime createdAtUtc,
    required DateTime updatedAtUtc,
  }) {
    if (accountMode == StockAccountMode.taiwanStock) {
      throw const DomainValidationException(
        'Principal trades require a principal-mode stock account.',
      );
    }
    if (principalMinor <= 0) {
      throw const DomainValidationException(
        'Trade principal must be greater than 0.',
      );
    }
    return _create(
      id: id,
      stockAccountId: stockAccountId,
      cashAccountId: cashAccountId,
      side: side,
      symbol: symbol,
      name: name,
      accountMode: accountMode,
      currencyCode: accountMode.currencyCode,
      quantityMicro: null,
      priceMinor: null,
      principalMinor: principalMinor,
      tradeDate: tradeDate,
      note: note,
      createdAtUtc: createdAtUtc,
      updatedAtUtc: updatedAtUtc,
    );
  }

  int get cashAmountMinor {
    final quantity = quantityMicro;
    final price = priceMinor;
    if (quantity != null && price != null) {
      return (quantity * price / StockHolding.quantityScale).round();
    }
    return principalMinor!;
  }

  String? get quantityDisplay {
    final quantity = quantityMicro;
    if (quantity == null) {
      return null;
    }
    final whole = quantity ~/ StockHolding.quantityScale;
    final fraction = (quantity % StockHolding.quantityScale).toString().padLeft(
      6,
      '0',
    );
    final trimmed = fraction.replaceFirst(RegExp(r'0+$'), '');
    return trimmed.isEmpty ? whole.toString() : '$whole.$trimmed';
  }

  static StockTrade _create({
    required String id,
    required String stockAccountId,
    required String cashAccountId,
    required StockTradeSide side,
    required String symbol,
    required String name,
    required StockAccountMode accountMode,
    required CurrencyCode currencyCode,
    required int? quantityMicro,
    required int? priceMinor,
    required int? principalMinor,
    required LocalDate tradeDate,
    required String? note,
    required DateTime createdAtUtc,
    required DateTime updatedAtUtc,
  }) {
    _validateUuid(id, 'Stock trade id');
    _validateUuid(stockAccountId, 'Stock account id');
    _validateUuid(cashAccountId, 'Cash account id');
    if (currencyCode != accountMode.currencyCode) {
      throw const DomainValidationException(
        'Trade currency must match stock account mode.',
      );
    }
    if (accountMode == StockAccountMode.taiwanStock) {
      if (quantityMicro == null ||
          priceMinor == null ||
          principalMinor != null) {
        throw const DomainValidationException(
          'Taiwan stock trades require quantity and price only.',
        );
      }
    } else if (principalMinor == null ||
        quantityMicro != null ||
        priceMinor != null) {
      throw const DomainValidationException(
        'Principal stock trades require principal only.',
      );
    }
    final normalizedSymbol = _validateText(
      symbol,
      fieldName: 'Stock symbol',
      maxCodePoints: maxSymbolCodePoints,
    );
    final normalizedName = _validateText(
      name,
      fieldName: 'Stock name',
      maxCodePoints: maxNameCodePoints,
    );
    final normalizedNote = note?.trim();
    if (normalizedNote != null && normalizedNote.isEmpty) {
      throw const DomainValidationException('Trade note must not be empty.');
    }
    if (!createdAtUtc.isUtc || !updatedAtUtc.isUtc) {
      throw const DomainValidationException('Trade timestamps must be UTC.');
    }
    return StockTrade._(
      id: id,
      stockAccountId: stockAccountId,
      cashAccountId: cashAccountId,
      side: side,
      symbol: normalizedSymbol,
      name: normalizedName,
      accountMode: accountMode,
      currencyCode: currencyCode,
      quantityMicro: quantityMicro,
      priceMinor: priceMinor,
      principalMinor: principalMinor,
      tradeDate: tradeDate,
      note: normalizedNote,
      createdAtUtc: createdAtUtc,
      updatedAtUtc: updatedAtUtc,
    );
  }
}

void _validateUuid(String id, String fieldName) {
  final pattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );
  if (!pattern.hasMatch(id)) {
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
