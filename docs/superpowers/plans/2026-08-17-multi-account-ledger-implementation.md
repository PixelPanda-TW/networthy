# Multi-Account Cash Ledger Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add v0.3.0 multi-account cash bookkeeping with TWD/JPY/USD accounts, opening balances, same-currency transfers, grouped currency totals, and migration from v0.2.0 transactions into ledger tables.

**Architecture:** Introduce cash accounts and a ledger model while preserving the existing UI shape. `LedgerTransaction` is the user-visible record; `LedgerEntry` is the signed balance-affecting row. The app migrates existing v2 rows into ledger tables and stops writing to the old `transactions` table.

**Tech Stack:** Flutter, Dart, Drift, sqlite3 fixture migration tests, existing repository/use-case/presentation layering.

## Global Constraints

- Supported currencies are exactly `TWD`, `JPY`, and `USD`.
- Overview totals are grouped by currency; no exchange-rate conversion is performed.
- Transfers display as one user-facing record.
- Transfers are represented internally as two balanced same-currency ledger entries.
- Cross-currency transfers are rejected in v0.3.0.
- Accounts can be added, renamed, and archived; accounts cannot be deleted.
- Archived accounts cannot be selected for new income, expense, or transfer records.
- Historical records that reference archived accounts must still display the account name.
- Creating an account creates one system-generated opening-balance transaction and one entry.
- Opening-balance records are hidden from the normal records list and cannot be edited or deleted from the normal transaction UI in v0.3.0.
- Keep `ios/Runner.xcodeproj/project.pbxproj` unstaged unless the user explicitly asks to commit signing changes.
- After each task passes verification, run `git add`, `git commit`, and `git push`.

---

## File Structure

New domain files:

- `lib/domain/model/currency_code.dart`: `CurrencyCode` enum plus display/formatting helpers.
- `lib/domain/model/account.dart`: cash account validation and archive state.
- `lib/domain/model/ledger_transaction.dart`: transaction grouping model and type validation.
- `lib/domain/model/ledger_entry.dart`: signed account entry model.
- `lib/domain/ledger/ledger_transaction_builder.dart`: validates and builds income, expense, transfer, and opening-balance aggregates.
- `lib/domain/summary/currency_summary.dart`: grouped monthly totals and account balances.

New repository contracts:

- `lib/domain/repository/account_repository.dart`
- `lib/domain/repository/ledger_repository.dart`

New data files:

- `lib/data/repository/drift_account_repository.dart`
- `lib/data/repository/drift_ledger_repository.dart`

Modified data files:

- `lib/data/database/networthy_database.dart`
- `lib/data/database/networthy_database.g.dart`

New application files:

- `lib/application/account/account_command.dart`
- `lib/application/account/account_use_cases.dart`
- `lib/application/ledger/ledger_command.dart`
- `lib/application/ledger/ledger_use_cases.dart`

Presentation additions:

- `lib/presentation/settings/account_management_page.dart`
- `lib/presentation/transfer/transfer_form_page.dart`

Presentation modifications:

- `lib/main.dart`
- `lib/presentation/app/networthy_app.dart`
- `lib/presentation/home/home_shell.dart`
- `lib/presentation/overview/overview_page.dart`
- `lib/presentation/records/records_page.dart`
- `lib/presentation/settings/settings_page.dart`
- `lib/presentation/transaction/transaction_form_page.dart`

Test support:

- `test/presentation/test_app_harness.dart`

---

## Task 1: Domain model

**Files:**

- Create: `lib/domain/model/currency_code.dart`
- Create: `lib/domain/model/account.dart`
- Create: `lib/domain/model/ledger_transaction.dart`
- Create: `lib/domain/model/ledger_entry.dart`
- Create: `lib/domain/ledger/ledger_transaction_builder.dart`
- Create: `test/domain/model/account_test.dart`
- Create: `test/domain/model/ledger_transaction_test.dart`
- Create: `test/domain/ledger/ledger_transaction_builder_test.dart`

**Interfaces:**

- Produces `CurrencyCode.twd`, `CurrencyCode.jpy`, `CurrencyCode.usd`.
- Produces `CashAccount.create(...)`.
- Produces `LedgerTransactionType.income`, `expense`, `transfer`, `openingBalance`.
- Produces `LedgerTransaction.create(...)`.
- Produces `LedgerEntry.create(...)`.
- Produces `LedgerTransactionBuilder.income(...)`, `.expense(...)`, `.transfer(...)`, `.openingBalance(...)`.

- [ ] **Step 1: Write failing account model tests**

Add `test/domain/model/account_test.dart`:

```dart
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
        name: 'あ' * 31,
        currencyCode: CurrencyCode.jpy,
        isArchived: false,
        createdAtUtc: DateTime.utc(2026, 8, 17, 1),
        updatedAtUtc: DateTime.utc(2026, 8, 17, 1),
      ),
      throwsA(isA<DomainValidationException>()),
    );
  });
}
```

- [ ] **Step 2: Write failing ledger model tests**

Add `test/domain/model/ledger_transaction_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/domain/model/domain_validation.dart';
import 'package:networthy/domain/model/ledger_entry.dart';
import 'package:networthy/domain/model/ledger_transaction.dart';
import 'package:networthy/domain/model/local_date.dart';
import 'package:networthy/domain/model/currency_code.dart';

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
```

- [ ] **Step 3: Write failing ledger aggregate tests**

Add `test/domain/ledger/ledger_transaction_builder_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/domain/ledger/ledger_transaction_builder.dart';
import 'package:networthy/domain/model/account.dart';
import 'package:networthy/domain/model/currency_code.dart';
import 'package:networthy/domain/model/domain_validation.dart';
import 'package:networthy/domain/model/ledger_transaction.dart';
import 'package:networthy/domain/model/local_date.dart';

void main() {
  test('builds a same-currency transfer as one transaction with two entries', () {
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
    expect(aggregate.entries.map((entry) => entry.amountMinor), [-1000, 1000]);
    expect(aggregate.entries.map((entry) => entry.currencyCode).toSet(), {
      CurrencyCode.twd,
    });
  });

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
```

- [ ] **Step 4: Run red tests**

Run:

```sh
flutter test test/domain/model/account_test.dart test/domain/model/ledger_transaction_test.dart test/domain/ledger/ledger_transaction_builder_test.dart
```

Expected: compilation fails because new model files do not exist.

- [ ] **Step 5: Implement minimal domain model**

Implement:

- `CurrencyCode` enum with values `twd`, `jpy`, `usd`, wire values `TWD`, `JPY`, `USD`, and parsing from database strings.
- `CashAccount.create` with UUID/name/timestamp validation.
- `LedgerTransactionType` enum and `LedgerTransaction.create`.
- `LedgerEntry.create`, allowing positive and negative non-zero amounts for normal entries.
- `LedgerTransactionAggregate` with `transaction` and `entries`.
- `LedgerTransactionBuilder.income`, `.expense`, `.transfer`, `.openingBalance`.

Use existing `DomainValidationException` for domain failures.

- [ ] **Step 6: Verify**

Run:

```sh
dart format lib/domain/model/currency_code.dart lib/domain/model/account.dart lib/domain/model/ledger_transaction.dart lib/domain/model/ledger_entry.dart lib/domain/ledger/ledger_transaction_builder.dart test/domain/model/account_test.dart test/domain/model/ledger_transaction_test.dart test/domain/ledger/ledger_transaction_builder_test.dart
flutter test test/domain
flutter analyze
git diff --check
```

- [ ] **Step 7: Commit**

Run:

```sh
git add lib/domain/model/currency_code.dart lib/domain/model/account.dart lib/domain/model/ledger_transaction.dart lib/domain/model/ledger_entry.dart lib/domain/ledger/ledger_transaction_builder.dart test/domain/model/account_test.dart test/domain/model/ledger_transaction_test.dart test/domain/ledger/ledger_transaction_builder_test.dart
git commit -m "feat: add cash ledger domain model"
git push
```

---

## Task 2: Repository contracts

**Files:**

- Create: `lib/domain/repository/account_repository.dart`
- Create: `lib/domain/repository/ledger_repository.dart`
- Modify: `test/presentation/test_app_harness.dart`
- Create: `test/domain/repository/account_repository_contract_test.dart`
- Create: `test/domain/repository/in_memory_account_repository_test.dart`
- Create: `test/domain/repository/ledger_repository_contract_test.dart`
- Create: `test/domain/repository/in_memory_ledger_repository_test.dart`

**Interfaces:**

- Produces `AccountRepository`:
  - `Future<List<CashAccount>> listActive()`
  - `Future<List<CashAccount>> listAll()`
  - `Future<CashAccount?> findById(String id)`
  - `Future<String> displayNameFor(String id)`
  - `Future<CashAccount> create(CreateAccountRequest request)`
  - `Future<CashAccount> rename({required String id, required String name})`
  - `Future<void> archive(String id)`
  - `Future<CashAccount> ensureDefaultAccountSeeded()`
- Produces `LedgerRepository`:
  - `Future<void> save(LedgerTransactionAggregate aggregate)`
  - `Future<LedgerRecord?> findRecordById(String id)`
  - `Future<List<LedgerRecord>> list(LedgerQuery query)`
  - `Future<List<LedgerRecord>> latest({required int limit})`
  - `Future<CurrencyMonthlySummary> monthlySummary({required int year, required int month})`
  - `Future<List<AccountBalance>> accountBalances()`
  - `Future<void> delete(String id)`

- [ ] **Step 1: Write failing account repository contract**

Add contract tests that verify:

- default account seed creates `現金 TWD` exactly once;
- create account stores name/currency/opening-balance request metadata;
- rename changes display name;
- archive hides from `listActive` but preserves `findById`;
- archived account display falls back to name;
- unknown display name returns raw id.

Use `accountRepositoryContract(() => TestAccountRepository())` from the in-memory test.

- [ ] **Step 2: Write failing ledger repository contract**

Add contract tests that verify:

- save/list returns income, expense, and transfer records;
- `latest(limit: 5)` sorts by transaction date then created time;
- normal list excludes `openingBalance`;
- monthly summary groups income/expense/balance by currency;
- account balances include opening balances and transfers;
- delete removes a ledger transaction and its entries.

- [ ] **Step 3: Run red tests**

Run:

```sh
flutter test test/domain/repository/in_memory_account_repository_test.dart test/domain/repository/in_memory_ledger_repository_test.dart
```

Expected: compilation fails because repository contracts and in-memory implementations do not exist.

- [ ] **Step 4: Implement repository contracts and test doubles**

Implement:

- `AccountRepositoryException` with `safeMessage`.
- `CreateAccountRequest(id, name, currencyCode, openingBalanceMinor)`.
- `LedgerQuery(year, month, type, includeOpeningBalances)`.
- `LedgerRecord(transaction, entries)`.
- `AccountBalance(accountId, currencyCode, balanceMinor)`.
- `CurrencyMonthlySummary` grouped by `CurrencyCode`.
- `TestAccountRepository` and `TestLedgerRepository` in `test/presentation/test_app_harness.dart`.

The test doubles must enforce the same business constraints used by production repositories:

- no duplicate active account names for the same currency;
- archived accounts hidden from active lists;
- transfer aggregates must contain exactly two entries;
- opening balances excluded by default from records queries.

- [ ] **Step 5: Verify**

Run:

```sh
dart format lib/domain/repository/account_repository.dart lib/domain/repository/ledger_repository.dart test/presentation/test_app_harness.dart test/domain/repository/account_repository_contract_test.dart test/domain/repository/in_memory_account_repository_test.dart test/domain/repository/ledger_repository_contract_test.dart test/domain/repository/in_memory_ledger_repository_test.dart
flutter test test/domain/repository
flutter analyze
git diff --check
```

- [ ] **Step 6: Commit**

Run:

```sh
git add lib/domain/repository/account_repository.dart lib/domain/repository/ledger_repository.dart test/presentation/test_app_harness.dart test/domain/repository/account_repository_contract_test.dart test/domain/repository/in_memory_account_repository_test.dart test/domain/repository/ledger_repository_contract_test.dart test/domain/repository/in_memory_ledger_repository_test.dart
git commit -m "feat: add account ledger repository contracts"
git push
```

---

## Task 3: Drift persistence and v3 migration

**Files:**

- Modify: `lib/data/database/networthy_database.dart`
- Modify: `lib/data/database/networthy_database.g.dart`
- Create: `lib/data/repository/drift_account_repository.dart`
- Create: `lib/data/repository/drift_ledger_repository.dart`
- Modify: `test/data/database/networthy_database_migration_test.dart`
- Create: `test/data/repository/drift_account_repository_test.dart`
- Create: `test/data/repository/drift_ledger_repository_test.dart`

**Interfaces:**

- Consumes `AccountRepository`, `LedgerRepository`, `CashAccount`, `LedgerTransactionAggregate`.
- Produces Drift implementations with the same behavior as Task 2 contracts.

- [ ] **Step 1: Write failing Drift account repository tests**

Test:

- `ensureDefaultAccountSeeded()` creates only one `現金 TWD`;
- create account stores opening-balance ledger rows through the account use-case later, but repository itself stores account fields only;
- rename/archive persist and reload.

- [ ] **Step 2: Write failing Drift ledger repository tests**

Test:

- save income and expense aggregates, list records, and compute grouped currency summary;
- save transfer aggregate and list one transfer record with two entries;
- account balances include opening balance, income, expense, and transfer signs;
- delete removes ledger transaction plus entries.

- [ ] **Step 3: Write failing v2-to-v3 migration test**

Extend the existing real SQLite fixture test:

- manually create v2 schema with `transactions`, `app_settings_rows`, and `categories`;
- insert one income and one expense using existing v2 columns;
- set `PRAGMA user_version = 2`;
- open with `NetworthyDatabase`;
- assert schema version 3 tables exist;
- assert one default account `現金 TWD`;
- assert two ledger transactions migrated;
- assert income entry is positive and expense entry is negative;
- assert original category ids and notes remain.

- [ ] **Step 4: Run red tests**

Run:

```sh
flutter test test/data/repository/drift_account_repository_test.dart test/data/repository/drift_ledger_repository_test.dart test/data/database/networthy_database_migration_test.dart
```

Expected: compilation or migration failures because v3 schema/repositories do not exist.

- [ ] **Step 5: Implement schema and repositories**

Modify `NetworthyDatabase`:

- add `Accounts` table;
- add `LedgerTransactions` table;
- add `LedgerEntries` table;
- bump `schemaVersion` from 2 to 3;
- in `onUpgrade`, if `from < 3`, create new tables and migrate existing `transactions` rows.

Run:

```sh
dart run build_runner build --delete-conflicting-outputs
```

Implement Drift repositories:

- `DriftAccountRepository`
- `DriftLedgerRepository`

- [ ] **Step 6: Verify**

Run:

```sh
dart format lib/data/database/networthy_database.dart lib/data/repository/drift_account_repository.dart lib/data/repository/drift_ledger_repository.dart test/data/database/networthy_database_migration_test.dart test/data/repository/drift_account_repository_test.dart test/data/repository/drift_ledger_repository_test.dart
flutter test test/data
flutter analyze
git diff --check
```

- [ ] **Step 7: Commit**

Run:

```sh
git add lib/data/database/networthy_database.dart lib/data/database/networthy_database.g.dart lib/data/repository/drift_account_repository.dart lib/data/repository/drift_ledger_repository.dart test/data/database/networthy_database_migration_test.dart test/data/repository/drift_account_repository_test.dart test/data/repository/drift_ledger_repository_test.dart
git commit -m "feat: persist multi account ledger"
git push
```

---

## Task 4: Application use cases

**Files:**

- Create: `lib/application/account/account_command.dart`
- Create: `lib/application/account/account_use_cases.dart`
- Create: `lib/application/ledger/ledger_command.dart`
- Create: `lib/application/ledger/ledger_use_cases.dart`
- Modify: `lib/application/transaction/add_transaction_use_case.dart`
- Modify: `lib/application/transaction/edit_transaction_use_case.dart`
- Create: `test/application/account/account_use_cases_test.dart`
- Create: `test/application/ledger/ledger_use_cases_test.dart`
- Modify: `test/application/transaction/transaction_command_use_cases_test.dart`

**Interfaces:**

- Produces `CreateAccountUseCase`, `RenameAccountUseCase`, `ArchiveAccountUseCase`.
- Produces `AddLedgerIncomeExpenseUseCase`, `EditLedgerIncomeExpenseUseCase`, `AddTransferUseCase`, `DeleteLedgerRecordUseCase`.
- Keeps old transaction use cases compiling until presentation migration is complete.

- [ ] **Step 1: Write failing account use-case tests**

Test:

- create account validates name/currency and creates opening-balance aggregate through ledger repository;
- rename rejects archived or missing account with safe validation failure;
- archive rejects missing account and hides active account.

- [ ] **Step 2: Write failing ledger use-case tests**

Test:

- add expense against an active account creates negative entry;
- add income against active account creates positive entry;
- add transfer creates one transaction with two entries;
- transfer rejects same account, archived account, and cross-currency accounts;
- delete rejects opening-balance transaction.

- [ ] **Step 3: Run red tests**

Run:

```sh
flutter test test/application/account/account_use_cases_test.dart test/application/ledger/ledger_use_cases_test.dart
```

Expected: compilation fails because use cases do not exist.

- [ ] **Step 4: Implement use cases**

Use existing `ApplicationFailure.validation(...)` for safe user errors.

Command shapes:

```dart
class CreateAccountCommand {
  const CreateAccountCommand({
    required this.name,
    required this.currencyCode,
    required this.openingBalanceMinor,
  });
}
```

```dart
class LedgerIncomeExpenseCommand {
  const LedgerIncomeExpenseCommand({
    required this.type,
    required this.accountId,
    required this.amountMinor,
    required this.categoryId,
    required this.transactionDate,
    this.note,
  });
}
```

```dart
class TransferCommand {
  const TransferCommand({
    required this.sourceAccountId,
    required this.targetAccountId,
    required this.amountMinor,
    required this.transactionDate,
    this.note,
  });
}
```

Inject:

- `AccountRepository`
- `LedgerRepository`
- `CategoryRepository`
- `ApplicationClock`
- `TransactionIdGenerator`

- [ ] **Step 5: Verify**

Run:

```sh
dart format lib/application/account lib/application/ledger test/application/account test/application/ledger
flutter test test/application
flutter analyze
git diff --check
```

- [ ] **Step 6: Commit**

Run:

```sh
git add lib/application/account lib/application/ledger lib/application/transaction/add_transaction_use_case.dart lib/application/transaction/edit_transaction_use_case.dart test/application/account test/application/ledger test/application/transaction/transaction_command_use_cases_test.dart
git commit -m "feat: add account ledger use cases"
git push
```

---

## Task 5: Presentation dependency injection and ledger-backed existing UI

**Files:**

- Modify: `lib/main.dart`
- Modify: `lib/presentation/app/networthy_app.dart`
- Modify: `lib/presentation/home/home_shell.dart`
- Modify: `lib/presentation/overview/overview_page.dart`
- Modify: `lib/presentation/records/records_page.dart`
- Modify: `lib/presentation/transaction/transaction_form_page.dart`
- Modify: `test/presentation/test_app_harness.dart`
- Modify: `test/presentation/overview/overview_widget_test.dart`
- Modify: `test/presentation/records/records_page_widget_test.dart`
- Modify: `test/presentation/transaction/transaction_form_widget_test.dart`

**Interfaces:**

- Consumes `AccountRepository`, `LedgerRepository`, ledger use cases.
- Existing income/expense UI writes ledger records.
- Overview/records read ledger summaries/records.

- [ ] **Step 1: Write failing presentation tests**

Extend transaction form tests:

- app starts with default `現金 TWD` account selected;
- adding expense saves a ledger expense record against that account;
- editing old record keeps archived selected account visible as `現金 TWD（已封存）`.

Extend overview tests:

- TWD and USD summaries display as separate currency rows.

Extend records tests:

- records rows include account name and category path;
- opening-balance records are hidden.

- [ ] **Step 2: Run red tests**

Run:

```sh
flutter test test/presentation/overview/overview_widget_test.dart test/presentation/records/records_page_widget_test.dart test/presentation/transaction/transaction_form_widget_test.dart
```

Expected: failures because app constructors and UI do not yet accept account/ledger repositories.

- [ ] **Step 3: Inject account and ledger repositories**

Modify:

- `NetworthyApp(accounts: AccountRepository, ledger: LedgerRepository, ...)`
- `_AppGate`
- `HomeShell`
- `OverviewPage`
- `RecordsPage`
- `TransactionFormPage`

Modify `main.dart`:

- create `DriftAccountRepository(database)`;
- create `DriftLedgerRepository(database)`;
- call `await accounts.ensureDefaultAccountSeeded()`;
- pass repositories into `NetworthyApp`.

- [ ] **Step 4: Update existing income/expense UI**

Transaction form:

- load active accounts;
- default to `現金 TWD` or first active account;
- save income/expense through ledger use cases;
- include archived account only when editing that historical record.

Overview:

- read `ledger.monthlySummary`;
- render grouped currency metrics.

Records:

- read `ledger.list`;
- hide opening balances by default;
- render account name and category path.

- [ ] **Step 5: Verify**

Run:

```sh
dart format lib/main.dart lib/presentation/app/networthy_app.dart lib/presentation/home/home_shell.dart lib/presentation/overview/overview_page.dart lib/presentation/records/records_page.dart lib/presentation/transaction/transaction_form_page.dart test/presentation/test_app_harness.dart test/presentation/overview/overview_widget_test.dart test/presentation/records/records_page_widget_test.dart test/presentation/transaction/transaction_form_widget_test.dart
flutter test test/presentation
flutter analyze
git diff --check
```

- [ ] **Step 6: Commit**

Run:

```sh
git add lib/main.dart lib/presentation/app/networthy_app.dart lib/presentation/home/home_shell.dart lib/presentation/overview/overview_page.dart lib/presentation/records/records_page.dart lib/presentation/transaction/transaction_form_page.dart test/presentation/test_app_harness.dart test/presentation/overview/overview_widget_test.dart test/presentation/records/records_page_widget_test.dart test/presentation/transaction/transaction_form_widget_test.dart
git commit -m "feat: use ledger in bookkeeping UI"
git push
```

---

## Task 6: Account management UI

**Files:**

- Modify: `lib/presentation/settings/settings_page.dart`
- Create: `lib/presentation/settings/account_management_page.dart`
- Modify: `test/presentation/settings/settings_page_widget_test.dart`
- Create: `test/presentation/settings/account_management_widget_test.dart`

**Interfaces:**

- Consumes `AccountRepository`, `LedgerRepository`, account use cases.
- Produces Settings → 帳戶管理.

- [ ] **Step 1: Write failing widget tests**

Create account management tests:

- opens page with `帳戶管理` title;
- creates account `玉山台幣`, currency `TWD`, opening balance `1000`;
- verifies account appears and ledger balance is `1000`;
- renames account to `玉山薪轉`;
- archives account and verifies it disappears from active account list.

Extend settings test:

- tapping `帳戶管理` opens the page.

- [ ] **Step 2: Run red tests**

Run:

```sh
flutter test test/presentation/settings/account_management_widget_test.dart test/presentation/settings/settings_page_widget_test.dart
```

Expected: failures because account management page and settings entry do not exist.

- [ ] **Step 3: Implement account management page**

Page behavior:

- AppBar title `帳戶管理`;
- `新增帳戶` button;
- dialog fields:
  - `Key('account-name-field')`;
  - currency selector with `TWD`, `JPY`, `USD`;
  - `Key('opening-balance-field')`;
- row buttons:
  - tooltip `重新命名 <account name>`;
  - tooltip `封存 <account name>`;
- archive confirmation uses button text `封存`.

Opening balance:

- zero is allowed;
- positive and negative integers are allowed;
- display balances using currency-specific formatter.

- [ ] **Step 4: Verify**

Run:

```sh
dart format lib/presentation/settings/settings_page.dart lib/presentation/settings/account_management_page.dart test/presentation/settings/settings_page_widget_test.dart test/presentation/settings/account_management_widget_test.dart
flutter test test/presentation/settings
flutter analyze
git diff --check
```

- [ ] **Step 5: Commit**

Run:

```sh
git add lib/presentation/settings/settings_page.dart lib/presentation/settings/account_management_page.dart test/presentation/settings/settings_page_widget_test.dart test/presentation/settings/account_management_widget_test.dart
git commit -m "feat: add account management UI"
git push
```

---

## Task 7: Transfer UI

**Files:**

- Create: `lib/presentation/transfer/transfer_form_page.dart`
- Modify: `lib/presentation/home/home_shell.dart`
- Modify: `lib/presentation/overview/overview_page.dart`
- Modify: `lib/presentation/records/records_page.dart`
- Create: `test/presentation/transfer/transfer_form_widget_test.dart`
- Modify: `test/presentation/records/records_page_widget_test.dart`

**Interfaces:**

- Consumes `AddTransferUseCase`.
- Produces transfer entry point and single-row records display.

- [ ] **Step 1: Write failing transfer widget tests**

Test:

- transfer form creates one transfer record from `玉山台幣` to `現金 TWD`;
- records list displays `玉山台幣 → 現金 TWD NT$1,000` once;
- form rejects same-account transfer with `來源與目標帳戶不能相同`;
- form rejects cross-currency transfer with `v0.3.0 僅支援同幣別轉帳`.

- [ ] **Step 2: Run red tests**

Run:

```sh
flutter test test/presentation/transfer/transfer_form_widget_test.dart test/presentation/records/records_page_widget_test.dart
```

Expected: failures because transfer form and entry point do not exist.

- [ ] **Step 3: Implement transfer form and entry point**

UI:

- add transfer entry point from overview or home action area;
- source account dropdown lists active accounts;
- target account dropdown lists active accounts;
- amount field uses `Key('transfer-amount-field')`;
- note field uses `Key('transfer-note-field')`;
- save button text `儲存`.

Validation:

- amount > 0;
- source != target;
- source currency == target currency;
- both accounts active.

- [ ] **Step 4: Update records rendering**

For `LedgerTransactionType.transfer`, render one row:

```text
來源帳戶 → 目標帳戶 NT$1,000
```

Do not render the two entries as separate rows.

- [ ] **Step 5: Verify**

Run:

```sh
dart format lib/presentation/transfer/transfer_form_page.dart lib/presentation/home/home_shell.dart lib/presentation/overview/overview_page.dart lib/presentation/records/records_page.dart test/presentation/transfer/transfer_form_widget_test.dart test/presentation/records/records_page_widget_test.dart
flutter test test/presentation
flutter analyze
git diff --check
```

- [ ] **Step 6: Commit**

Run:

```sh
git add lib/presentation/transfer/transfer_form_page.dart lib/presentation/home/home_shell.dart lib/presentation/overview/overview_page.dart lib/presentation/records/records_page.dart test/presentation/transfer/transfer_form_widget_test.dart test/presentation/records/records_page_widget_test.dart
git commit -m "feat: add same currency transfer UI"
git push
```

---

## Task 8: Verification and release acceptance

**Files:**

- Modify: `docs/problems/v0.1.0.md`
- Create: `docs/verification/v0.3.0-multi-account-ledger.md`

**Interfaces:**

- Produces final v0.3.0 verification record.

- [ ] **Step 1: Write verification doc**

Create `docs/verification/v0.3.0-multi-account-ledger.md` with:

````markdown
# v0.3.0 Verification: Multi-Account Cash Ledger

## Automated commands

```sh
flutter test
flutter analyze
flutter build apk --release
flutter build ios --simulator
git diff --check
```

## Manual script

1. Open Settings → 帳戶管理.
2. Create account `玉山台幣`, currency `TWD`, opening balance `1000`.
3. Create account `現金 TWD`, currency `TWD`, opening balance `0`.
4. Create account `美金現金`, currency `USD`, opening balance `50`.
5. Add an expense from `玉山台幣`.
6. Confirm overview shows TWD totals separately from USD totals.
7. Create a transfer from `玉山台幣` to `現金 TWD`.
8. Confirm records show one transfer row.
9. Try a transfer from `玉山台幣` to `美金現金`.
10. Confirm the app rejects cross-currency transfer.
11. Archive `玉山台幣`.
12. Confirm new income/expense no longer lists it.
13. Confirm historical records still display `玉山台幣`.
````

- [ ] **Step 2: Update problem status**

Update `docs/problems/v0.1.0.md` problem 1 status:

- v0.3.0 implements multiple cash accounts, same-currency transfers, and TWD/JPY/USD currency grouping.
- Cross-currency transfers and exchange-rate conversion are outside v0.3.0.
- Stock accounts remain future work.

- [ ] **Step 3: Run final verification**

Run:

```sh
flutter test
flutter analyze
flutter build apk --release
flutter build ios --simulator
git diff --check
```

Expected:

- all tests pass;
- analyzer reports no issues;
- Android release APK exists at `build/app/outputs/flutter-apk/app-release.apk`;
- iOS simulator app exists at `build/ios/iphonesimulator/Runner.app`;
- `ios/Runner.xcodeproj/project.pbxproj` remains unstaged if it is still only local signing work.

- [ ] **Step 4: Record build results**

Append observed command results and artifact paths to `docs/verification/v0.3.0-multi-account-ledger.md`.

- [ ] **Step 5: Commit**

Run:

```sh
git add docs/problems/v0.1.0.md docs/verification/v0.3.0-multi-account-ledger.md
git commit -m "docs: verify multi account ledger"
git push
```
