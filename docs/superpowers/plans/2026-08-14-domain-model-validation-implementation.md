# Domain Model and Validation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement Milestone 2 domain models, validation rules, local-date handling, V1 categories, settings defaults, and monthly summary calculations.

**Architecture:** Keep all bookkeeping business rules in `lib/domain/**` as pure Dart. Domain code must not import Flutter, SQLite, secure storage, or platform packages. Later data/application layers will consume these domain types.

**Tech Stack:** Dart, Flutter test runner, pure domain model classes.

## Global Constraints

- Transaction amounts use 64-bit integers, not floating point.
- V1 currency is fixed to `TWD`.
- Amount must be greater than 0 and not exceed 999,999,999 TWD.
- Transaction dates are local calendar dates, not UTC instants.
- Created/updated timestamps are UTC.
- Category records use stable IDs, not display names.
- V1 default expense categories: 餐飲、交通、購物、居住、娛樂、醫療、教育、其他.
- V1 default income categories: 薪資、獎金、投資、其他.
- V1 does not allow adding, deleting, or sorting categories.
- Notes are optional and must be at most 100 Unicode code points.
- Domain code must not depend on Flutter or database packages.

---

## File Structure

- `lib/domain/model/transaction_type.dart`: income/expense enum.
- `lib/domain/model/local_date.dart`: year-month-day value object and month matching.
- `lib/domain/model/category.dart`: stable category definitions and compatibility checks.
- `lib/domain/model/transaction.dart`: transaction entity and validation.
- `lib/domain/model/app_settings.dart`: settings defaults.
- `lib/domain/model/domain_validation.dart`: shared validation exception.
- `lib/domain/summary/monthly_summary.dart`: summary result objects and calculation.
- `test/domain/model/transaction_validation_test.dart`: amount, note, date, category tests.
- `test/domain/model/category_test.dart`: V1 category and compatibility tests.
- `test/domain/model/app_settings_test.dart`: defaults.
- `test/domain/summary/monthly_summary_test.dart`: monthly totals and percentages.
- `README.md`: local development note for CocoaPods Ruby environment.

## Tasks

### Task 1: Record Local Development Environment Note

- [ ] Add README note: when CocoaPods is affected by stale `GEM_HOME`/`GEM_PATH`, run iOS commands with `env -u GEM_HOME -u GEM_PATH`.

### Task 2: Category and Transaction Type Domain

- [ ] Write failing tests for default V1 categories and type compatibility.
- [ ] Implement transaction type enum, category value object, and category catalog.
- [ ] Verify category tests pass.

### Task 3: Money, Note, Date, and Transaction Validation

- [ ] Write failing tests for amount lower/upper bounds, note length, local date preservation, and category/type mismatch.
- [ ] Implement local date and transaction entity validation.
- [ ] Verify transaction validation tests pass.

### Task 4: App Settings Defaults

- [ ] Write failing tests for settings defaults.
- [ ] Implement app settings value object.
- [ ] Verify app settings tests pass.

### Task 5: Monthly Summary Calculation

- [ ] Write failing tests for monthly income, expense, balance, category totals, percentages, leap day, and month filtering.
- [ ] Implement monthly summary calculator.
- [ ] Verify summary tests pass.

### Task 6: Milestone Verification and Git

- [ ] Run `FLUTTER_SUPPRESS_ANALYTICS=true flutter analyze`.
- [ ] Run `FLUTTER_SUPPRESS_ANALYTICS=true flutter test`.
- [ ] Confirm domain files do not import Flutter or data packages.
- [ ] Commit with `feat: add domain model validation`.
- [ ] Push to `origin/main`.

## Self-Review

- Spec coverage: covers Transaction, AppSettings, income/expense type, stable V1 categories, amount/note/category/date validation, and monthly summary calculations.
- Placeholder scan: no placeholder items remain.
- Type consistency: domain names are consistent across files and tests.
