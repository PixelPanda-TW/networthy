import 'domain_validation.dart';

enum CurrencyCode {
  twd('TWD', 'NT\$'),
  jpy('JPY', '¥'),
  usd('USD', 'US\$');

  const CurrencyCode(this.wireValue, this.symbol);

  final String wireValue;
  final String symbol;

  static CurrencyCode fromWireValue(String value) {
    for (final currencyCode in CurrencyCode.values) {
      if (currencyCode.wireValue == value) {
        return currencyCode;
      }
    }
    throw DomainValidationException('Unsupported currency code: $value.');
  }
}
