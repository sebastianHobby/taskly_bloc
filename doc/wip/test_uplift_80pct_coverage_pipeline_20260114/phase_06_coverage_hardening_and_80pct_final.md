# Phase 06 — Coverage hardening and final push to ≥80%

Created at: 2026-01-14T07:44:19Z
Last updated at: 2026-01-15T00:00:00Z

## AI instructions (required)

- Run `flutter analyze` for this phase.
- In this **last phase**, fix **any** `flutter analyze` error or warning (regardless of whether it is related to this phase).
- Review `doc/architecture/` before implementing and keep architecture docs updated if this phase changes architecture.
- During the phase: focus on tests that compile; avoid repeatedly running test/coverage commands while scaffolding.
- End of phase: run **exactly one** coverage command to validate the final ≥80% target.

## End-of-phase verification (run once)

Recommended VS Code task (coverage + filter + summary, no pipeline):

- `flutter_test_coverage_no_pipeline`

## Intent

Finish the uplift:
- reach and stabilize ≥80% filtered line coverage
- ensure suites remain fast and maintainable
- ensure team can keep the bar without heroics

## Deliverables

### 1) Raise coverage gate to 80%

- Move the ramp to the final gate (≥80%).
- Keep per-layer minimums enforced (or at least reported) so coverage stays meaningful.

### 2) Kill low-value coverage work

Avoid tests that only confirm:
- generated code
- pure freezed models with no logic
- configuration-only files

If something must be excluded from coverage, document why and keep the exclude pattern narrow.

### 3) Flake hardening

- Identify flaky tests (from reports / reruns) and fix root causes:
  - unbounded waits
  - racey stream subscriptions
  - reliance on real clock/time
  - cross-test shared state

### 4) Maintenance guardrails

- Add a lightweight “new tests checklist” in `test/README.md`:
  - safe wrappers
  - deterministic time
  - cleanup via `addTearDown`
  - avoid `pumpAndSettle` with stream-driven widgets

## Acceptance criteria

- Overall filtered coverage: ≥80%
- Domain/data/presentation per-layer minimums met (final values agreed)
- Pipeline smoke is reliable on local stack
- `flutter analyze` is clean
