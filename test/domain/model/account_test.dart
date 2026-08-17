import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/domain/model/account.dart';
import 'package:networthy/domain/model/currency_code.dart';
import 'package:networthy/domain/model/domain_validation.dart';

void main() {
  test('creates a valid cash account', () {
    final account = CashAccount.create(
      id: '00000000-0000-4000-8000-000000030001',
      name: '玉山台幣',
      currencyCode: CurrencyCode.twd,
      isArchived: false,
      createdAtUtc: DateTime.utc(2026, 8, 17, 1),
      updatedAtUtc: DateTime.utc(2026, 8, 17, 1),
    );

    expect(account.name, '玉山台幣');
    expect(account.currencyCode, CurrencyCode.twd);
    expect(account.isArchived, isFalse);
  });

  test('normalizes account name and rejects invalid values', () {
    expect(
      () => CashAccount.create(
        id: 'not-a-uuid',
        name: '玉山台幣',
        currencyCode: CurrencyCode.twd,
        isArchived: false,
        createdAtUtc: DateTime.utc(2026, 8, 17, 1),
        updatedAtUtc: DateTime.utc(2026, 8, 17, 1),
      ),
      throwsA(isA<DomainValidationException>()),
    );

    final normalized = CashAccount.create(
      id: '00000000-0000-4000-8000-000000030002',
      name: '  現金 TWD  ',
      currencyCode: CurrencyCode.twd,
      isArchived: false,
      createdAtUtc: DateTime.utc(2026, 8, 17, 1),
      updatedAtUtc: DateTime.utc(2026, 8, 17, 1),
    );
    expect(normalized.name, '現金 TWD');

    expect(
      () => CashAccount.create(
        id: '00000000-0000-4000-8000-000000030003',
        name: List.filled(31, 'あ').join(),
        currencyCode: CurrencyCode.jpy,
        isArchived: false,
        createdAtUtc: DateTime.utc(2026, 8, 17, 1),
        updatedAtUtc: DateTime.utc(2026, 8, 17, 1),
      ),
      throwsA(isA<DomainValidationException>()),
    );
  });
}
