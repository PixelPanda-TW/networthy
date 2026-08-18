import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/domain/model/currency_code.dart';
import 'package:networthy/domain/model/domain_validation.dart';
import 'package:networthy/domain/model/stock_account.dart';

void main() {
  test('stock account mode fixes currency', () {
    expect(StockAccountMode.taiwanStock.currencyCode, CurrencyCode.twd);
    expect(StockAccountMode.taiwanEtf.currencyCode, CurrencyCode.twd);
    expect(StockAccountMode.usStock.currencyCode, CurrencyCode.usd);
  });

  test('creates stock account and validates values', () {
    final account = StockAccount.create(
      id: '00000000-0000-4000-8000-000000040001',
      name: '富邦證券',
      mode: StockAccountMode.taiwanStock,
      currencyCode: CurrencyCode.twd,
      isArchived: false,
      createdAtUtc: DateTime.utc(2026, 8, 17, 1),
      updatedAtUtc: DateTime.utc(2026, 8, 17, 1),
    );

    expect(account.name, '富邦證券');
    expect(account.currencyCode, CurrencyCode.twd);

    expect(
      () => StockAccount.create(
        id: 'not-a-uuid',
        name: '富邦證券',
        mode: StockAccountMode.taiwanStock,
        currencyCode: CurrencyCode.twd,
        isArchived: false,
        createdAtUtc: DateTime.utc(2026, 8, 17, 1),
        updatedAtUtc: DateTime.utc(2026, 8, 17, 1),
      ),
      throwsA(isA<DomainValidationException>()),
    );

    expect(
      () => StockAccount.create(
        id: '00000000-0000-4000-8000-000000040002',
        name: '美股帳戶',
        mode: StockAccountMode.usStock,
        currencyCode: CurrencyCode.twd,
        isArchived: false,
        createdAtUtc: DateTime.utc(2026, 8, 17, 1),
        updatedAtUtc: DateTime.utc(2026, 8, 17, 1),
      ),
      throwsA(isA<DomainValidationException>()),
    );
  });
}
