# Milestone 8 Implementation Plan: Security, Privacy, Performance, Accessibility Hardening

## Scope

Verify the non-functional release gates before release packaging:

- Sensitive logging audit.
- Release-build logging configuration.
- Database plaintext inspection procedure.
- Accessibility labels for primary actions.
- Touch target sizing review.
- System text scaling review.
- Performance measurement for homepage-scale monthly data.
- Airplane-mode manual test script.

## Tasks

1. Add automated sensitive logging audit.
   - Scan `lib/` source for raw logging APIs.
   - Allow logging only through a documented safe release policy if needed later.

2. Add primary-control accessibility tests.
   - Verify screen-reader labels for add transaction, month navigation, records tab, delete record, app lock, and clear data controls.
   - Verify primary tappable controls meet the 48dp minimum touch target baseline.

3. Add text-scaling tests for main flows.
   - Exercise overview, records, settings, and transaction form at common enlarged text scale.
   - Fail on render/layout exceptions.

4. Add homepage-scale performance test.
   - Generate 10,000 local transactions.
   - Measure monthly summary calculation, the homepage's primary data aggregation dependency.
   - Keep automated threshold at 1 second.

5. Add manual verification documentation.
   - Database/WAL/journal/temp plaintext inspection procedure.
   - Release logging policy.
   - Airplane-mode add/view/edit/delete script.
   - M8 acceptance checklist and verification commands.

6. Verify and publish.
   - Run focused tests.
   - Run full Flutter test suite.
   - Run analyzer.
   - Commit and push.

