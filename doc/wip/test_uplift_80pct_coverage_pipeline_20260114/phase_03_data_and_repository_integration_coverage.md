# Phase 03 — Data + repository integration coverage (offline-first)

Created at: 2026-01-14T07:44:19Z
Last updated at: 2026-01-15T00:00:00Z

## AI instructions (required)

- Run `flutter analyze` for this phase.
- Fix any `flutter analyze` errors/warnings **caused by this phase’s changes** by the end of the phase.
- Review `doc/architecture/` before implementing and keep architecture docs updated if this phase changes architecture.
- During the phase: focus on writing tests that compile; avoid repeatedly running test/coverage commands while scaffolding.
- End of phase: run **exactly one** test or coverage command to validate.

## End-of-phase verification (run once)

Recommended command (DB-backed confidence for offline-first):

- `flutter test --preset=database`

## Intent

Strengthen offline-first correctness by testing the real data stack locally, without network:
- Drift queries
- repository implementations
- watches/reactive streams

These tests should run under `flutter test --preset=database` and not require Supabase/PowerSync.

## Deliverables

### 1) One shared DB test harness

Create/standardize a helper that:
- creates a fresh DB per test or per group
- clears all tables safely
- provides deterministic IDs/time
- ensures full cleanup in `tearDown`/`tearDownAll`

Goal:
- repository tests are concise and consistent

### 2) Repository behavior matrix

For each repository implementation:
- CRUD correctness
- update semantics (partial updates, conflict behaviors)
- watch semantics (streams emit on changes, correct ordering)
- constraints behavior (invalid data rejected or corrected)
- transaction behavior if relevant

### 3) Contract suites run against real repositories

For repos that have contract suites from Phase 01:
- add a “real impl runner” variant tagged `repository` or `integration`

Current suites (fake + Drift-backed):
- Task repository
  - Fake: `test/contracts/repositories/task_repository_contract_fake_test.dart`
  - Drift-backed: `test/contracts/repositories/task_repository_contract_drift_test.dart` (tagged `repository`)
- Project repository
  - Fake: `test/contracts/repositories/project_repository_contract_fake_test.dart`
  - Drift-backed: `test/contracts/repositories/project_repository_contract_drift_test.dart` (tagged `repository`)
- Value repository
  - Fake: `test/contracts/repositories/value_repository_contract_fake_test.dart`
  - Drift-backed: `test/contracts/repositories/value_repository_contract_drift_test.dart` (tagged `repository`)

Canonical runs:
- Fast CI-style (fakes only): `flutter test --preset=fast test/contracts/repositories/`
- Repository-only: `flutter test --preset=repository test/contracts/repositories/`

## Acceptance criteria

- Every repo has at least one DB-backed integration test file.
- Contract suites run against both fakes and real implementations.
- `--preset=database` becomes a meaningful confidence suite.

## Risks & mitigations

- Risk: DB-backed tests become slow.
  - Mitigation: keep fixtures small, avoid unnecessary awaits, isolate tests.

- Risk: PowerSync schema limitations (views cannot UPSERT).
  - Mitigation: tests should mirror production patterns (update-then-insert, insert-or-ignore).
