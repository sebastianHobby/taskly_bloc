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

### 1.3 Package public API boundary (strict)

Dart package convention is a visibility boundary:

- `lib/` is public API.
- `lib/src/` is implementation detail.

Normative rules:

- Code outside a package must not import or export `package:<pkg>/src/...`.
- Each package must expose a clean public surface via `lib/` entrypoints
  (typically a barrel like `package:<pkg>/<pkg>.dart` or feature barrels).
- If another package needs something that currently lives under `lib/src/`, do
  not deep-import it.
  - Prefer promoting the symbol into the package's public API (`lib/`), or
  introducing an explicit shared abstraction in an appropriate shared package.
  - If a narrow exception is unavoidable, document it and keep it temporary.

Guardrail:

- Script: [tool/no_local_package_src_deep_imports.dart](../../tool/no_local_package_src_deep_imports.dart)
  - Fails on `import`/`export` of `package:<local>/src/...` from outside that
    local package.

## 2) Presentation boundary (BLoC-only)

- Widgets/pages must not call repositories/services directly.
- Widgets/pages must not subscribe to domain/data streams directly.
- BLoCs own subscriptions and expose widget-ready state.

Allowed exceptions (narrow): ephemeral UI-only state (controllers, focus nodes,
animations, scroll controllers) that does not represent domain/data state.

### 2.1 Shared UI extraction: `packages/taskly_ui` (strict)

Reusable UI components (widgets and small UI helpers) must live in
`packages/taskly_ui`.

Normative rules:

- `taskly_ui` must remain **pure UI**: no BLoCs/Cubits, no repositories/services,
  no use-cases, no DI, and no stream subscriptions.
- `taskly_ui` must not perform navigation or import app routing (`go_router`,
  `Routing`, etc.).
- Reusable UI must follow **data in / events out** APIs (props + callbacks).
- App code must not deep-import `taskly_ui` internals; import only
  `package:taskly_ui/taskly_ui.dart`.

Allowed exceptions (narrow):

- Ephemeral UI-only state that is inherently screen-local (controllers, focus
  nodes, animations, scroll controllers).
- Feature-unique widgets that are not reused (keep them inside the owning
  feature/screen; promote to `taskly_ui` if they become shared).
- Short-lived experiments/prototypes that are explicitly scoped and removed or
  extracted if they become permanent.

See: [doc/architecture/README.md](README.md)

See also: [BLOC_GUIDELINES.md](BLOC_GUIDELINES.md)

### 2.2 UI composition model (4-tier) (strict)

All UI in Taskly must follow a consistent composition vocabulary so shared UI
stays reusable and feature screens remain easy to reason about.

Normative rules:

- All reusable UI must be expressed using the **4-tier model**:
  - **Primitives**: tiny, style-driven building blocks (buttons, chips,
    spacing, text styles). No domain meaning.
  - **Entities**: UI for a single domain concept (for example, a “Task tile”
    visual), still **render-only** with callbacks.
  - **Sections**: composed blocks that group primitives/entities into a
    reusable chunk (empty/error sections, list headers, etc.). Must remain
    presentation-agnostic (no routing/state).
  - **Screens/Templates**: full pages and flows (routing, BLoC wiring, effects,
    feature-specific orchestration). These live in the app presentation layer.

- Code placement is strict:
  - **Primitives / Entities / Sections** that are shared across screens/features
    must live in `packages/taskly_ui`.
  - **Screens/Templates** must live in the app presentation layer (for example
    under `lib/presentation/`). They must not live in `packages/taskly_ui`.

- Shared UI APIs must be **data in / events out**:
  - render from immutable inputs (props/view-models)
  - report user intent only via callbacks
  - no app side-effects (no writes, no navigation)

- `taskly_ui` must remain pure UI (see 2.1): no BLoCs/Cubits, repositories,
  services/use-cases, DI wiring, or stream subscriptions; no routing/navigation.

- `taskly_ui` source layout must reflect the 4-tier taxonomy:
  - `packages/taskly_ui/lib/src/primitives/`
  - `packages/taskly_ui/lib/src/entities/`
  - `packages/taskly_ui/lib/src/sections/`
  - (Reserved) `packages/taskly_ui/lib/src/templates/` for layout-only
    scaffolding that remains routing/state-free.

Allowed exceptions (narrow):

- Ephemeral UI-only state that is inherently screen-local (controllers, focus
  nodes, animations, scroll controllers).
- Feature-unique widgets that are not reused (keep in the owning feature).
- Explicitly short-lived prototypes/experiments that are scoped and removed or
  extracted if they become permanent.

## 3) State management standard

- Application state is **BLoC-only**.
- Do not introduce new Cubits for domain/app state.
- Keep navigation/snackbar/dialog side-effects driven by presentation patterns
  that do not leak domain/data dependencies.

### 3.1 Reactive subscription lifecycle (strict)

Reactive streams used to derive UI state must be bound to BLoC event-handler
lifecycle.

Normative rules:

- Do not call `emit(...)` from any asynchronous callback that may outlive the
  current event handler.
  - Examples: stream `.listen(...)` callbacks, `future.then(...)`, timers.
- For stream-backed screens, bind streams using `await emit.forEach(...)` or
  `await emit.onEach(...)`.
- After any `await` point, do not emit unless the handler is still active.
  - Check `if (emit.isDone) return;` before emitting.

Rationale:

- Prevents "emit was called after an event handler completed normally" crashes.
- Makes cancellation/retry deterministic.

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
