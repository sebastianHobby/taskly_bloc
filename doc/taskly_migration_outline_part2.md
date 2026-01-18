# Taskly Rebuild + Package Extraction — Migration Outline (Part 2)

> Audience: developers + architects
>
> Purpose: expand the scope of the original migration outline with a concrete
> **Phase 2** target scope, sequencing, and decision points.
>
> This is still **not** an implementation plan. It is a scope + design outline
> to align work across contributors.
>
> Alignment: this document is written to match the future-state architecture
> under `doc/architecture/`.

---

## 0) Ground Rules (future-state invariants)

Phase 2 work must stay compliant with these invariants:

- **Layering direction is strict**: presentation 4 domain 4 data.
- **Presentation boundary is BLoC-only**:
  - widgets/pages must not call repositories/services directly
  - widgets/pages must not subscribe to domain/data streams directly
  - BLoCs own subscriptions and emit widget-ready state
- **Explicit routes and explicit screens** (no catch-all route to a runtime
  screen interpreter).
- **Offline-first**: local SQLite (PowerSync-backed) is UI source of truth.
- **PowerSync + SQLite views constraint**: avoid local UPSERT helper patterns
  against PowerSync schema tables (prefer update-then-insert or insert-or-ignore).
- **Time model**: no `DateTime.now()` in domain/data; use injected time service.
- **Time model (presentation)**: avoid direct `DateTime.now()` usage in presentation; use `NowService` and enforce via guardrails/pre-push.
- **Error handling**: do not leak raw exceptions as control flow across
  boundaries; map to typed failures and avoid permanently terminating UI streams.

---

## 1) Part 2 goals (Phase 2 outcome)

Phase 2 is considered done when:

1) The app shell continues to work across all platforms, with auth + sync
   functioning from day 1.
2) Remaining USM entrypoints are either removed or clearly isolated behind a
   short-lived strangler boundary, with explicit routes/screens taking over.
3) The extracted packages (`taskly_core`, `taskly_domain`, `taskly_data`) are
   the primary dependency surface for the app layer (with implementation hidden
   under each packages `lib/src`).
4) High-risk cross-cutting constraints are enforced consistently:
   - time model compliance
   - PowerSync view-safe write patterns
   - error taxonomy + reporting pipeline pattern
5) Tests and guardrails keep providing fast feedback and prevent regressions.

---

## 2) Phase 2 scope (workstreams)

### WS-1: Complete the USM strangler (explicit screens everywhere)

**Scope**
- Convert remaining shell routes still backed by USM `ScreenSpec` to explicit
  Flutter pages.
- Ensure all new/converted screens follow the BLoC-only presentation boundary.
- Standardize common feed rendering primitives (row model, row keys,
  grouping/headers) without reintroducing runtime screen interpretation.

**Non-goals (Phase 2)**
- A pixel-perfect redesign of every screen.
- Removing every shared widget; reuse is encouraged via shared widgets.

**Acceptance criteria**
- No top-level route relies on catch-all mapping.
- Converted screens do not directly watch DB streams in widgets.

**Key risks**
- Duplicate feed semantics across screens.
- Scope context duplication and inconsistent route param parsing.

**Note: shared UI extraction (`taskly_ui`)**

The migration outline (Part 1) defines a future `taskly_ui` package boundary
(DEC-096ADEC-099B):

- `taskly_ui` is **pure UI** (widgets, section renderers, UI-only ephemeral
  state).
- It must not own BLoCs, subscribe to domain/data streams, access
  repositories/use-cases, or perform `go_router` navigation.
- Interactivity is exposed via callbacks / UI events handled by app-owned BLoCs.
- It may depend on public domain identity types, but must not depend on data.

As of 2026-01-18, `packages/taskly_ui` exists and is the home for pure UI
primitives (and future entities/sections) that are reused across screens.
Continue migrating shared UI there incrementally while keeping screens,
routing, and BLoCs in the app.


### WS-2: Package API hardening (public surfaces + hidden internals)

**Scope**
- Define/lock public entrypoints for each extracted package.
- Remove (or block) deep imports from the app into package internals.
- Move remaining legacy implementations under `lib/src` inside packages.

**Acceptance criteria**
- App depends on package public APIs only.
- Guardrails prevent accidental deep imports.

**Key risks**
- Public API churn causing cascading refactors.
- Circular dependencies if package boundaries are not crisp.


### WS-3: Data stack lifecycle + sync correctness hardening

**Scope**
- Keep the explicit auth-gated session lifecycle:
  - pre-auth: local DB open + repositories usable
  - post-auth: PowerSync connect + upload/download enabled
- Normalize write patterns to be PowerSync-view-safe.
- Expand pipeline smoke/extended coverage for changed features.

**Acceptance criteria**
- No new local UPSERT patterns against PowerSync schema tables.
- Sync/connect/disconnect works across sign-in/out transitions.

**Key risks**
- Drift writes accidentally using UPSERT helpers.
- Upload queue wedging on schema mismatches.


### WS-4: Error taxonomy + reporting pipeline expansion

**Scope**
- Replicate the Auth vertical slice error handling approach across major
  user flows:
  - map data-layer exceptions to domain `AppFailure`
  - BLoCs own expected failures and render deterministic error states
  - unexpected/unmapped failures go through `AppErrorReporter`
- Standardize operation context propagation in intent handlers.

**Acceptance criteria**
- Domain-facing APIs do not leak raw exceptions for control flow.
- Reactive UI streams do not terminate permanently due to transient failures.

**Key risks**
- Over-centralizing UI error UX (should remain screen-owned for expected cases).
- Inconsistent retry semantics.

**Status (Jan 2026 snapshot)**
- Migrated beyond Auth: task/project/value editors, global tile actions (`ScreenActionsBloc`), global settings, focus setup, and values list.
- Remaining likely hotspots: Journal flows (add log, entry editor, tracker CRUD/prefs), feed-level blocks/Cubits that still catch raw exceptions and surface strings, and any background/maintenance write flows.


### WS-5 (optional / stretch): Recurrence foundations (if Phase 2 includes it)

**Scope (only if included in Phase 2)**
- Introduce recurrence tables + APIs per `RECURRENCE_SYNC_CONTRACT.md`.
- Ensure Supabase schema + PowerSync rules include new columns from day 1.
- Implement fail-soft occurrence expansion with structured warnings.

**Acceptance criteria**
- Range query contract is in place for scheduled occurrences.
- Deterministic IDs and conflict policy are implemented per invariants.

**Key risks**
- Large surface area + tight coupling to sync rules.
- Migration complexity across DB, sync rules, domain APIs, and UI.

---

## 3) Phase 2 sequencing (recommended high-level order)

This is sequencing guidance, not a step-by-step plan.

1) **Lock package public APIs** (so subsequent refactors dont churn surface).
2) **USM strangler conversions** route-by-route (explicit pages + BLoCs).
3) **Data stack hardening** (view-safe writes + session lifecycle consistency).
4) **Error handling rollout** feature-by-feature.
5) Optional: **Recurrence foundations** (only if explicitly included).

---

## 4) Phase 2 constraints and quality bar

- Always keep the architecture invariants in `doc/architecture/` as the source
  of truth.
- Prefer smallest vertical slices that are releasable without breaking sync.
- Testing expectations:
  - Small loop: presets like `fast` / `quick` for everyday changes.
  - DB-heavy work: `database` preset.
  - Pipeline changes: run tagged `pipeline` tests intentionally.

---

## 5) Open design questions (Batch 1 of N)

Please answer these 4 so I can refine the Phase 2 scope and update this outline.
Each includes options and a recommendation.

### Q1) What is the *primary* Phase 2 objective?

- **A)** Finish USM strangler first (explicit screens for all remaining routes),
  then package hardening.
- **B)** Package hardening first (public APIs + no deep imports), then screens.
- **C)** Parallelize: convert screens + harden packages opportunistically.

**Recommendation:** **B**. Locking public package surfaces early reduces churn
and makes the remaining refactors safer and more parallelizable.

**Decision:** **A** (finish USM strangler first).


### Q2) How strict should we be about removing the root `lib/domain` and
`lib/data` during Phase 2?

- **A)** Hard cutover: remove them as soon as package replacements exist.
- **B)** Gradual: allow temporary adapters in app-layer while migrating.
- **C)** Keep indefinitely: tolerate duplicates until the end of migration.

**Recommendation:** **A** (with small, explicit temporary adapters only when
necessary). This matches the existing DEC-002A intent and prevents long-lived
split-brain.

**Decision:** **A** (hard cutover).


### Q3) What failure contract should domain APIs expose to BLoCs?

- **A)** `Result<T, AppFailure>` (or equivalent sealed success/failure)
  everywhere; avoid throwing for expected failures.
- **B)** Mixed: use `Result` for write use-cases, allow throws for reads.
- **C)** Exception-driven: standardize exception types and catch in BLoC.

**Recommendation:** **A**. It matches the invariant dont leak raw exceptions
and makes UI state deterministic.

**Decision:** **A** (`Result<T, AppFailure>` contract for expected failures; unexpected/unmapped still go through `AppErrorReporter`).


### Q4) How should we stage the recurrence foundations relative to Phase 2?

- **A)** In Phase 2 scope (tables + sync rules + APIs + minimal UI).
- **B)** Pre-work only: schema + sync rules in Phase 2, code later.
- **C)** Out of Phase 2: keep Phase 2 focused on screens/packages/errors.

**Recommendation:** **C** unless you explicitly want recurrence to be a Phase 2
headline. Its a large cross-cutting change that can destabilize sync if rushed.

**Decision:** **A** (recurrence is in Phase 2 scope).

---

## 5.1) Open design questions (Batch 2 of N)

Please answer these next 4 so I can refine the Phase 2 scope and sequencing.

### Q5) What is the Phase 2 recurrence MVP surface area?

- **A)** Data + domain only: tables + sync rules + repositories/use-cases +
  occurrence expansion + scheduled occurrence watcher contract; UI stays on the
  existing scheduled implementation until Phase 3.
- **B)** Data + domain + Scheduled integration: implement the domain
  `watchScheduledOccurrences(rangeStartDay, rangeEndDay, scope?)` contract and
  switch Scheduled screen to it in Phase 2.
- **C)** End-to-end recurrence editing in Phase 2: add occurrence-aware editor
  mode (edit occurrence vs series) + actions (skip/reschedule/complete) with UI.

**Recommendation:** **B**. It yields real value and validates the recurrence
pipeline without committing to the full editor UX surface immediately.

**Decision:** **B + C** (Scheduled switches to `watchScheduledOccurrences(...)` in Phase 2, and recurrence editing UX is also in Phase 2 scope).

**Status:** **B completed** — the domain `watchScheduledOccurrences(...)` contract is implemented and the Scheduled screen has been migrated to it (DEC-253A).


### Q6) How do we stage Supabase schema + PowerSync sync-rules changes for recurrence?

- **A)** Schema/rules first: land Supabase migrations + PowerSync sync rules
  before app code depends on them; app code ships after.
- **B)** Ship together: land schema/rules and app changes in the same
  release window; tests enforce ordering.
- **C)** App first: ship app code with feature flags; enable schema/rules
  later.

**Recommendation:** **A**. It avoids partial rollout states and reduces the
chance of wedging the upload queue on unknown columns/constraints.

**Decision:** **A** (schema + sync rules first).

**Confirmation gate:** Before implementing Phase 2 recurrence code that depends
on new columns/tables, confirm (explicitly) that:

- Supabase migrations for recurrence tables/constraints have been applied
  (local + target environments).
- PowerSync replication + `supabase/powersync-sync-rules.yaml` include the new
  tables/columns.
- Local pipeline tests are ready to exercise the new schema.


### Q7) Where should occurrence expansion live (source of truth) for Phase 2?

- **A)** Domain-owned expansion: domain service reads base entities + completion
  + exceptions (via repositories) and emits occurrence-aware items.
- **B)** Data-owned expansion: implement as SQL/Drift queries (or hybrid) that
  return occurrence-aware rows directly.
- **C)** Presentation-owned expansion: BLoC expands occurrences from base
  entities.

**Recommendation:** **A**. It aligns with the domain owns business rules
direction and keeps presentation thin, while still allowing data to optimize
queries under repository APIs later.

**Decision:** **A** (domain-owned expansion).


### Q8) Deterministic ID strategy for recurrence writes (completion/exception rows)

- **A)** UUIDv5 everywhere with explicit namespaces per table/kind; treat
  duplicates as same logical event and follow the invariant conflict policy.
- **B)** Stable hash->UUID (custom) with the same canonical inputs; same
  conflict policy.
- **C)** Server-generated IDs only; client writes without deterministic IDs.

**Recommendation:** **A**. It matches DEC-262A/DEC-263A intent, keeps IDs
portable across devices, and is easy to validate in tests.

**Decision:** **A** (UUIDv5 + explicit namespaces).

---

## 5.2) Open design questions (Batch 3 of N)

### Q9) How should the recurrence editor UX ship within Phase 2?

- **A)** Actions-only UI (skip/reschedule/complete) from Scheduled rows; series
  editing is Phase 3.
- **B)** Full occurrence-aware editor mode now (edit occurrence vs edit series)
  for tasks + projects.
- **C)** Hybrid: actions first, then series editing for tasks only (projects
  later).

**Decision:** **C**.


### Q10) Where should recurrence actions live in the UI?

- **A)** Inline row affordances (overflow menu per occurrence row).
- **B)** Bottom sheet / context menu launcher from row tap.
- **C)** Dedicated occurrence details screen that hosts actions and links.

**Decision:** **B**.


### Q11) How should we encode occurrence identity in routes for Phase 2?

- **A)** Query params only per contract: `entityType`, `entityId`, `localDay`,
  `tag` (no `instanceKey`).
- **B)** Path segment with an opaque encoded blob.
- **C)** Mixed: path for entity, query for occurrence fields.

**Decision:** **A**.

---

## 5.3) Open design questions (Batch 4 of N)

### Q13) Which screens do we prioritize for the USM strangler in Phase 2?

- **A)** Convert all top-level shell routes first, regardless of complexity.
- **B)** Convert highest-traffic journeys first.
- **C)** Convert easiest screens first to build momentum, then tackle hard ones.

**Decision:** **C**.


### Q14) How do we enforce no deep imports + stable package public APIs during Phase 2?

- **A)** Social contract + code review only.
- **B)** Guardrails/analyzer rules to block `package:taskly_*/src/...` deep imports.
- **C)** Both: guardrails + a defined public API checklist per package.

**Decision:** Already implemented for deep-import blocking via repo guardrails
(`tool/no_local_package_src_deep_imports.dart` run by `tool/guardrails.dart`).
Public API checklist remains optional process/documentation.


### Q15) How should we handle shared UI building blocks previously provided by USM templates?

- **A)** Duplicate minimal UI per screen for speed.
- **B)** Create shared presentation components (widgets + small helpers) used
  by explicit screens, not specs.
- **C)** Keep USM template widgets and call them from explicit screens as a bridge.

**Decision:** **B**.


### Q12) Whats the Phase 2 policy for USM remnants while recurrence work lands?

- **A)** No new USM: only remove/strangle; recurrence UI must be explicit
  screens/widgets/BLoCs.
- **B)** Temporary USM bridge allowed for recurrence screens only.
- **C)** USM allowed as long as routing is explicit.

**Decision:** **A**.

---

## 6) Notes / edits log

- Created at: 2026-01-17 (UTC)
- Last updated at: 2026-01-17 (UTC)
