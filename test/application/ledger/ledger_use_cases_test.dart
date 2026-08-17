import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/application/common/application_failure.dart';
import 'package:networthy/application/ledger/ledger_command.dart';
import 'package:networthy/application/ledger/ledger_use_cases.dart';
import 'package:networthy/domain/ledger/ledger_transaction_builder.dart';
import 'package:networthy/domain/model/account.dart';
import 'package:networthy/domain/model/currency_code.dart';
import 'package:networthy/domain/model/ledger_entry.dart';
import 'package:networthy/domain/model/ledger_transaction.dart';
import 'package:networthy/domain/model/local_date.dart';
import 'package:networthy/domain/model/transaction_type.dart';
import 'package:networthy/domain/repository/account_repository.dart';
import 'package:networthy/domain/repository/ledger_repository.dart';

import '../../presentation/test_app_harness.dart';

void main() {
  test(
    'adds expense and income against active accounts with signed entries',
    () async {
      final accounts = TestAccountRepository(seedDefault: false);
      final ledger = TestLedgerRepository();
      final categories = TestCategoryRepository();
      final account = await _createAccount(accounts);
      final useCase = AddLedgerIncomeExpenseUseCase(
        accounts: accounts,
        ledger: ledger,
        categories: categories,
        clock: TestClock(DateTime.utc(2026, 8, 17, 1)),
        idGenerator: TestIdGenerator([
          '00000000-0000-4000-8000-000000034101',
          '00000000-0000-4000-8000-000000034102',
          '00000000-0000-4000-8000-000000034103',
          '00000000-0000-4000-8000-000000034104',
        ]),
      );

      final expense = await useCase.execute(
        LedgerIncomeExpenseCommand(
          type: TransactionType.expense,
          accountId: account.id,
          amountMinor: 1200,
          categoryId: 'expense.food',
          transactionDate: LocalDate(2026, 8, 17),
          note: '午餐',
        ),
      );
      final income = await useCase.execute(
        LedgerIncomeExpenseCommand(
          type: TransactionType.income,
          accountId: account.id,
          amountMinor: 5000,
          categoryId: 'income.salary',
          transactionDate: LocalDate(2026, 8, 17),
          note: '薪水',
        ),
      );

      expect(expense.failure, isNull);
      expect(income.failure, isNull);
      expect(
        (await ledger.list(
          const LedgerQuery(),
        )).expand((record) => record.entries).map((entry) => entry.amountMinor),
        [5000, -1200],
      );
    },
  );

  test('adds transfer as one transaction with two balanced entries', () async {
    final accounts = TestAccountRepository(seedDefault: false);
    final ledger = TestLedgerRepository();
    final source = await _createAccount(
      accounts,
      id: '00000000-0000-4000-8000-000000034105',
      name: '玉山台幣',
    );
    final target = await _createAccount(
      accounts,
      id: '00000000-0000-4000-8000-000000034106',
      name: '現金 TWD',
    );

    final result =
        await AddTransferUseCase(
          accounts: accounts,
          ledger: ledger,
          clock: TestClock(DateTime.utc(2026, 8, 17, 1)),
          idGenerator: TestIdGenerator([
            '00000000-0000-4000-8000-000000034107',
            '00000000-0000-4000-8000-000000034108',
            '00000000-0000-4000-8000-000000034109',
          ]),
        ).execute(
          TransferCommand(
            sourceAccountId: source.id,
            targetAccountId: target.id,
            amountMinor: 1000,
            transactionDate: LocalDate(2026, 8, 17),
            note: '領現',
          ),
        );

    expect(result.failure, isNull);
    expect(result.record?.transaction.type, LedgerTransactionType.transfer);
    expect(result.record?.entries.map((entry) => entry.amountMinor), [
      -1000,
      1000,
    ]);
  });

  test('edits income or expense and preserves record identity', () async {
    final accounts = TestAccountRepository(seedDefault: false);
    final ledger = TestLedgerRepository();
    final categories = TestCategoryRepository();
    final account = await _createAccount(accounts);
    final createdAtUtc = DateTime.utc(2026, 8, 17, 1);
    await ledger.save(
      LedgerTransactionAggregate(
        transaction: LedgerTransaction.create(
          id: '00000000-0000-4000-8000-000000034130',
          type: LedgerTransactionType.expense,
          categoryId: 'expense.food',
          transactionDate: LocalDate(2026, 8, 17),
          note: '午餐',
          createdAtUtc: createdAtUtc,
          updatedAtUtc: createdAtUtc,
        ),
        entries: [
          LedgerEntry.create(
            id: '00000000-0000-4000-8000-000000034131',
            transactionId: '00000000-0000-4000-8000-000000034130',
            accountId: account.id,
            amountMinor: -1200,
            currencyCode: CurrencyCode.twd,
            createdAtUtc: createdAtUtc,
          ),
        ],
      ),
    );

    final result =
        await EditLedgerIncomeExpenseUseCase(
          accounts: accounts,
          ledger: ledger,
          categories: categories,
          clock: TestClock(DateTime.utc(2026, 8, 17, 2)),
        ).execute(
          EditLedgerIncomeExpenseCommand(
            id: '00000000-0000-4000-8000-000000034130',
            type: TransactionType.income,
            accountId: account.id,
            amountMinor: 5000,
            categoryId: 'income.salary',
            transactionDate: LocalDate(2026, 8, 18),
            note: '薪水',
          ),
        );

    expect(result.failure, isNull);
    expect(
      result.record?.transaction.id,
      '00000000-0000-4000-8000-000000034130',
    );
    expect(result.record?.transaction.createdAtUtc, createdAtUtc);
    expect(
      result.record?.transaction.updatedAtUtc,
      DateTime.utc(2026, 8, 17, 2),
    );
    expect(result.record?.transaction.type, LedgerTransactionType.income);
    expect(
      result.record?.entries.single.id,
      '00000000-0000-4000-8000-000000034131',
    );
    expect(result.record?.entries.single.amountMinor, 5000);
  });

  test(
    'transfer rejects same account archived account and cross currency',
    () async {
      final accounts = TestAccountRepository(seedDefault: false);
      final ledger = TestLedgerRepository();
      final twd = await _createAccount(accounts);
      final usd = await _createAccount(
        accounts,
        id: '00000000-0000-4000-8000-000000034110',
        name: '美金',
        currency: CurrencyCode.usd,
      );
      final archived = await _createAccount(
        accounts,
        id: '00000000-0000-4000-8000-000000034111',
        name: '封存',
      );
      await accounts.archive(archived.id);
      final useCase = AddTransferUseCase(
        accounts: accounts,
        ledger: ledger,
        clock: TestClock(DateTime.utc(2026, 8, 17, 1)),
        idGenerator: TestIdGenerator([
          '00000000-0000-4000-8000-000000034112',
          '00000000-0000-4000-8000-000000034113',
          '00000000-0000-4000-8000-000000034114',
          '00000000-0000-4000-8000-000000034115',
          '00000000-0000-4000-8000-000000034116',
          '00000000-0000-4000-8000-000000034117',
          '00000000-0000-4000-8000-000000034118',
          '00000000-0000-4000-8000-000000034119',
          '00000000-0000-4000-8000-000000034120',
        ]),
      );

      for (final command in [
        TransferCommand(
          sourceAccountId: twd.id,
          targetAccountId: twd.id,
          amountMinor: 1000,
          transactionDate: LocalDate(2026, 8, 17),
        ),
        TransferCommand(
          sourceAccountId: twd.id,
          targetAccountId: archived.id,
          amountMinor: 1000,
          transactionDate: LocalDate(2026, 8, 17),
        ),
        TransferCommand(
          sourceAccountId: twd.id,
          targetAccountId: usd.id,
          amountMinor: 1000,
          transactionDate: LocalDate(2026, 8, 17),
        ),
      ]) {
        final result = await useCase.execute(command);
        expect(result.failure?.type, ApplicationFailureType.validation);
      }
    },
  );

  test('delete rejects opening balance transaction', () async {
    final ledger = TestLedgerRepository();
    final account = CashAccount.create(
      id: '00000000-0000-4000-8000-000000034121',
      name: '現金 TWD',
      currencyCode: CurrencyCode.twd,
      isArchived: false,
      createdAtUtc: DateTime.utc(2026, 8, 17, 1),
      updatedAtUtc: DateTime.utc(2026, 8, 17, 1),
    );
    final opening = LedgerTransactionBuilder.openingBalance(
      transactionId: '00000000-0000-4000-8000-000000034122',
      entryId: '00000000-0000-4000-8000-000000034123',
      account: account,
      amountMinor: 0,
      transactionDate: LocalDate(2026, 8, 17),
      createdAtUtc: DateTime.utc(2026, 8, 17, 1),
    );
    await ledger.save(opening);

    final result = await DeleteLedgerRecordUseCase(ledger).execute(
      DeleteLedgerRecordCommand(id: opening.transaction.id, confirmed: true),
    );

    expect(result.failure?.type, ApplicationFailureType.validation);
    expect(await ledger.findRecordById(opening.transaction.id), isNotNull);
  });
}

Future<CashAccount> _createAccount(
  AccountRepository accounts, {
  String id = '00000000-0000-4000-8000-000000034100',
  String name = '玉山台幣',
  CurrencyCode currency = CurrencyCode.twd,
}) {
  return accounts.create(
    CreateAccountRequest(
      id: id,
      name: name,
      currencyCode: currency,
      openingBalanceMinor: 0,
    ),
  );
}
