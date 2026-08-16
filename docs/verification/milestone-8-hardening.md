# Milestone 8 Verification: Security, Privacy, Performance, Accessibility

## Automated gates

Run:

```sh
FLUTTER_SUPPRESS_ANALYTICS=true flutter test test/security test/performance test/presentation/accessibility
FLUTTER_SUPPRESS_ANALYTICS=true flutter test
FLUTTER_SUPPRESS_ANALYTICS=true flutter analyze
```

Expected result:

- No raw logging APIs in `lib/`.
- Primary controls expose screen-reader labels.
- Primary controls meet the 48dp touch-target baseline.
- Main flows render under common enlarged text scaling.
- Monthly overview aggregation for 10,000 rows completes under 1 second.

## Release logging policy

The release build must not emit accounting amounts, notes, database paths, encryption key material, authentication results, or repository errors containing raw local data.

Current policy:

- Production source under `lib/` uses no raw `print`, `debugPrint`, or `log` calls.
- Future diagnostic logging must be routed through an explicit safe adapter and must log only event names or coarse failure classes.
- Release diagnostics must default to no sensitive payloads.

## Database plaintext inspection

Follow [Database Plaintext Inspection Procedure](../security/database-plaintext-inspection.md).

Pass criteria:

- Database, WAL, journal, SHM, and SQLite temp files do not contain marker note, amount, or category plaintext.

## Airplane-mode manual test script

1. Enable airplane mode before launching the app.
2. Launch Networthy.
3. Add an expense transaction with a unique note, for example `M8_OFFLINE_ADD`.
4. Confirm it appears on the overview recent list.
5. Open the records tab and confirm the same transaction is visible.
6. Edit the transaction amount or note.
7. Confirm overview and records both show the edited value.
8. Delete the transaction from the records tab and confirm it disappears.
9. Keep airplane mode enabled for the whole script.

Pass criteria:

- Add, view, edit, and delete work without network connectivity.
- No screen asks for network access during the flow.

