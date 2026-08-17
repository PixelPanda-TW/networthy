# v0.3.0 Design: Multi-Account Cash Ledger

## Scope

v0.3.0 adds multi-account cash bookkeeping with three supported currencies:
`TWD`, `JPY`, and `USD`.

This release includes:

- multiple cash accounts;
- account currencies;
- account opening balances;
- same-currency transfers between accounts;
- account rename and archive;
- overview totals grouped by currency;
- migration from the v0.2.0 transaction model into ledger tables.

This release does not include:

- stock accounts;
- cash-plus-stock accounts;
- exchange rates;
- cross-currency transfers;
- cloud sync or backup.

Stock account support remains a later version because it needs a separate
portfolio model, security identity, cost-basis decisions, and market value
reporting. v0.3.0 should first stabilize the cash ledger foundation.

## Design decisions

- Totals are grouped by currency. The app does not calculate a combined net
  worth across currencies.
- New accounts support an opening balance.
- Transfers display as one user-facing record.
- Transfers are represented internally as balanced ledger entries.
- Accounts can be added, renamed, and archived. They cannot be deleted.
- Archived accounts are unavailable for new transactions but remain visible in
  historical records.
- v0.3.0 supports same-currency transfers only.

## Data model

### Account

`Account` represents a cash account.

Fields:

- `id`: UUID string.
- `name`: user-visible account name, up to 30 Unicode code points after
  trimming.
- `currencyCode`: one of `TWD`, `JPY`, `USD`.
- `isArchived`: archived accounts cannot be selected for new income, expense,
  or transfer records.
- `createdAtUtc`: UTC creation timestamp.
- `updatedAtUtc`: UTC update timestamp.

Validation:

- `id` must be a UUID string.
- `name` is required after trimming and must be at most 30 Unicode code
  points.
- `currencyCode` must be `TWD`, `JPY`, or `USD`.
- timestamps must be UTC.

### LedgerTransaction

`LedgerTransaction` is the user-visible record. It groups one or more ledger
entries.

Types:

- `income`
- `expense`
- `transfer`
- `openingBalance`

Fields:

- `id`: UUID string.
- `type`: one of the transaction types above.
- `categoryId`: required for income and expense; null for transfer and opening
  balance.
- `transactionDate`: local calendar date.
- `note`: optional user note.
- `createdAtUtc`: UTC creation timestamp.
- `updatedAtUtc`: UTC update timestamp.

Rules:

- `income` and `expense` require a category compatible with the transaction
  type.
- `transfer` has no category.
- `openingBalance` has no category and is created by account creation.
- User-facing records are loaded from ledger transactions plus their entries.

### LedgerEntry

`LedgerEntry` is the balance-affecting row.

Fields:

- `id`: UUID string.
- `transactionId`: parent ledger transaction id.
- `accountId`: affected account id.
- `amountMinor`: signed amount in the account currency.
- `currencyCode`: duplicated from the account currency for query stability.
- `createdAtUtc`: UTC creation timestamp.

Amount sign rules:

- positive amount means the account balance increases;
- negative amount means the account balance decreases.

Transaction entry rules:

- income: one positive entry;
- expense: one negative entry;
- same-currency transfer: two entries under one transaction, one negative from
  the source account and one positive to the target account;
- opening balance: one entry, positive or negative allowed.

Transfer validation:

- source and target accounts must be different;
- source and target accounts must use the same currency;
- source and target accounts must be active for new transfers;
- cross-currency transfers are rejected in v0.3.0.

## Database migration

The Drift schema moves from version 2 to version 3.

New tables:

- `accounts`
- `ledger_transactions`
- `ledger_entries`

The existing `transactions` table remains in the database for at least one
release. v0.3.0 stops writing to it, but retaining it reduces migration risk
and preserves an easy rollback/reference path while the ledger model settles.

Migration from v2:

1. Create ledger tables.
2. Create the default account `現金 TWD` if no account exists.
3. Convert each existing v2 transaction into one ledger transaction.
4. Convert income rows into one positive ledger entry.
5. Convert expense rows into one negative ledger entry.
6. Preserve transaction date, category id, currency code, note, created time,
   and updated time.

Bootstrap seed:

- App startup creates the ledger/account repositories.
- Account repository seeds default account `現金 TWD` only if no account rows
  exist.
- Seeding is idempotent and must not create duplicates.

## Application behavior

Account use cases:

- create account with name, currency, and opening balance;
- rename account;
- archive account;
- list active accounts;
- list all accounts for historical display;
- resolve display name for archived or missing accounts safely.

Ledger use cases:

- add income against an active account;
- add expense against an active account;
- add same-currency transfer between two active accounts;
- edit existing income, expense, and transfer records;
- delete existing user-created income, expense, and transfer records;
- query monthly overview grouped by currency;
- query records list with single-row transfer display.

Opening balance policy:

- Creating an account creates one opening-balance ledger transaction and one
  ledger entry.
- Opening-balance rows are system-generated.
- Opening-balance amount may be positive, zero, or negative.
- Opening-balance records cannot be edited or deleted from the normal
  transaction UI in v0.3.0.
- Opening balances do not appear in the normal records list.
- Opening balances contribute to account balances.

## UI behavior

### Settings

Settings adds `帳戶管理`.

Account management supports:

- adding an account with name, currency, and opening balance;
- renaming an account;
- archiving an account;
- listing active accounts grouped or labeled by currency.

No delete action is offered.

### Income and expense form

The transaction form adds an account picker.

Rules:

- new income/expense records list active accounts only;
- editing a historical record whose account is archived still shows
  `帳戶名稱（已封存）`;
- category behavior remains the v0.2.0 repository-backed category behavior.

### Transfer form

The app adds a transfer entry point.

Fields:

- source account;
- target account;
- amount;
- date;
- note.

Validation:

- amount must be greater than zero;
- source and target accounts must be different;
- source and target accounts must have the same currency;
- source and target accounts must be active.

### Overview

The overview displays income, expense, and balance grouped by currency.

Example:

- `TWD 收入 NT$10,000`
- `TWD 支出 NT$2,000`
- `TWD 結餘 NT$8,000`
- `JPY 結餘 ¥30,000`
- `USD 結餘 US$500`

The overview also lists account balances by currency. No exchange-rate
conversion is shown.

### Records

Income/expense rows display:

- account name;
- category display path;
- amount;
- note or fallback label.

Transfer rows display as a single record:

- `來源帳戶 → 目標帳戶 金額`

Opening balances are hidden from the normal records list.

## Testing strategy

Each implementation milestone uses TDD: write a failing test, verify the red
failure, implement the minimal production code, then verify green.

Required automated coverage:

- `Account` domain validation.
- `LedgerTransaction` and `LedgerEntry` validation.
- same-currency transfer balancing rules.
- transfer rejection when accounts differ by currency.
- account repository contract tests.
- ledger repository contract tests.
- v2-to-v3 migration using a real SQLite v2 fixture.
- default account seed idempotency.
- income/expense account picker behavior.
- archived account historical display behavior.
- account management widget flow.
- transfer widget flow.
- overview grouped-by-currency totals.
- records list single-row transfer display.

Required final verification:

```sh
flutter test
flutter analyze
flutter build apk --release
flutter build ios --simulator
git diff --check
```

## Milestones

1. Domain model
   - `Account`
   - `LedgerTransaction`
   - `LedgerEntry`
   - currency validation
   - transfer balancing rules

2. Repository contracts
   - `AccountRepository`
   - `LedgerRepository`
   - in-memory contract tests

3. Drift persistence and migration
   - schema version 3
   - accounts and ledger tables
   - v2-to-v3 migration
   - default account seed

4. Application use cases
   - create account
   - rename/archive account
   - add income/expense against account
   - add transfer
   - safe edit/delete behavior

5. Presentation dependency injection and existing transaction UI migration
   - app uses account and ledger repositories
   - income/expense form supports account picker
   - overview and records read from ledger queries

6. Account management UI
   - settings entry
   - add/rename/archive account
   - opening balance flow

7. Transfer UI
   - transfer entry point
   - same-currency validation
   - records display as one transfer row

8. Verification and release acceptance
   - full tests
   - analyzer
   - Android release build
   - iOS simulator build
   - verification document

Each milestone must be committed and pushed independently after passing its
verification commands.
