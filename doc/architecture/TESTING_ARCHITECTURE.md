# Testing — Architecture Summary

> Audience: developers + architects
>
> Scope: how testing is structured in this repo (where tests live, how suites are
> selected, and how the existing tooling records artifacts and performance).

## 1) Executive Summary

Taskly’s testing architecture is designed around three goals:

1) **Fast feedback** for everyday development (unit + widget tests).
2) **High-confidence integration checks** for persistence and cross-component
   flows.
3) **Reproducible diagnostics** when something fails (recorded artifacts,
   consistent tagging, and stable conventions).

Core principles:

- **Layer-aligned tests**: write tests at the lowest layer that provides the
  needed confidence (domain → data → presentation).
- **Hermetic by default**: unit/widget tests should not require network access.
- **Explicit “real stack” boundaries**: tests that touch real DBs and local
  Supabase/PowerSync are tagged and run intentionally.
- **Artifact-first**: failure output and machine output are captured so failures
  can be debugged after the fact.

## 2) Where Things Live (Folder Map)

The test suite is organized under `test/` by layer and test type:

- `test/core/` — cross-cutting utilities/services
- `test/domain/` — domain models, queries, use-cases, business logic
- `test/data/` — repository and data-layer tests
- `test/presentation/` — BLoC and UI/widget tests
- `test/integration/` — integration tests (real DB or multi-component)
- `test/contracts/` — contract-style tests (shared expectations)
- `test/integration_test/` — integration_test-style / harness-style tests
- `test/helpers/` — shared test utilities (builders, contexts)
- `test/mocks/` — mock implementations
- `test/fixtures/` — test data builders and fixtures

For a detailed directory guide (and examples), see: `test/README.md`.

## 3) Test Types (and when to use which)

### 3.1 Unit tests (tag: `unit`)

Use unit tests when you can validate behavior without real IO:

- domain services and rules
- pure mapping/validation logic
- state machines and reducers

Expected characteristics:

- fast
- deterministic
- uses fakes/stubs/mocks as needed

### 3.2 Widget tests (tag: `widget`)

Use widget tests to validate UI composition and interaction logic without
spinning up full platform integrations:

- widget composition and layout behavior
- form validation
- BLoC/widget wiring

### 3.3 Integration tests (tag: `integration`)

Use integration tests when correctness depends on real persistence or multiple
components working together:

- repository implementations against a real/in-memory database
- multi-step domain workflows that cross boundaries

### 3.4 Pipeline / local stack tests (tag: `pipeline`)

These are “real stack” tests that may involve the local Supabase + PowerSync
pipeline (network + services). They are slower and should be run intentionally.

## 4) Tagging, Presets, and Selective Execution

The repo uses `dart_test.yaml` to define and standardize test tags and presets.

### 4.1 Common tags

- `unit` — fast, isolated tests
- `widget` — Flutter widget tests
- `integration` — slower tests with real DB or multi-component flows
- `repository` — DB-backed repository tests
- `slow` — known-slow tests
- feature tags (examples): `tasks`, `wellbeing`, `parity`
- `pipeline` — local-stack pipeline tests

### 4.2 Presets

Presets allow consistent suite selection (examples):

- `--preset=fast` — excludes `integration`, `slow`, `repository`
- `--preset=integration` — includes only `integration`
- `--preset=quick` — excludes `slow`
- `--preset=database` — includes `integration` and `repository`

This enables a stable “small loop / big loop” workflow:

- small loop: run `fast`
- big loop: run `quick` or `database`
- targeted confidence: run `integration` / `repository` / `pipeline`

## 5) Recorded Test Runs (Artifacts + Timings)

This repo includes a test recorder script:

- `tool/test_run_recorder.dart`

It runs `flutter test --machine`, captures raw output, computes per-test timings,
and writes one folder per run under:

- `build_out/test_runs/<timestamp>/`

Recorded artifacts include:

- `machine.jsonl` — raw `flutter test --machine` output
- `stderr.txt` — stderr output
- `summary.json` — structured summary (counts, failures, slowest tests)
- `summary.md` — human-readable summary

On failures, it can optionally capture an additional `-r expanded` rerun for
readable failure details (typically only for failing tests).

Recording runs is the default workflow in this repo because it preserves the
exact failure output and produces a structured timing summary that makes slow
tests obvious.

### 5.2 VS Code tasks

The workspace defines tasks for common runs:

- `flutter_test_record` — uses the recorder script
- `flutter_test_machine` — raw `flutter test --machine`
- `flutter_test_expanded` — human-readable failures

(These tasks are defined in the VS Code workspace configuration and should be
preferred over ad-hoc command variants.)

## 6) Coverage

Coverage is generated with Flutter’s built-in support and then optionally
filtered to match what the repo considers “meaningful coverage”.

### 6.1 Files excluded from coverage

The repo uses:

- `tool/coverage_filter.dart`

to filter `coverage/lcov.info` into:

- `coverage/lcov_filtered.info`

Typical exclusions include generated files (`*.g.dart`, `*.freezed.dart`),
localization, some infrastructure wiring, and declarative configuration.

## 7) Quality Bar and Conventions

## 7) Safe Test Patterns & Helpers (Preventing Hangs/Timeouts)

This repo contains a small set of “safe defaults” for writing tests.

The intent is to prevent the most common failure mode in Flutter tests:
**a test that never completes because a stream/animation keeps scheduling
frames**.

### 7.1 Use the safe test wrappers

Prefer the wrappers in `test/helpers/` over raw `test()` / `testWidgets()`:

- `testWidgetsSafe(...)` in `test/helpers/test_helpers.dart`
  - enforces a *hard* timeout on total test duration
  - provides a targeted error message when a widget test hangs
- `testSafe(...)` in `test/helpers/test_helpers.dart`
  - same idea for async unit tests
- `blocTestSafe(...)` in `test/helpers/bloc_test_patterns.dart`
  - wraps `bloc_test` with timeout protection (especially around `act()`)
  - initializes logging (`Talker`) for tests
- `testContract(...)` in `test/helpers/contract_test_helpers.dart`
  - contract tests should be fast and have a short, explicit timeout

### 7.2 Widget tests: avoid `pumpAndSettle()` when streams are involved

In this codebase, many widgets are backed by BLoCs that subscribe to streams.
Those streams can keep scheduling frames, which makes `pumpAndSettle()` hang.

Preferred patterns:

- Use `tester.pumpForStream()` (extension in `test/helpers/test_helpers.dart`)
  to process a bounded number of frames.
- Use `tester.pumpUntilFound(finder)` for “wait until X appears” assertions.

Helper entry points you’ll see in tests:

- `pumpLocalizedApp(...)` / `pumpLocalizedRouterApp(...)` in
  `test/helpers/pump_app.dart` (theme + l10n + MaterialApp)
- `WidgetTester.pumpApp(...)` / `pumpWidgetWithBloc(...)` in
  `test/helpers/widget_test_helpers.dart` (MaterialApp + localizations + BLoC)

### 7.3 BLoC tests: prefer state-driven streams that replay the latest value

Hangs in BLoC tests commonly come from race conditions with streams:

1) a test emits data into a stream controller
2) the bloc subscribes *after* the emit
3) the data is missed, so the expected states never arrive

Use stream helpers designed for this:

- `TestStreamController<T>` in `test/helpers/bloc_test_patterns.dart`
  - backed by `BehaviorSubject` so late subscribers still receive the latest
    value
- Stream waiting helpers in `test/helpers/bloc_test_helpers.dart`
  - `waitForStreamEmissions(...)`
  - `waitForStreamMatch(...)`
  - `expectStreamEmits(...)` / `expectStreamEmitsInOrder(...)`

### 7.4 Standard test setup templates

To reduce boilerplate and keep tests consistent, the repo provides reusable
templates:

- `TestData` (Object Mother) in `test/fixtures/test_data.dart`
  - central place to build domain objects with sensible defaults
- `registerAllFallbackValues()` in `test/helpers/fallback_values.dart`
  - required for `mocktail` when using `any()` with domain objects
  - typically called once per test file via `setUpAll(registerAllFallbackValues)`
- `BlocTestContext` in `test/helpers/bloc_test_helpers.dart`
  - pre-wires common repository mocks and default stubs

### 7.5 Concurrency, timeouts, and suite-level safety nets

Suite-wide defaults live in `dart_test.yaml`:

- global timeout safety net
- per-tag timeouts (`slow`, `pipeline`, etc.)
- concurrency configuration

If a test hangs, fix the underlying cause (unclosed streams, infinite
animations, missing stubs) rather than increasing timeouts.

---

## Appendix A — Typical Developer Loop

```text
1) flutter analyze
2) small loop: run preset=fast (unit/widget)
3) big loop (before merging): run preset=quick or database
4) when touching sync/persistence pipelines: run tag=pipeline intentionally
5) when a failure happens: use the recorder artifacts in build_out/test_runs/
```
