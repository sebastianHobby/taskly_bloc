# Taskly Rebuild + Package Extraction Migration Outline

> Goal for this document (today): capture a high-level, end-to-end overview of what we need to change.
>
> This is *not* an implementation plan. Other AI agents (and humans) will refine and implement each package of work step-by-step.
>
> Target outcome:
> - App remains a Flutter app (root app layout).
> - App depends only on clean public APIs of the extracted packages:
>   - `taskly_core`
>   - `taskly_domain`
>   - `taskly_data`
> - Internal details are hidden (private implementation under `lib/src` in each package).
> - Unified Screen Model (USM) / data-driven screens are removed as a key goal.
> - Supabase auth + PowerSync sync must work from day 1.
> - All platforms supported (Android, iOS, Web, Windows, macOS).

## Decisions locked in

- App shell layout: keep root Flutter app (DEC-001A).
- Remove root `lib/domain` + `lib/data` early (DEC-002A), after package replacements are ready.
- Bootstrap refactor style: modular startup + GetIt (DEC-003B).
- Package API shape: multiple public entrypoints per package + a small root barrel (DEC-004B).
- Enforce `lib/src` best practice (DEC-005A).
- USM removal strategy: strangler pattern (disable entrypoints first, then delete) (DEC-006B).

- Editing UX as a route: editors are deep-linkable routes (even if presented as a sheet/panel) (DEC-015A).
- Scheduled/Agenda grouping: flat date-based feed (day groups only) showing projects + tasks by start/deadline, preserving the existing tag semantics and labels "Starts" / "Ongoing" / "Due" (DEC-016).
- My Day refresh policy: snapshot remains the primary surface; refresh is coordinator-driven (home-day boundary + debounced input changes) with explicit refresh requests allowed, and the UI provides a manual "Refresh allocation" action without any staleness indication or thresholds (DEC-017B, DEC-030A).

- Agenda in-day ordering: deterministic sort (pinned first → tasks before projects → Due before Starts before Ongoing → then time → then name) (DEC-018B).
- Same-day start+deadline semantics: show only "Due" (no double tag) (DEC-019A).
- Feed horizon + empty-day behavior: near-term dense (includes empty days), later sparse (only dates with items) (DEC-020A).

- MVP route schema: resource-first routes (`/my-day`, `/anytime`, `/scheduled`, plus `/task/:id/edit`, `/project/:id/edit`, `/value/:id/edit`) (DEC-024A).
- Editor presentation: adaptive (modal sheet on mobile, right-side panel on desktop), with full-page fallback when deep-linked directly (DEC-025A).
- Scope/filter persistence: hybrid (identity scope in route; secondary filters persisted locally) (DEC-026C).

- Routing library for MVP: `go_router` (DEC-027A).
- Deep-link editor fallback rule: if navigated from within an app shell route, open editor as sheet/panel; if entered directly on `/task/:id/edit` (etc), render full-page (DEC-028A).
- Scope identity encoding: path-based (`/project/:id/<screen>`, `/value/:id/<screen>`) (DEC-029B).

- Scoped feed support (MVP): scoped variants exist only for Anytime + Scheduled; My Day does not support scope routes or “filter allocation by scope” semantics (DEC-081B).
- Editor close/back-stack behavior: in-shell editors return to the originating feed/scope via normal back-stack; direct deep-link editors render full-page and close uses NotFound “Go Home” fallback rules when there is no in-shell origin (DEC-082A).

- Data stack integration contract: TBC (under review/building). Do not lock the exact public API surface (types + init hooks) yet; verify against the current `taskly_data` public API when implementing Packages B/C/D to avoid coordination churn (DEC-032A).

- Centralized error handling: two-tier model — screens own recoverable UI errors; unexpected/diagnostic errors go to a global AppErrorReporter (logs via `taskly_core/logging`; optional debug-only UX surfacing) (DEC-039A).
- Error taxonomy: domain defines sealed `AppFailure` types; data maps exceptions → failures; presentation maps failures → UI (DEC-040A).
- Correlation/tracing: introduce `OperationContext` with per-intent correlation IDs and propagate through use-cases/repos; logging includes `correlationId` (DEC-041A).
- Global unexpected error UX (prod): show a minimal non-blocking toast for unexpected errors only (never for expected failures), throttled to avoid spam; expected/user-actionable error UX remains screen-owned (DEC-042B).
- OperationContext creation: created in presentation when dispatching an intent, then passed explicitly into domain use-cases (no global state) (DEC-043A).
- Logging schema: standard structured fields enforced via `taskly_core/logging` wrapper (`feature`, `screen`, `intent`, `operation`, `correlationId`, `entityType`/`entityId`, `severity`) (DEC-044A).

- Post-USM screen definitions: explicit Flutter screens in presentation, plus (at most) a small navigation destinations registry; no data-driven screen spec system (DEC-045A).
- Cross-screen caching: cache/derive at repository/domain level only; UI models are derived per BLoC instance (DEC-046A).
- Optimistic UI for MVP: none; rely on offline-first local DB writes + reactive watchers for immediacy (DEC-047A).

- RxDart policy: allowed in domain/data for shared stream composition/caching; BLoCs may use sparingly but must expose plain Dart streams/state; never leak Rx types into widgets (DEC-048A).
- Shared derived stream caching: use `shareReplay(1)` (or equivalent) for expensive derived streams in domain services; lifecycle/dispose owned by the DI-registered service (DEC-049A).
- Cache lifecycle/invalidation: app-session-scoped caches reset on sign-out/user switch; invalidation driven by explicit input streams (DB watchers, clock ticks, settings changes), not TTL/manual clear-cache APIs (DEC-050A).
- RxDart dependency: permitted in `taskly_domain` and `taskly_data` (DEC-050A).

- Entity identity: domain defines opaque typed ID value types (`TaskId`/`ProjectId`/`ValueId`); presentation uses typed IDs (no raw strings in UI) (DEC-051A).
- Route param decoding: central `RouteCodec` parses/validates `go_router` path params into typed IDs; invalid params route to NotFound and log via AppErrorReporter/logging schema (DEC-052A).
- Time source: domain exposes a `Clock` contract; all “now/today/day-boundary” logic uses it for determinism and tests (DEC-053A).

- Screen composition post-USM: allow a static code-level “screen template” per screen to wire sections together (still explicit code; not data-driven) (DEC-054B).
- Pagination convention: repositories expose “current window” streams; BLoC owns paging intents; widgets only provide scroll signals (no repo calls) (DEC-055A).
- Bootstrap readiness/gating: `AppLifecycleBloc` gates app shell routes based on env/data/auth/maintenance readiness; screens assume dependencies are ready once routed (DEC-056A).

- Refresh allocation wiring: My Day overflow action emits an intent; dispatcher routes to My Day BLoC; domain coordinator/use-case refreshes the allocation snapshot (DEC-057A).
- Invalid deep link handling: single NotFound screen + structured router log event + “Go Home” CTA (DEC-058A).
- Editor host placement: shared `EditorHostPage` owns sheet/panel/full-page decisions so DEC-025A/DEC-028A are enforced in one place (DEC-059A).

- Destinations registry: registry provides only `GoRoute` builders + nav labels/icons; no business logic or data access (DEC-060A).
- Selection state: screen-local ephemeral state in BLoC; resets on route change; no global store (DEC-061A).
- Offline-first conflict policy (MVP): do not surface sync conflicts in prod UX; log via AppErrorReporter, and only show user-facing errors when a user action fails. In debug builds, also show a snackbar/toast when a true conflict/merge situation is detected (including data rejected from Supabase but persisted in PowerSync), and log full details (DEC-062A).

- Sync conflict detection: `taskly_data` emits a typed `SyncAnomaly` stream (domain-facing contract) with cases like `supabaseRejectedButLocalApplied` / `conflictResolvedWithRemote` / `conflictResolvedWithLocal`; includes `correlationId` + entity refs (DEC-063A).
- Debug conflict snackbar trigger: `AppLifecycleBloc` subscribes to `SyncAnomaly` and triggers debug snackbar via intent dispatcher/effects (DEC-064A).
- NotFound “Go Home”: navigate to last-known shell route when available, else `/my-day` (DEC-065B).

- Post-USM BLoC ownership: hybrid — each screen has a screen-level BLoC for scope + orchestration; heavy/reusable sections may have their own BLoCs (DEC-066C).
- One-off UI effects: BLoCs expose a separate `UiEffect` stream; widgets forward to the Intent Dispatcher for navigation/dialog/snackbar effects (DEC-067A).
- Scoped route context: introduce a reusable `ScopeContextBloc` producing `ScopeHeaderUiModel` and derived counts/summary metrics for `/project/:id/*` and `/value/:id/*` routes (DEC-068B).

- Screen vs section BLoC responsibilities (MVP feeds): Screen BLoC owns route/scope (when applicable), filter persistence, selection, and UI effects; one main “feed section” BLoC owns repository/domain subscriptions + row model mapping and emits `AsyncSectionState<List<ListRowUiModel>>` (DEC-083B).

- Cross-screen list row modeling: shared flat `ListRowUiModel` union for My Day / Anytime / Scheduled; hierarchy is expressed via minimal structural metadata (e.g., `depth` + grouping keys) supporting only the needed shapes (Values → Projects → Tasks, Projects → Tasks). Value grouping headers are configurable per screen between header-only vs tappable-to-scope navigation (DEC-069A).
- Async state convention: sections emit `AsyncSectionState<T>`; screen templates decide whether loading/empty/error renders inline or escalates to screen-level gating (DEC-070C).
- Selection convention: selection/multi-select state is screen-local in the screen BLoC (typed IDs), with platform-appropriate gestures; bulk actions are dispatched as intents via the central dispatcher (DEC-071A).

- My Day row mapping (MVP): allocation snapshot is mapped into the shared `ListRowUiModel` union using explicit header rows + minimal hierarchy metadata (DEC-084A). The row model must support Project rows with Task rows underneath (hierarchy) as an expected near-future shape.

- Row hierarchy metadata: minimal `depth` + grouping keys only (no generic tree/parent pointers); hierarchy is encoded by explicit header rows + row `depth` indentation conventions (DEC-072A).
- Group header behavior: configurable per screen/section between structural-only vs tappable-to-scope headers; tappable headers navigate to scope, with edits/actions via overflow as needed (DEC-073C).
- Scheduled semantics on rows: attach explicit `agendaMeta` (date + tag Starts/Ongoing/Due) to `taskRow`/`projectRow` variants; Scheduled BLoC owns deterministic ordering per locked agenda rules (DEC-074A).

- Scheduled optional buckets (MVP): implement Today/This Week/Next Week/Later as an additional header row variant in the shared row union (not separate sections); bucket collapse state remains ephemeral (not persisted) (DEC-085B).

- Task editor entrypoint from feeds: row tap opens the task editor route (`/task/:id/edit`) and presentation follows the centralized EditorHost rules (sheet/panel in-shell, full-page on direct deep-link) (DEC-075A).
- Scope navigation trigger: tappable group headers navigate to the corresponding scoped route (`/value/:id/<screen>`, `/project/:id/<screen>`), preserving back-stack behavior (DEC-076A).
- Secondary filter persistence: persist only key filters per feed/scope (e.g., Scheduled range preset + tag filters), keep search queries ephemeral by default (DEC-077B).

- Scheduled range UX: range preset is screen state and drives the domain query window; preset is persisted per DEC-077B and UI may “jump to today” without changing the preset (DEC-078A).
- Scheduled grouping: preserve day-group semantics, with optional higher-level UI buckets (Today/This Week/Next Week/Later) that contain day groups; bucket collapse state is ephemeral (not persisted) (DEC-079A).
- Scheduled filtering: only entity type filter (All/Tasks/Projects); Starts/Ongoing/Due tags are always shown and not user-filterable (DEC-080C).

- Feed filter persistence specifics (MVP): persist filters per (screen + scope identity) for Anytime + Scheduled (global vs scoped are distinct); keep persisted keys minimal (DEC-086A). For Scheduled this includes range preset + entity type filter; for Anytime, do not introduce additional persisted filters unless explicitly added later.

## Architecture constraints (non-negotiable)

- Presentation boundary: widgets/pages do not call repositories directly and do not subscribe to non-UI streams directly; BLoCs own those subscriptions.
- Offline-first: Drift is the local source of truth for UI state.
- PowerSync + SQLite: avoid Drift UPSERT helpers on PowerSync schema tables (view limitation).

## Work packages (discrete bundles)

### Package A — Public API cleanup and `lib/src` restructuring (per extracted package)

**Intent:** The app (and other packages) should import only curated entrypoints. No deep imports into internal folders.

Deliverables (for each package):
- Establish `lib/src/**` as implementation location.
- Create curated public entrypoints:
  - `taskly_core`: `env.dart`, `logging.dart`, plus a small `taskly_core.dart` barrel.
  - `taskly_domain`: bounded context entrypoints (examples: `allocation.dart`, `attention.dart`, `journal.dart`, `queries.dart`, `interfaces.dart`, `time.dart`) + `taskly_domain.dart` barrel.
  - `taskly_data`: entrypoints (examples: `sync.dart`, `db.dart`, `repositories.dart`) + `taskly_data.dart` barrel.
- Update internal imports across repo so nothing imports from `package:taskly_*/src/...`.

Acceptance criteria:
- App and packages compile using only the public entrypoints.
- Public surface is intentionally small and reviewed.

#### Phase 1 / Batch 1 — `taskly_core` API cleanup (approved for implementation)

Status: Complete (2026-01-17).

Scope:
- Move implementation from `packages/taskly_core/lib/core/**` to `packages/taskly_core/lib/src/**`.
- Introduce public entrypoints:
  - `packages/taskly_core/lib/env.dart`
  - `packages/taskly_core/lib/logging.dart`
  - keep/adjust `packages/taskly_core/lib/taskly_core.dart` as a small barrel.
- Update usages (at minimum inside `taskly_data`) so imports become:
  - `package:taskly_core/env.dart`
  - `package:taskly_core/logging.dart`
  (or via the barrel if chosen).

Non-goals:
- No runtime behavior changes.
- No USM removal changes.
- No app bootstrap refactor.


### Package B — Day-1 data stack and auth/sync wiring (package-first)

**Intent:** Make Supabase auth + PowerSync sync a first-class, reusable capability owned by `taskly_data`, not the app.

Deliverables:
- A clear, public "data stack" API in `taskly_data` that the app can call, e.g.:
  - initialize Supabase
  - open PowerSync database
  - bind Drift `AppDatabase`
  - run post-auth maintenance (seeders, cleanup)
- Remove (or deprecate) app-specific wiring that duplicates this.

Acceptance criteria:
- App can start and authenticate on all platforms using only `taskly_data` + `taskly_core`.
- Sync works and is not tied to USM.


### Package C — App bootstrap modularization (GetIt + services)

**Intent:** Keep startup understandable, testable, and stable across platforms.

Deliverables:
- Split bootstrap into modules (example modules):
  - Logging
  - Env
  - Auth + Supabase init
  - PowerSync/Drift open
  - DI registration
  - Post-auth maintenance trigger
- Ensure errors are captured (Flutter framework errors + zone errors) and logged.

Acceptance criteria:
- Single, readable startup sequence.
- Platform-agnostic behavior.


### Package D — USM strangler: remove entrypoints and replace MVP routes with explicit Flutter screens

**Intent:** Remove data-driven screen system from the user experience while keeping the architecture boundary rule.

Deliverables:
- Disable/remove USM routing entrypoints:
  - catch-all `/:segment`
  - screen catalog and screen editor UI
  - unified screen page rendering
- Replace with explicit, hand-authored screens for the MVP:
  - My Day
  - Anytime (Someday)
  - Scheduled

Presentation design decisions (confirmed):
- DEC-010B (Navigation): Adaptive destinations navigation (rail on desktop/tablet, drawer/bottom nav adaptation on mobile) for My Day / Anytime / Scheduled.
- DEC-011H (Entity UX): Editor-first everywhere, with filter-first context views for Project/Value ("scope"), reserving dedicated detail screens as a later phase if needed.
- DEC-012A (Widget composition): 4-layer UI stack: Primitives → Entities → Sections → Screens/Templates.
- DEC-013A (Centralized actions): Intent Dispatcher pattern; UI emits typed intents, a single dispatcher handles navigation/dialogs and funnels mutations through BLoCs/use-cases.

Acceptance criteria:
- App no longer navigates through USM.
- MVP screens function via BLoCs and repository streams.

Notes:
- MVP semantics must be explicitly defined:
  - My Day: allocation snapshot vs live allocation stream
  - Scheduled: occurrences agenda vs tasks with date fields

MVP semantics decisions (confirmed):
- DEC-007C (My Day): Hybrid model. Snapshot is the primary surface; live signals may drive secondary UX (alerts/banners/refresh).
- DEC-008A (Scheduled): Occurrences agenda in a date range (RRULE expansion + exceptions).

Day-1 auth/sync packaging decision (confirmed):
- DEC-009A (`taskly_data` public API): Single facade "data stack" initializer returning strongly-typed handles (sync DB, Drift DB, repos, lifecycle hooks).

UI model policy decision (confirmed):
- DEC-014 (Selective UI models): UI-model ("B-model") mapping is mandatory for:
  - Entity tiles (Task/Project/Value tile models)
  - Agenda/hierarchy sections (domain → UI row expansion)
  - Scope/filter models (cross-screen)
  Direct rendering of domain objects is allowed only for tiny, low-risk surfaces (e.g. simple header text) and should remain rare.


### Package E — Delete root `lib/domain/**` and `lib/data/**` (DEC-002A)

**Intent:** Complete the migration so the app uses packages only.

Deliverables:
- Remove root domain/data folders.
- Any still-needed functionality is relocated into `taskly_domain` / `taskly_data`.
- App imports refer only to package public APIs.

Acceptance criteria:
- No root-level domain/data implementations remain.
- App compiles and runs with packages only.


### Package F — Hardening: tests, presets, and CI alignment

**Intent:** Ensure the rebuild stays safe and maintainable.

Deliverables:
- Update tests to use package public APIs and avoid root domain/data references.
- Add package-level tests where appropriate (domain rules, repository behavior).
- Keep pipeline/local stack tests usable for sync confidence.

Acceptance criteria:
- `flutter analyze` clean.
- Test presets remain useful (`fast`, `quick`, `database`, `pipeline`).


### Package G — Values v2 (primary/secondary slots) + legacy cleanup

**Intent:** Move the app from junction-table value assignments to a slot-based
model:

- `projects.primary_value_id`, `projects.secondary_value_id`
- `tasks.override_primary_value_id`, `tasks.override_secondary_value_id`

This aligns with the domain rule:
- Tasks inherit project values only when the task has no overrides.
- Overrides require a primary; secondary is optional.
- If overriding primary, the task does not inherit the project secondary.

**Temporary compatibility decision:** Keep the legacy tables
`project_values` / `task_values` for now (read-only / unused by the app) so we
can roll out the app change without immediately removing sync rules, pipeline
test wiring, or historical data. A follow-up package removes the legacy path.

Deliverables:
- Update `taskly_domain` models to include primary/secondary slots and task
  override slots.
- Update `taskly_data` repositories and SQL filtering to use slot columns and
  repository-side queries (no value join-table dependency).
- Update PowerSync + Drift local schema to include new columns on `tasks` and
  `projects`.

Acceptance criteria:
- App reads and writes value slots through repositories.
- No runtime dependency on `project_values` / `task_values` remains in app code.
- Effective value semantics match the locked inheritance rules.

#### Package G2 (follow-up) — Remove legacy junction tables

Deliverables:
- Remove `project_values` / `task_values` from:
  - Supabase schema (after a safe window)
  - PowerSync sync rules (`supabase/powersync-sync-rules.yaml`)
  - PowerSync client schema (`packages/taskly_data/lib/data/infrastructure/powersync/schema.dart`)
  - Drift tables (`packages/taskly_data/lib/data/infrastructure/drift/drift_database.dart`)
  - Deterministic ID generator hooks (`packages/taskly_data/lib/data/id/id_generator.dart`)
  - Pipeline/integration tests that assert join-table rewrite behavior

Acceptance criteria:
- Sync pipeline and test presets do not reference the legacy tables.
- No codepaths can create/update legacy join rows.


## Ongoing architecture/maintainability improvement prompts

During implementation, agents should continuously flag opportunities as explicit decisions (with options + recommendation), for example:
- Consolidating duplicate env/logging utilities into `taskly_core`.
- Creating a reusable `taskly_data` “data stack” API instead of app-specific helpers.
- Reducing public API surface area to minimize coupling.
- Improving dependency direction (presentation -> domain contracts -> data impls).


## Handoff checklist (must not guess)

If any of these are still unclear at implementation time, agents must ask and must not assume.

- My Day staleness surfacing for DEC-017B: define how staleness is shown (banner/chip/timestamp) and the stale threshold (if any).
- Data stack integration contract: if Package B is implemented by a different agent, document the expected public API surface (types + init hooks) so Package C/D can integrate without coordination churn.


## Open questions (do not assume)

If any of these remain unanswered at implementation time, agents must ask and must not assume.

- None for this batch (DEC-015A / DEC-016 / DEC-017B are locked in).
- None for this batch (DEC-024A / DEC-025A / DEC-026C are locked in).
