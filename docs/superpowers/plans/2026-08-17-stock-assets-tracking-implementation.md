# Stock Assets Tracking Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build v0.4.0 stock assets tracking with a new `資產` tab, stock accounts, valuation/principal holdings, and overview asset summaries.

**Architecture:** Add a stock asset domain and persistence layer separate from the existing cash ledger. Stock account mode determines fixed currency and holding behavior: Taiwan individual stocks use valuation mode, Taiwan ETF and US stock accounts use principal mode. Presentation adds an assets page for management and overview summary rows without merging currencies or combining cash and stock totals.

**Tech Stack:** Flutter, Dart, Drift, sqlite3 migration tests, existing domain/repository/application/presentation layering.

## Global Constraints

- Bottom navigation order is exactly `總覽`, `資產`, `紀錄`, `設定`.
- Supported stock account modes are exactly `taiwanStock`, `taiwanEtf`, and `usStock`.
- `taiwanStock` currency is fixed to `TWD`.
- `taiwanEtf` currency is fixed to `TWD`.
- `usStock` currency is fixed to `USD`.
- Stock account mode determines behavior. A single stock account cannot mix modes.
- Stock accounts can be archived but not deleted.
- Stock holdings can be archived but not deleted.
- Archived accounts and holdings are hidden from active lists but remain stored.
- Taiwan individual stock holdings store quantity, average cost, and current price.
- Taiwan ETF and US stock holdings store principal only.
- Quantity uses fixed-point integer storage with 6 decimal places.
- Prices use fixed-point integer storage with 2 decimal places.
- Principal uses minor currency units.
- Overview displays stock assets separately from cash totals.
- No exchange-rate conversion is performed.
- v0.4.0 does not include buy/sell transactions, cash-account integration, automatic quotes, realized gain/loss, taxes, fees, dividends, or splits.
- Keep `ios/Runner.xcodeproj/project.pbxproj` unstaged unless the user explicitly asks to commit signing changes.
- After each task passes verification, run `git add`, `git commit`, and `git push`.

---

## File Structure

New domain files:

- `lib/domain/model/stock_account.dart`: stock account mode, fixed currency mapping, account validation.
- `lib/domain/model/stock_holding.dart`: valuation/principal holding models, fixed-point validation, calculated values.
- `lib/domain/repository/stock_account_repository.dart`: stock account repository contract and create request.
- `lib/domain/repository/stock_holding_repository.dart`: stock holding repository contract and save requests.
- `lib/domain/summary/stock_asset_summary.dart`: grouped stock asset summary for overview.

New data files:

- `lib/data/repository/drift_stock_account_repository.dart`
- `lib/data/repository/drift_stock_holding_repository.dart`

Modified data files:

- `lib/data/database/networthy_database.dart`
- `lib/data/database/networthy_database.g.dart`
- `test/data/database/networthy_database_migration_test.dart`

New application files:

- `lib/application/stock/stock_account_command.dart`
- `lib/application/stock/stock_account_use_cases.dart`
- `lib/application/stock/stock_holding_command.dart`
- `lib/application/stock/stock_holding_use_cases.dart`
- `lib/application/stock/stock_summary_use_case.dart`

Presentation additions:

- `lib/presentation/assets/assets_page.dart`

Presentation modifications:

- `lib/main.dart`
- `lib/presentation/app/networthy_app.dart`
- `lib/presentation/home/home_shell.dart`
- `lib/presentation/overview/overview_page.dart`
- `test/presentation/test_app_harness.dart`

---

## Task 1: Stock domain model

**Files:**

- Create: `lib/domain/model/stock_account.dart`
- Create: `lib/domain/model/stock_holding.dart`
- Create: `lib/domain/summary/stock_asset_summary.dart`
- Create: `test/domain/model/stock_account_test.dart`
- Create: `test/domain/model/stock_holding_test.dart`
- Create: `test/domain/summary/stock_asset_summary_test.dart`

**Interfaces:**

- Produces `StockAccountMode.taiwanStock`, `.taiwanEtf`, `.usStock`.
- Produces `StockAccountMode.currencyCode`.
- Produces `StockAccount.create(...)`.
- Produces `StockHolding.valuation(...)`.
- Produces `StockHolding.principal(...)`.
- Produces `StockAssetSummary.calculate(...)`.

- [ ] **Step 1: Write failing stock account tests**

Add `test/domain/model/stock_account_test.dart`:

```dart
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
```

- [ ] **Step 2: Write failing stock holding tests**

Add `test/domain/model/stock_holding_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/domain/model/domain_validation.dart';
import 'package:networthy/domain/model/stock_account.dart';
import 'package:networthy/domain/model/stock_holding.dart';

void main() {
  test('valuation holding calculates cost market value and unrealized gain', () {
    final holding = StockHolding.valuation(
      id: '00000000-0000-4000-8000-000000040101',
      accountId: '00000000-0000-4000-8000-000000040102',
      symbol: '2330',
      name: '台積電',
      accountMode: StockAccountMode.taiwanStock,
      quantityMicro: 1500000,
      averageCostMinor: 60000,
      currentPriceMinor: 65000,
      isArchived: false,
      createdAtUtc: DateTime.utc(2026, 8, 17, 1),
      updatedAtUtc: DateTime.utc(2026, 8, 17, 1),
    );

    expect(holding.quantityDisplay, '1.5');
    expect(holding.costMinor, 90000);
    expect(holding.marketValueMinor, 97500);
    expect(holding.unrealizedGainLossMinor, 7500);
  });

  test('principal holding stores principal without valuation fields', () {
    final holding = StockHolding.principal(
      id: '00000000-0000-4000-8000-000000040103',
      accountId: '00000000-0000-4000-8000-000000040104',
      symbol: 'VOO',
      name: 'Vanguard S&P 500 ETF',
      accountMode: StockAccountMode.usStock,
      principalMinor: 500000,
      isArchived: false,
      createdAtUtc: DateTime.utc(2026, 8, 17, 1),
      updatedAtUtc: DateTime.utc(2026, 8, 17, 1),
    );

    expect(holding.principalMinor, 500000);
    expect(holding.marketValueMinor, isNull);
    expect(holding.unrealizedGainLossMinor, isNull);
  });

  test('rejects invalid mode-specific values', () {
    expect(
      () => StockHolding.valuation(
        id: '00000000-0000-4000-8000-000000040105',
        accountId: '00000000-0000-4000-8000-000000040106',
        symbol: '0050',
        name: '元大台灣50',
        accountMode: StockAccountMode.taiwanEtf,
        quantityMicro: 1000000,
        averageCostMinor: 10000,
        currentPriceMinor: 12000,
        isArchived: false,
        createdAtUtc: DateTime.utc(2026, 8, 17, 1),
        updatedAtUtc: DateTime.utc(2026, 8, 17, 1),
      ),
      throwsA(isA<DomainValidationException>()),
    );

    expect(
      () => StockHolding.principal(
        id: '00000000-0000-4000-8000-000000040107',
        accountId: '00000000-0000-4000-8000-000000040108',
        symbol: '2330',
        name: '台積電',
        accountMode: StockAccountMode.taiwanStock,
        principalMinor: 100000,
        isArchived: false,
        createdAtUtc: DateTime.utc(2026, 8, 17, 1),
        updatedAtUtc: DateTime.utc(2026, 8, 17, 1),
      ),
      throwsA(isA<DomainValidationException>()),
    );
  });
}
```

- [ ] **Step 3: Write failing stock summary tests**

Add `test/domain/summary/stock_asset_summary_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/domain/model/currency_code.dart';
import 'package:networthy/domain/model/stock_account.dart';
import 'package:networthy/domain/model/stock_holding.dart';
import 'package:networthy/domain/summary/stock_asset_summary.dart';

void main() {
  test('groups valuation market value and principal by account mode', () {
    final summary = StockAssetSummary.calculate([
      StockHolding.valuation(
        id: '00000000-0000-4000-8000-000000040201',
        accountId: '00000000-0000-4000-8000-000000040202',
        symbol: '2330',
        name: '台積電',
        accountMode: StockAccountMode.taiwanStock,
        quantityMicro: 2000000,
        averageCostMinor: 60000,
        currentPriceMinor: 65000,
        isArchived: false,
        createdAtUtc: DateTime.utc(2026, 8, 17, 1),
        updatedAtUtc: DateTime.utc(2026, 8, 17, 1),
      ),
      StockHolding.principal(
        id: '00000000-0000-4000-8000-000000040203',
        accountId: '00000000-0000-4000-8000-000000040204',
        symbol: 'VOO',
        name: 'Vanguard S&P 500 ETF',
        accountMode: StockAccountMode.usStock,
        principalMinor: 500000,
        isArchived: false,
        createdAtUtc: DateTime.utc(2026, 8, 17, 1),
        updatedAtUtc: DateTime.utc(2026, 8, 17, 1),
      ),
    ]);

    expect(summary.taiwanStockMarketValueMinor, 130000);
    expect(summary.taiwanStockUnrealizedGainLossMinor, 10000);
    expect(summary.principalByCurrency[CurrencyCode.usd], 500000);
  });
}
```

- [ ] **Step 4: Run red tests**

Run:

```sh
flutter test test/domain/model/stock_account_test.dart test/domain/model/stock_holding_test.dart test/domain/summary/stock_asset_summary_test.dart
```

Expected: compilation fails because stock domain files do not exist.

- [ ] **Step 5: Implement stock domain models**

Create:

- `StockAccountMode` enum with `wireValue`, `displayName`, `currencyCode`, and `fromWireValue`.
- `StockAccount.create(...)`.
- `StockHolding.valuation(...)`.
- `StockHolding.principal(...)`.
- `StockAssetSummary.calculate(...)`.

Implementation rules:

- use the same UUID and UTC validation style as `CashAccount`;
- use `DomainValidationException` for invalid values;
- trim account, symbol, and holding names;
- quantity display removes trailing zeroes after the decimal point;
- cost and market value use integer arithmetic:
  - `costMinor = (quantityMicro * averageCostMinor / 1000000).round()`;
  - `marketValueMinor = (quantityMicro * currentPriceMinor / 1000000).round()`.

- [ ] **Step 6: Verify**

Run:

```sh
dart format lib/domain/model/stock_account.dart lib/domain/model/stock_holding.dart lib/domain/summary/stock_asset_summary.dart test/domain/model/stock_account_test.dart test/domain/model/stock_holding_test.dart test/domain/summary/stock_asset_summary_test.dart
flutter test test/domain/model/stock_account_test.dart test/domain/model/stock_holding_test.dart test/domain/summary/stock_asset_summary_test.dart
flutter analyze
git diff --check
```

- [ ] **Step 7: Commit**

Run:

```sh
git add lib/domain/model/stock_account.dart lib/domain/model/stock_holding.dart lib/domain/summary/stock_asset_summary.dart test/domain/model/stock_account_test.dart test/domain/model/stock_holding_test.dart test/domain/summary/stock_asset_summary_test.dart
git commit -m "feat: add stock asset domain model"
git push
```

---

## Task 2: Stock repository contracts

**Files:**

- Create: `lib/domain/repository/stock_account_repository.dart`
- Create: `lib/domain/repository/stock_holding_repository.dart`
- Create: `test/domain/repository/stock_account_repository_contract_test.dart`
- Create: `test/domain/repository/in_memory_stock_account_repository_test.dart`
- Create: `test/domain/repository/stock_holding_repository_contract_test.dart`
- Create: `test/domain/repository/in_memory_stock_holding_repository_test.dart`
- Modify: `test/presentation/test_app_harness.dart`

**Interfaces:**

- Consumes `StockAccount`, `StockAccountMode`, `StockHolding`.
- Produces `StockAccountRepository`, `CreateStockAccountRequest`, `StockAccountRepositoryException`.
- Produces `StockHoldingRepository`, `SaveValuationHoldingRequest`, `SavePrincipalHoldingRequest`, `StockHoldingRepositoryException`.
- Produces test doubles `TestStockAccountRepository` and `TestStockHoldingRepository`.

- [ ] **Step 1: Write failing repository contract tests**

Add account contract tests that verify:

- create, rename, archive;
- active list hides archived accounts;
- all list preserves archived accounts;
- duplicate active account names are rejected within the same mode.

Add holding contract tests that verify:

- save and edit valuation holding;
- save and edit principal holding;
- archive hides from active list;
- all list preserves archived holdings;
- holdings are filtered by account id.

- [ ] **Step 2: Run red tests**

Run:

```sh
flutter test test/domain/repository/stock_account_repository_contract_test.dart test/domain/repository/stock_holding_repository_contract_test.dart
```

Expected: compilation fails because repository contracts do not exist.

- [ ] **Step 3: Implement repository contracts and in-memory test doubles**

Create account repository interface:

```dart
abstract interface class StockAccountRepository {
  Future<List<StockAccount>> listActive();
  Future<List<StockAccount>> listAll();
  Future<StockAccount?> findById(String id);
  Future<StockAccount> create(CreateStockAccountRequest request);
  Future<StockAccount> rename({required String id, required String name});
  Future<void> archive(String id);
}
```

Create holding repository interface:

```dart
abstract interface class StockHoldingRepository {
  Future<List<StockHolding>> listActiveByAccount(String accountId);
  Future<List<StockHolding>> listAllByAccount(String accountId);
  Future<List<StockHolding>> listAllActive();
  Future<StockHolding?> findById(String id);
  Future<StockHolding> saveValuation(SaveValuationHoldingRequest request);
  Future<StockHolding> savePrincipal(SavePrincipalHoldingRequest request);
  Future<void> archive(String id);
}
```

Add test doubles to `test/presentation/test_app_harness.dart`:

- `TestStockAccountRepository`
- `TestStockHoldingRepository`

- [ ] **Step 4: Verify**

Run:

```sh
dart format lib/domain/repository/stock_account_repository.dart lib/domain/repository/stock_holding_repository.dart test/domain/repository/stock_account_repository_contract_test.dart test/domain/repository/in_memory_stock_account_repository_test.dart test/domain/repository/stock_holding_repository_contract_test.dart test/domain/repository/in_memory_stock_holding_repository_test.dart test/presentation/test_app_harness.dart
flutter test test/domain/repository
flutter analyze
git diff --check
```

- [ ] **Step 5: Commit**

Run:

```sh
git add lib/domain/repository/stock_account_repository.dart lib/domain/repository/stock_holding_repository.dart test/domain/repository/stock_account_repository_contract_test.dart test/domain/repository/in_memory_stock_account_repository_test.dart test/domain/repository/stock_holding_repository_contract_test.dart test/domain/repository/in_memory_stock_holding_repository_test.dart test/presentation/test_app_harness.dart
git commit -m "feat: add stock repository contracts"
git push
```

---

## Task 3: Drift persistence and schema v4

**Files:**

- Modify: `lib/data/database/networthy_database.dart`
- Modify: `lib/data/database/networthy_database.g.dart`
- Modify: `test/data/database/networthy_database_migration_test.dart`
- Create: `lib/data/repository/drift_stock_account_repository.dart`
- Create: `lib/data/repository/drift_stock_holding_repository.dart`
- Create: `test/data/repository/drift_stock_account_repository_test.dart`
- Create: `test/data/repository/drift_stock_holding_repository_test.dart`

**Interfaces:**

- Consumes stock repository contracts.
- Produces Drift tables `stock_accounts` and `stock_holdings`.
- Produces `DriftStockAccountRepository`.
- Produces `DriftStockHoldingRepository`.

- [ ] **Step 1: Write failing migration and repository tests**

Add migration test:

- open a schema v3 database fixture;
- migrate to latest;
- assert `stock_accounts` and `stock_holdings` exist;
- assert existing cash ledger data remains readable.

Add repository tests:

- persisted stock accounts survive reload;
- persisted valuation holdings survive reload and calculate values;
- persisted principal holdings survive reload;
- archive hides rows from active lists.

- [ ] **Step 2: Run red tests**

Run:

```sh
flutter test test/data/database/networthy_database_migration_test.dart test/data/repository/drift_stock_account_repository_test.dart test/data/repository/drift_stock_holding_repository_test.dart
```

Expected: failures because schema v4 and Drift repositories do not exist.

- [ ] **Step 3: Implement Drift schema v4**

Modify `NetworthyDatabase`:

- bump `schemaVersion` from `3` to `4`;
- add `StockAccounts` table;
- add `StockHoldings` table;
- migration step from v3 to v4 creates both tables;
- do not seed stock accounts.

Required columns:

`stock_accounts`:

- `id`
- `name`
- `mode`
- `currency_code`
- `is_archived`
- `created_at_utc`
- `updated_at_utc`

`stock_holdings`:

- `id`
- `account_id`
- `symbol`
- `name`
- `mode`
- `currency_code`
- `quantity_micro`
- `average_cost_minor`
- `current_price_minor`
- `principal_minor`
- `is_archived`
- `created_at_utc`
- `updated_at_utc`

- [ ] **Step 4: Run code generation**

Run:

```sh
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 5: Implement Drift repositories**

Implement:

- row-to-domain mapping;
- create/save/rename/archive;
- duplicate active account name validation within same mode;
- active/all filtering;
- holding filtering by account id.

- [ ] **Step 6: Verify**

Run:

```sh
dart format lib/data/database/networthy_database.dart lib/data/database/networthy_database.g.dart lib/data/repository/drift_stock_account_repository.dart lib/data/repository/drift_stock_holding_repository.dart test/data/database/networthy_database_migration_test.dart test/data/repository/drift_stock_account_repository_test.dart test/data/repository/drift_stock_holding_repository_test.dart
flutter test test/data
flutter analyze
git diff --check
```

- [ ] **Step 7: Commit**

Run:

```sh
git add lib/data/database/networthy_database.dart lib/data/database/networthy_database.g.dart lib/data/repository/drift_stock_account_repository.dart lib/data/repository/drift_stock_holding_repository.dart test/data/database/networthy_database_migration_test.dart test/data/repository/drift_stock_account_repository_test.dart test/data/repository/drift_stock_holding_repository_test.dart
git commit -m "feat: persist stock assets"
git push
```

---

## Task 4: Stock application use cases

**Files:**

- Create: `lib/application/stock/stock_account_command.dart`
- Create: `lib/application/stock/stock_account_use_cases.dart`
- Create: `lib/application/stock/stock_holding_command.dart`
- Create: `lib/application/stock/stock_holding_use_cases.dart`
- Create: `lib/application/stock/stock_summary_use_case.dart`
- Create: `test/application/stock/stock_account_use_cases_test.dart`
- Create: `test/application/stock/stock_holding_use_cases_test.dart`
- Create: `test/application/stock/stock_summary_use_case_test.dart`

**Interfaces:**

- Consumes stock repositories and `ApplicationClock`, `TransactionIdGenerator`.
- Produces account use cases: `CreateStockAccountUseCase`, `RenameStockAccountUseCase`, `ArchiveStockAccountUseCase`.
- Produces holding use cases: `SaveValuationStockHoldingUseCase`, `SavePrincipalStockHoldingUseCase`, `ArchiveStockHoldingUseCase`.
- Produces `LoadStockAssetSummaryUseCase`.

- [ ] **Step 1: Write failing account use-case tests**

Test:

- create account generates id and stores mode-fixed currency;
- rename rejects missing or archived account;
- archive rejects missing account and hides active account.

- [ ] **Step 2: Write failing holding use-case tests**

Test:

- valuation holding can be saved only under a Taiwan stock account;
- principal holding can be saved only under Taiwan ETF or US stock accounts;
- archived accounts reject new holdings;
- archive holding hides active holding.

- [ ] **Step 3: Write failing summary use-case tests**

Test:

- summary includes Taiwan stock market value and unrealized gain/loss;
- summary includes Taiwan ETF principal;
- summary includes US stock principal;
- archived holdings are excluded.

- [ ] **Step 4: Run red tests**

Run:

```sh
flutter test test/application/stock
```

Expected: compilation fails because stock use cases do not exist.

- [ ] **Step 5: Implement use cases**

Use command/result pattern matching existing application code:

```dart
class CreateStockAccountCommand {
  const CreateStockAccountCommand({required this.name, required this.mode});
}
```

```dart
class SaveValuationStockHoldingCommand {
  const SaveValuationStockHoldingCommand({
    required this.accountId,
    required this.symbol,
    required this.name,
    required this.quantityMicro,
    required this.averageCostMinor,
    required this.currentPriceMinor,
  });
}
```

```dart
class SavePrincipalStockHoldingCommand {
  const SavePrincipalStockHoldingCommand({
    required this.accountId,
    required this.symbol,
    required this.name,
    required this.principalMinor,
  });
}
```

Validation failures use `ApplicationFailure.validation(...)`.

- [ ] **Step 6: Verify**

Run:

```sh
dart format lib/application/stock test/application/stock
flutter test test/application
flutter analyze
git diff --check
```

- [ ] **Step 7: Commit**

Run:

```sh
git add lib/application/stock test/application/stock
git commit -m "feat: add stock asset use cases"
git push
```

---

## Task 5: Assets page and navigation

**Files:**

- Create: `lib/presentation/assets/assets_page.dart`
- Modify: `lib/main.dart`
- Modify: `lib/presentation/app/networthy_app.dart`
- Modify: `lib/presentation/home/home_shell.dart`
- Modify: `test/presentation/test_app_harness.dart`
- Create: `test/presentation/assets/assets_page_widget_test.dart`
- Modify: `test/presentation/accessibility/primary_controls_accessibility_test.dart`
- Modify: `test/presentation/accessibility/text_scaling_widget_test.dart`

**Interfaces:**

- Consumes stock repositories and stock use cases.
- Produces `AssetsPage`.
- Adds bottom navigation destination `資產` between `總覽` and `紀錄`.

- [ ] **Step 1: Write failing widget tests**

Test:

- bottom navigation order is `總覽`, `資產`, `紀錄`, `設定`;
- assets page creates a Taiwan stock account;
- assets page renames and archives a stock account;
- assets page creates a valuation holding under Taiwan stock account;
- assets page creates a principal holding under Taiwan ETF account;
- archived holdings disappear from active holding list.

- [ ] **Step 2: Run red tests**

Run:

```sh
flutter test test/presentation/assets/assets_page_widget_test.dart test/presentation/accessibility/primary_controls_accessibility_test.dart test/presentation/accessibility/text_scaling_widget_test.dart
```

Expected: failures because `AssetsPage` and navigation entry do not exist.

- [ ] **Step 3: Inject stock repositories**

Modify:

- `main.dart`: create `DriftStockAccountRepository` and `DriftStockHoldingRepository`;
- `NetworthyApp`: accept stock repositories;
- `_AppGate`: pass stock repositories;
- `HomeShell`: pass stock repositories to `AssetsPage`;
- test harness app calls: pass `TestStockAccountRepository` and `TestStockHoldingRepository`.

- [ ] **Step 4: Implement assets page**

Page behavior:

- AppBar title `資產`;
- account creation dialog:
  - `Key('stock-account-name-field')`;
  - mode choices `台股個股`, `台股 ETF`, `美股`;
- holding creation dialog for Taiwan stock account:
  - `Key('stock-symbol-field')`;
  - `Key('stock-name-field')`;
  - `Key('stock-quantity-field')`;
  - `Key('stock-average-cost-field')`;
  - `Key('stock-current-price-field')`;
- holding creation dialog for principal accounts:
  - `Key('stock-symbol-field')`;
  - `Key('stock-name-field')`;
  - `Key('stock-principal-field')`;
- row tooltips:
  - `重新命名 <account name>`;
  - `封存 <account name>`;
  - `修改 <symbol>`;
  - `封存 <symbol>`.

- [ ] **Step 5: Verify**

Run:

```sh
dart format lib/main.dart lib/presentation/app/networthy_app.dart lib/presentation/home/home_shell.dart lib/presentation/assets/assets_page.dart test/presentation/test_app_harness.dart test/presentation/assets/assets_page_widget_test.dart test/presentation/accessibility/primary_controls_accessibility_test.dart test/presentation/accessibility/text_scaling_widget_test.dart
flutter test test/presentation
flutter analyze
git diff --check
```

- [ ] **Step 6: Commit**

Run:

```sh
git add lib/main.dart lib/presentation/app/networthy_app.dart lib/presentation/home/home_shell.dart lib/presentation/assets/assets_page.dart test/presentation/test_app_harness.dart test/presentation/assets/assets_page_widget_test.dart test/presentation/accessibility/primary_controls_accessibility_test.dart test/presentation/accessibility/text_scaling_widget_test.dart
git commit -m "feat: add stock assets page"
git push
```

---

## Task 6: Overview stock asset summary

**Files:**

- Modify: `lib/presentation/overview/overview_page.dart`
- Modify: `lib/presentation/home/home_shell.dart`
- Create: `test/presentation/overview/stock_asset_summary_widget_test.dart`

**Interfaces:**

- Consumes `LoadStockAssetSummaryUseCase`.
- Produces overview summary rows for Taiwan stock market value, Taiwan ETF principal, and US stock principal.

- [ ] **Step 1: Write failing overview tests**

Test:

- overview displays `台股個股市值 NT$...`;
- overview displays `台股 ETF 本金 NT$...`;
- overview displays `美股本金 US$...`;
- overview does not merge stock and cash totals;
- archived holdings are excluded.

- [ ] **Step 2: Run red tests**

Run:

```sh
flutter test test/presentation/overview/stock_asset_summary_widget_test.dart
```

Expected: failures because overview does not render stock asset summaries.

- [ ] **Step 3: Implement overview stock summary loading**

Modify `OverviewPage`:

- accept stock repositories or `LoadStockAssetSummaryUseCase` dependencies through `HomeShell`;
- load stock summary alongside existing cash ledger summary;
- render stock summary section after cash metrics;
- use `formatCurrency(...)`;
- show no stock section when all stock summary values are zero.

- [ ] **Step 4: Verify**

Run:

```sh
dart format lib/presentation/overview/overview_page.dart lib/presentation/home/home_shell.dart test/presentation/overview/stock_asset_summary_widget_test.dart
flutter test test/presentation/overview
flutter analyze
git diff --check
```

- [ ] **Step 5: Commit**

Run:

```sh
git add lib/presentation/overview/overview_page.dart lib/presentation/home/home_shell.dart test/presentation/overview/stock_asset_summary_widget_test.dart
git commit -m "feat: show stock assets on overview"
git push
```

---

## Task 7: v0.4.0 release verification

**Files:**

- Modify: `docs/problems/v0.1.0.md`
- Create: `docs/verification/v0.4.0-stock-assets-tracking.md`

**Interfaces:**

- Produces final v0.4.0 verification record.

- [ ] **Step 1: Write verification doc**

Create `docs/verification/v0.4.0-stock-assets-tracking.md`:

````markdown
# v0.4.0 Verification: Stock Assets Tracking

## Automated commands

```sh
flutter test
flutter analyze
flutter build apk --release
flutter build ios --simulator
git diff --check
```

## Manual script

1. Open the `資產` tab.
2. Create a `台股個股` account named `富邦證券`.
3. Add holding `2330` / `台積電`, quantity `1.5`, average cost `600`, current price `650`.
4. Confirm the holding displays cost, market value, and unrealized gain/loss.
5. Create a `台股 ETF` account named `ETF 本金`.
6. Add holding `0050` / `元大台灣50`, principal `100000`.
7. Confirm the holding displays principal only.
8. Create a `美股` account named `美股本金`.
9. Add holding `VOO`, principal `5000`.
10. Confirm the holding displays principal only with USD formatting.
11. Open `總覽`.
12. Confirm cash, Taiwan stock market value, Taiwan ETF principal, and US stock principal are displayed separately.
13. Archive one holding.
14. Confirm the archived holding disappears from active assets and overview.
```
````

- [ ] **Step 2: Update problem status**

Update `docs/problems/v0.1.0.md` problem 2 status:

- v0.4.0 implements stock asset snapshot tracking;
- Taiwan individual stocks support quantity/cost/current-price valuation;
- Taiwan ETF and US stock accounts track principal only;
- buy/sell transactions and cash-account integration remain outside v0.4.0.

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

Append observed command results and artifact paths to `docs/verification/v0.4.0-stock-assets-tracking.md`.

- [ ] **Step 5: Commit**

Run:

```sh
git add docs/problems/v0.1.0.md docs/verification/v0.4.0-stock-assets-tracking.md
git commit -m "docs: verify stock assets tracking"
git push
```
