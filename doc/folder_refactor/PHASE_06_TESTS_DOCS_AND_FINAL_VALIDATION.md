# Phase 06 — Tests, Docs, and Final Validation (only phase that runs tests)

## Goal

Finish the refactor by updating test imports, updating architecture docs, and running tests.

This is the **only** phase where tests are run and fixed.

## Step 1 — Update tests (imports/paths)

- Update imports under `test/**` to the new paths created in Phases 01–05.
- Avoid refactoring test structure unless required.

## Step 2 — Update architecture docs (paths)

Update the “Where Things Live” sections to reflect the new folder structure:

- `doc/architecture/UNIFIED_SCREEN_MODEL_ARCHITECTURE.md`
- `doc/architecture/ALLOCATION_SYSTEM_ARCHITECTURE.md`
- `doc/architecture/ATTENTION_SYSTEM_ARCHITECTURE.md`
- `doc/architecture/POWERSYNC_SUPABASE_DATA_SYNC_ARCHITECTURE.md`

Also update any other docs that reference moved paths (search for `lib/domain/models/screens`, `lib/domain/services/screens`, `lib/data/powersync`, etc.).

## Step 3 — Codegen (if needed)

If any models were touched or build outputs are stale:

- Run `dart run build_runner build --delete-conflicting-outputs`

## Step 4 — Analyze (required)

- Run `flutter analyze`
- Fix any errors/warnings.

## Step 5 — Run tests (allowed here)

Suggested order:

1. `flutter test` (unit/widget)
2. If desired/available: focused integration suites after unit/widget are clean.

Fix test failures in this phase only.

## Definition of done

- `flutter analyze` clean.
- `flutter test` clean.
- No leftover imports referencing pre-refactor paths.
- Docs accurately reflect new locations.
