import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/domain/ledger/ledger_transaction_builder.dart';
import 'package:networthy/domain/model/account.dart';
import 'package:networthy/domain/model/currency_code.dart';
import 'package:networthy/domain/model/ledger_transaction.dart';
import 'package:networthy/domain/model/local_date.dart';
import 'package:networthy/domain/repository/ledger_repository.dart';

void main() {}

void ledgerRepositoryContract({
  required Future<LedgerRepository> Function() createRepository,
}) {
  test('saves income expense and transfer records', () async {
    final repository = await createRepository();
    final cash = _account(
      id: '00000000-0000-4000-8000-000000031101',
      name: '現金 TWD',
      currency: CurrencyCode.twd,
    );
    final bank = _account(
      id: '00000000-0000-4000-8000-000000031102',
      name: '玉山台幣',
      currency: CurrencyCode.twd,
    );

    await repository.save(
      LedgerTransactionBuilder.income(
        transactionId: '00000000-0000-4000-8000-000000031103',
        entryId: '00000000-0000-4000-8000-000000031104',
        account: bank,
        amountMinor: 5000,
        categoryId: 'income.salary',
        transactionDate: LocalDate(2026, 8, 17),
        note: '薪水',
        createdAtUtc: DateTime.utc(2026, 8, 17, 1),
      ),
    );
    await repository.save(
      LedgerTransactionBuilder.expense(
        transactionId: '00000000-0000-4000-8000-000000031105',
        entryId: '00000000-0000-4000-8000-000000031106',
        account: bank,
        amountMinor: 1200,
        categoryId: 'expense.food',
        transactionDate: LocalDate(2026, 8, 18),
        note: '午餐',
        createdAtUtc: DateTime.utc(2026, 8, 18, 1),
      ),
    );
    await repository.save(
      LedgerTransactionBuilder.transfer(
        transactionId: '00000000-0000-4000-8000-000000031107',
        sourceEntryId: '00000000-0000-4000-8000-000000031108',
        targetEntryId: '00000000-0000-4000-8000-000000031109',
        source: bank,
        target: cash,
        amountMinor: 1000,
        transactionDate: LocalDate(2026, 8, 19),
        note: '領現',
        createdAtUtc: DateTime.utc(2026, 8, 19, 1),
      ),
    );

    final records = await repository.list(
      const LedgerQuery(year: 2026, month: 8),
    );

    expect(records.map((record) => record.transaction.type), [
      LedgerTransactionType.transfer,
      LedgerTransactionType.expense,
      LedgerTransactionType.income,
    ]);
    expect(records.first.entries, hasLength(2));
  });

  test('latest sorts by transaction date then created time', () async {
    final repository = await createRepository();
    final account = _account(
      id: '00000000-0000-4000-8000-000000031110',
      name: '現金 TWD',
      currency: CurrencyCode.twd,
    );
    await repository.save(
      _expense(
        account: account,
        transactionId: '00000000-0000-4000-8000-000000031111',
        entryId: '00000000-0000-4000-8000-000000031112',
        date: LocalDate(2026, 8, 16),
        createdAtUtc: DateTime.utc(2026, 8, 16, 12),
        note: 'older date',
      ),
    );
    await repository.save(
      _expense(
        account: account,
        transactionId: '00000000-0000-4000-8000-000000031113',
        entryId: '00000000-0000-4000-8000-000000031114',
        date: LocalDate(2026, 8, 17),
        createdAtUtc: DateTime.utc(2026, 8, 17, 9),
        note: 'same day older create',
      ),
    );
    await repository.save(
      _expense(
        account: account,
        transactionId: '00000000-0000-4000-8000-000000031115',
        entryId: '00000000-0000-4000-8000-000000031116',
        date: LocalDate(2026, 8, 17),
        createdAtUtc: DateTime.utc(2026, 8, 17, 11),
        note: 'same day newer create',
      ),
    );

    final latest = await repository.latest(limit: 2);

    expect(latest.map((record) => record.transaction.note), [
      'same day newer create',
      'same day older create',
    ]);
  });

  test(
    'opening balances are excluded from normal records and included in balances',
    () async {
      final repository = await createRepository();
      final account = _account(
        id: '00000000-0000-4000-8000-000000031117',
        name: '現金 TWD',
        currency: CurrencyCode.twd,
      );
      await repository.save(
        LedgerTransactionBuilder.openingBalance(
          transactionId: '00000000-0000-4000-8000-000000031118',
          entryId: '00000000-0000-4000-8000-000000031119',
          account: account,
          amountMinor: 1000,
          transactionDate: LocalDate(2026, 8, 17),
          createdAtUtc: DateTime.utc(2026, 8, 17, 1),
        ),
      );

      expect(await repository.list(const LedgerQuery()), isEmpty);
      expect(
        (await repository.list(
          const LedgerQuery(includeOpeningBalances: true),
        )).single.transaction.type,
        LedgerTransactionType.openingBalance,
      );
      expect((await repository.accountBalances()).single.balanceMinor, 1000);
    },
  );

  test(
    'monthly summary groups income expense and balance by currency',
    () async {
      final repository = await createRepository();
      final twd = _account(
        id: '00000000-0000-4000-8000-000000031120',
        name: '台幣',
        currency: CurrencyCode.twd,
      );
      final usd = _account(
        id: '00000000-0000-4000-8000-000000031121',
        name: '美金',
        currency: CurrencyCode.usd,
      );
      await repository.save(
        LedgerTransactionBuilder.income(
          transactionId: '00000000-0000-4000-8000-000000031122',
          entryId: '00000000-0000-4000-8000-000000031123',
          account: twd,
          amountMinor: 5000,
          categoryId: 'income.salary',
          transactionDate: LocalDate(2026, 8, 17),
          note: null,
          createdAtUtc: DateTime.utc(2026, 8, 17, 1),
        ),
      );
      await repository.save(
        LedgerTransactionBuilder.expense(
          transactionId: '00000000-0000-4000-8000-000000031124',
          entryId: '00000000-0000-4000-8000-000000031125',
          account: twd,
          amountMinor: 1200,
          categoryId: 'expense.food',
          transactionDate: LocalDate(2026, 8, 18),
          note: null,
          createdAtUtc: DateTime.utc(2026, 8, 18, 1),
        ),
      );
      await repository.save(
        LedgerTransactionBuilder.income(
          transactionId: '00000000-0000-4000-8000-000000031126',
          entryId: '00000000-0000-4000-8000-000000031127',
          account: usd,
          amountMinor: 50,
          categoryId: 'income.other',
          transactionDate: LocalDate(2026, 8, 18),
          note: null,
          createdAtUtc: DateTime.utc(2026, 8, 18, 2),
        ),
      );

      final summary = await repository.monthlySummary(year: 2026, month: 8);

      expect(summary.totalIncomeMinorByCurrency[CurrencyCode.twd], 5000);
      expect(summary.totalExpenseMinorByCurrency[CurrencyCode.twd], 1200);
      expect(summary.balanceMinorByCurrency[CurrencyCode.twd], 3800);
      expect(summary.balanceMinorByCurrency[CurrencyCode.usd], 50);
    },
  );

  test('delete removes transaction and entries', () async {
    final repository = await createRepository();
    final account = _account(
      id: '00000000-0000-4000-8000-000000031128',
      name: '現金 TWD',
      currency: CurrencyCode.twd,
    );
    final aggregate = _expense(
      account: account,
      transactionId: '00000000-0000-4000-8000-000000031129',
      entryId: '00000000-0000-4000-8000-000000031130',
      date: LocalDate(2026, 8, 17),
      createdAtUtc: DateTime.utc(2026, 8, 17, 1),
      note: 'delete me',
    );
    await repository.save(aggregate);

    await repository.delete(aggregate.transaction.id);

    expect(await repository.findRecordById(aggregate.transaction.id), isNull);
    expect(
      await repository.list(const LedgerQuery(includeOpeningBalances: true)),
      isEmpty,
    );
  });
}

CashAccount _account({
  required String id,
  required String name,
  required CurrencyCode currency,
}) {
  return CashAccount.create(
    id: id,
    name: name,
    currencyCode: currency,
    isArchived: false,
    createdAtUtc: DateTime.utc(2026, 8, 17, 1),
    updatedAtUtc: DateTime.utc(2026, 8, 17, 1),
  );
}

LedgerTransactionAggregate _expense({
  required CashAccount account,
  required String transactionId,
  required String entryId,
  required LocalDate date,
  required DateTime createdAtUtc,
  required String note,
}) {
  return LedgerTransactionBuilder.expense(
    transactionId: transactionId,
    entryId: entryId,
    account: account,
    amountMinor: 100,
    categoryId: 'expense.food',
    transactionDate: date,
    note: note,
    createdAtUtc: createdAtUtc,
  );
}
