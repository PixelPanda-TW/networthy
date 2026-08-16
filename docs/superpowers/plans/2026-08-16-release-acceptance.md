# Release Acceptance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Confirm the MVP is shippable against the original design doc and capture final release evidence.

**Architecture:** M9 does not add product behavior. It hardens release identifiers, runs automated and platform build gates, and records manual acceptance scope and V1 exclusions in checked-in documentation.

**Tech Stack:** Flutter, Android Gradle Kotlin DSL, iOS Xcode project configuration, Flutter widget/unit tests, Markdown release evidence.

## Global Constraints

- V1 is Flutter iOS/Android.
- V1 is offline-first and does not require login or backend sync.
- Local accounting database must be encrypted.
- Do not log SQL binding values, notes, amounts, keys, or full database paths in release builds.
- V1 excludes registration, login, cloud sync, multi-user, import/export, bank integrations, budgets, recurring transactions, notifications, multi-currency, custom categories, full-text search, and AI categorization.
- Completion requires `git add`, `git commit`, and `git push`.

---

## Files

- Create: `test/release/release_configuration_test.dart`
- Create: `docs/verification/milestone-9-release-acceptance.md`
- Modify: `android/app/build.gradle.kts`
- Move: `android/app/src/main/kotlin/com/example/networthy/MainActivity.kt` to `android/app/src/main/kotlin/tw/pixelpanda/networthy/MainActivity.kt`
- Modify: `ios/Runner.xcodeproj/project.pbxproj`
- Modify: `README.md`

## Tasks

### Task 1: Release identifier audit

- [ ] Add `test/release/release_configuration_test.dart` that fails if Android or iOS still use `com.example.networthy`.
- [ ] Run `flutter test test/release/release_configuration_test.dart` and confirm it fails on the placeholder identifiers.
- [ ] Change Android namespace/applicationId and iOS bundle identifier to `tw.pixelpanda.networthy`.
- [ ] Move/update Android `MainActivity.kt` package to match.
- [ ] Re-run the release configuration test and confirm it passes.

### Task 2: Release acceptance documentation

- [ ] Add `docs/verification/milestone-9-release-acceptance.md` with automated gates, manual checklist, known V1 limitations, and final build artifact locations.
- [ ] Update `README.md` with release acceptance commands.

### Task 3: Final verification

- [ ] Run `flutter test`.
- [ ] Run `flutter analyze`.
- [ ] Run `flutter build apk --release`.
- [ ] Run an iOS installable build command suitable for this local environment.
- [ ] Run `git diff --check`.
- [ ] Commit and push.

