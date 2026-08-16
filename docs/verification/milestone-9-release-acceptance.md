# Milestone 9 Verification: Release Acceptance

## Automated gates

Run:

```sh
FLUTTER_SUPPRESS_ANALYTICS=true flutter test
FLUTTER_SUPPRESS_ANALYTICS=true flutter analyze
FLUTTER_SUPPRESS_ANALYTICS=true flutter build apk --release
FLUTTER_SUPPRESS_ANALYTICS=true flutter build ios --simulator
```

Observed on 2026-08-16:

- `FLUTTER_SUPPRESS_ANALYTICS=true flutter test`: passed, 80 tests.
- `FLUTTER_SUPPRESS_ANALYTICS=true flutter analyze`: passed, no issues found.
- `FLUTTER_SUPPRESS_ANALYTICS=true flutter build apk --release`: passed, built `build/app/outputs/flutter-apk/app-release.apk`.
- `FLUTTER_SUPPRESS_ANALYTICS=true flutter build ios --simulator`: passed, built `build/ios/iphonesimulator/Runner.app`.

Release identifiers:

- Android namespace/applicationId: `tw.pixelpanda.networthy`
- iOS PRODUCT_BUNDLE_IDENTIFIER: `tw.pixelpanda.networthy`

## Final build artifacts

- Android release APK: `build/app/outputs/flutter-apk/app-release.apk`
- iOS simulator app bundle: `build/ios/iphonesimulator/Runner.app`

The Android APK is installable for local release acceptance. Store distribution still requires project-owned signing credentials outside this repo.

## Manual acceptance checklist

Record these results on at least one Android device/emulator and one iOS simulator/device before external distribution:

- [ ] iOS installs and launches.
- [ ] Android installs and launches.
- [ ] Airplane mode add/view/edit/delete works.
- [ ] Monthly totals and category totals match the entered transactions.
- [ ] Force close and restart preserves and decrypts data.
- [ ] App lock hides accounting data until authentication.
- [ ] Clear-all-data removes database, key, and settings.
- [ ] Major screens have no overflow at normal and common enlarged text scale.
- [ ] Screen reader identifies primary actions.
- [ ] Database, WAL, journal, SHM, and temp files contain no accounting plaintext.

## Known V1 limitations

These limitations intentionally match the design doc's V1 exclusions:

- No registration, login, backend, or cloud sync.
- No multi-user, family ledger, or multi-device support.
- No backup, restore, import, or export.
- No bank, credit-card, or invoice integrations.
- No budgets, recurring transactions, or notifications.
- No multi-account, multi-currency, or exchange-rate conversion.
- No custom categories, full-text search, or AI categorization.
- No investment or asset-management features.

## Release acceptance interpretation

Milestone 9 confirms this repository can produce local installable Android and iOS artifacts and that the MVP behavior is covered by automated and manual gates. App Store / Play Store submission remains a separate distribution task because it requires external credentials, store metadata, screenshots, and signing assets.
