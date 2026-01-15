# Phase 01 — Test architecture foundations (wrappers, helpers, contracts)

Created at: 2026-01-14T07:44:19Z
Last updated at: 2026-01-15T00:00:00Z

## AI instructions (required)

- Run `flutter analyze` for this phase.
- Fix any `flutter analyze` errors/warnings **caused by this phase’s changes** by the end of the phase.
- Review `doc/architecture/` before implementing and keep architecture docs updated if this phase changes architecture.
- During the phase: focus on tests that **compile**; avoid repeatedly running test/coverage commands while scaffolding.
- End of phase: run **exactly one** test command to validate compilation and basic correctness.
- Use the existing generated coverage artifacts (`coverage/lcov_filtered.info`) for prioritization; do not regenerate coverage in this phase.

## Intent

Make adding tests cheap and reliable:
- prevent hangs/timeouts
- reduce boilerplate
- make tests easier to read and debug

This phase is foundational: it should not be blocked on achieving major coverage gains.

## Status

Completed (core foundations already exist in the repo).

## What’s in place now

- Safe wrappers and helpers are centralized under `test/helpers/` and re-exported via `test/helpers/test_imports.dart`.
- Contract suite helpers exist (`test/helpers/contract_test_helpers.dart`) and multiple repository contract suites are already present under `test/contracts/`.
- Deterministic time and fixtures exist (`test/helpers/test_clock.dart`, `test/fixtures/test_data.dart`).

## How to use generated LCOV in this phase

Use the existing filtered report to pick the next “foundation” targets (without re-running coverage):

- `dart run tool/coverage_summary.dart` (reads `coverage/lcov_filtered.info` by default)

## End-of-phase verification (run once)

- `flutter test --preset=fast`

## Notes

- This phase should not introduce new architectural patterns without explicit confirmation.
- Prefer incremental refactors: do not rewrite the entire test suite.
