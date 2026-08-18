# Stock Trading and Cash Integration Implementation Plan

> For agentic workers: REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** Build v0.5 manual stock buy/sell workflows that atomically update stock trade history, stock holding snapshots, and same-currency cash ledger entries.

**Architecture:** Keep stock accounts and cash accounts as separate domain concepts. Add a validated StockTrade domain model and a Drift-backed trade table, then expose one application operation whose persistence adapter performs the trade, holding, and ledger writes inside one Drift transaction. Extend the existing assets page with buy/sell forms and a read-only trade history while preserving v0.4 manual holding management.

**Tech Stack:** Flutter, Dart, Drift, encrypted SQLite, existing repository/use-case/application-failure patterns, Flutter widget tests.

**Spec:** docs/superpowers/specs/2026-08-18-stock-trading-cash-integration-design.md

## Global Constraints

- Same-currency trades only: Taiwan stock and Taiwan ETF use TWD; US stock uses USD.
- Buy decreases the selected cash account balance and sell increases it.
- Taiwan individual stocks track quantity and weighted average cost; Taiwan ETF and US stock accounts track principal only.
- v0.5 excludes fees, taxes, dividends, splits, FX conversion, automatic quotes, trade edits, and trade deletion.
- A failed operation must leave the trade table, holding snapshot, and cash ledger unchanged.
- Existing v0.4 cash, stock accounts, and stock holdings must survive schema migration without backfill.
- Keep ios/Runner.xcodeproj/project.pbxproj out of commits because it contains local iOS signing state.
- Every task ends with focused tests, git diff --check, and its own git commit/push.

---

### Task 1: Add validated trade domain model and application commands

**Files:**

- Create: lib/domain/model/stock_trade.dart
- Create: lib/domain/repository/stock_trade_repository.dart
- Create: lib/application/stock/stock_trade_command.dart
- Test: test/domain/model/stock_trade_test.dart
- Test: test/domain/repository/stock_trade_repository_contract_test.dart

**Interfaces:**

- Consumes: StockAccountMode, CurrencyCode, LocalDate, DomainValidationException, and existing repository contract style.
- Produces: StockTradeSide with buy/sell; immutable StockTrade; SaveStockTradeRequest; StockTradeRepository.save, findById, listByStockAccount, and listLatest; and ExecuteStockTradeCommand with all user-entered fields.

- [ ] Step 1: Write failing domain tests.

  Add tests for:

      final trade = StockTrade.valuation(
        id: validId,
        stockAccountId: stockAccountId,
        cashAccountId: cashAccountId,
        side: StockTradeSide.buy,
        symbol: '2330',
        name: '台積電',
        quantityMicro: 1 * StockHolding.quantityScale,
        priceMinor: 90000,
        tradeDate: LocalDate(2026, 8, 18),
        note: '定期買入',
        createdAtUtc: createdAt,
        updatedAtUtc: updatedAt,
      );
      expect(trade.cashAmountMinor, 90000);

  Also assert valuation trades reject non-positive quantity/price, principal trades reject non-positive principal, mode-specific fields cannot be mixed, IDs must be UUIDs, text is trimmed and bounded, and timestamps are UTC.

- [ ] Step 2: Run the focused test and verify it fails.

  Run: flutter test test/domain/model/stock_trade_test.dart
  Expected: FAIL because the new trade model and command types do not exist.

- [ ] Step 3: Implement the domain model.

  Define StockTrade.valuation and StockTrade.principal factories. Store quantity in quantityMicro, price/principal in minor units, and expose cashAmountMinor. Compute valuation cash amount as (quantityMicro * priceMinor / StockHolding.quantityScale).round(); principal cash amount is principalMinor. Require positive values for every new trade and persist the selected stock account mode and its fixed currency.

- [ ] Step 4: Add repository contract and command DTOs.

  Match existing repository exception and request patterns. The repository contract must expose:

      abstract interface class StockTradeRepository {
        Future<void> save(StockTrade trade);
        Future<StockTrade?> findById(String id);
        Future<List<StockTrade>> listByStockAccount(String stockAccountId);
        Future<List<StockTrade>> listLatest({required int limit});
      }

  The application command must carry stock account ID, cash account ID, side, symbol, name, either valuation fields or principal, local trade date, and optional note.

- [ ] Step 5: Run domain and contract tests.

  Run: flutter test test/domain/model/stock_trade_test.dart test/domain/repository/stock_trade_repository_contract_test.dart
  Expected: PASS.

- [ ] Step 6: Commit and push.

      git add lib/domain/model/stock_trade.dart lib/domain/repository/stock_trade_repository.dart lib/application/stock/stock_trade_command.dart test/domain/model/stock_trade_test.dart test/domain/repository/stock_trade_repository_contract_test.dart
      git commit -m "feat: add stock trade domain contract"
      git push

### Task 2: Add schema v5, Drift trade persistence, and migration coverage

**Files:**

- Modify: lib/data/database/networthy_database.dart
- Modify: lib/data/database/networthy_database.g.dart (generated by build_runner)
- Create: lib/data/repository/drift_stock_trade_repository.dart
- Test: test/data/repository/drift_stock_trade_repository_test.dart
- Modify: test/data/database/networthy_database_migration_test.dart

**Interfaces:**

- Consumes: StockTrade, StockTradeRepository, and Drift table conventions used by DriftStockHoldingRepository.
- Produces: StockTrades table, NetworthyDatabase.schemaVersion == 5, v4-to-v5 migration that creates only the new table, and DriftStockTradeRepository.

- [ ] Step 1: Write failing persistence and migration tests.

  Test that a valuation trade and a principal trade round-trip through an in-memory database, latest/list ordering is deterministic by trade date and creation time, and a v4 database opens at schema v5 with all existing rows plus an empty stock_trades table.

- [ ] Step 2: Run focused tests and verify failure.

  Run: flutter test test/data/repository/drift_stock_trade_repository_test.dart test/data/database/networthy_database_migration_test.dart
  Expected: FAIL because the table, repository, and v5 migration do not exist.

- [ ] Step 3: Add the Drift table and migration.

  Add columns for UUID, stock/cash account IDs, side, symbol/name, mode, currency, nullable quantity/price/principal, local date parts, note, and UTC timestamps. Add if (from < 5) await migrator.createTable(stockTrades); after the v4 stock tables. Do not rewrite existing ledger or stock snapshot rows.

- [ ] Step 4: Generate Drift code and implement the repository.

  Run: dart run build_runner build --delete-conflicting-outputs

  Map rows through the domain factories. Reject impossible rows through the existing repository exception pattern. Store and query dates using year/month/day columns, and order latest trades by trade date descending then creation timestamp descending.

- [ ] Step 5: Run persistence and migration tests.

  Run: flutter test test/data/repository/drift_stock_trade_repository_test.dart test/data/database/networthy_database_migration_test.dart
  Expected: PASS.

- [ ] Step 6: Commit and push.

      git add lib/data/database/networthy_database.dart lib/data/database/networthy_database.g.dart lib/data/repository/drift_stock_trade_repository.dart test/data/repository/drift_stock_trade_repository_test.dart test/data/database/networthy_database_migration_test.dart
      git commit -m "feat: persist stock trades"
      git push

### Task 3: Implement the atomic stock trade application operation

**Files:**

- Create: lib/application/stock/execute_stock_trade_use_case.dart
- Create: lib/data/repository/drift_stock_trade_executor.dart
- Modify: lib/domain/repository/stock_trade_repository.dart
- Modify: lib/data/repository/drift_stock_account_repository.dart
- Modify: lib/data/repository/drift_stock_holding_repository.dart
- Modify: lib/data/repository/drift_ledger_repository.dart
- Modify: lib/domain/model/category.dart
- Test: test/application/stock/execute_stock_trade_use_case_test.dart
- Test: test/data/repository/drift_stock_trade_executor_test.dart

**Interfaces:**

- Consumes: account/holding/ledger repositories, LedgerTransactionBuilder.income/expense, ApplicationClock, TransactionIdGenerator, and the Task 1 command/model.
- Produces: ExecuteStockTradeUseCase.execute(ExecuteStockTradeCommand); an atomic persistence port implemented by Drift; stable investment category IDs expense.investment and income.investment; and deterministic validation failures.

- [ ] Step 1: Write failing use-case tests.

  Cover successful Taiwan stock buy weighted-cost update, Taiwan stock sell quantity reduction/current-price update, ETF/US principal buy and sell, currency mismatch, archived accounts, missing cash account, over-sell, mode-field mismatch, and the no-holding sell case. Assert the generated ledger amount/category/type and trade data.

- [ ] Step 2: Write failing atomic rollback tests.

  Use an in-memory Drift database and force a persistence failure after one staged write. Assert that findById returns no trade, the holding remains unchanged, and the cash account balance/ledger record remains unchanged.

- [ ] Step 3: Run tests and verify failure.

  Run: flutter test test/application/stock/execute_stock_trade_use_case_test.dart test/data/repository/drift_stock_trade_executor_test.dart
  Expected: FAIL because the use case and atomic executor do not exist.

- [ ] Step 4: Implement the domain/application calculation.

  Load the active stock and cash accounts, compare currencies, select the active holding by account and symbol, validate the command mode, and calculate the next snapshot. For Taiwan stocks use:

      final newQuantity = oldQuantity + deltaQuantity;
      final weightedCost =
          oldQuantity * oldAverageCost + buyQuantity * buyPrice;
      final newAverageCost = (weightedCost / newQuantity).round();

  For sells preserve average cost. When quantity/principal becomes zero, write an archived zero snapshot; a later buy creates a new active snapshot. Reject selling without an active holding.

- [ ] Step 5: Implement one Drift transaction boundary.

  Add an executor that receives the validated trade, updated holding, and ledger aggregate, then runs the trade insert, holding upsert/archive, and ledger transaction/entries insert inside one _database.transaction. Reuse existing ledger row mapping helpers or extract them without changing externally visible behavior. Do not call three independent repository transactions from the use case.

- [ ] Step 6: Wire stable investment categories and failures.

  Add expense.investment to CategoryCatalog.expenseCategories and keep income.investment for sells. Map validation exceptions to ApplicationFailure.validation and storage exceptions to the existing safe persistence failure.

- [ ] Step 7: Run focused application/data tests.

  Run: flutter test test/application/stock/execute_stock_trade_use_case_test.dart test/data/repository/drift_stock_trade_executor_test.dart test/application/common/application_failure_test.dart
  Expected: PASS.

- [ ] Step 8: Commit and push.

      git add lib/application/stock/execute_stock_trade_use_case.dart lib/data/repository/drift_stock_trade_executor.dart lib/domain/repository/stock_trade_repository.dart lib/data/repository/drift_stock_account_repository.dart lib/data/repository/drift_stock_holding_repository.dart lib/data/repository/drift_ledger_repository.dart lib/domain/model/category.dart test/application/stock/execute_stock_trade_use_case_test.dart test/data/repository/drift_stock_trade_executor_test.dart
      git commit -m "feat: atomically execute stock trades"
      git push

### Task 4: Wire production dependencies and expose trade history data

**Files:**

- Modify: lib/main.dart
- Modify: lib/presentation/app/networthy_app.dart
- Modify: lib/presentation/home/home_shell.dart
- Create: lib/application/stock/stock_trade_history_use_case.dart
- Test: test/application/stock/stock_trade_history_use_case_test.dart
- Modify: test/presentation/test_app_harness.dart

**Interfaces:**

- Consumes: DriftStockTradeRepository, atomic executor/use case, existing app dependency injection, and stock summary models.
- Produces: production wiring for trade execution and a read-only StockTradeHistoryUseCase returning latest trades without changing old optional-constructor test compatibility.

- [ ] Step 1: Write failing history and dependency tests.

  Assert latest trades are returned in newest-first order and the test harness can construct the app with an in-memory trade repository/executor.

- [ ] Step 2: Implement the history use case and dependency injection.

  Add repository/use-case fields as optional only where existing widget tests need backward-compatible constructors; production main.dart must always inject real Drift implementations. Keep v0.4 assets and overview behavior unchanged when no trade service is supplied.

- [ ] Step 3: Run focused tests.

  Run: flutter test test/application/stock/stock_trade_history_use_case_test.dart test/presentation/assets/assets_page_widget_test.dart test/presentation/overview/overview_widget_test.dart
  Expected: PASS.

- [ ] Step 4: Commit and push.

      git add lib/main.dart lib/presentation/app/networthy_app.dart lib/presentation/home/home_shell.dart lib/application/stock/stock_trade_history_use_case.dart test/application/stock/stock_trade_history_use_case_test.dart test/presentation/test_app_harness.dart
      git commit -m "feat: wire stock trade services"
      git push

### Task 5: Add buy/sell form and read-only trade history to the assets page

**Files:**

- Modify: lib/presentation/assets/assets_page.dart
- Create: lib/presentation/assets/stock_trade_form.dart
- Create: lib/presentation/assets/stock_trade_history.dart
- Test: test/presentation/assets/stock_trade_form_widget_test.dart
- Modify: test/presentation/assets/assets_page_widget_test.dart

**Interfaces:**

- Consumes: ExecuteStockTradeUseCase, ExecuteStockTradeCommand, active cash accounts, stock accounts/holdings, and StockTradeHistoryUseCase.
- Produces: active stock account cards with 買入 and 賣出 actions, mode-specific fields, compatible cash-account selection, success refresh, safe failure SnackBars, and read-only history rows.

- [ ] Step 1: Write failing widget tests.

  Test opening buy and sell actions, selecting a cash account, Taiwan stock quantity/price fields, ETF/US principal fields, submit success, error display, and read-only history showing side/symbol/amount/date/linked account names without edit/delete controls.

- [ ] Step 2: Run widget tests and verify failure.

  Run: flutter test test/presentation/assets/stock_trade_form_widget_test.dart test/presentation/assets/assets_page_widget_test.dart
  Expected: FAIL because the trade actions, form, and history widgets do not exist.

- [ ] Step 3: Implement the focused form widget.

  Use a GlobalKey<FormState>, a buy/sell selector, active compatible cash-account dropdown, symbol/name fields, mode-specific numeric fields, date picker, note, and a submit callback. Do not expose quantity/price for principal modes. Validate locally before invoking the use case.

- [ ] Step 4: Integrate actions and refresh behavior.

  Inject the trade use case and history use case into AssetsPage, add 買入 and 賣出 buttons to active account cards, close the dialog only after success, show safeMessage on failure, and call _reload after success.

- [ ] Step 5: Implement read-only history.

  Render newest-first rows with buy/sell labels, symbol/name, amount, date, and account names. Do not add edit or delete buttons in v0.5.

- [ ] Step 6: Run widget tests.

  Run: flutter test test/presentation/assets/stock_trade_form_widget_test.dart test/presentation/assets/assets_page_widget_test.dart test/presentation/overview/overview_widget_test.dart
  Expected: PASS.

- [ ] Step 7: Commit and push.

      git add lib/presentation/assets/assets_page.dart lib/presentation/assets/stock_trade_form.dart lib/presentation/assets/stock_trade_history.dart test/presentation/assets/stock_trade_form_widget_test.dart test/presentation/assets/assets_page_widget_test.dart
      git commit -m "feat: add stock trade assets flow"
      git push

### Task 6: Add v0.5 verification, documentation, and release checks

**Files:**

- Create: docs/verification/v0.5.0-stock-trading-cash-integration.md
- Modify: test/release/release_configuration_test.dart
- Test: test/security/sensitive_logging_audit_test.dart

**Interfaces:**

- Consumes: all v0.5 features and existing release/security test conventions.
- Produces: evidence for migration, atomicity, UI, and release readiness; no trade symbol, note, account data, or database content is written to logs.

- [ ] Step 1: Add release/security assertions.

  Assert the v0.5 schema/version configuration and scan new trade code for forbidden sensitive logging.

- [ ] Step 2: Run focused release/security tests.

  Run: flutter test test/release/release_configuration_test.dart test/security/sensitive_logging_audit_test.dart
  Expected: PASS.

- [ ] Step 3: Write verification evidence.

  Document exact commands and observed results for focused domain/data/application/widget tests, full flutter test, flutter analyze, flutter build apk --release, flutter build ios --simulator, and git diff --check. Record that existing v0.4 snapshots are preserved and v0.6 edit/delete/realized P/L remain out of scope.

- [ ] Step 4: Run complete v0.5 verification.

  Run: flutter test
  Run: flutter analyze
  Run: flutter build apk --release
  Run: flutter build ios --simulator
  Run: git diff --check
  Expected: all tests pass, analyzer reports no issues, both builds succeed, and diff check is clean.

- [ ] Step 5: Commit and push.

      git add docs/verification/v0.5.0-stock-trading-cash-integration.md test/release/release_configuration_test.dart test/security/sensitive_logging_audit_test.dart
      git commit -m "docs: verify stock trading cash integration"
      git push

## Plan self-review

- Spec coverage: Task 1 covers trade validation and command shape; Task 2 covers schema v5 table, migration, and persistence; Task 3 covers account/mode validation, weighted cost, principal tracking, cash categories, and atomic rollback; Task 4 covers production wiring and history data; Task 5 covers assets UI and read-only history; Task 6 covers release verification and sensitive logging.
- Placeholder scan: no TODO, TBD, FIXME, or unspecified handling steps are used.
- Type consistency: ExecuteStockTradeCommand, StockTrade, StockTradeRepository, ExecuteStockTradeUseCase, and StockTradeHistoryUseCase are named consistently across tasks; the atomic executor is the only component allowed to coordinate the three Drift writes.
