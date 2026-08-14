# Flutter Bookkeeping MVP Milestone Memory

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:brainstorming` before changing product behavior, `superpowers:test-driven-development` before implementing features or bug fixes, and `superpowers:verification-before-completion` before claiming a milestone is complete.

**Source spec:** `2026-08-10-flutter-bookkeeping-mvp-design.md`

**Goal:** Build a Flutter offline-first personal bookkeeping MVP for iOS and Android with encrypted local storage, optional biometric app lock, and core income/expense flows.

**Architecture:** Use a layered architecture: `presentation`, `application`, `domain`, `data`, and `platform`. UI calls use cases or repository abstractions; it must not directly access SQL. Domain code must not depend on Flutter or database packages.

**Tech Stack:** Flutter Material 3, Drift, sqlite3 3.x, SQLCipher or SQLite3MultipleCiphers, flutter_secure_storage, local_auth, shared_preferences or equivalent non-sensitive preferences.

## Global Constraints

- V1 platforms: iOS and Android.
- V1 language: Traditional Chinese.
- V1 currency: TWD only, displayed as `NT$12,500`.
- V1 is single-user, local-only, no registration, no backend, no cloud sync.
- Core functionality must work without network.
- Accounting database must be encrypted.
- Database key must be generated with cryptographically secure randomness and stored only in iOS Keychain / Android Keystore backed secure storage.
- Database key must not be stored in SharedPreferences or equivalent general key-value storage.
- Do not log SQL binding values, notes, amounts, keys, or full database paths in release builds.
- Transaction amounts use 64-bit integers, not floating point.
- Transaction dates are local calendar dates; created/updated timestamps are UTC.
- Category records must use stable IDs, not localized display names.
- V1 does not support custom categories, import/export, backup/restore, budgets, recurring transactions, notifications, search, AI categorization, multi-account, multi-currency, bank integration, login, or sync.

---

## Milestone 0: Project Bootstrap and Technical Decisions

**Purpose:** Establish the Flutter project, dependency baseline, architecture folders, and repeatable local/test commands.

**Deliverables:**

- Flutter iOS/Android project exists.
- Initial folder boundaries exist for `presentation`, `application`, `domain`, `data`, and `platform`.
- Package versions are pinned and lockfile is committed.
- Basic CI/local commands are documented.
- App can launch on iOS and Android simulator/emulator with a placeholder shell.

**Acceptance gates:**

- `flutter analyze` passes.
- `flutter test` passes.
- iOS and Android debug builds launch.
- No product feature depends on network or backend configuration.

## Milestone 1: Encrypted Database Spike

**Purpose:** Prove encrypted SQLite works reliably before building product features.

**Deliverables:**

- Choose SQLCipher or SQLite3MultipleCiphers after a real iOS/Android spike.
- Generate at least a 256-bit database key using secure randomness.
- Store and retrieve the key via secure storage.
- Open encrypted SQLite before any schema query.
- Validate the encryption provider and key with a minimal query.
- Document the selected provider and rejected alternative if applicable.

**Acceptance gates:**

- iOS real-device or representative device test: create, close, reopen encrypted DB.
- Android real-device or representative device test: create, close, reopen encrypted DB.
- External file inspection confirms database, WAL, journal, and temp files do not contain test plaintext.
- Wrong key cannot read data.
- Missing key does not silently create a new key over an existing database.

## Milestone 2: Domain Model and Validation

**Purpose:** Lock down core bookkeeping rules independent of Flutter and persistence.

**Deliverables:**

- `Transaction` domain model.
- `AppSettings` domain model.
- Income/expense type model.
- Stable category IDs for V1 default categories.
- Amount validation: required, integer, greater than 0, maximum 999,999,999 TWD.
- Note validation: optional, max 100 Unicode characters.
- Category/type compatibility validation.
- Local calendar-date handling for transaction date.
- Monthly summary calculation for income, expense, balance, category totals, and category percentages.

**Acceptance gates:**

- Unit tests cover amount boundaries and illegal input.
- Unit tests cover income/expense category compatibility.
- Unit tests cover monthly totals, balance, category totals, and percentages.
- Unit tests cover month boundaries, leap day, and timezone changes without moving transaction dates.
- Domain package has no Flutter/database dependency.

## Milestone 3: Persistence and Repository Layer

**Purpose:** Implement encrypted local persistence behind repository abstractions.

**Deliverables:**

- Drift schema for transactions and app settings.
- Repository interfaces consumed by application/UI layers.
- Repository implementation using encrypted SQLite.
- CRUD operations for transactions.
- Query operations for month filtering, type filtering, latest five transactions, and monthly summaries.
- Settings persistence for onboarding completion, app lock enabled, currency code, last expense category, and last income category.
- Migration baseline.
- Clear-all-data operation that removes database, database key, and related preferences.

**Acceptance gates:**

- Repository tests cover create, read, update, delete.
- Database tests cover first create and reopening with existing key.
- Database tests cover wrong key rejection.
- Database tests cover schema migration preserving existing data.
- Database tests cover delete causing summary refresh.
- Database tests cover key-missing state without automatic overwrite.
- Clear-all-data test verifies database, key, and preferences are removed.

## Milestone 4: Application Use Cases and State Flows

**Purpose:** Implement product workflows without binding them directly to UI widgets.

**Deliverables:**

- Add transaction use case.
- Edit transaction use case.
- Delete transaction use case with confirmation contract.
- Monthly overview use case.
- Transaction list filtering use case.
- Last-category preference behavior split by income and expense.
- Onboarding completion use case.
- App-lock state machine, including cold start and background-over-30-seconds behavior.
- Error states distinguishing decryption failure from general read/write failure.

**Acceptance gates:**

- Unit tests cover add/edit/delete flows.
- Unit tests cover last expense category and last income category being stored separately.
- Unit tests cover immediate summary update after add/edit/delete.
- Unit tests cover App lock state machine and 30-second background threshold.
- Unit tests verify save failure preserves form state through application state.

## Milestone 5: Core UI — Onboarding, Navigation, Overview, and Form

**Purpose:** Deliver the primary user path: understand local-only risk, view monthly summary, and add/edit transactions quickly.

**Deliverables:**

- One-page onboarding explaining local storage and uninstall/data-loss risk.
- Bottom navigation: Overview, Records, Settings.
- Monthly overview page with income, expense, balance, category spending totals/percentages, recent five transactions, and add button.
- Month switching on overview.
- Shared add/edit transaction form.
- Amount field auto-focused on open with numeric keyboard.
- Amount display uses thousands separators; stored value remains integer.
- Default new transaction type is expense.
- Date defaults to device-local today.
- Form validation messages shown beside relevant fields.
- Save success returns to source page and refreshes statistics.
- Save failure keeps entered form data and shows non-sensitive error copy.

**Acceptance gates:**

- Widget/integration test covers onboarding start.
- Widget/integration test covers adding an expense in the intended fast path.
- Widget/integration test covers editing a transaction.
- Widget/integration test covers month switching and refreshed totals.
- Widget tests cover empty, loading, and error states.
- Main screens have no layout overflow under normal text scaling.

## Milestone 6: Records List and Deletion

**Purpose:** Complete transaction browsing, filtering, editing entry, and safe deletion.

**Deliverables:**

- Records page sorted by transaction date descending, then created time descending for same-day records.
- Month filter.
- Type filter: all, income, expense.
- Tap record to edit.
- Delete record flow with confirmation.
- Immediate summary/list refresh after edit or delete.

**Acceptance gates:**

- Widget/integration test covers default ordering.
- Widget/integration test covers month filtering.
- Widget/integration test covers all/income/expense filtering.
- Widget/integration test covers delete confirmation.
- Widget/integration test verifies deleted records update related monthly summary.

## Milestone 7: Settings, Biometric App Lock, and Privacy UI

**Purpose:** Add user-controlled privacy features and destructive-data controls.

**Deliverables:**

- Settings page displays app version.
- Settings page displays offline storage and data-loss privacy explanation.
- Biometric App lock toggle, default off.
- Device support and enrolled-biometric checks before enabling App lock.
- System PIN/pattern/passcode fallback allowed.
- Lock screen shown on cold start when enabled.
- Lock screen shown after returning from background if background duration exceeds 30 seconds.
- Background/app-switcher privacy overlay hides accounting content.
- Failed/cancelled auth stays on lock screen and allows retry or leaving App.
- Clear-all-data flow with double confirmation.
- If App lock is enabled, clear-all-data requires system authentication before clearing.

**Acceptance gates:**

- Widget/integration test covers enabling and disabling App lock.
- Widget/integration test covers unsupported or unenrolled biometric case preserving prior toggle state.
- Integration test covers background return lock behavior.
- Integration/manual test covers app-switcher preview masking.
- Integration test covers clear-all-data returning to first-use state.
- Manual device test covers Face ID/Touch ID/Android biometrics and system credential fallback.

## Milestone 8: Security, Privacy, Performance, and Accessibility Hardening

**Purpose:** Verify the non-functional requirements before release packaging.

**Deliverables:**

- Sensitive logging audit.
- Release-build logging configuration.
- Database file plaintext inspection procedure.
- Accessibility labels for primary actions.
- Touch target sizing review.
- System text scaling review.
- Performance measurement for homepage with up to 10,000 transactions.
- Airplane-mode manual test script.

**Acceptance gates:**

- Release build does not output sensitive logs.
- Database, WAL, journal, and temp files contain no accounting plaintext in release-like build.
- Homepage loads local data within 1 second for 10,000 transactions on representative hardware.
- Main controls meet platform basic accessibility sizing.
- Screen reader can identify primary actions.
- Main flows remain usable under common system text scaling.
- Airplane mode supports add, view, edit, and delete.

## Milestone 9: Release Acceptance

**Purpose:** Confirm the MVP is shippable against the original design doc.

**Deliverables:**

- Final iOS installable build.
- Final Android installable build.
- Manual acceptance checklist results.
- Known limitations note matching V1 exclusions.

**Acceptance gates:**

- iOS and Android install and launch.
- Offline add/view/edit/delete works.
- Monthly and category statistics are correct.
- Force close and restart preserves and decrypts data.
- App lock hides accounting data until authentication.
- Clear-all-data removes database, key, and settings.
- Major screens have no overflow.
- Screen reader identifies primary actions.
- All V1 non-goals remain excluded.

## Execution Order

1. Milestone 0: Project Bootstrap and Technical Decisions
2. Milestone 1: Encrypted Database Spike
3. Milestone 2: Domain Model and Validation
4. Milestone 3: Persistence and Repository Layer
5. Milestone 4: Application Use Cases and State Flows
6. Milestone 5: Core UI — Onboarding, Navigation, Overview, and Form
7. Milestone 6: Records List and Deletion
8. Milestone 7: Settings, Biometric App Lock, and Privacy UI
9. Milestone 8: Security, Privacy, Performance, and Accessibility Hardening
10. Milestone 9: Release Acceptance

## Notes for Future Sessions

- Treat this file as the remembered milestone breakdown for the Flutter bookkeeping MVP.
- This directory is a Git repository. Every time a milestone is completed, run `git add`, `git commit`, and `git push` for that milestone's finished work.
- If implementation starts from this plan, first create or verify an isolated working branch/worktree.
- Do not start building transaction features until the encrypted database spike has passed on both platforms.
- Keep V1 intentionally narrow; move sync, login, backup/export, custom categories, budgets, recurring transactions, search, AI categorization, multi-currency, and bank integrations to post-MVP work.
