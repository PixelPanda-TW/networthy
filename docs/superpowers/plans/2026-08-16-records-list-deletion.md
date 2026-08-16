# Records List Deletion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete Milestone 6 transaction browsing, filtering, editing entry, and safe deletion.

**Architecture:** Add a presentation `RecordsPage` that uses repository contracts and existing transaction form/use cases. Keep SQL and data-layer imports out of presentation; HomeShell coordinates refresh after record mutations.

**Tech Stack:** Flutter Material 3 widgets, existing application use cases, existing domain repository contracts, Flutter widget tests.

## Global Constraints

- V1 platforms: iOS and Android.
- V1 language: Traditional Chinese.
- V1 currency: TWD only, displayed as `NT$12,500`.
- V1 is single-user, local-only, no registration, no backend, no cloud sync.
- UI calls use cases or repository abstractions; it must not directly access SQL.
- Transaction amounts use 64-bit integers, not floating point.
- Transaction dates are local calendar dates; created/updated timestamps are UTC.
- Category records must use stable IDs, not localized display names.

---

## Task 1: Records List and Ordering

**Files:**
- Create: `lib/presentation/records/records_page.dart`
- Modify: `lib/presentation/home/home_shell.dart`
- Test: `test/presentation/records/records_page_widget_test.dart`

**Interfaces:**
- Records tab lists transactions sorted by transaction date descending, then created time descending for same-day records.
- Rows show date, category, amount, and note/type fallback.

- [ ] Write failing widget test for default ordering.
- [ ] Run focused test and confirm missing page/behavior fails.
- [ ] Implement records page and wire it into HomeShell.
- [ ] Run focused test and confirm it passes.

## Task 2: Month and Type Filters

**Files:**
- Modify: `lib/presentation/records/records_page.dart`
- Test: `test/presentation/records/records_page_widget_test.dart`

**Interfaces:**
- Month filter uses previous/next month controls.
- Type filter supports all, income, and expense.

- [ ] Write failing widget tests for month filtering and all/income/expense filtering.
- [ ] Run focused tests and confirm failures.
- [ ] Implement filter controls and query behavior.
- [ ] Run focused tests and confirm they pass.

## Task 3: Edit and Delete Flow

**Files:**
- Modify: `lib/presentation/records/records_page.dart`
- Modify: `lib/presentation/home/home_shell.dart`
- Test: `test/presentation/records/records_page_widget_test.dart`

**Interfaces:**
- Tapping a record opens the shared edit form.
- Delete button opens a confirmation dialog.
- Confirmed delete removes the record and refreshes records list and overview-related monthly summary.

- [ ] Write failing widget tests for tap-to-edit and delete confirmation.
- [ ] Run focused tests and confirm failures.
- [ ] Implement edit entry and delete confirmation.
- [ ] Run focused tests and confirm they pass.

## Task 4: Milestone Verification and Commit

**Files:**
- Create: `docs/verification/milestone-6-records-list-deletion.md`

- [ ] Run `dart format lib test`.
- [ ] Run `flutter analyze`.
- [ ] Run `flutter test`.
- [ ] Verify presentation does not import Drift/sqlite/data packages.
- [ ] Document verification evidence.
- [ ] `git add` all Milestone 6 changes.
- [ ] `git commit -m "feat: add records list and deletion"`.
- [ ] `git push`.
