import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/domain/model/currency_code.dart';
import 'package:networthy/domain/model/domain_validation.dart';
import 'package:networthy/domain/model/ledger_entry.dart';
import 'package:networthy/domain/model/ledger_transaction.dart';
import 'package:networthy/domain/model/local_date.dart';

void main() {
  test('creates transaction and signed entry models', () {
    final transaction = LedgerTransaction.create(
      id: '00000000-0000-4000-8000-000000030101',
      type: LedgerTransactionType.expense,
      categoryId: 'expense.food',
      transactionDate: LocalDate(2026, 8, 17),
      note: '午餐',
      createdAtUtc: DateTime.utc(2026, 8, 17, 1),
      updatedAtUtc: DateTime.utc(2026, 8, 17, 1),
    );
    final entry = LedgerEntry.create(
      id: '00000000-0000-4000-8000-000000030102',
      transactionId: transaction.id,
      accountId: '00000000-0000-4000-8000-000000030103',
      amountMinor: -120,
      currencyCode: CurrencyCode.twd,
      createdAtUtc: DateTime.utc(2026, 8, 17, 1),
    );

    expect(transaction.type, LedgerTransactionType.expense);
    expect(entry.amountMinor, -120);
  });

  test('requires category only for income and expense', () {
    expect(
      () => LedgerTransaction.create(
        id: '00000000-0000-4000-8000-000000030104',
        type: LedgerTransactionType.expense,
        categoryId: null,
        transactionDate: LocalDate(2026, 8, 17),
        note: null,
        createdAtUtc: DateTime.utc(2026, 8, 17, 1),
        updatedAtUtc: DateTime.utc(2026, 8, 17, 1),
      ),
      throwsA(isA<DomainValidationException>()),
    );

    final transfer = LedgerTransaction.create(
      id: '00000000-0000-4000-8000-000000030105',
      type: LedgerTransactionType.transfer,
      categoryId: null,
      transactionDate: LocalDate(2026, 8, 17),
      note: null,
      createdAtUtc: DateTime.utc(2026, 8, 17, 1),
      updatedAtUtc: DateTime.utc(2026, 8, 17, 1),
    );
    expect(transfer.categoryId, isNull);
  });
}
