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

## Progress log (implementation notes)

### 2026-01-17

- **Routing**: Explicit MVP shell routes exist for `/my-day`, `/anytime`, `/scheduled`, and `/inbox` (no `/:segment` catch-all route).
- **USM strangler (My Day first)**: `/my-day` can now run as a non-USM MVP screen behind `ENABLE_MVP_MY_DAY=true` (with a safe fallback to the existing USM `ScreenSpec` when disabled).
  - MVP screen reuses `MyDayGateBloc` prerequisites gating and renders the existing My Day hero + ranked tasks UI.
- **Editor host (DEC-025A/DEC-028A/DEC-059A)**: Route-backed editors now use a centralized host behavior:
  - in-app origin (back-stack) → open editor as modal (sheet/panel/dialog)
  - direct deep link (no back-stack) → render editor full-page
- **State management policy (presentation)**: for new work, prefer full `Bloc` (events + states) over `Cubit`. Existing Cubits may remain temporarily, but do not introduce new Cubits.
- **Notes**: Most shell routes still render USM-backed system screens via `ScreenSpec` for now. `/anytime` is now an explicit Flutter screen and no longer uses USM.

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

- My Day staleness UX (MVP): none. Do not show any staleness indicators (no banner/chip/timestamp/thresholds); keep only the manual “Refresh allocation” action per DEC-017B (DEC-189A).

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

- Data stack integration contract: lock a two-phase model with explicit auth-gated session lifecycle (DEC-032B).
  - Phase 1 (pre-auth): open local DB + Drift, create repositories, but do not connect PowerSync upload/download.
  - Phase 2 (post-auth): app-controlled `startSession()`/`stopSession()` (or equivalent) that connects/disconnects sync and runs post-auth maintenance; session starts after sign-in and stops on sign-out/user switch.
  - Readiness gating remains owned by the app (`AppLifecycleBloc`), while `taskly_data` owns sync/DB internals behind `TasklyDataStack`.

- Scheduled repeating occurrence action model: full recurrence editing model (DEC-203C).
  - Provide explicit “edit this occurrence” vs “edit series” flows (occurrence-aware editor mode), not just entity-only actions.
  - Occurrence-specific mutations (skip/reschedule) are supported via recurrence exceptions and are keyed by occurrence identity (aligned with `AgendaOccurrenceRef`).

- Recurrence anchor-date semantics: strict anchors (DEC-204A).
  - Fixed-date mode (`repeatFromCompletion=false`): anchor/DTSTART is the entity `startDate` (required when RRULE is set).
  - From-completion mode (`repeatFromCompletion=true`): anchor is derived from completion history; if no completion exists yet, fall back to `startDate`.

- Occurrence editing route shape: keep existing entity editor routes and pass occurrence context via query params (DEC-205A).
  - Example: `/task/:id/edit?mode=occurrence&occ=<encoded-occurrence-ref>` and `/task/:id/edit?mode=series`.

- Occurrence action/capability dispatch: introduce a unified `ActionSubject` (entity vs occurrence) contract (DEC-206B).
  - Capability evaluation and action catalog take an `ActionSubject` plus context; occurrence mutations use occurrence identity (aligned with `AgendaOccurrenceRef`).

- Occurrence-aware editor scope: hybrid model (DEC-207C).
  - Provide a lightweight occurrence exception editor (skip/reschedule/complete/notes) plus an explicit “Edit series…” escape hatch to the normal entity editor.

- Centralized error handling: two-tier model — screens own recoverable UI errors; unexpected/diagnostic errors go to a global AppErrorReporter (logs via `taskly_core/logging`; optional debug-only UX surfacing) (DEC-039A).
- Error taxonomy: domain defines sealed `AppFailure` types; data maps exceptions → failures; presentation maps failures → UI (DEC-040A).
- Correlation/tracing: introduce `OperationContext` with per-intent correlation IDs and propagate through use-cases/repos; logging includes `correlationId` (DEC-041A).
- Global unexpected error UX (prod): show a minimal non-blocking toast for unexpected errors only (never for expected failures), throttled to avoid spam; expected/user-actionable error UX remains screen-owned (DEC-042B).
- OperationContext creation: created in presentation when dispatching an intent, then passed explicitly into domain use-cases (no global state) (DEC-043A).
- Logging schema: standard structured fields enforced via `taskly_core/logging` wrapper (`feature`, `screen`, `intent`, `operation`, `correlationId`, `entityType`/`entityId`, `severity`) (DEC-044A).

- Post-USM screen definitions: explicit Flutter screens in presentation, plus (at most) a small navigation destinations registry; no data-driven screen spec system (DEC-045A).
- Cross-screen caching: cache/derive at repository/domain level only; UI models are derived per BLoC instance (DEC-046A).
- Optimistic UI for MVP: none; rely on offline-first local DB writes + reactive watchers for immediacy (DEC-047A).

- Shared UI package (MVP): introduce a separate `taskly_ui` package for reusable, presentation-layer UI building blocks only (primitives/entities/sections/row renderers). User-visible screens, routing, EditorHost behavior, and BLoCs remain in the app for MVP. Widgets in `taskly_ui` must remain “pure UI” (no repository/use-case access, no stream subscriptions, no `go_router` navigation); interactivity is exposed via callbacks/UI events to be handled by app-owned BLoCs/dispatcher (DEC-096A).

- `taskly_ui` contents boundary: in addition to primitives/entities/row renderers, `taskly_ui` may include reusable section widgets/renderers (loading/empty/error/list sections) and may own UI-only ephemeral state (expand/collapse, animations), but must not own BLoCs or subscriptions (DEC-097B).
- Theme/assets/l10n ownership with `taskly_ui`: the app owns `ThemeData`, asset bundles, and localization setup; `taskly_ui` provides tokens/ThemeExtensions and consumes them via `Theme.of(context)`. Preserve the current theme preset options/UX (e.g., existing preset choices and behaviors) while refactoring (DEC-098A).
- `taskly_ui` dependency + action contract: `taskly_ui` may depend on public `taskly_domain` identity types (e.g., `TaskId`/`ProjectId`/`ValueId`) and emit small UI event unions/callbacks for user interactions; it must not depend on `taskly_data` and must not perform navigation directly (DEC-099B).

- RxDart policy: allowed in domain/data for shared stream composition/caching; BLoCs may use sparingly but must expose plain Dart streams/state; never leak Rx types into widgets (DEC-048A).
- Shared derived stream caching: use `shareReplay(1)` (or equivalent) for expensive derived streams in domain services; lifecycle/dispose owned by the DI-registered service (DEC-049A).
- Cache lifecycle/invalidation: app-session-scoped caches reset on sign-out/user switch; invalidation driven by explicit input streams (DB watchers, clock ticks, settings changes), not TTL/manual clear-cache APIs (DEC-050A).
- RxDart dependency: permitted in `taskly_domain` and `taskly_data` (DEC-050A).

- Entity identity: domain defines opaque typed ID value types (`TaskId`/`ProjectId`/`ValueId`); presentation uses typed IDs (no raw strings in UI) (DEC-051A).
- Route param decoding: central `RouteCodec` validates UUID v4/v5 and routes invalid params to NotFound with structured logs; until typed IDs exist end-to-end, `RouteCodec` will pass validated `String` IDs and a follow-up work item will promote this to typed IDs (DEC-052A).
- Time source: domain exposes a `Clock` contract; all “now/today/day-boundary” logic uses it for determinism and tests (DEC-053A).

- Screen composition post-USM: allow a static code-level “screen template” per screen to wire sections together (still explicit code; not data-driven) (DEC-054B).
- Pagination convention: repositories expose “current window” streams; BLoC owns paging intents; widgets only provide scroll signals (no repo calls) (DEC-055A).
- Bootstrap readiness/gating: `AppLifecycleBloc` gates app shell routes based on env/data/auth/maintenance readiness; screens assume dependencies are ready once routed (DEC-056A).

- Refresh allocation wiring: My Day overflow action emits an intent; dispatcher routes to My Day BLoC; domain coordinator/use-case refreshes the allocation snapshot (DEC-057A).
- Invalid deep link handling: single NotFound screen + structured router log event + “Go Home” CTA (DEC-058A).
- Editor host placement: shared `EditorHostPage` owns sheet/panel/full-page decisions so DEC-025A/DEC-028A are enforced in one place (DEC-059A).

- Editor form framework + typing policy: standardize all editors on `flutter_form_builder`. Widgets own the `FormBuilder` state/key and field widgets, while the editor BLoC owns the entity subscription/snapshot, validation policy, and save/delete intents. The widget→BLoC boundary must use typed draft/value objects (no `Map<String, dynamic>` / stringly-typed field names crossing into BLoCs) (DEC-106A).

- Editor loading/error UX: two-phase gate — initial load is blocking (loading state until first snapshot); after the first snapshot, subsequent subscription/refresh failures are non-blocking (inline banner + retry) without discarding the user’s current draft (DEC-107C). If the entity is deleted while the editor is open, render a read-only “This was deleted” state with a primary “Go Home” action (DEC-107C).
- Editor save/close behavior: save success always closes the editor. In-shell editors close via normal back-stack to the originating feed/scope; direct deep-link editors close via the NotFound “Go Home” fallback rules when there is no in-shell origin (DEC-108B).
- Unsaved changes prompt: standard dirty-guard — when the form is dirty and not saving, intercept close/back/dismiss and prompt Stay / Discard; when saving, prevent dismissal until save completes; after successful save, no prompt (DEC-109A).

- Editor delete behavior: delete requires confirmation; on successful delete, close the editor immediately. In-shell editors return via back-stack to the originating feed/scope; direct deep-link editors close via the NotFound “Go Home” fallback rules. If the entity is deleted remotely while the editor is open, reuse the read-only “This was deleted” state (DEC-118A).
- Editor read-only mode: if an entity is not editable (permissions/locked), render the editor in a hard read-only mode (fields disabled + clear banner), hide Save/Delete, and allow Close (DEC-119A).

- Destinations registry: registry provides only `GoRoute` builders + nav labels/icons; no business logic or data access (DEC-060A).
- Selection state: screen-local ephemeral state in BLoC; resets on route change; no global store (DEC-061A).
- Offline-first conflict policy (MVP): do not surface sync conflicts in prod UX; log via AppErrorReporter, and only show user-facing errors when a user action fails. In debug builds, also show a snackbar/toast when a true conflict/merge situation is detected (including data rejected from Supabase but persisted in PowerSync), and log full details (DEC-062A).

- Sync conflict detection: `taskly_data` emits a typed `SyncAnomaly` stream (domain-facing contract) with cases like `supabaseRejectedButLocalApplied` / `conflictResolvedWithRemote` / `conflictResolvedWithLocal`; includes `correlationId` + entity refs (DEC-063A).
- Debug conflict snackbar trigger: `AppLifecycleBloc` subscribes to `SyncAnomaly` and triggers debug snackbar via intent dispatcher/effects (DEC-064A).
- NotFound “Go Home”: navigate to last-known shell route when available, else `/my-day` (DEC-065B).

- Post-USM BLoC ownership: hybrid — each screen has a screen-level BLoC for scope + orchestration; heavy/reusable sections may have their own BLoCs (DEC-066C).
- Presentation state primitive (MVP): use `Bloc` for new presentation state; avoid introducing new `Cubit`s. Prefer explicit events + states to keep intent logging and cross-screen conventions consistent.
- One-off UI effects: BLoCs expose a separate `UiEffect` stream; widgets forward to the Intent Dispatcher for navigation/dialog/snackbar effects (DEC-067A).
- Scoped route context: introduce a reusable `ScopeContextBloc` producing `ScopeHeaderUiModel` and derived counts/summary metrics for `/project/:id/*` and `/value/:id/*` routes (DEC-068B).

- Scoped header content (MVP): `ScopeHeaderRow` shows identity plus a small “two-metrics” summary for orientation; metrics are computed in `ScopeContextBloc` (subscriptions remain in BLoCs) and kept cheap/available via public domain/data APIs (DEC-125B).

- Screen vs section BLoC responsibilities (MVP feeds): Screen BLoC owns route/scope (when applicable), filter persistence, selection, and UI effects; one main “feed section” BLoC owns repository/domain subscriptions + row model mapping and emits `AsyncSectionState<List<ListRowUiModel>>` (DEC-083B).

- Feed row mapping ownership (MVP): each feed’s main list section BLoC owns domain subscriptions, hierarchy expansion, and mapping into `AsyncSectionState<List<ListRowUiModel>>`; the Screen BLoC remains focused on orchestration, selection, persisted filters, and UI effects (DEC-100B).

- Scheduled ordering + buckets (MVP): Scheduled main feed section BLoC is responsible for deterministic ordering and for constructing DateHeader rows plus optional BucketHeader rows (Today/This Week/Next Week/Later) per the locked agenda semantics and bucket rules (DEC-101B).

- Anytime grouping (MVP): Anytime supports header-row grouping using the shared row model (Value → Project → Task; scoped variants still show the scope header row for user orientation). Grouping is fixed (not user-configurable/persisted) to keep secondary filter persistence minimal (DEC-102B).

- Anytime scoped hierarchy UX: on scoped routes (e.g., `/value/:id/anytime`), render a single `ScopeHeaderRow` for orientation and still show a clear hierarchy beneath it (Projects as parents with child Tasks underneath) even when the global grouping shape is Value → Project → Task (DEC-111A).

- Anytime scoped header de-duplication: on scoped routes, render `ScopeHeaderRow(scope)` and suppress the grouping header for that same scope entity (avoid “double scope” headers). Under a value scope, still render Project → Task hierarchy; under a project scope, render Task children directly under the scope header (DEC-120A).

- Scheduled scoped header + de-duplication (MVP): on scoped Scheduled routes, render a single `ScopeHeaderRow(scope)` for orientation and suppress any grouping/header row that would duplicate that same scope identity (DEC-192A).

- Global synthetic Inbox pseudo-project (MVP): tasks with no project are grouped under a pseudo project called “Inbox”. Inbox behaves like a project for grouping/headers, but is not editable/deletable and must not be treated as a real `ProjectId` for editor routes. This is a global app concept (applies wherever a project header could appear) and is modeled in the domain via a synthetic grouping reference (not a UI-only hack) (DEC-129B, DEC-130A).
- Inbox navigation (MVP): tapping the Inbox header navigates to an Inbox placeholder screen (empty-state screen) rather than opening an editor (DEC-130A).

- Synthetic project grouping reference shape (MVP): define a public domain type (e.g., `ProjectGroupingRef`) as a sealed union with cases `real(ProjectId)` and `inbox` (no ID). This type must not be treated as a `ProjectId`, and must provide a stable key representation for grouping/persistence (e.g., `project:<id>` and `inbox`) without leaking UI concerns (DEC-131A).
- Inbox route shape (MVP): Inbox is a global, deep-linkable shell route at `/inbox` (same app-shell container as `/my-day`, `/anytime`, `/scheduled`), and is not an editor route. Normal back-stack rules apply when navigated to from within the app shell (DEC-132A).
- `rowKey` format conventions (MVP): `rowKey` values are deterministic, globally stable strings with a versioned prefix (e.g., `v1/...`) and a composite structure including `screen` + `rowType` + required disambiguators. Scheduled item rows must include the day key and agenda tag (Starts/Ongoing/Due) when needed to avoid collisions; header and placeholder rows must also have deterministic keys (DEC-133A).
- Inbox screen behavior (MVP): Inbox is a real feed screen that shows all “no project” tasks (not just an empty placeholder). It uses the same feed row model + feed section BLoC pattern; tapping a task row opens the task editor route; Inbox itself remains non-editable/non-deletable (DEC-134A).
- Minimal a11y policy for hierarchy feeds (MVP): list renderers derive hierarchy semantics from scanning the flat list using `depth` + grouping keys (and the known row variants), ensuring deterministic reading order and proper header semantics; `rowKey` is identity-only (not spoken). Prefer best-practice semantics labeling that includes the current group context (bucket/date) for headers/placeholder rows (DEC-135A).

- Scheduled occurrence identity (MVP): define a public domain reference type (e.g., `AgendaOccurrenceRef`) that uniquely identifies a rendered Scheduled row instance using typed fields (entity type + entity ID + local day + agenda tag Starts/Ongoing/Due, plus an extra disambiguator if RRULE can yield multiple same-day same-tag instances). This ref is the canonical identity for Scheduled “instances” and supports deterministic `rowKey`s and action dispatch without making `rowKey` the source of truth (DEC-136A).
- Scheduled rowKey identity source (MVP): Scheduled task/project item rows always use `AgendaOccurrenceRef` as the canonical instance identity (for both repeating and non-repeating), and `rowKey` encodes the same fields (including `instanceKey` when present) under the Scheduled screen namespace (DEC-190A).
- Editor routes in `go_router` (MVP): keep editor paths exactly as locked (`/task/:id/edit`, `/project/:id/edit`, `/value/:id/edit`) and implement them as top-level routes that always build the shared `EditorHostPage`. `EditorHostPage` owns the sheet/panel vs full-page decision using the in-shell-origin vs direct deep-link rule (DEC-137A).
- Filter persistence with Inbox feed (MVP): treat Inbox as its own `screenKey` (e.g., `inbox`) with `scopeKey=global` under the existing `(screenKey, scopeKey)` persistence scheme. Do not model Inbox as a scope identity (it is not a `ProjectId`) and do not reuse Anytime’s scope keys for Inbox (DEC-138A).

- `rowKey` encoding + escaping standard (MVP): use a canonical, human-readable, versioned composite string format (e.g., `v1/<screen>/<rowType>/<k>=<v>...`) where values are UTF-8 percent-encoded and IDs use their canonical string form. Dates use `YYYY-MM-DD`; enums are lowercase. Encoded values must not contain raw `/` or `=` (DEC-139A).
- Inbox feed row model shape (MVP): the Inbox screen’s chrome shows the Inbox identity; the list itself contains only Task rows (flat) for “no project” tasks (no Inbox header row inside the list) (DEC-140A).
- Scheduled occurrence disambiguator (MVP): when the occurrence engine can yield multiple same-day same-tag instances, the domain must provide an additional stable `instanceKey` (engine-generated) on `AgendaOccurrenceRef` to disambiguate identity independent of ordering (DEC-141B).

- `rowKey` construction ownership (MVP): each feed section BLoC constructs canonical `rowKey` strings as part of row mapping, using shared presentation-layer helpers as needed. Do not move `rowKey` generation into `taskly_ui` or into domain (DEC-142A).
- A11y localization policy for derived group-context labels (MVP): renderers build screen-reader labels from structured row fields (bucket title/date label/placeholder kind/entity title) using app localization; BLoCs emit structured data, not prebuilt semantics strings (DEC-143A).
- Inbox task capabilities + overflow actions (MVP): Inbox uses the same capability-driven overflow menu model as other feeds (central action catalog + BLoCs decide availability from domain capabilities + context). Avoid Inbox-specific action IDs for MVP (DEC-144A).

- Inbox “no project” definition (MVP): Inbox shows tasks whose project reference is absent in the domain model (e.g., `projectId == null`); Inbox membership is exactly this rule with no additional heuristics in MVP (DEC-145A).
- Project assignment from Inbox (MVP): include a non-destructive overflow action “Assign to project…” (from the central action catalog) that opens a picker flow; availability is capability-driven and uses the standard intent dispatcher + BLoC mutation path (DEC-146B).
- Scheduled “ongoing” tagging across ranges (MVP): Starts/Ongoing/Due tags are taken directly from the occurrence engine output within the requested range; `AgendaOccurrenceRef` includes the tag and no additional cross-range persistence is introduced for “ongoing” (DEC-147A).

- Scoped Scheduled semantics + ownership (MVP): implement scoped Scheduled via a public domain use-case/service that takes `(scope, range, filters)` and returns the scoped agenda stream; presentation does not client-filter a global stream. For `/value/:id/scheduled`, include only tasks/projects directly tagged to that value (no implicit inclusion of items via project→value linkage) (DEC-191A).

- “Assign to project…” picker UX (MVP): implement as an in-shell modal flow (dialog/sheet/panel depending on platform) invoked via an intent effect; it is not deep-linkable as a route in MVP (DEC-148B).
- Picker includes “Remove project” (MVP): the project picker includes a top option “No project (Inbox)” that sets the task’s project reference to absent (`projectId = null`) (DEC-149A).
- Picker search scope (MVP): provide simple search by project name only; no advanced filters in MVP; results ordering remains deterministic (DEC-150A).

- Project picker data source + ownership (MVP): the project picker uses its own small BLoC that subscribes to a public domain query/use-case stream of projects; picker widgets remain pure UI and do not call repositories directly (DEC-151A).
- Project picker result contract (MVP): picker returns `ProjectId?` where `null` means “No project (Inbox)”; the mutation path sets `projectId=null` accordingly (DEC-152B).
- Project picker ordering (MVP): when search is empty, order projects deterministically by display name then ID (DEC-153A).

- Project picker domain contract (MVP): introduce a dedicated public domain use-case/service for picker list + name search, returning a stream of picker-ready project items with deterministic ordering. The picker BLoC subscribes to this stream; widgets remain pure UI and do not call repositories directly (DEC-154C).

- Project picker contents (MVP): the picker shows a “No project (Inbox)” option plus the full project list in the same flow (DEC-155A).
- Project picker reuse (MVP): reuse the same picker flow across screens/editors where “assign project” is needed (Inbox overflow, Task editor, and any future feed actions) (DEC-156A).

- Project picker empty/error UX (MVP): show inline empty state (“No matching projects”) and inline error (banner + retry) within the modal; modal does not hard-block the parent screen and does not force-close on transient errors (DEC-157A).
- Project picker selection side effects (MVP): selecting a project immediately dispatches the mutation intent and closes the modal on success; if the mutation fails, surface the error inline and keep the modal open (DEC-158A).
- Project “display name” source (MVP): use a single canonical domain-provided title field for both display and deterministic sorting; presentation may add visual fallbacks but must not change sort keys (DEC-159A).

- Task project assignment mutation API (MVP): implement project assignment as a typed intent (e.g., `AssignTaskProjectIntent(taskId, ProjectId?)`) that routes through the central Intent Dispatcher to a domain use-case which performs the write via repository contracts. UI updates are driven by offline-first DB watchers (DEC-160A).
- Capability gating for “Assign project” (MVP): show the action only when domain capabilities indicate the task is editable and the project field is mutable; otherwise hide it (do not show disabled) (DEC-161A).
- Inbox screen header/navigation (MVP): Inbox uses a standard screen header (AppBar title “Inbox” + optional short explanation), no edit affordance, and normal back behavior (DEC-162A).

- “Assign to project” feedback UX (MVP): on success, close the picker modal without additional toasts/snackbars; on failure, show an inline error in the modal with retry and keep the modal open (DEC-163A).
- Inbox empty-state (MVP): when Inbox has zero “no project” tasks, show a friendly empty state with a single primary CTA “Create task” (no secondary CTA) (DEC-164A).
- RowKey helper location (MVP): place `rowKey` helper functions in the app presentation layer near list-row mapping utilities; keep them pure functions and do not move them into `taskly_ui` or other packages (DEC-165A).

- Inbox “Create task” CTA (MVP): CTA opens the Task Editor for a new task draft with `projectId = null` (Inbox) using the standard editor host presentation rules (DEC-166A).
- New-task editor identity (MVP): introduce an ephemeral `TaskDraftId` used only within presentation/editor while editing a not-yet-saved task; save creates the real entity and closes the editor (DEC-167A).
- New task visibility in feeds (MVP): new task drafts do not appear in feeds until saved; no temporary/optimistic feed rows are introduced, so no draft rowKeys are required in feeds (DEC-168A).

- `TaskDraftId` location (MVP): `TaskDraftId` is presentation/editor-only plumbing (not a public domain identity type) (DEC-169B).
- New-task defaults policy (MVP): presentation sets minimal defaults for new drafts (title empty, `projectId` from context, other fields null) with no domain-level defaults use-case in MVP (DEC-170B).
- Create-task write path (MVP): editor BLoC dispatches a typed create intent (e.g., `CreateTaskIntent(draft, OperationContext)`) to a domain use-case; use-case inserts via repository contracts and returns the real `TaskId` (DEC-171A).

- “New task” deep link policy (MVP): do not add a deep-linkable route for creating a new task; creation is reachable from in-shell CTAs/buttons only in MVP (DEC-172A).

- New task editor launch mechanism (MVP): open the new-task draft editor via an in-shell modal flow (sheet/panel/dialog depending on platform) with no URL route; still apply the shared editor host sizing/presentation rules for in-shell editors (DEC-188A).
- Inbox create-task CTA placement (MVP): use a FAB to create a new task on platforms where FAB is idiomatic; on other platforms, provide an equivalent primary “New task” action in the screen chrome (DEC-173C).
- Logging for assign-project + create-task intents (MVP): log these intents using the standard structured logging schema (`feature`, `screen`, `intent`, `operation`, `correlationId`, entity refs) for diagnostics and traceability (DEC-174A).

- Inbox FAB platform rule (MVP): use a FAB for “New task” on Android/iOS; use a primary header action on desktop/web (DEC-175A).
- Inbox task ordering (MVP): reuse Anytime task ordering rules for Inbox so behavior is consistent and deterministic (DEC-176A).
- Inbox list section rendering (MVP): use the standard list section patterns (loading state, empty state per DEC-164A, inline error banner + retry) consistent with other feeds (DEC-177A).

- Inbox destination visibility (MVP): Inbox is a first-class destination alongside My Day / Anytime / Scheduled and is visible in the app’s destinations navigation chrome (rail/drawer) (DEC-178A).
- Inbox header-row interaction rule (MVP): in feeds where Inbox appears as a project-like header row, tapping it navigates to `/inbox`. Its overflow never offers edit/delete/rename and never treats it as a real project; it may expose capability-driven actions applicable to children (e.g., bulk assign) via the standard action system (DEC-179A).
- Inbox multi-select (MVP): do not add Inbox-specific multi-select/bulk action UX in MVP; keep Inbox single-selection/tap-to-edit behaviors only (DEC-180B).

- Inbox deep-link behavior (MVP): `/inbox` is paramless and is never NotFound; failures are handled via normal app readiness gating and inline error/retry patterns (DEC-181A).
- Inbox scope header rendering (MVP): `/inbox` never renders a `ScopeHeaderRow` (Inbox is not a scope entity); use only screen chrome + list section (DEC-182A).
- Inbox task rowKey convention (MVP): task rows in Inbox use an Inbox-specific `rowKey` namespace (e.g., `v1/inbox/task/id=<id>`) to avoid cross-screen key collisions and to stabilize per-screen scroll/ephemeral state (DEC-183B).

- Inbox empty-state modeling (MVP): do not model the empty-state as a list row; render it via standard section-level empty UI (no `rowKey` required) (DEC-184A).
- Inbox retry responsibility (MVP): retry triggers the Inbox feed section BLoC to resubscribe/reload; UI emits only a retry event and never calls repositories directly (DEC-185A).
- Inbox header row in Anytime (MVP): Anytime includes an Inbox project-like header row with a stable Anytime namespace key (e.g., `v1/anytime/group_header/project=inbox`) and label “Inbox”; tapping it navigates to `/inbox` per the Inbox header interaction rule (DEC-186A).

- Cross-screen list row modeling: shared flat `ListRowUiModel` union for My Day / Anytime / Scheduled; hierarchy is expressed via minimal structural metadata (e.g., `depth` + grouping keys) supporting only the needed shapes (Values → Projects → Tasks, Projects → Tasks). Value grouping headers are configurable per screen between header-only vs tappable-to-scope navigation (DEC-069A).
- Row identity keys (MVP): every `ListRowUiModel` variant (headers + entity rows) includes a required, stable `rowKey` used for Flutter keys, a11y identity, scroll targeting (e.g., jump-to-today), and stabilizing ephemeral UI state across rebuilds (DEC-127A).
- Async state convention: sections emit `AsyncSectionState<T>`; screen templates decide whether loading/empty/error renders inline or escalates to screen-level gating (DEC-070C).
- Selection convention: selection/multi-select state is screen-local in the screen BLoC (typed IDs), with platform-appropriate gestures; bulk actions are dispatched as intents via the central dispatcher (DEC-071A).

- My Day row mapping (MVP): allocation snapshot is mapped into the shared `ListRowUiModel` union using explicit header rows + minimal hierarchy metadata (DEC-084A). The row model must support Project rows with Task rows underneath (hierarchy) as an expected near-future shape.

- My Day hierarchy + ordering (MVP): My Day renders a 3-level hierarchy: `ValueHeader` → `ProjectRow` → child `TaskRow`s. The `ValueHeader` must display the Value priority. Values are ordered by highest priority first (ties broken deterministically, e.g., by display name then ID). Within each value group, preserve the allocation snapshot’s provided deterministic ordering for projects and tasks (fallback to stable name/ID ordering only if snapshot ordering is unavailable) (DEC-110).

- My Day rowKey conventions (MVP): My Day `rowKey` includes the local day key plus hierarchy disambiguators to avoid collisions and stabilize per-day ephemeral UI state. Minimum disambiguators: ProjectRow includes `localDay` + `valueId` + project grouping ref key (`project:<id>` or `inbox`); TaskRow includes `localDay` + `valueId` + `taskId` (DEC-187A).

- My Day header/row interactions (MVP): `ValueHeader` is tappable-to-scope (navigates to the corresponding scoped route, following the tappable header convention) (DEC-115A). `ProjectRow` tap opens the project editor route; expand/collapse (when supported) uses a separate affordance so tap remains “open editor” (DEC-116A).

- Row hierarchy metadata: minimal `depth` + grouping keys only (no generic tree/parent pointers); hierarchy is encoded by explicit header rows + row `depth` indentation conventions (DEC-072A).
- Group header behavior: configurable per screen/section between structural-only vs tappable-to-scope headers; tappable headers navigate to scope, with edits/actions via overflow as needed (DEC-073C).
- Scheduled semantics on rows: attach explicit `agendaMeta` (date + tag Starts/Ongoing/Due) to `taskRow`/`projectRow` variants; Scheduled BLoC owns deterministic ordering per locked agenda rules (DEC-074A).

- Scheduled optional buckets (MVP): implement Today/This Week/Next Week/Later as an additional header row variant in the shared row union (not separate sections); bucket collapse state remains ephemeral (not persisted) (DEC-085B).

- Scheduled bucket header row contract + collapse: bucket headers are purely structural list rows with `bucketKey`, `title`, optional range metadata, and ephemeral `isCollapsed`. Collapsing hides all rows until the next bucket header (including the date headers within the bucket). Jump-to-today may expand the bucket containing today if collapsed (DEC-112A).

- Scheduled bucket/date header relationship: within a bucket, `BucketHeaderRow` is followed by one or more `DateHeaderRow`s. Both expose grouping metadata so rendering/a11y can treat this as a hierarchy (bucket depth 0, date depth 1, item rows depth 2). Collapse behavior remains bucket-key driven (DEC-121A).

- Scheduled grouping metadata (concrete row fields): `BucketHeaderRow` exposes `bucketKey`; `DateHeaderRow` exposes a day key (e.g., `localDay`) and may include `bucketKey` when buckets are enabled; item rows in Scheduled carry the day key (and may carry `bucketKey` when buckets are enabled). Rendering/a11y treats hierarchy deterministically by scanning the flat list (headers + items) rather than requiring explicit parent pointers. Buckets are optional; when omitted, the feed is `DateHeaderRow` + item rows only (DEC-124B).

- Task editor entrypoint from feeds: row tap opens the task editor route (`/task/:id/edit`) and presentation follows the centralized EditorHost rules (sheet/panel in-shell, full-page on direct deep-link) (DEC-075A).
- Scope navigation trigger: tappable group headers navigate to the corresponding scoped route (`/value/:id/<screen>`, `/project/:id/<screen>`), preserving back-stack behavior (DEC-076A).
- Secondary filter persistence: persist only key filters per feed/scope (e.g., Scheduled range preset + tag filters), keep search queries ephemeral by default (DEC-077B).

- MVP row interactions (feeds): task/project row tap opens the editor; group headers are tappable-to-scope only when configured; overflow exposes edit plus a minimal set of non-destructive actions, all dispatched via intents/effects (DEC-103A).

- Overflow action composition (MVP): use a hybrid model — centralize action definitions (IDs/labels/icons/order) in a shared “action catalog”, while each screen/section BLoC decides availability based on domain capabilities (editable/read-only, etc.) and screen context. The UI builds overflow menus from the emitted action IDs and routes selections to the intent dispatcher (DEC-126C). Foundation implemented: `TileOverflowActionCatalog` + `TileIntentDispatcher` wiring for task/project tile overflows and entity detail AppBar overflow delete (with optional pop-on-success).

- Scheduled range UX: range preset is screen state and drives the domain query window; preset is persisted per DEC-077B and UI may “jump to today” without changing the preset (DEC-078A).
- Scheduled grouping: preserve day-group semantics, with optional higher-level UI buckets (Today/This Week/Next Week/Later) that contain day groups; bucket collapse state is ephemeral (not persisted) (DEC-079A).
- Scheduled filtering: only entity type filter (All/Tasks/Projects); Starts/Ongoing/Due tags are always shown and not user-filterable (DEC-080C).

- Scheduled “smallest preset includes today” definition (MVP): when jump-to-today needs to expand the range to include today (DEC-194B), choose the first preset that includes today from this priority order: `day → week → month → 90d → year` (DEC-198A).

- Scheduled persisted filters when preset auto-changes (MVP): when jump-to-today changes the persisted range preset (DEC-194B), keep the entity type filter and any other persisted Scheduled filters unchanged; only the range preset changes (DEC-199A).

- Scheduled empty-day inclusion: near-term dense vs later sparse behavior is driven by the selected range preset (e.g., week preset includes empty days for the whole week; longer presets include empty days for a shorter near-term window, then become sparse) (DEC-123B).

- Scheduled in-day grouping (MVP): within each `DateHeader` day group, do not insert tag subheaders; show Starts/Ongoing/Due as tags on task/project rows, and rely on deterministic ordering for grouping emphasis (DEC-113A).
- Scheduled empty days UX (MVP): when a `DateHeaderRow` has zero item rows (dense-range inclusion), render a subtle, non-interactive placeholder row under the header (e.g., “No scheduled items”) (DEC-128B).
- Scheduled time semantics (MVP): Scheduled ordering has no time-of-day concept; ordering is date-based only (DEC-114C).

- Scheduled header + placeholder rowKey conventions (MVP): ensure deterministic `rowKey`s for structural rows:
  - `BucketHeaderRow` uses `bucketKey`.
  - `DateHeaderRow` uses `localDay` and includes `bucketKey` when buckets are enabled.
  - Empty-day placeholder rows include `localDay` (and `bucketKey` when enabled) plus a placeholder kind discriminator (e.g., `kind=no_items`). (DEC-193A)

- Scheduled within-day tie-break ordering (MVP): after pinned → tasks before projects → tag priority, use stable name ordering then ID as tie-breakers (no additional time-based ordering) (DEC-117B).

- Scheduled “jump to today” semantics: jump-to-today is a scroll/positioning action and may expand the bucket containing today if collapsed (ephemeral). If today is not included in the currently selected range preset, jump-to-today changes the persisted range preset to the smallest preset that includes today and then scrolls to today (DEC-104A amended by DEC-194B).

- Scheduled jump-to-today scroll target: jump-to-today scrolls to the `DateHeaderRow` for today (top of today’s group), not to the first item row (DEC-122A).

- Scheduled row tap behavior for repeating occurrences (MVP): tapping a Scheduled row always opens the base entity editor (`/task/:id/edit` or `/project/:id/edit`) with no occurrence-specific route parameters in MVP (DEC-195A).

- `ScopeHeaderRow` rowKey conventions (MVP): `ScopeHeaderRow` uses a stable, screen-scoped key `v1/<screen>/scope_header/scope=<scopeKey>` where `scopeKey` is `value:<id>` or `project:<id>` (DEC-196A).

- Scheduled a11y label policy for Starts/Ongoing/Due tags (MVP): screen reader labels include the tag as a short prefix (e.g., “Due: <title>”) and include group context (bucket/date) derived by the renderer scanning `depth` + grouping keys; BLoCs emit structured fields only (DEC-197A).

- Scheduled occurrence engine failure UX (MVP): two-phase behavior for the Scheduled feed section — initial load is blocking until the first snapshot; after first snapshot, subsequent refresh/subscription failures are non-blocking (inline banner + retry) without discarding the last known-good list (DEC-200A).

- Persisted filter keying scheme (for DEC-086A): key records by `(screenKey, scopeKey)` where `scopeKey` is `global | value:<id> | project:<id>`, storing only explicitly allowed minimal keys per screen (DEC-105A).

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
  - `taskly_data`: entrypoints (examples: `sync.dart`, `db.dart`, `id.dart`) + `taskly_data.dart` barrel.
- Update app + other packages so they do not import from `package:taskly_*/src/...`.

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

#### Phase 1 / Batch 2 — `taskly_domain` public API cleanup + `lib/src` restructure

Status: Complete (2026-01-17).

Scope:
- App code imports use only `taskly_domain` public entrypoints (no deep imports into internal folders).
- `packages/taskly_domain/lib/domain/**` moved to `packages/taskly_domain/lib/src/**`.
- Public entrypoints under `packages/taskly_domain/lib/*.dart` updated to export from `src/**`.
- Internal `taskly_domain` imports updated to avoid `package:taskly_domain/domain/...`.

Notes:
- No new public exports were introduced; this was a mechanical path + boundary cleanup.
- Repo validated with `flutter analyze` (clean).

#### Phase 1 / Batch 3 — `taskly_data` public API cleanup + `lib/src` restructure

Status: Complete (2026-01-17).

Scope:
- Moved implementation from `packages/taskly_data/lib/data/**` to `packages/taskly_data/lib/src/**`.
- Introduced curated public entrypoints:
  - `packages/taskly_data/lib/db.dart`
  - `packages/taskly_data/lib/id.dart`
  - `packages/taskly_data/lib/sync.dart`
  - `packages/taskly_data/lib/repository_exceptions.dart`
  - keep `packages/taskly_data/lib/data_stack.dart` and `packages/taskly_data/lib/taskly_data.dart` as the primary app-facing API.
- Removed the DI-module export from `taskly_data` public API; app composition owns GetIt wiring.
- Updated internal imports within `taskly_data` and migrated app shims so no code imports from `package:taskly_data/data/...`.

Notes:
- App now initializes `TasklyDataStack`, then requests typed bindings and registers domain contracts in the app DI root.
- Repo validated with `flutter analyze` (clean).


### Completed packages (shipped)

- Day-1 data stack and auth/sync wiring (Package B): complete (2026-01-17).
  - `taskly_data` owns Supabase + PowerSync + Drift wiring behind `TasklyDataStack`.
  - Local data is cleared on sign-out and on user switch.

- App bootstrap modularization (Package C): complete (2026-01-17).
  - Bootstrap split into small modules under `lib/bootstrap/**`.
  - Post-auth services start/stop is auth-gated (starts after sign-in; stops on sign-out).

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

Progress:
- Completed (2026-01-17): Routing strangler entrypoints
  - Removed the unified catch-all `/:segment` route.
  - Added explicit `go_router` routes for MVP entrypoints (`/my-day`, `/anytime`, `/scheduled`) and other typed system screens.
  - Added router-level NotFound handling and UUID route param validation.
- Completed (2026-01-17): Inbox explicit screen
  - Added `/inbox` as a first-class route and main navigation destination.
  - Implemented `InboxBloc` subscribing to `TaskQuery.inbox()` and rendering via `TaskView`.
  - Added a “Create task” FAB that opens the new-task draft editor (no deep-linkable create route per DEC-172A/DEC-188A).
- In progress: Replace MVP screens with explicit Flutter screens (BLoCs + widgets), removing remaining USM rendering from the MVP user experience.

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

Progress:
- Completed (2026-01-17): Remove USM-era tile capability dependency from root domain
  - Moved tile capability model + resolver into presentation:
    - `lib/presentation/entity_views/tile_capabilities/entity_tile_capabilities.dart`
    - `lib/presentation/entity_views/tile_capabilities/entity_tile_capabilities_resolver.dart`
  - Deleted legacy USM/root-domain implementations:
    - `lib/domain/screens/templates/params/entity_tile_capabilities.dart` (+ generated outputs)
    - `lib/domain/screens/runtime/entity_tile_capabilities_resolver.dart`
  - Updated app + legacy USM + tests to import the new presentation locations.

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
- Tighten AI Copilot instructions: update `.github/copilot-instructions.md` to enforce best-practice boundaries (no deep imports, presentation boundary/BLoC ownership, go_router rules) and to require architecture-first work (review `doc/architecture/**` before significant changes, and update architecture docs when behavior/layering changes).

Acceptance criteria:
- `flutter analyze` clean.
- Test presets remain useful (`fast`, `quick`, `database`, `pipeline`).


## Ongoing architecture/maintainability improvement prompts

During implementation, agents should continuously flag opportunities as explicit decisions (with options + recommendation), for example:
- Consolidating duplicate env/logging utilities into `taskly_core`.
- Creating a reusable `taskly_data` “data stack” API instead of app-specific helpers.
- Reducing public API surface area to minimize coupling.
- Improving dependency direction (presentation -> domain contracts -> data impls).


## Handoff checklist (must not guess)

If any of these are still unclear at implementation time, agents must ask and must not assume.

- (none)





## Open questions (do not assume)

If any of these remain unanswered at implementation time, agents must ask and must not assume.

- (none)

