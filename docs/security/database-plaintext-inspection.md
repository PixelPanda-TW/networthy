# Database Plaintext Inspection Procedure

Use this procedure for release-like verification that accounting plaintext is not visible in the encrypted database artifacts.

## Scope

Inspect all SQLite artifacts created by the app:

- `networthy.db`
- `networthy.db-wal`
- `networthy.db-shm`
- `networthy.db-journal`
- temporary SQLite files in the same app documents directory

## Procedure

1. Install a release-like build on a simulator or device.
2. Add transactions with distinctive marker values:
   - note: `M8_SECRET_NOTE_MARKER`
   - category: normal app category such as `expense.food`
   - amount: a distinctive amount such as `987654`
3. Fully close the app so SQLite flushes pending work.
4. Copy all database artifacts from the app documents directory into `build/verification/`.
5. Search bytes, not decoded SQL rows, for each marker:
   - `M8_SECRET_NOTE_MARKER`
   - `987654`
   - any intentionally unique note/category marker used during the test
6. The gate passes only when no database, WAL, journal, SHM, or temp artifact contains those plaintext markers.

## Current automated coverage

Milestone 1 already verifies encrypted database creation, reopen, and wrong-key rejection in `test/data/spike/encrypted_database_spike_test.dart`.
Milestone 8 keeps this manual artifact-inspection procedure as the release gate because the exact artifact paths differ between iOS simulator, Android emulator, and physical devices.

