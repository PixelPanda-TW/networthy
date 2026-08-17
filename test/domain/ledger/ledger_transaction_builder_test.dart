import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/domain/ledger/ledger_transaction_builder.dart';
import 'package:networthy/domain/model/account.dart';
import 'package:networthy/domain/model/currency_code.dart';
import 'package:networthy/domain/model/domain_validation.dart';
import 'package:networthy/domain/model/ledger_transaction.dart';
import 'package:networthy/domain/model/local_date.dart';

void main() {
  test(
    'builds a same-currency transfer as one transaction with two entries',
    () {
      final source = _account(
        id: '00000000-0000-4000-8000-000000030201',
        name: '玉山台幣',
        currency: CurrencyCode.twd,
      );
      final target = _account(
        id: '00000000-0000-4000-8000-000000030202',
        name: '現金',
        currency: CurrencyCode.twd,
      );

      final aggregate = LedgerTransactionBuilder.transfer(
        transactionId: '00000000-0000-4000-8000-000000030203',
        sourceEntryId: '00000000-0000-4000-8000-000000030204',
        targetEntryId: '00000000-0000-4000-8000-000000030205',
        source: source,
        target: target,
        amountMinor: 1000,
        transactionDate: LocalDate(2026, 8, 17),
        note: '領現',
        createdAtUtc: DateTime.utc(2026, 8, 17, 1),
      );

      expect(aggregate.transaction.type, LedgerTransactionType.transfer);
      expect(aggregate.entries.map((entry) => entry.amountMinor), [
        -1000,
        1000,
      ]);
      expect(aggregate.entries.map((entry) => entry.currencyCode).toSet(), {
        CurrencyCode.twd,
      });
    },
  );

  test('rejects cross-currency transfer and same-account transfer', () {
    final twd = _account(
      id: '00000000-0000-4000-8000-000000030206',
      name: '台幣',
      currency: CurrencyCode.twd,
    );
    final usd = _account(
      id: '00000000-0000-4000-8000-000000030207',
      name: '美金',
      currency: CurrencyCode.usd,
    );

    expect(
      () => LedgerTransactionBuilder.transfer(
        transactionId: '00000000-0000-4000-8000-000000030208',
        sourceEntryId: '00000000-0000-4000-8000-000000030209',
        targetEntryId: '00000000-0000-4000-8000-000000030210',
        source: twd,
        target: usd,
        amountMinor: 1000,
        transactionDate: LocalDate(2026, 8, 17),
        note: null,
        createdAtUtc: DateTime.utc(2026, 8, 17, 1),
      ),
      throwsA(isA<DomainValidationException>()),
    );

    expect(
      () => LedgerTransactionBuilder.transfer(
        transactionId: '00000000-0000-4000-8000-000000030211',
        sourceEntryId: '00000000-0000-4000-8000-000000030212',
        targetEntryId: '00000000-0000-4000-8000-000000030213',
        source: twd,
        target: twd,
        amountMinor: 1000,
        transactionDate: LocalDate(2026, 8, 17),
        note: null,
        createdAtUtc: DateTime.utc(2026, 8, 17, 1),
      ),
      throwsA(isA<DomainValidationException>()),
    );
  });
}

CashAccount _account({
  required String id,
  required String name,
  required CurrencyCode currency,
  bool isArchived = false,
}) {
  return CashAccount.create(
    id: id,
    name: name,
    currencyCode: currency,
    isArchived: isArchived,
    createdAtUtc: DateTime.utc(2026, 8, 17, 1),
    updatedAtUtc: DateTime.utc(2026, 8, 17, 1),
  );
}
