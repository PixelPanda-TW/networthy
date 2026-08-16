# Milestone 5 Core UI Verification

Date: 2026-08-16

## Scope Verified

- One-page onboarding explains local-only storage and uninstall / clear-data loss risk.
- Completing onboarding persists the setting and enters the home shell.
- Bottom navigation includes `總覽`, `紀錄`, and `設定`.
- Monthly overview shows income, expense, balance, category totals, recent records, empty state, loading state, and error fallback.
- Month switching updates the displayed month.
- Add transaction form defaults to expense, auto-focuses amount, uses numeric input, validates amount, and saves integer TWD amounts.
- Save success returns to overview and refreshes totals/recent transactions.
- Tapping a recent transaction opens the shared edit form and updates overview after save.
- Save failure keeps entered form data and shows non-sensitive error copy.
- Production bootstrap wires encrypted Drift repositories into `NetworthyApp`; widget tests inject in-memory repositories.

## Verification Commands

```bash
dart format lib test
```

Result: exit 0, `Formatted 61 files (0 changed)` after the final API fix.

```bash
FLUTTER_SUPPRESS_ANALYTICS=true flutter analyze
```

Result: exit 0, `No issues found!`.

```bash
FLUTTER_SUPPRESS_ANALYTICS=true flutter test
```

Result: exit 0, `All tests passed!` with 60 passing tests.

```bash
rg "package:drift|package:sqlite3|data/" lib/presentation
```

Result: exit 1 with no matches, confirming presentation does not import Drift, sqlite3, or data-layer code.

## Notes

- Category labels are still stable category IDs in M5. Localized display names can be introduced as a presentation-only formatter in a later UI polish pass.
- Records and Settings tabs are navigation placeholders for Milestone 6 and Milestone 7.
