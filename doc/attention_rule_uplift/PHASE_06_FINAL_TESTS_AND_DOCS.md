# Phase 06 — Final: tests + documentation + deletion audit

## Outcome

- All relevant documentation under `doc/architecture/` is updated to match the new attention system.
- Tests are updated and executed (first time in this uplift).
- A concrete deletion audit exists proving no legacy replacement code remains.

## Scope

- Update docs.
- Update/add tests.
- Run tests.
- Produce deletion inventory.

## Constraints

- This is the first phase allowed to modify or run tests.
- Maintain big-bang integrity: if any legacy code remains, either:
  - delete it, or
  - explicitly justify why it is not legacy/replaced.

## Steps

1) Documentation rewrite

Update relevant docs under `doc/architecture/`:

- `ATTENTION_SYSTEM_ARCHITECTURE.md`
  - Rewrite end-to-end flow to reflect:
    - new domain model and query API
    - engine-based evaluation
    - runtime state table semantics
    - trigger handling (DB + temporal)
    - how screens consume attention streams

- `UNIFIED_SCREEN_MODEL_ARCHITECTURE.md`
  - Update any references to section-level attention evaluation if they changed.

- `POWERSYNC_SUPABASE_DATA_SYNC_ARCHITECTURE.md`
  - Ensure the new tables and sync rules are reflected (if the doc enumerates them).

2) Deletion audit

Create a short section (in this phase doc or a new file) listing:

- Deleted legacy files/folders
- The replacement component for each deletion
- Rationale

The requirement is: no backward-compatible parallel code.

3) Tests (now allowed)

- Update/add unit tests that validate:
  - runtime state behaviors (dismiss-until-hash-change, snooze)
  - engine stream reactivity on:
    - DB changes
    - temporal invalidation pulses

- Update/add integration tests only if needed.

4) Run tests

- Run targeted unit tests first.
- Then run the broader suite.

5) Final checkpoints

- Run: `flutter analyze`
- Confirm app builds/starts on the primary dev target.

## Exit criteria

- Docs match reality.
- Tests pass.
- No legacy-replaced code remains.
