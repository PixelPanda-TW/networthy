# Application Use Cases State Flows Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement Milestone 4 application workflows without binding product behavior directly to Flutter widgets.

**Architecture:** Add a pure Dart `lib/application` layer that depends on domain models and repository contracts only. Use cases perform command/query orchestration, update last-category settings, expose non-sensitive failures, and provide controller state that preserves form input on save failure.

**Tech Stack:** Pure Dart application services, existing domain models, existing repository contracts, Flutter test for unit tests.

## Global Constraints

- V1 platforms: iOS and Android.
- V1 language: Traditional Chinese.
- V1 currency: TWD only, displayed as `NT$12,500`.
- V1 is single-user, local-only, no registration, no backend, no cloud sync.
- Core functionality must work without network.
- Domain code must not depend on Flutter or database packages.
- UI calls use cases or repository abstractions; it must not directly access SQL.
- Transaction amounts use 64-bit integers, not floating point.
- Transaction dates are local calendar dates; created/updated timestamps are UTC.
- Category records must use stable IDs, not localized display names.

---

## Task 1: Application Failure and Ports

**Files:**
- Create: `lib/application/common/application_failure.dart`
- Create: `lib/application/common/application_ports.dart`
- Test: `test/application/common/application_failure_test.dart`

**Interfaces:**
- Produces `ApplicationFailureType { decryption, persistence, validation }`.
- Produces `ApplicationFailure` with `type` and `safeMessage`.
- Produces `ApplicationClock` and `TransactionIdGenerator`.

- [ ] Write failing tests for decryption and persistence failure factories.
- [ ] Run focused test and confirm missing symbols fail.
- [ ] Implement failure and port types.
- [ ] Run focused test and confirm it passes.

## Task 2: Transaction Commands

**Files:**
- Create: `lib/application/transaction/transaction_command.dart`
- Create: `lib/application/transaction/add_transaction_use_case.dart`
- Create: `lib/application/transaction/edit_transaction_use_case.dart`
- Test: `test/application/transaction/transaction_command_use_cases_test.dart`

**Interfaces:**
- Produces `TransactionCommand` containing `type`, `amountMinor`, `categoryId`, `transactionDate`, and `note`.
- Produces `TransactionCommandResult` with `transaction` and nullable `failure`.
- Add creates a new `BookkeepingTransaction` using generated id and UTC clock.
- Edit preserves original `createdAtUtc` and updates `updatedAtUtc`.
- Both save through `TransactionRepository` and update last category through `SettingsRepository`.

- [ ] Write failing add/edit tests, including separate last expense and income category updates.
- [ ] Run focused test and confirm missing symbols fail.
- [ ] Implement command object and use cases.
- [ ] Run focused test and confirm it passes.

## Task 3: Delete Confirmation and Query Use Cases

**Files:**
- Create: `lib/application/transaction/delete_transaction_use_case.dart`
- Create: `lib/application/transaction/monthly_overview_use_case.dart`
- Create: `lib/application/transaction/list_transactions_use_case.dart`
- Test: `test/application/transaction/query_and_delete_use_cases_test.dart`

**Interfaces:**
- Produces `DeleteTransactionRequest(id, confirmed)`.
- Delete returns a validation failure when `confirmed == false`.
- Monthly overview returns summary plus latest five transactions.
- List use case forwards month/type filters through `TransactionQuery`.

- [ ] Write failing delete/query tests.
- [ ] Run focused test and confirm missing symbols fail.
- [ ] Implement delete, overview, and list use cases.
- [ ] Run focused test and confirm it passes.

## Task 4: Application State Flow

**Files:**
- Create: `lib/application/transaction/bookkeeping_flow_controller.dart`
- Test: `test/application/transaction/bookkeeping_flow_controller_test.dart`

**Interfaces:**
- Produces immutable `BookkeepingFlowState`.
- State contains selected `year`, `month`, current `MonthlySummary`, recent transactions, form command, saving flag, and nullable `ApplicationFailure`.
- `add`, `edit`, and `delete` refresh monthly summary and latest transactions immediately after successful repository mutation.
- Failed save preserves submitted form command in state.

- [ ] Write failing tests for refresh after add/edit/delete and preserved form state on save failure.
- [ ] Run focused test and confirm missing symbols fail.
- [ ] Implement controller with pure Dart async methods.
- [ ] Run focused test and confirm it passes.

## Task 5: Onboarding and App Lock State Machine

**Files:**
- Create: `lib/application/settings/onboarding_use_case.dart`
- Create: `lib/application/security/app_lock_state_machine.dart`
- Test: `test/application/settings/onboarding_use_case_test.dart`
- Test: `test/application/security/app_lock_state_machine_test.dart`

**Interfaces:**
- `CompleteOnboardingUseCase` sets `AppSettings.onboardingCompleted` to true.
- `AppLockStateMachine` evaluates cold start and resume after background duration.
- Lock triggers when app lock is enabled and either cold start occurs or background duration is greater than 30 seconds.

- [ ] Write failing onboarding and app-lock tests.
- [ ] Run focused tests and confirm missing symbols fail.
- [ ] Implement onboarding and app-lock state machine.
- [ ] Run focused tests and confirm they pass.

## Task 6: Milestone Verification and Commit

**Files:**
- Create: `docs/verification/milestone-4-application-use-cases.md`

- [ ] Run `dart format lib test`.
- [ ] Run `flutter analyze`.
- [ ] Run `flutter test`.
- [ ] Verify `lib/application` imports no Flutter, Drift, sqlite3, or data layer packages.
- [ ] Document verification evidence.
- [ ] Run `git status --short`.
- [ ] `git add` all Milestone 4 changes.
- [ ] `git commit -m "feat: add application use cases"`.
- [ ] `git push`.
