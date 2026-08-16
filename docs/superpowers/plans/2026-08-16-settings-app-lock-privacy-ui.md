# Settings App Lock Privacy UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement Milestone 7 settings, app-lock, privacy overlay, and clear-all-data flows behind testable ports.

**Architecture:** Add application ports for device authentication and local data clearing. Presentation uses settings repository plus these ports; platform-specific biometric adapters can be wired later without changing UI contracts.

**Tech Stack:** Flutter Material 3 widgets, existing app-lock state machine, existing settings repository contract, existing clear-local-data data service behind a port.

## Global Constraints

- V1 platforms: iOS and Android.
- V1 language: Traditional Chinese.
- V1 currency: TWD only.
- V1 is single-user, local-only, no registration, no backend, no cloud sync.
- UI calls use cases or repository abstractions; it must not directly access SQL.
- Accounting database must be encrypted.
- Database key must not be stored in SharedPreferences or equivalent general key-value storage.
- Do not log SQL binding values, notes, amounts, keys, or full database paths in release builds.

---

## Task 1: Security Ports and App Lock Screen

**Files:**
- Create: `lib/application/security/device_authenticator.dart`
- Create: `lib/presentation/security/lock_screen.dart`
- Modify: `lib/presentation/app/networthy_app.dart`
- Test: `test/presentation/security/app_lock_widget_test.dart`

**Interfaces:**
- `DeviceAuthenticator` exposes support/enrollment status and `authenticate`.
- Lock screen shows on cold start when app lock is enabled.
- Failed or cancelled auth stays on lock screen and allows retry.

- [ ] Write failing widget tests for cold-start lock and failed auth retry.
- [ ] Run focused tests and confirm missing symbols/behavior fail.
- [ ] Implement security port and lock screen gate.
- [ ] Run focused tests and confirm they pass.

## Task 2: Background Privacy Overlay and Resume Lock

**Files:**
- Modify: `lib/presentation/app/networthy_app.dart`
- Test: `test/presentation/security/app_lock_widget_test.dart`

**Interfaces:**
- App lifecycle inactive/paused displays privacy overlay hiding accounting content.
- Resume after background duration greater than 30 seconds shows lock screen when app lock is enabled.

- [ ] Write failing widget tests using `tester.binding.handleAppLifecycleStateChanged`.
- [ ] Run focused tests and confirm failures.
- [ ] Implement lifecycle observer and overlay/lock state.
- [ ] Run focused tests and confirm they pass.

## Task 3: Settings Page and Biometric Toggle

**Files:**
- Create: `lib/presentation/settings/settings_page.dart`
- Modify: `lib/presentation/home/home_shell.dart`
- Test: `test/presentation/settings/settings_page_widget_test.dart`

**Interfaces:**
- Settings page displays app version and offline/data-loss privacy copy.
- App lock toggle defaults off.
- Enabling checks device support and enrollment before saving.
- Unsupported or unenrolled device preserves prior toggle state.
- Disabling app lock persists false.

- [ ] Write failing widget tests for settings copy, enabling, disabling, unsupported, and unenrolled cases.
- [ ] Run focused tests and confirm failures.
- [ ] Implement settings page and wire HomeShell settings tab.
- [ ] Run focused tests and confirm they pass.

## Task 4: Clear-All-Data Flow

**Files:**
- Create: `lib/application/settings/local_data_clearer.dart`
- Modify: `lib/presentation/settings/settings_page.dart`
- Modify: `lib/presentation/app/networthy_app.dart`
- Test: `test/presentation/settings/clear_all_data_widget_test.dart`

**Interfaces:**
- Clear-all-data uses double confirmation.
- If app lock is enabled, clear-all-data requires authentication before clearing.
- Success reloads app settings and returns to first-use/onboarding state.

- [ ] Write failing widget tests for double confirmation, auth-required clear, and return-to-first-use state.
- [ ] Run focused tests and confirm failures.
- [ ] Implement clearer port, UI flow, and app reset callback.
- [ ] Run focused tests and confirm they pass.

## Task 5: Milestone Verification and Commit

**Files:**
- Create: `docs/verification/milestone-7-settings-app-lock-privacy.md`

- [ ] Run `dart format lib test`.
- [ ] Run `flutter analyze`.
- [ ] Run `flutter test`.
- [ ] Verify presentation does not import Drift/sqlite/data packages.
- [ ] Document verification evidence and manual biometric caveat.
- [ ] `git add` all Milestone 7 changes.
- [ ] `git commit -m "feat: add settings app lock privacy controls"`.
- [ ] `git push`.
