# Testing — Architecture Summary

> Audience: developers + architects
>
> Scope (target state): the **architecture** of tests in this repo — invariants,
> taxonomy, and enforcement. Operational “how to run tests” details belong in
> `test/README.md` so this doc stays stable as tooling evolves.

## 1) Goals

Testing in Taskly optimizes for three outcomes:

1) **Fast feedback** for everyday development (unit + widget).
2) **High-confidence integration checks** for persistence and multi-component
   flows.
3) **Reproducible diagnostics** when something fails.

Core principles:

- **Layer-aligned tests**: test at the lowest layer that gives confidence.
- **Hermetic-by-default**: unit/widget tests do not require network.
- **Explicit real-stack boundaries**: pipeline tests are opt-in and tagged.
- **Artifact-first**: structured output exists to debug failures.

## 2) Non-goals

- Do not test Flutter framework behavior itself (prefer unit tests of our logic
  and widget tests of our composition/wiring).
- Do not make the fast loop depend on external services.
- Do not let tests become an architectural escape hatch (tests must follow the
  same layering boundaries as production code).

## 3) Testing Invariants (Normative)

This section defines **non-negotiable** rules for tests in this repo.

### TG-001-A — Hermetic-by-default for unit/widget tests

**Invariant:** tests tagged `unit` or `widget` must be hermetic. They must not:

- require network access
- touch a real Supabase/PowerSync stack
- require non-temp filesystem state
- depend on wall-clock time (`DateTime.now()`)

If the behavior requires real persistence/network, it must be tested under an
explicit tag such as `integration`, `repository`, or `pipeline`.

### TG-002-A — Mandatory safe wrappers for new tests

**Invariant:** new tests must use the repo’s “safe wrappers” instead of raw
`test()` / `testWidgets()` / `blocTest()`.

This is the primary defense against hung tests and ensures consistent timeout
and diagnostics behavior across the suite.

### TG-003-A — No leaked resources after a test

**Invariant:** every resource created in a test must be cleaned up
deterministically.

Examples include (non-exhaustive):

- `StreamController`s, stream subscriptions
- timers
- BLoCs
- database handles

Cleanup must be registered immediately using `addTearDown(...)` (or test helper
APIs built on top of it).

### TG-004-A — Presentation boundary holds in tests

**Invariant:** widget tests must not call repositories/services directly and
must not subscribe to domain/data streams from widget code.

In widget tests, repositories are mocked/faked behind the BLoC and the widget
renders BLoC state.

### TG-005-A — Tagging is directory-driven and enforceable

**Invariant:** test type is determined by directory and must align with tags
and presets.

If a test does not fit the directory contract, move it or change its tag.

### TG-006-A — OperationContext propagation is verified for write flows

**Invariant:** any test that validates a user-initiated write path must assert:

- the `OperationContext` is created at the presentation boundary (typically the
  BLoC handler interpreting user intent), and
- the same context (correlation id) is passed through domain/data write APIs.

### TG-007-A — No `src/` deep imports in tests across packages

**Invariant:** tests outside a package must not import
`package:<local_package>/src/...`.

Tests may import only public APIs (`package:<pkg>/<pkg>.dart` or other `lib/`
entrypoints).

### TG-008-A — Flakiness policy: quarantine over retries

**Invariant:** flaky tests must be quarantined and kept out of default presets.

- Use an explicit tag (`flaky`) and exclude it from `fast/quick`.
- Do not enable global retries by default to mask nondeterminism.

### TG-009-A — Performance budgets are manually enforced per preset

**Invariant:** tests that meaningfully slow the developer loop must be tagged
`slow` and excluded from `--preset=fast`.

Use timing artifacts (for example `test/last_run.json`) to identify regressions.

## 4) Taxonomy: where tests live (directory contract)

This contract is intended to keep tests discoverable and enforceable.

| Directory | Primary tags | IO policy | Typical scope |
| --- | --- | --- | --- |
| `test/core/**` | `unit` | hermetic | cross-cutting pure logic |
| `test/domain/**` | `unit` | hermetic | domain rules, reducers, mapping |
| `test/presentation/**` | `widget` (or `unit` for pure BLoC/state) | hermetic | widget composition + BLoC wiring |
| `test/data/**` | `repository` / `integration` | local DB only | repository behavior against real DB |
| `test/integration/**` | `integration` | local DB only | multi-component flows without network |
| `test/integration_test/**` | `pipeline` | local stack only | local Supabase/PowerSync pipeline |
| `test/contracts/**` | `unit` | hermetic | shared expectations across impls |
| `test/diagnosis/**` | `diagnosis` (optional) | varies | repros/investigations (not default) |

Notes:

- “local DB only” means no network; use in-memory or ephemeral on-disk DB.
- Pipeline tests must self-skip if the environment is not pointing at a local
  stack.

### 4.1 Canonical templates (seed suite)

This repo intentionally keeps a small set of **seed tests** that act as
copy/paste templates for new tests and as living examples of the invariants
above.

Use these as the starting point when creating new tests:

- `test/domain/test_data_seed_test.dart`
  - Demonstrates TG-001 (no wall-clock): `TestData` defaults to
    `TestConstants.referenceDate`.
  - Demonstrates explicit time parameters in helpers (for example
    `isToday(now: ...)`).
  - Uses safe wrappers: `testSafe` (TG-002).

- `test/core/operation_context_seed_test.dart`
  - Demonstrates TG-006 (OperationContext propagation) using
    `TestOperationContextFactory`, `OperationContextSpy`, and
    `expectOperationContextForwarded`.
  - Uses safe wrappers: `testSafe` (TG-002).

- `test/presentation/ui/priority_flag_widget_test.dart`
  - Demonstrates TG-002 for widget tests using `testWidgetsSafe`.
  - Demonstrates hermetic widget testing patterns (no repository access;
    Material wrapper; explicit semantics assertions).

## 5) Suites, tags, and presets

Canonical tags, presets, timeouts, and `file_reporters` live in `dart_test.yaml`.
This document defines *policy*; `dart_test.yaml` defines *execution*.

## 6) Artifacts (diagnostics and coverage)

### 6.1 Structured test output

The suite writes structured output to:

- `test/last_run.json`

This is part of the architecture because it enables reproducible debugging.

### 6.2 Coverage

Coverage can be generated and filtered via repo tooling.

- Filter script: `tool/coverage_filter.dart`
- Summary script: `tool/coverage_summary.dart`

## 7) Enforcement and guardrails

Guardrails should be cheap, predictable, and aligned with the invariants.
Enforcement targets include:

- Directory ↔ tag contract (TG-005-A)
- No `src/` deep imports (TG-007-A)
- Preset exclusions for `flaky` and `slow` (TG-008-A, TG-009-A)

Layering invariants are already enforced by repo guardrails (see
`tool/no_layering_violations.dart`).

## 8) Anti-patterns (do not introduce)

- Widget tests that call repositories/services directly.
- Widget tests that use unbounded `pumpAndSettle()` for stream-backed UI.
- Tests that rely on `DateTime.now()` or environment time.
- Tests that leak stream subscriptions/timers/BLoCs.
- Tests that import `package:<local>/src/...` across packages.
