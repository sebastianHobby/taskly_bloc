# Architecture Invariants (Normative)

> Audience: developers + architects
>
> Scope: the non-negotiable rules we follow to keep Taskly clean, robust, and
> maintainable.
>
> These are **invariants** (rules), not feature requirements.

## 0) How to use this document

- When adding new code, keep changes compliant with these invariants.
- When refactoring legacy areas, move them toward these invariants.
- If an invariant blocks progress, treat it as an explicit decision: document
  why, scope the exception narrowly, and plan removal.

## 1) Layering and dependency direction

### 1.1 Dependency direction (strict)

- Allowed dependency direction is: **presentation → domain → data**.
- The reverse direction is forbidden:
  - domain must not import presentation
  - data must not import domain implementation details from presentation

Guardrail:

- Central runner: [tool/guardrails.dart](../../tool/guardrails.dart)
- Layering check: [tool/no_layering_violations.dart](../../tool/no_layering_violations.dart)
  - Escape hatch (use sparingly): `// ignore-layering-guardrail`

### 1.2 `shared/` and `core/` placement

- `shared/` is for broadly reusable building blocks that are not screen/UI
  specific.
- `shared/` must not depend on `presentation/`.
- `core/` is for cross-cutting infrastructure (DI wiring, platform integration,
  logging, etc.).

## 2) Presentation boundary (BLoC-only)

- Widgets/pages must not call repositories/services directly.
- Widgets/pages must not subscribe to domain/data streams directly.
- BLoCs own subscriptions and expose widget-ready state.

Allowed exceptions (narrow): ephemeral UI-only state (controllers, focus nodes,
animations, scroll controllers) that does not represent domain/data state.

See: [doc/architecture/README.md](README.md)

## 3) State management standard

- Application state is **BLoC-only**.
- Do not introduce new Cubits for domain/app state.
- Keep navigation/snackbar/dialog side-effects driven by presentation patterns
  that do not leak domain/data dependencies.

## 4) Write boundary and atomicity

### 4.1 Single write boundary per feature

- All domain writes must go through a small set of explicit **use-cases** (or an
  equivalent feature write facade) rather than ad-hoc writes from screens.

### 4.2 Transactionality

- If a write touches multiple tables, it must be **atomic** using a database
  transaction.
- Never rely on “eventual consistency inside the local DB” for a single user
  action.

## 5) Offline-first + PowerSync constraints

### 5.1 Local source of truth

- Local SQLite (PowerSync-backed) is the primary source of truth for UI.

### 5.2 SQLite views: no local UPSERT against PowerSync tables

PowerSync applies schema using SQLite views. SQLite cannot UPSERT views.

- Do not use Drift UPSERT helpers against tables that are part of the PowerSync
  schema.
- Prefer update-then-insert or insert-or-ignore patterns.

See: [doc/architecture/POWERSYNC_SUPABASE_DATA_SYNC_ARCHITECTURE.md](POWERSYNC_SUPABASE_DATA_SYNC_ARCHITECTURE.md)

Guardrail: the repo includes a lightweight check to prevent accidental usage.

- Script: [tool/no_powersync_local_upserts.dart](../../tool/no_powersync_local_upserts.dart)
  - Scans `lib/data/` and `packages/taskly_data/lib/` for common Drift UPSERT
    patterns (`insertOnConflictUpdate`, `insertAllOnConflictUpdate`,
    `insertOrReplace`, `InsertMode.insertOrReplace`).
  - Escape hatch (use sparingly): add `// ignore-powersync-upsert-guardrail` in
    a file to skip it.
- CI: enforced in GitHub Actions analyze job:
  - [.github/workflows/main.yaml](../../.github/workflows/main.yaml)
    (step: "Run repo guardrails")

## 6) Sync conflicts/anomalies policy

Conflicts are treated as correctness bugs, not “merge inputs”.

- The system must not silently overwrite on deterministic-ID conflicts.
- **Release behavior**: log a SEVERE/ERROR event with enough context to debug
  (entity type/id, occurrence keys, operation, stack trace).
- **Debug behavior**: after logging, throw an error to fail fast.

This policy is intentionally logging-first (not persisted), per current decision.

## 7) Time model and clocks

- Domain/data must not call `DateTime.now()` directly.
- Time must come from an injected time/clock service.
- Day-key and date-only conversions must be centralized (no ad-hoc conversions
  inside screens).

Guardrail:

- Script: [tool/no_datetime_now_in_domain_data.dart](../../tool/no_datetime_now_in_domain_data.dart)
  - Escape hatch (use sparingly): `// ignore-datetime-now-guardrail`

Recurrence + date-only semantics are further specified in:
- [doc/architecture/RECURRENCE_SYNC_CONTRACT.md](RECURRENCE_SYNC_CONTRACT.md)

## 8) Error handling across boundaries

- Domain-facing APIs should not leak raw exceptions as a control flow
  mechanism.
- Prefer typed failures (a `Result`/sealed failure model) so BLoCs can render
  deterministic error states.
- Reactive streams used for UI must not permanently terminate the UI due to a
  transient failure; map failures into state and provide explicit retry.

### 8.1 OperationContext for write correlation (strict)

All **user-initiated mutations** must be correlated end-to-end with an
`OperationContext`.

Normative rules:

- Presentation creates an `OperationContext` **at the boundary of the user
  intent** (typically in the BLoC event handler) and passes it down through
  domain write APIs into repository mutations.
- Any domain/data API that performs a mutation **must accept** an optional
  `OperationContext? context` parameter and **must forward it** when delegating
  to deeper layers.
- Data-layer write implementations must include the `OperationContext` fields
  (at minimum `correlationId`, `feature`, `screen`, `intent`, `operation`, and
  entity identifiers when present) in structured logs.
- When mapping errors to user-facing failures (e.g., `AppFailure`), prefer a
  consistent mapping that preserves the `correlationId` so failures and logs can
  be joined.

Rationale:

- Enables correlated structured logging across UI → domain → data.
- Makes failure mapping deterministic and debuggable without relying on ad-hoc
  log messages.

Implementation note (non-normative): presentation uses a factory helper to
generate `OperationContext` with a UUID v4 correlation id.

## 9) Documentation invariants

- Documents under `doc/architecture/` describe the **future-state** architecture.
- Legacy architecture details are centralized in:
  - [doc/architecture/LEGACY_ARCHITECTURE_OVERVIEW.md](LEGACY_ARCHITECTURE_OVERVIEW.md)
