# Phase 04 — Presentation/BLoC coverage uplift (avoid flaky UI tests)

Created at: 2026-01-14T07:44:19Z
Last updated at: 2026-01-15T00:00:00Z

## AI instructions (required)

- Run `flutter analyze` for this phase.
- Fix any `flutter analyze` errors/warnings **caused by this phase’s changes** by the end of the phase.
- Review `doc/architecture/` before implementing and keep architecture docs updated if this phase changes architecture.
- During the phase: focus on writing tests that compile; avoid repeatedly running test/coverage commands while scaffolding.
- End of phase: run **exactly one** test or coverage command to validate.

## End-of-phase verification (run once)

Recommended command (presentation scope, keeps runtime reasonable):

- `flutter test --preset=fast test/presentation/`

## Intent

Raise meaningful coverage in `lib/presentation` without creating brittle widget tests.

Primary focus:
- BLoCs, reducers, and state machines

Secondary focus:
- a small number of widget smoke tests for critical rendering branches

## Strategy

### 1) BLoC test matrix (minimum per BLoC)

For each BLoC:
- initial state
- happy path event -> state sequence
- empty state
- error path
- retry path
- cancellation/dispose (no late emissions)

Prefer `blocTestSafe`.

### 2) Widget tests: only where they add unique confidence

Add widget tests only for:
- critical screen composition conditions
- navigation wiring
- “does not crash” smoke for key flows

Avoid:
- broad golden snapshot suites unless theming/fonts are stable and updates are intentional
- `pumpAndSettle()` in stream-driven widgets

### 3) Reduce mocking friction

Use:
- `BlocTestContext`
- fakes for stream sources
- shared fixture builders

## Targets

- Increase `lib/presentation` filtered coverage from ~21% toward **≥ 70%** over time.
- Do not block overall 80% on UI alone; domain+data should carry most of the uplift.

## Acceptance criteria

- Most presentation coverage comes from BLoC tests.
- Widget tests are few, stable, and focused.
