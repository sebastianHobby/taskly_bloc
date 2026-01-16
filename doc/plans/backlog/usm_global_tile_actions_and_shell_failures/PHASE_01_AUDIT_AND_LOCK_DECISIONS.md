# Plan Phase 01 — Audit & Lock Decisions (Option C + Shell Failure Policy)

Created at: 2026-01-16T00:00:00Z
Last updated at: 2026-01-16T04:36:01.7618276Z
## Goal
Lock the canonical design for a global, reusable USM tile action system (Option C) and align it with a single, app-shell-level failure surfacing policy for `ScreenActionsBloc`.

This phase is intentionally read-mostly and produces a repo-grounded checklist for implementation phases.

## Canonical decisions (locked)
  - **Domain owns capabilities** (and module-level capability overrides).
  - **Presentation owns intents + dispatcher** (intents are context-free data; dispatcher uses `BuildContext`).

## Repo alignment note (locked)
This plan targets the typed USM rendering path:
- `UnifiedScreenPageFromSpec` in `lib/presentation/screens/view/unified_screen_spec_page.dart`
- `ScreenItemTileBuilder` in `lib/presentation/screens/tiles/screen_item_tile_builder.dart`

The older `UnifiedScreenPage` (thin `ScreenBloc`) and widget-driven `EntityActionService` wiring are explicitly out-of-scope for this plan.

## Confirmed decisions (Q1–Q15) — locked
These decisions were confirmed interactively and should be treated as canonical
for implementation.

### Entity typing
- Reuse existing `EntityType` enum everywhere (no new `EntityKind`, no stringly-typed entity kinds).
  - Follow-up implementation lock (1A): migrate remaining `String entityType` surfaces
    (notably `AgendaItem` and `ScreenActionsDeleteEntity`) to `EntityType`.

### Tile intent surface
- Remove special-case completion callbacks (e.g. `onTaskToggle`); completion is expressed via a `TileIntent`.
- Completion intent must include explicit scope:
  - `entity` | `occurrence`
  - if `occurrence`: include both `occurrenceDate` and `originalOccurrenceDate`.

Lock (Q4A): For occurrence-scoped completion, always carry `originalOccurrenceDate` end-to-end (do not drop it at any layer).

Completion display policy (3A, locked):
- Checkbox state and UI completion truth use occurrence completion when present:
  - `entity.occurrence?.isCompleted ?? entity.completed`
- Completion intent scope is `occurrence` when `occurrence != null`, else `entity`.

### Capabilities (domain)
- Capabilities are computed per-item in domain (not in widgets).
- Capability overrides are module/section-level and are expressed as typed module params (persisted as part of the `ScreenSpec` module params when applicable).
- Overrides are applied in domain interpreters and the resolved capabilities are attached to the resolved `SectionVm` (domain interpreter output).

### Navigation intents (presentation)
- Tasks are editor-only (tile open uses route-based navigation, via `Routing`).
- Align values opens the editor deep-link (`openToValues: true`).
- Move-to-project supports both:
  - quick move (mutation), and
  - editor deep-link (navigation)
  and is capability-gated per section/module.

Move-to-project modeling (locked):
- navigation intent opens the picker/editor choice UX
- mutation intent performs the move after the user selects a destination

### Delete + pin UX
- Delete confirmation uses the existing shared helper `showDeleteConfirmationDialog` with entity-specific copy (including cascade descriptions where relevant).
- Tiles do not show local SnackBars for mutation success/failure; failures are surfaced globally.
- Project pin capability exists but defaults OFF (hidden) with a TODO to enable later via capability overrides once UX is validated.

Project pinning policy (locked):
- default-off is enforced at the capability level (capability hidden unless explicitly enabled by a module override)

### Global failure surfacing details
- Failures are surfaced by exactly one authenticated app-shell listener (SnackBars).
- Failure payload shape (for safe defaults and localization hooks):
  - typed `failureKind`
  - `fallbackMessage`
  - optional raw `error`
- Dedup/throttle:
  - key: `(failureKind, entityType, entityId)`
  - window: 2000ms
  - behavior: replace (hide current then show)

### Occurrence mismatch handling
If a completion intent implies occurrence-scoped completion but the entity is not consistent with `OccurrenceData`:
- Debug: assert
- Release: emit a generic failure SnackBar message

## Current repo reality (must be audited/verified)
Inventory (confirm all call sites):
  - `ScreenItemTileBuilder.build(...)`
  - any direct `TaskView(...)`, `ProjectView(...)`, `ValueView(...)` construction
    - include non-USM call sites (e.g. `presentation/features/next_action/widgets/pinned_section.dart`)
  - direct widget-layer `getIt<EntityActionService>()` usage
  - existing `ScreenActionsBloc` event coverage and call sites
  - any `BlocListener<ScreenActionsBloc, ...>` doing SnackBars at page level
  - any additional failure-to-SnackBar patterns

## Completion semantics (must be consistent globally)
Occurrences are modeled with `OccurrenceData` on `Task`/`Project`.

Completion payloads must include an explicit scope:

Required fields for occurrence scope:

Rationale:

## UTC vs local: repo truth to preserve
Confirm (and do not break) existing semantics:

If any layer currently drops `originalOccurrenceDate` on write, that must be wired end-to-end in later phases.

## Newly confirmed decisions (post-review) — locked
- (Q005A) Capabilities live on `ScreenItem.*` (renderable item model), with an "optional-first → required later" migration approach.
- (Q006C) Remove the `onTaskToggle` callback path entirely and replace it with an explicit tile action surface that is passed through renderers and `ScreenItemTileBuilder`.

## Global failure surfacing decision (locked)
Architecture choice: **Global provider + single listener at authenticated app shell**.

Canonical host (repo reality): `_AuthenticatedApp` (authenticated app shell) owns:

Hardening policy (lock in writing now):

Guardrails (locked):

## Deliverables
  - `EntityTileCapabilities`
  - `EntityTileCapabilitiesOverride` (module-level override)
  - `CompletionScope`
  - `TileIntent` and `TileIntentDispatcher`

## Locked implementation deltas captured after review
- (1A) Standardize entity typing on `EntityType` across agenda + screen actions.
- (2B) Capabilities live on item VMs/items (not a sidecar map).
- (3A) Completion display uses `occurrence.isCompleted` when present.

## Locked implementation decisions (batch 2)
- (A) `ScreenActionsBloc` is provided once at authenticated app shell, and failures are surfaced by a single app-shell listener (no per-page SnackBars).
- (A) `ScreenActionsFailureState` payload includes `failureKind` + `fallbackMessage` + optional `error` (+ optional entity context for dedupe).
- (A) Delete confirmation is owned by the dispatcher (dialog shown via `BuildContext`), and destructive flows may use the existing `Completer<void>` pattern.

## Locked implementation decisions (batch 3 — dispatcher placement)
- (1A) Provide a single `TileIntentDispatcher` at the authenticated app shell (alongside the global `ScreenActionsBloc`).
- (2A) Dispatcher types + default implementation live next to the tile builder (`lib/presentation/screens/tiles/`).
- (3C) Navigation handling is hybrid:
  - prefer `Routing` for conventional navigation,
  - use `EditorLauncher` when editor-only flags are required (e.g. `openToValues: true`).

## AI instructions (required)

## Completion checklist

## Migration checklist (call site → intended replacement)

### Tile construction
- `lib/presentation/screens/tiles/screen_item_tile_builder.dart`
  - Add a tile action surface input (capabilities + dispatcher)
  - Replace `onTaskToggle` callback with a completion intent (checkbox emits
    `TileIntent.setCompletion(...)`)
  - Remove any tile-level navigation fallbacks that conflict with intent
    policy (task tap uses `Routing` per Q7A)

### Direct entity view instantiation
- `lib/presentation/features/next_action/widgets/pinned_section.dart`
  - Stop constructing `TaskView` directly OR pass the same action surface
    (capabilities + dispatcher) that USM renderers use
  - Ensure completion checkbox and overflow actions route through intents

### Entity views (make “dumb”)
- `lib/presentation/entity_views/task_view.dart`
  - Remove all `getIt<EntityActionService>()` usage
  - Replace overflow actions with intent emissions:
    - Pin: `TileIntent.setPinned(...)` (success silent; failures via bloc)
    - Delete: `TileIntent.requestDelete(...)` (confirm handled above tile)
    - Edit/open: `TileIntent.openEditorOrDetails(...)` routed via `Routing`
    - Move-to-project: capability-gated quick move vs editor deep-link
    - Align values: open editor with `openToValues: true`
  - Remove tile-local SnackBars
- `lib/presentation/entity_views/project_view.dart`
  - Remove all `getIt<EntityActionService>()` usage
  - Replace overflow actions with intent emissions:
    - Delete: `TileIntent.requestDelete(...)` with entity-specific confirm copy
    - Align values: open editor with `openToValues: true`
    - Pin project: default capability OFF (TODO enable later)
  - Remove tile-local SnackBars

### ScreenActionsBloc provisioning + failure surfacing
- `lib/presentation/features/app/view/app.dart` (`_AuthenticatedApp`)
  - Provide a single global `BlocProvider<ScreenActionsBloc>`
  - Add a global `scaffoldMessengerKey` to `MaterialApp.router`
  - Add a single global failure listener that shows SnackBars on failures only
    with dedupe `(failureKind, entityType, entityId)` within 2000ms
- Remove per-page providers/listeners:
  - `lib/presentation/screens/view/unified_screen_spec_page.dart`
  - `lib/presentation/features/projects/view/project_detail_unified_page.dart`
  - `lib/presentation/features/values/view/value_detail_unified_page.dart`

### ScreenActions failure payloads
- `lib/presentation/screens/bloc/screen_actions_state.dart`
  - Extend `ScreenActionsFailureState` to carry:
    - typed `failureKind`
    - `fallbackMessage`
    - `error`
    - optional `entityType`/`entityId` (for dedupe keying)

### Occurrence-aware completion (end-to-end)
- Extend completion intent + bloc events + service/repo plumbing to carry:
  - `occurrenceDate`
  - `originalOccurrenceDate`
- Add debug assert and release-safe generic failure on mismatch
