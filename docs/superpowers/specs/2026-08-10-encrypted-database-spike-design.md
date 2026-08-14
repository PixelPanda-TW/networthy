# Encrypted Database Spike Design

**Source milestone:** Milestone 1 in `docs/superpowers/plans/2026-08-10-flutter-bookkeeping-mvp-milestones.md`

## Goal

Prove that the bookkeeping app can create, close, and reopen an encrypted local SQLite database on iOS and Android before product feature work starts.

## Scope

This spike creates the minimum Flutter project and encryption slice required to validate the storage strategy. It is not the final accounting schema and does not implement bookkeeping UI.

In scope:

- Generate a 256-bit database key using cryptographically secure randomness.
- Store the key in secure storage.
- Open an encrypted SQLite database before any schema query.
- Write and read a known plaintext marker through encrypted SQLite.
- Close and reopen the database with the same key.
- Reject a wrong key.
- Detect the state where a database exists but the key is missing, without replacing the key or overwriting the database.
- Document the iOS and Android manual file-inspection procedure for database, WAL, journal, and temp files.

Out of scope:

- Transaction domain model.
- Drift production schema.
- App screens.
- App lock.
- Backup, restore, sync, import, export, or account features.

## Provider Strategy

Start with SQLite3MultipleCiphers through Dart `sqlite3` 3.x build-hook compatible integration. This matches the main design doc direction and avoids adopting `sqlcipher_flutter_libs` as a required sqlite3 3.x dependency.

If SQLite3MultipleCiphers cannot be made stable on both platforms during this milestone, switch the spike to SQLCipher and document the reason. If neither provider can be validated without broadening scope, stop and report the blocker before product feature work.

## Architecture

The spike uses a narrow storage boundary:

- `SecureDatabaseKeyStore` owns generation, persistence, retrieval, and deletion of the database key.
- `EncryptedDatabaseSpike` owns encrypted SQLite open/validate/write/read/reopen behavior.
- `EncryptedDatabaseSpikeStatus` distinguishes success, wrong key, missing key, and provider validation failure.
- A small debug-only runner exposes the spike result in logs or a simple placeholder UI without printing sensitive values.

The code must not log the key, SQL bind values, marker text, full database path, notes, or amounts.

## Validation

Automated tests cover key-generation and missing-key state logic where platform dependencies can be replaced with test doubles.

Manual validation is required for the encryption provider:

1. Run the spike on iOS.
2. Confirm create, close, reopen, and wrong-key rejection.
3. Extract or inspect the app container.
4. Search database, WAL, journal, and temp files for the marker plaintext.
5. Repeat the same procedure on Android.

Milestone 1 is not complete until automated checks pass and manual verification results are recorded.

## Git Rule

When Milestone 1 is complete, run `git add`, `git commit`, and `git push` for the finished milestone work.
