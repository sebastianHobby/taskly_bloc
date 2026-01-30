# Testing -- Guide

> Audience: developers + architects
>
> Scope: the **structure** of tests in this repo -- taxonomy, execution model,
> taxonomy, and enforcement. Operational "how to run tests" details belong in
> `test/README.md` so this doc stays stable as tooling evolves.

This document is **descriptive**. The single normative source of testing rules
is:
- [../INVARIANTS.md](../INVARIANTS.md) (Testing invariants)

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
- Do not let tests become an architectural escape hatch (tests should follow
  the same layering boundaries as production code; see
  [../INVARIANTS.md](../INVARIANTS.md)).

## 3) Testing rules (where they live)

All non-negotiable rules live in:
- [../INVARIANTS.md](../INVARIANTS.md)
  - Test hang safety for reactive code
  - Testing invariants (TG-001...TG-009)
  - Testing taxonomy (directory contract)

## 4) Taxonomy: where tests live (directory contract)

This contract is intended to keep tests discoverable and enforceable. The
canonical table lives in:

- [../INVARIANTS.md](../INVARIANTS.md#34-testing-taxonomy-directory-contract-strict)

Notes:

- "local DB only" means no network; use in-memory or ephemeral on-disk DB.
- Pipeline tests self-skip if the environment is not pointing at a local stack.

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
- `packages/taskly_data/test/unit/errors/failure_guard_seed_test.dart`
  - Demonstrates data-layer failure mapping via `FailureGuard`.
  - Uses safe wrappers: `testSafe` (TG-002).

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

#### 6.2.1 Coverage goals (planning targets)

These targets guide prioritization and help keep coverage aligned with the
testing standards in `INVARIANTS.md`. They are directional, not hard gates.

- `taskly_core`: 90%+ (core utilities and cross-cutting infrastructure)
- `taskly_domain`: 70%+ (business semantics and domain services)
- `taskly_data`: 60%+ (repositories, mappers, sync helpers)
- `taskly_bloc` (app/presentation): 60%+ (BLoCs, screen orchestration)
- `taskly_ui`: 50%+ (widget and golden tests for shared UI)

#### 6.2.2 Test mix standards (by layer)

- **Unit**: domain rules, validators, mapping, and BLoC reducers/state
  transitions.
- **Widget**: UI composition, BLoC wiring, and critical shared UI components.
- **Repository/Integration**: persistence behavior against real local DB.
- **Pipeline**: local Supabase/PowerSync flows, offline → online sync,
  and round-trips of critical entities.

## 7) Enforcement and guardrails

Guardrails should be cheap, predictable, and aligned with the invariants.
Enforcement targets include:

- Directory <-> tag contract (TG-005-A)
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


