# Persistence Repository Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement encrypted local persistence for bookkeeping transactions and app settings behind pure Dart repository interfaces.

**Architecture:** Keep repository contracts independent from Flutter, Drift, and sqlite packages. Put encrypted database opening, Drift schema, row mapping, migration baseline, and clear-all-data behavior in the data layer.

**Tech Stack:** Flutter, Drift, sqlite3 with SQLite3MultipleCiphers, flutter_secure_storage, path/path_provider, pure Dart domain models.

## Global Constraints

- V1 platforms: iOS and Android.
- V1 currency: TWD only.
- Core functionality must work without network.
- Accounting database must be encrypted.
- Database key must be generated with cryptographically secure randomness and stored only in iOS Keychain / Android Keystore backed secure storage.
- Database key must not be stored in SharedPreferences or equivalent general key-value storage.
- Do not log SQL binding values, notes, amounts, keys, or full database paths in release builds.
- Transaction amounts use 64-bit integers, not floating point.
- Transaction dates are local calendar dates; created/updated timestamps are UTC.
- Category records must use stable IDs, not localized display names.
- Domain code must not depend on Flutter or database packages.

---

## File Structure

- Create `lib/domain/repository/transaction_repository.dart`: pure Dart transaction repository contract and query filter value object.
- Create `lib/domain/repository/settings_repository.dart`: pure Dart settings repository contract.
- Create `lib/data/database/encrypted_database_opener.dart`: opens sqlite3 database with the stored encryption key and rejects missing/wrong keys.
- Create `lib/data/database/networthy_database.dart`: Drift database, tables, schema version, migration strategy, and type converters.
- Create `lib/data/database/networthy_database.drift`: SQL schema for transactions and app settings.
- Create `lib/data/repository/drift_transaction_repository.dart`: maps between Drift rows and `BookkeepingTransaction`, implements CRUD, filtering, latest five, and monthly summary.
- Create `lib/data/repository/drift_settings_repository.dart`: persists `AppSettings`.
- Create `lib/data/repository/clear_local_data.dart`: deletes database files, secure key, and related non-sensitive preference entries.
- Create tests under `test/data/repository/` and `test/data/database/` for repository behavior, encrypted open/reopen, wrong key, migration, key-missing, summary refresh, and clear-all-data.

---

## Task 1: Repository Contracts and First CRUD Test

**Files:**
- Create: `lib/domain/repository/transaction_repository.dart`
- Test: `test/data/repository/drift_transaction_repository_test.dart`

**Interfaces:**
- Produces `TransactionQuery`, `TransactionRepository`, and these methods:
  - `Future<void> save(BookkeepingTransaction transaction)`
  - `Future<BookkeepingTransaction?> findById(String id)`
  - `Future<List<BookkeepingTransaction>> list(TransactionQuery query)`
  - `Future<List<BookkeepingTransaction>> latest({required int limit})`
  - `Future<MonthlySummary> monthlySummary({required int year, required int month})`
  - `Future<void> delete(String id)`

- [ ] Write a failing repository CRUD test using a temporary encrypted database.
- [ ] Run the focused test and confirm it fails because repository/database classes do not exist.
- [ ] Add only the pure repository contract needed by the test.
- [ ] Run the focused test and confirm it still fails at the missing data implementation boundary.

## Task 2: Dependencies and Drift Schema Baseline

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/data/database/networthy_database.dart`
- Create: `lib/data/database/networthy_database.drift`

**Interfaces:**
- Produces `NetworthyDatabase` with `schemaVersion == 1`.
- Defines `transactions` table fields: `id`, `type`, `amount_minor`, `currency_code`, `category_id`, `transaction_year`, `transaction_month`, `transaction_day`, `note`, `created_at_utc`, `updated_at_utc`.
- Defines `app_settings` table fields: `id`, `onboarding_completed`, `biometric_lock_enabled`, `currency_code`, `last_expense_category_id`, `last_income_category_id`.

- [ ] Add Drift/build dependencies.
- [ ] Run dependency resolution.
- [ ] Add schema and database files.
- [ ] Run code generation.
- [ ] Run analyzer and fix compile errors only.

## Task 3: Encrypted Database Opener

**Files:**
- Create: `lib/data/database/encrypted_database_opener.dart`
- Test: `test/data/database/encrypted_database_opener_test.dart`

**Interfaces:**
- Produces `EncryptedDatabaseOpener.open()` returning a Drift-compatible database connection.
- Uses `DatabaseKeyStore.loadOrCreate(databaseExists: exists)` when opening for normal app use.
- Applies `pragma key = "x'<hex>'"` before schema reads.
- Verifies the cipher provider with `pragma cipher_version` or `pragma cipher`.

- [ ] Write tests for first create, reopen with existing key, wrong key rejection, and missing-key-with-existing-db rejection.
- [ ] Confirm tests fail for missing opener behavior.
- [ ] Implement opener using sqlite3 + Drift connection.
- [ ] Confirm focused opener tests pass.

## Task 4: Transaction Repository Implementation

**Files:**
- Create: `lib/data/repository/drift_transaction_repository.dart`
- Test: `test/data/repository/drift_transaction_repository_test.dart`

**Interfaces:**
- Consumes `NetworthyDatabase` and `TransactionRepository`.
- Produces CRUD, month filtering, type filtering, latest five ordering, and monthly summaries.

- [ ] Extend repository tests for create/read/update/delete.
- [ ] Add tests for month filtering, type filtering, latest five ordering, and delete refreshing monthly summary.
- [ ] Confirm focused tests fail.
- [ ] Implement row mapping and repository queries.
- [ ] Confirm focused repository tests pass.

## Task 5: Settings Repository Implementation

**Files:**
- Create: `lib/domain/repository/settings_repository.dart`
- Create: `lib/data/repository/drift_settings_repository.dart`
- Test: `test/data/repository/drift_settings_repository_test.dart`

**Interfaces:**
- Produces `SettingsRepository` with:
  - `Future<AppSettings> load()`
  - `Future<void> save(AppSettings settings)`

- [ ] Write tests for default settings and persisted settings.
- [ ] Confirm focused tests fail.
- [ ] Implement settings repository as a single-row Drift table.
- [ ] Confirm focused settings tests pass.

## Task 6: Migration and Clear-All-Data

**Files:**
- Modify: `lib/data/database/networthy_database.dart`
- Create: `lib/data/repository/clear_local_data.dart`
- Test: `test/data/database/networthy_database_migration_test.dart`
- Test: `test/data/repository/clear_local_data_test.dart`

**Interfaces:**
- Produces a baseline migration strategy that preserves data when opening an existing schema-1 database.
- Produces `ClearLocalData` with `Future<void> clear()` deleting database files, encryption key, and non-sensitive preferences.

- [ ] Write migration-preserves-data test.
- [ ] Write clear-all-data removal test.
- [ ] Confirm focused tests fail.
- [ ] Implement migration strategy and clear operation.
- [ ] Confirm focused tests pass.

## Task 7: Milestone Verification and Commit

**Files:**
- Modify: `README.md`
- Create or modify: `docs/verification/milestone-3-persistence-repository.md`

- [ ] Run `dart format` on changed Dart files.
- [ ] Run `flutter analyze`.
- [ ] Run `flutter test`.
- [ ] Document verification evidence and local caveats.
- [ ] Run `git status --short`.
- [ ] `git add` all Milestone 3 changes.
- [ ] `git commit -m "feat: add encrypted persistence repositories"`.
- [ ] `git push`.
