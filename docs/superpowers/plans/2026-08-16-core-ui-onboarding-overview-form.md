# Core UI Onboarding Overview Form Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver the Milestone 5 core Flutter UI path: onboarding, bottom navigation, monthly overview, and add/edit transaction form.

**Architecture:** Add a `presentation` layer that depends on application use cases/controllers, not SQL or Drift. The root app accepts injectable repositories and platform ports for tests, while production startup wires encrypted Drift repositories asynchronously.

**Tech Stack:** Flutter Material 3 widgets, existing application use cases, existing domain/data repositories, Flutter widget tests.

## Global Constraints

- V1 platforms: iOS and Android.
- V1 language: Traditional Chinese.
- V1 currency: TWD only, displayed as `NT$12,500`.
- V1 is single-user, local-only, no registration, no backend, no cloud sync.
- Core functionality must work without network.
- UI calls use cases or repository abstractions; it must not directly access SQL.
- Transaction amounts use 64-bit integers, not floating point.
- Transaction dates are local calendar dates; created/updated timestamps are UTC.
- Category records must use stable IDs, not localized display names.

---

## Task 1: App Root and Onboarding

**Files:**
- Modify: `lib/main.dart`
- Create: `lib/presentation/app/networthy_app.dart`
- Test: `test/presentation/app/onboarding_widget_test.dart`

**Interfaces:**
- `NetworthyApp` accepts `TransactionRepository`, `SettingsRepository`, `ApplicationClock`, `TransactionIdGenerator`, and optional initial date.
- Onboarding shows local-only and uninstall/data-loss copy.
- Completing onboarding saves settings and shows the home shell.

- [ ] Write failing onboarding widget test.
- [ ] Run focused test and confirm missing UI fails.
- [ ] Implement app root and onboarding.
- [ ] Run focused test and confirm it passes.

## Task 2: Overview and Navigation Shell

**Files:**
- Create: `lib/presentation/home/home_shell.dart`
- Create: `lib/presentation/overview/overview_page.dart`
- Test: `test/presentation/overview/overview_widget_test.dart`

**Interfaces:**
- Bottom navigation labels: `總覽`, `紀錄`, `設定`.
- Overview shows income, expense, balance, category totals, recent five transactions, empty/loading/error states, and month switch controls.

- [ ] Write failing overview navigation/month/empty/error widget tests.
- [ ] Run focused tests and confirm missing UI fails.
- [ ] Implement shell and overview page.
- [ ] Run focused tests and confirm they pass.

## Task 3: Add/Edit Transaction Form

**Files:**
- Create: `lib/presentation/transaction/transaction_form_page.dart`
- Modify: `lib/presentation/overview/overview_page.dart`
- Test: `test/presentation/transaction/transaction_form_widget_test.dart`

**Interfaces:**
- Default new transaction type is expense.
- Amount field is auto-focused and numeric.
- Amount display uses thousands separators; persisted amount remains integer.
- Form validation messages show beside relevant fields.
- Save success returns to source page and refreshes overview.
- Save failure keeps entered form data and shows non-sensitive error copy.

- [ ] Write failing add/edit/save-failure widget tests.
- [ ] Run focused tests and confirm missing form behavior fails.
- [ ] Implement shared add/edit form.
- [ ] Run focused tests and confirm they pass.

## Task 4: Milestone Verification and Commit

**Files:**
- Create: `docs/verification/milestone-5-core-ui.md`

- [ ] Run `dart format lib test`.
- [ ] Run `flutter analyze`.
- [ ] Run `flutter test`.
- [ ] Verify presentation does not import Drift/sqlite packages.
- [ ] Document verification evidence.
- [ ] `git add` all Milestone 5 changes.
- [ ] `git commit -m "feat: add core bookkeeping UI"`.
- [ ] `git push`.
