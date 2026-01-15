# Test uplift plan — 80% coverage + integration + pipeline

Created at: 2026-01-14T07:44:19Z
Last updated at: 2026-01-15T00:00:00Z

## Goal

Build a scalable testing foundation and raise *meaningful* line coverage to **≥ 80%** (measured on `coverage/lcov_filtered.info`), while adding strong DB-backed integration coverage and reliable local-stack pipeline coverage.

This plan is split into phases. Each phase is designed to be independently shippable, and to keep the repo usable throughout the uplift.

## Baseline (measured)

- Filtered overall coverage (from `coverage/lcov_filtered.info`): **29.6%** (LH=5309 / LF=17933)
- Filtered per-layer coverage (lib/*):
  - `lib/domain`: 49.52%
  - `lib/data`: 27.80%
  - `lib/presentation`: 21.19%
  - `lib/core`: 4.16%

## Existing architecture & conventions to build on

- Testing architecture: `doc/architecture/TESTING_ARCHITECTURE.md`
- Suite selection (tags + presets): `dart_test.yaml`
- Coverage filtering (what counts): `tool/coverage_filter.dart`
- Pipeline tests exist and are already tagged `pipeline`: `test/integration_test/powersync_supabase_pipeline_test.dart`

## Phase index

- Phase 00: Measurement, suite entrypoints, and coverage gates (completed)
- Phase 01: Test architecture foundations (wrappers, helpers, contracts) (completed)
- Phase 02: Domain coverage uplift (highest ROI)
- Phase 03: Data layer + repository integration coverage (offline-first)
- Phase 04: Presentation/BLoC coverage uplift (avoid flaky UI tests)
- Phase 05: Local-stack pipeline coverage (smoke + extended)
- Phase 06: Coverage hardening + maintainability (final push to ≥80%)

## Execution policy (compile-first, low-churn)

This plan optimizes for **tests that compile** and a low-feedback-cost workflow.

- During a phase: iterate with `flutter analyze` (and fixing compile errors) as often as needed.
- During a phase: avoid running tests/coverage repeatedly while scaffolding.
- End of phase: run **exactly one** test command (or one coverage command) to validate the phase.
- Phase 01: use the existing generated coverage artifacts (`coverage/lcov_filtered.info`) to choose targets; do not regenerate coverage in that phase.

## Coverage ramp (to avoid perma-`--no-verify` culture)

Because the baseline is far from 80%, move the coverage gate in steps:

- Gate 1: 35%
- Gate 2: 45%
- Gate 3: 55%
- Gate 4: 65%
- Gate 5: 75%
- Gate 6: 80%

Recommended *eventual* per-layer minimums (filtered):

- `lib/domain`: ≥ 85%
- `lib/data`: ≥ 80%
- `lib/presentation`: ≥ 70% (mostly via BLoCs)
- `lib/core`: case-by-case (test real logic; exclude pure wiring with justification)

## How to run

- Fast loop: `flutter test --preset=fast`
- Broader: `flutter test --preset=quick`
- DB coverage: `flutter test --preset=database`
- Excluding pipeline: `flutter test --preset=no_pipeline`
- Pipeline (local stack only, opt-in): see `test/integration_test/powersync_supabase_pipeline_test.dart`

Coverage generation:

1) `flutter test --coverage`
2) `dart run tool/coverage_filter.dart`
3) (optional) `genhtml coverage/lcov_filtered.info -o coverage/html`

## Notes

- This plan assumes tests are **hermetic by default** and do not require network access.
- Pipeline tests are intentionally **opt-in** and run only against local stack endpoints.
