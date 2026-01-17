# Unified Screen Model — Architecture Summary

> Audience: developers + architects
>
> Scope: the current unified screen system in this repo (routing → system
> screen specs → interpretation → rendering → preferences persistence).

## 1) Executive Summary

Taskly renders screens through a single, typed, declarative model:

- **`ScreenSpec`**: typed screen definition (identity + chrome + template +
  slotted modules).
- **`ScreenTemplateSpec`**: page-level template (either a scaffold shell or a
  dedicated full-screen feature UI).
- **`ScreenModuleSpec`**: typed modules placed into slots (`header`, `primary`).
- **`ScreenSpecDataInterpreter`**: interprets a `ScreenSpec` into reactive
  **`ScreenSpecData`** by routing module params to typed interpreters.
- **`ScreenModuleInterpreterRegistry`**: centralizes module → interpreter
  mapping and ensures interpreter failures are localized to section-level
  error VMs.
- **`UnifiedScreenPageFromSpec` → `ScreenSpecBloc` → `ScreenTemplateWidget`**:
  builds UI from interpreted `ScreenSpecData`.
- **`ScreenActionsBloc`**: executes mutations triggered by templates/sections
  so widgets do not call domain services directly.

Presentation boundary (normative): widgets/pages do not call repositories or
domain/data services directly and do not subscribe to non-UI streams directly.
All cross-layer interaction for unified screens happens inside `ScreenSpecBloc`
(or other presentation BLoCs), which subscribes to domain-level
streams and emits widget-friendly state.

System screens are defined in code via `SystemScreenSpecs`. Screen ordering and
visibility preferences are persisted separately.

Routing supports the following URL patterns:

- **Screens (unified)**: `/:segment` → `Routing.buildScreen(screenKey)` → `SystemScreenSpecs` → unified rendering.
- **Entity editors (NAV-01)**:
  - Create: `/<entityType>/new` (e.g. `/task/new?projectId=abc`)
  - Edit: `/<entityType>/:id/edit`
- **Journal entry editor**:
  - Create: `/journal/entry/new` (optional query: `trackerIds=a,b,c`)
  - Edit: `/journal/entry/:id/edit`
- **Entity detail (read/composite)**: `/<entityType>/:id` (only for entities that have a read/composite surface)

There are also a small number of **route aliases/redirects** (for backwards
compatibility) implemented in the router (for example `/task/:id` →
`/task/:id/edit`, legacy `/projects` paths, and legacy `/someday` redirecting
to the canonical Anytime URL).

Important naming note:
- The system screen key for Anytime is still `someday`, but the canonical URL
  segment is `anytime` (see `Routing.screenPath` and `Routing.parseScreenKey`).

As of the core ED/RD cutover, **tasks are editor-only**: navigating to
`/task/:id` opens the task editor modal (there is no read-only task detail
page).

The supported entity route types are `task`, `project`, and `value`.

### 1.1 Non-negotiable invariants (keep the system clean)

These rules are intentionally strict. If you need to break one, treat it as an
architecture change and document the rationale.

- **Presentation boundary**: widgets/pages do not call repositories, and do not
  subscribe to domain/data streams directly. Use a presentation BLoC.
- **Reactive UI**: interpreters should expose reactive outputs (prefer
  `watch(...)`/streams) so offline-first DB changes are reflected automatically.
- **Section isolation**: interpreter failures yield a section-level error VM;
  do not fail the whole screen stream for section-specific errors.
- **Mutations funnel**: user-triggered mutations (create/edit/delete/pin/etc)
  are executed via `ScreenActionsBloc` (or a dedicated presentation BLoC), not
  from widgets.
- **Typed configuration**: do not introduce stringly-typed module params or
  ad-hoc JSON screen definitions. Extend the typed model.
- **No cross-layer imports**: domain must not import presentation; presentation
  must not depend on data implementations (only contracts/services).
- **Stable identity**: shipped `screenKey` values are stable; changes must
  include routing and preference-migration consideration.

### 1.2 Entity style resolution (tile consistency)

Unified screens frequently render tasks/projects/values through list-like
modules (lists, interleaved lists, hierarchy lists, agenda). To prevent UI
drift across screens, entity tile styling is resolved in the domain layer.

- **`EntityStyleV1`**: a typed styling contract (density + tile variants + small
  toggles) that describes how entity tiles should be rendered.
- **Resolution key**: `(ScreenTemplateSpec, SectionTemplateId)` (template +
  module type), so reusing a module yields consistent styling.
- **Overrides**: rare, explicit `EntityStyleOverrideV1` values may be applied on
  top of module defaults.

Resolution precedence:

1) `EntityStyleOverrideV1` (explicit override)
2) `(template, module)` default
3) global default

**Normative rule (enforcement):** presentation renderers must not instantiate
entity widgets (e.g. `TaskView`, `ProjectView`) directly. Renderers must build
tiles via a central tile builder that requires the resolved `EntityStyleV1`.

### 1.3 Tile action surface (capabilities + intents)

Unified screens also standardize *behavior* (what a tile can do) via a single
tile action surface.

- **Domain owns capabilities**: `EntityTileCapabilities` + `CompletionScope`
  are computed from domain models (and optional module overrides) and are
  carried on renderable item models (e.g. `ScreenItem.*`, `AgendaItem`).
- **Presentation owns intents + dispatcher**: tiles emit typed `TileIntent`
  values (context-free data). A `TileIntentDispatcher` executes those intents
  using `BuildContext` (for navigation/dialogs) and funnels mutations through
  `ScreenActionsBloc`.

Failure surfacing policy (non-negotiable):

- Tiles do not show local SnackBars for mutation failures.
- `ScreenActionsBloc` failure states are surfaced by exactly one listener at
  the authenticated app shell (via `scaffoldMessengerKey`), with dedupe/throttle
  keyed by `(failureKind, entityType, entityId)`.

---

## 2) Where Things Live (Folder Map)

### Domain model (screen "language")
- `ScreenSpec`, `ScreenTemplateSpec`, `ScreenModuleSpec`, `SlottedModules`,
  `ScreenChrome`, `ScreenGateSpec`
  - [lib/domain/screens/language/models/screen_spec.dart](../../lib/domain/screens/language/models/screen_spec.dart)

### Template/section IDs
- Canonical section template IDs used at render time
  - [lib/domain/screens/language/models/section_template_id.dart](../../lib/domain/screens/language/models/section_template_id.dart)

### Domain pipeline (spec -> data)
- Typed interpreters + spec interpreter (`ScreenSpecData`, `SectionVm`)
  - [lib/domain/screens/runtime/screen_spec_data_interpreter.dart](../../lib/domain/screens/runtime/screen_spec_data_interpreter.dart)
  - [lib/domain/screens/runtime/screen_module_interpreter_registry.dart](../../lib/domain/screens/runtime/screen_module_interpreter_registry.dart)
  - [lib/domain/screens/runtime/](../../lib/domain/screens/runtime/)
  - [lib/domain/screens/templates/interpreters/](../../lib/domain/screens/templates/interpreters/)

### System screen catalog
- System screen specs (typed)
  - [lib/domain/screens/catalog/system_screens/system_screen_specs.dart](../../lib/domain/screens/catalog/system_screens/system_screen_specs.dart)

### Persistence + maintenance
- Screen preferences persistence (visibility + ordering)
  - [lib/data/screens/repositories/screen_catalog_repository_impl.dart](../../lib/data/screens/repositories/screen_catalog_repository_impl.dart)

### Presentation (UI + BLoCs)
- Unified screen view (typed) + templates + renderers
  - [lib/presentation/screens/view/unified_screen_spec_page.dart](../../lib/presentation/screens/view/unified_screen_spec_page.dart)
  - [lib/presentation/screens/templates/screen_template_widget.dart](../../lib/presentation/screens/templates/screen_template_widget.dart)
- Mutations/actions boundary
  - [lib/presentation/screens/bloc/screen_actions_bloc.dart](../../lib/presentation/screens/bloc/screen_actions_bloc.dart)
- Per-section rendering switchboard
  - [lib/presentation/widgets/section_widget.dart](../../lib/presentation/widgets/section_widget.dart)
  - [lib/presentation/screens/templates/renderers/section_renderer_registry.dart](../../lib/presentation/screens/templates/renderers/section_renderer_registry.dart)

### Routing
- Single place for conventions and screen construction
  - [lib/presentation/routing/routing.dart](../../lib/presentation/routing/routing.dart)
  - [lib/presentation/routing/router.dart](../../lib/presentation/routing/router.dart)

Note: older migration docs may reference a legacy `lib/core/routing/` stack.
In the current codebase, the authenticated app shell is wired to the router in
`lib/presentation/routing/`.

---

## 3) High-Level Architecture

### 3.1 Component Diagram

The following diagram uses plain text so it renders in any Markdown viewer:

```text
+------------------------------+
|            Routing           |
|  GoRouter '/:segment'        |
|         '/<entity>/new'      |
|         '/<entity>/:id/edit' |
|         '/task/:id' (redirect) |
|         '/project/:id'       |
|         '/value/:id'         |
|  Routing.buildScreen         |
|  Routing.buildEntityDetail   |
+--------------+---------------+
               |
               v
+------------------------------+
|     Presentation Layer       |
|  UnifiedScreenPageFromSpec   |
|    -> ScreenSpecBloc         |
|    -> ScreenTemplateWidget   |
|       -> StandardScaffoldV1  |
|          -> SectionWidget(s) |
|             -> SectionRendererRegistry |
+--------------+---------------+
               |
               v
+------------------------------+
|   Presentation (Entities)    |
|  Entity detail route widget  |
|  (registered builder)        |
+--------------+---------------+
               |
               v
+------------------------------+
|         Domain services      |
|  ScreenSpecDataInterpreter   |
|    -> typed module           |
|       interpreters           |
+--------------+---------------+
               |
               v
+------------------------------+
|        Data / Persistence    |
|  screen_preferences (Drift)  |
+------------------------------+
```

### 3.2 End-to-End Runtime Flow (Sequence)

Plain-text sequence (portable Markdown):

```text
1) User navigates to '/:segment' (URL uses hyphens)
2) Routing.parseScreenKey(segment) -> screenKey (convert '-' → '_' and apply aliases, e.g. 'anytime' → 'someday')
3) Router calls Routing.buildScreen(screenKey)
4) Routing.buildScreen(screenKey) selects a ScreenSpec from SystemScreenSpecs
   (or returns a "Screen not found" widget if unknown)
5) UI builds UnifiedScreenPageFromSpec(spec)
6) ScreenSpecBloc subscribes to ScreenSpecDataInterpreter.watchScreen(spec)
7) ScreenSpecDataInterpreter:
   - evaluates optional screen gate criteria
   - if gate is active: emits ScreenSpecData with gate template and no sections
   - otherwise interprets modules:
     a) for each slotted module, routes typed params via ScreenModuleInterpreterRegistry
     b) wraps interpreter output into a typed SectionVm variant (params are strongly typed)
     c) interpreter failures yield section-level error VMs (screen stays alive)
     d) combines streams into one ScreenSpecData
8) ScreenSpecBloc converts domain/runtime outputs into widget-friendly state
  (and owns any stream subscriptions).
9) ScreenTemplateWidget renders ScreenSpecBloc state:
   - standardScaffoldV1: builds scaffold and renders header/primary sections
   - full-screen templates: render a dedicated feature page
10) SectionWidget delegates rendering to SectionRendererRegistry and switches
    on the SectionVm variant (no casting required)
```

### 3.3 Entity Routes (ED/RD) — Runtime Flow

Entity routes use NAV-01 conventions:
- **Editor (create)**: `/<entityType>/new` (route-backed modal editor)
- **Editor (edit)**: `/<entityType>/:id/edit` (route-backed modal editor)
- **Detail (read/composite)**: `/<entityType>/:id` (only for entities that have a detail surface)

Editor routes are handled by dedicated route pages (e.g. `TaskEditorRoutePage`).
Entity detail routes are handled by `Routing.buildEntityDetail`.

#### Editor route flow

```text
1) User navigates to '/<entityType>/new' or '/<entityType>/:id/edit'
2) GoRouter selects the corresponding editor route page
3) Editor route page opens the modal editor UX and then returns (pop)
```

#### Detail route flow

```text
1) User navigates to '/<entityType>/:id'
2) Router parses entityType + id
3) Router calls Routing.buildEntityDetail(entityType, id)
4) Routing resolves a registered builder for the entityType
  - Builders are registered at app startup (bootstrap) via Routing.registerEntityBuilders
5) Presentation builds the entity widget returned by the builder
6) Entity UX is entity-specific:
  - task: route is editor-only; opens editor modal and then returns
  - project/value: route builds a unified entity detail page
```

### 3.4 Editor/Detail Data Contract (ED/RD) — Overview

The unified screen model describes how **screens** are composed and rendered.
Entity ED/RD flows layer on top of that routing surface using a
FormBuilder-first editor contract.

This section is intentionally high-level; the detailed, normative contract is
in:

- [doc/backlog/editor_detail_template_contracts_formbuilder.md](../backlog/editor_detail_template_contracts_formbuilder.md)

#### Editor (ED) — Draft → Command

- Editors hold explicit `*Draft` state (the editable form model).
- On save, editors produce a `Create*Command` or `Update*Command`.
- Persistence consumes commands; UI does not write directly to repositories.

#### Validation — Field-addressable mapping

- Domain validation returns a structured, field-addressable error model.
- Presentation maps domain errors onto FormBuilder field errors using stable
  field keys (plus optional form-level errors).

#### Field keys — Typed and stable

- Each editor defines centralized, typed field keys (avoid ad-hoc string
  literals).
- Field keys are used consistently for:
  - FormBuilder field names
  - validation/error mapping
  - test assertions

#### Action surfaces — Template owns actions

- The editor template owns the action surface (save/cancel/delete placement).
- The reusable form module is fields-only and exposes a narrow interface (e.g.
  validate/save callbacks).

#### Detail (RD) — Read/composite pages do not embed editors

- Entity detail pages do not contain editor UI.
- Editing is launched via the standardized editor entry points (typically via
  `EditorLauncher`).
- After the editor closes, detail UI refreshes from the offline-first source of
  truth (reactive watches), not from editor return values.

### 3.5 Entity Editor/Detail (ED/RD) — Outline (developer rules)

This expands the ED/RD overview into a practical outline so changes stay
consistent.

#### Routing surface (NAV-01)

- **Create editor**: `/<entityType>/new` (optional query params like
  `?projectId=...` are allowed when they represent editor defaults).
- **Edit editor**: `/<entityType>/:id/edit`
- **Detail (read/composite)**: `/<entityType>/:id` (only when the entity has a
  real read/composite surface).
- **Task special case**: tasks are editor-only; `/task/:id` redirects/behaves
  like edit.

#### Responsibilities (what lives where)

- **Routing**: parses route params, selects the correct editor/detail route
  page, and uses `Routing.buildEntityDetail(...)` for RD surfaces.
- **Editor route pages**: own the modal editor UX lifecycle (open modal, await,
  pop). They should not persist data directly.
- **Draft -> Command**: editors maintain explicit `*Draft` state and produce a
  `Create*Command` / `Update*Command` on save.
- **Persistence**: consumes commands in lower layers (domain/data). The editor
  UI does not call repositories/services directly.

#### Validation contract (field-addressable)

- Domain validation returns a structured error model keyed by **stable typed
  field keys** (avoid ad-hoc string literals).
- Presentation maps domain errors onto FormBuilder field errors using those
  keys, plus optional form-level errors.

#### Refresh semantics (offline-first)

- After an editor closes, the parent/detail UI refreshes from the local DB via
  reactive watches (BLoC/domain streams), not from editor return values.
- Avoid passing “updated entity” objects back through navigation; treat the DB
  as the source of truth.

#### Testing expectations

- Unit tests: command mapping and domain validation error shapes.
- Widget tests: field key mapping and “save disabled / error displayed” flows.
- Integration tests (when needed): route conventions and modal lifecycle.

---

## 4) Core Concepts (What each piece is responsible for)

### 4.1 `ScreenSpec`

`ScreenSpec` is a typed, compile-time safe screen definition:
- Identity: `id`, `screenKey`, `name`
- Chrome: `ScreenChrome` (app bar actions, FAB ops, etc.)
- Template: `ScreenTemplateSpec` (shell/orchestration)
- Modules: `SlottedModules` (typed modules assigned to layout slots)
- Optional gate: `ScreenGateSpec` (swap template based on criteria)

See: [lib/domain/screens/language/models/screen_spec.dart](../../lib/domain/screens/language/models/screen_spec.dart)

### 4.2 `ScreenTemplateSpec` (page shell)

Templates determine the page-level layout and how slots are arranged.

Examples:
- `standardScaffoldV1`: scaffold with `header` + `primary` slots
- Full-screen feature templates: `settingsMenu`, `journalHub`, `focusSetupWizard`, …

See: [lib/domain/screens/language/models/screen_spec.dart](../../lib/domain/screens/language/models/screen_spec.dart)

### 4.3 `ScreenModuleSpec` (typed modules)

Modules carry typed params directly (no screen-definition JSON), and are mapped
to:
- a typed interpreter in `ScreenSpecDataInterpreter`
- a renderer in `SectionWidget`

See:
- [lib/domain/screens/language/models/screen_spec.dart](../../lib/domain/screens/language/models/screen_spec.dart)
- [lib/domain/screens/runtime/screen_spec_data_interpreter.dart](../../lib/domain/screens/runtime/screen_spec_data_interpreter.dart)

### 4.4 Rendering

- `UnifiedScreenPageFromSpec` hosts `ScreenSpecBloc` and displays loading/error
  states.
- `ScreenTemplateWidget` renders the selected `ScreenTemplateSpec`.
- `SectionWidget` renders each `SectionVm` produced from modules.

See:
- [lib/presentation/screens/view/unified_screen_spec_page.dart](../../lib/presentation/screens/view/unified_screen_spec_page.dart)
- [lib/presentation/screens/templates/screen_template_widget.dart](../../lib/presentation/screens/templates/screen_template_widget.dart)
- [lib/presentation/widgets/section_widget.dart](../../lib/presentation/widgets/section_widget.dart)

### 4.5 Mutations (UI actions) — `ScreenActionsBloc`

Unified screens follow a strict “read is reactive, write is explicit” rule:

- **Reads**: BLoCs subscribe to domain/data streams and emit renderable state.
- **Writes**: user-triggered mutations flow through a presentation BLoC.

In the unified screen pipeline, the standard write boundary is
`ScreenActionsBloc`:

- Events represent user intent (toggle completion, pin/unpin, delete, …).
- The bloc delegates to domain actions (`EntityActionService`).
- Failures are logged (`talker`) and surfaced as a short-lived failure state.

Entry points:

- Bloc: [lib/presentation/screens/bloc/screen_actions_bloc.dart](../../lib/presentation/screens/bloc/screen_actions_bloc.dart)
- State: [lib/presentation/screens/bloc/screen_actions_state.dart](../../lib/presentation/screens/bloc/screen_actions_state.dart)
- Action execution: [lib/domain/screens/runtime/entity_action_service.dart](../../lib/domain/screens/runtime/entity_action_service.dart)

#### UI invocation patterns

There are two supported invocation patterns:

1) **Fire-and-forget** (best for cheap toggles)

- UI dispatches an event and returns immediately.
- If the write fails, the bloc emits `ScreenActionsFailureState` and then
  returns to idle so future failures can be surfaced again.

2) **Await completion** (best for flows that must sequence UI)

- Event carries an optional `Completer<void>`.
- UI awaits the completer to sequence follow-up actions (e.g. pop a page after
  delete completes).

This pattern is used in the codebase for destructive actions and pin/unpin.

#### Surfacing failures to the user

`ScreenActionsBloc` failures are ephemeral; without a listener they will only
be visible in logs.

Recommendation for unified screens and entity detail screens:

- Add a `BlocListener<ScreenActionsBloc, ScreenActionsState>` at the page/screen
  root (above templates/sections).
- When receiving `ScreenActionsFailureState`, show a `SnackBar`.

Use the existing friendly error mapping and localization utilities:

- Prefer `friendlyErrorMessageForUi(state.error, l10n)` when `error` is present
  (fallback to `state.message` when it is not).
- Helper reference: [lib/presentation/shared/errors/friendly_error_message.dart](../../lib/presentation/shared/errors/friendly_error_message.dart)

If you need richer error UX (undo actions, retries, confirmation), keep it in
presentation. Do not move UI concerns (SnackBars, dialogs) into domain.

---

## 5) Persistence & System Screen Lifecycle

### 5.1 What is persisted

- **System screens** are defined in code via `SystemScreenSpecs`.
- **Preferences** (visibility + sort order) are stored in Drift
  (`screen_preferences`).
- The preferences repository can return `null` for unknown screen keys.

Key entry points:
- Repository (system screens + DB preferences):
  [lib/data/screens/repositories/screen_catalog_repository_impl.dart](../../lib/data/screens/repositories/screen_catalog_repository_impl.dart)
- Catalog (system screen specs):
  [lib/domain/screens/catalog/system_screens/system_screen_specs.dart](../../lib/domain/screens/catalog/system_screens/system_screen_specs.dart)

---

## 6) Configuration Catalog (Typed)

This section summarizes the configuration surface area available to build
system screens without adding new UI code.

### 6.1 Screen identity & composition (`ScreenSpec`)

| Field | Meaning | When to set / notes |
|---|---|---|
| `screenKey` | Stable key used in routing and lookups | Treat as immutable once shipped; URL segment uses hyphens (`_` → `-`). |
| `name` | Display name (AppBar + navigation) | User-facing; avoid changing for system screens unless you also consider UX implications. |
| `template` | Screen template | Choose a shell (`standardScaffoldV1`) or a full-screen feature template. |
| `modules` | Slotted modules | Main way to compose a screen (`header` + `primary`). |
| `chrome` | UI chrome configuration | Use for icon/FAB/app bar actions/badges. |

### 6.2 Chrome configuration (`ScreenChrome`)

See: [lib/domain/screens/language/models/screen_chrome.dart](../../lib/domain/screens/language/models/screen_chrome.dart)

| Option | Type | Description | When to use |
|---|---|---|---|
| `iconName` | `String?` | Icon identifier for navigation | Set for any screen that appears in nav. |
| `badgeConfig` | `BadgeConfig` | How navigation badge is computed | Use when nav badge needs to reflect a specific section/query; defaults to `fromFirstSection()`. |
| `fabOperations` | `List<FabOperation>` | Which FAB actions are available | Use for create actions like task/project/value. |
| `appBarActions` | `List<AppBarAction>` | AppBar action buttons | Use for settings/help or other global actions. |
| `settingsRoute` | `String?` | Route to open for settingsLink action | Use when `appBarActions` includes `settingsLink`. |

**Guidance**
- Prefer one primary FAB per screen; if you need multiple, consider a different interaction pattern or a custom `ScreenTemplateSpec`.
- Keep chrome declarative: avoid hardcoding per-screen app bars in renderers unless you are building a dedicated full-screen feature template.


### 6.3 Module configuration (`ScreenModuleSpec`)

| Option | Type | Description | When to use |
|---|---|---|---|
| `params` | typed params | Module params (queries, layout, gate config, etc.) | Required for most modules. |
| `title` | `String?` | Optional title override | Use to label multiple instances of the same module on a screen. |

Note: modules currently do not have an `enabled` flag; disable by removing the
module or gating at the screen level.

### 6.4 Module catalog (existing configuration options)

#### 6.4.1 Section modules (rendered by `SectionWidget`)

These correspond to `ScreenModuleSpec` cases and are rendered using
`SectionTemplateId`.

| SectionTemplateId | Family | Params type | What it renders | When to use |
|---|---|---|---|---|
| `task_list_v2` | Query / List (tasks) | `ListSectionParamsV2` | Task list driven by `TaskQuery` | Default for task-based screens and entity detail (project tasks). |
| `value_list_v2` | Query / List (values) | `ListSectionParamsV2` | Value list driven by `ValueQuery` | Value dashboards and selection. |
| `interleaved_list_v2` | Query / List (mixed) | `InterleavedListSectionParamsV2` | Mixed list feed (tasks/projects/values) | When one feed combines multiple sources. |
| `hierarchy_value_project_task_v2` | Query / Hierarchy | `HierarchyValueProjectTaskSectionParamsV2` | Hierarchical Value → Project → Task view | When you need structured grouping and drill-down scanning. |
| `agenda_v2` | Agenda | `AgendaSectionParamsV2` | Date-grouped agenda view | Scheduled/time-sliced views (upcoming / “calendar-ish” feeds). |
| `attention_banner_v2` | Attention | `AttentionBannerSectionParamsV2` | Attention banner | Top-of-screen “attention” summary banners. |
| `attention_inbox_v1` | Attention | `AttentionInboxSectionParamsV1` | Attention inbox | Review/attention flow UI. |
| `entity_header` | Entity detail | `EntityHeaderSectionParams` | Entity header section (project/value) | Top section for entity detail screens. |
| `my_day_hero_v1` | My Day | none | My Day hero/summary module | My Day header composition. |
| `my_day_ranked_tasks_v1` | My Day | none | My Day “Today” ranked tasks section | My Day primary content (allocation-driven). |
| `create_value_cta_v1` | CTA | none | Values screen CTA (create value) | Values screen footer. |
| `journal_today_composer_v1` | Journal | none | Journal Today composer/quick-add entry launcher | Journal screen header. |
| `journal_today_entries_v1` | Journal | none | Journal Today entries list | Journal screen primary. |
| `journal_history_teaser_v1` | Journal | none | CTA that navigates to journal history | Journal screen header. |
| `journal_history_list_v1` | Journal | none | Journal history list | `journal_history` system screen. |
| `journal_manage_trackers_v1` | Journal | none | Journal tracker management section | `journal_manage_trackers` system screen. |

#### 6.4.1.1 Recommended module taxonomy (minimize variants)

The current modules fall into a small number of **UI paradigms**. When
introducing new screens or refactoring existing ones, try to stay inside these
families instead of introducing new one-off modules/templates.

- **Query family** (list-like): the primary user intent is “show results of a
  query” (flat list, mixed list, or a structured hierarchy). This family is
  where most “task/project/value view types” should converge.
  - Flat lists: `task_list_v2`, `value_list_v2`
  - Mixed lists: `interleaved_list_v2`
  - Structured lists: `hierarchy_value_project_task_v2` (a Query variant with
    deterministic grouping/structure)
- **Agenda family**: the primary user intent is “show time-sliced work” (date
  buckets, ongoing, upcoming). Agenda is not just a query list; it carries
  distinct semantics and UX constraints.

Practical boundary rule:
- If the main axis is **entity grouping/filtering**, stay in Query.
- If the main axis is **time**, use Agenda.

This separation helps keep renderers simpler and keeps `EntityStyleV1` defaults
stable per family.

Note: `SectionTemplateId` includes some legacy IDs for former custom screens.
In the typed USM pipeline, section rendering should be driven by `SectionVm`
variants (and the corresponding `SectionTemplateId` values listed above).

#### 6.4.2 Full-screen templates (rendered by `ScreenTemplateWidget`)

These correspond to `ScreenTemplateSpec` cases. They render dedicated pages and
do not rely on section modules.

| ScreenTemplateSpec | Params | What it renders |
|---|---|---|
| `settingsMenu` | none | Settings feature UI. |
| `journalHub` | none | Journal hub UI (Today / History / Trackers). |
| `attentionRules` | none | Attention rules UI. |
| `focusSetupWizard` | none | Focus setup wizard UI. |
| `trackerManagement` | none | Tracker management UI. |
| `statisticsDashboard` | none | Statistics dashboard UI (placeholder at the moment). |
| `myDayFocusModeRequired` | none | Gate screen shown when My Day focus mode is missing. |

Note: `entityDetailScaffoldV1` is also a screen template, but it is used for
entity read/composite (RD) surfaces that still render sections via modules.

**Guidance**
- Prefer *parameterized* templates (`*_list_v2`, `agenda_v2`, `allocation`) for screens where the primary purpose is "show data in a consistent, configurable way".
- Prefer *no-params* templates for screens that are effectively standalone "apps within the app" (settings dashboards, management screens). If these start needing configurable variation, promote them to typed params/modules instead of encoding flags into unrelated configs.

### 6.5 Entity Style (`EntityStyleV1`) and tile variants

For list-like modules that render entity tiles (tasks/projects/values), styling
is driven by a domain-resolved `EntityStyleV1`.

Key rules:

- The domain layer resolves an `EntityStyleV1` per section using
  `(ScreenTemplateSpec, SectionTemplateId)` via `EntityStyleResolver`.
- Section params may provide a rare, explicit `EntityStyleOverrideV1`.
- Presentation renderers must not infer styling ad-hoc.

**Normative enforcement (presentation)**

- Renderers must not directly instantiate entity view widgets
  (`TaskView`/`ProjectView`/`ValueView`).
- Renderers must use the centralized builder:
  - `ScreenItemTileBuilder`: [lib/presentation/screens/tiles/screen_item_tile_builder.dart](../../lib/presentation/screens/tiles/screen_item_tile_builder.dart)
- Field-level rendering policies (like date labeling) should not be duplicated per-tile; use the field catalog:
  - `DateLabelFormatter`: [lib/presentation/field_catalog/formatters/date_label_formatter.dart](../../lib/presentation/field_catalog/formatters/date_label_formatter.dart)

**Where variants are defined**
- Screen item tiles: [lib/domain/screens/templates/params/screen_item_tile_variants.dart](../../lib/domain/screens/templates/params/screen_item_tile_variants.dart)
- Attention/review tiles: [lib/domain/screens/templates/params/attention_tile_variants.dart](../../lib/domain/screens/templates/params/attention_tile_variants.dart)

**Common style inputs**
- `EntityStyleV1`: resolved at runtime and carried on `SectionVm`
- `EntityStyleOverrideV1`: optional override in relevant params models
- Allocation modules: `taskTileVariant`
- Summary/alerts modules: summary tile variants (attention/review)

**Current supported variants**
- `TaskTileVariant`: `list_tile`
- `ProjectTileVariant`: `list_tile`
- `ValueTileVariant`: `compact_card`
- `AttentionItemTileVariant`: `standard`
- `ReviewItemTileVariant`: `standard`

**When to add a new variant**

Add a new variant only when a real screen requires a distinct presentation and
there is (or will be) a concrete renderer implementation for it.

Guidance:

- Prefer adding a new field to `EntityStyleV1` (and updating resolver defaults)
  when a style decision should be consistent across screens/modules.
- Use a variant when the change is a cohesive, named UI mode for a specific
  entity tile type (task/project/value/attention/review).
- Avoid “mega variants” that implicitly change multiple unrelated UI
  decisions.
- Add new enum values deliberately: they are API surface area and should be
  test-covered.

### 6.6 Presentation-only list filters (filter bar pattern)

Some list-style modules support optional, *presentation-only* filter controls
that are enabled by typed params and rendered by the section renderer.

This pattern exists to let system screens opt into lightweight filtering
without introducing new screen templates, domain concepts, or persistence.

#### 6.6.1 What is configurable (domain)

List-like params expose an optional `filters` field:
- `ListSectionParamsV2.filters`: `SectionFilterSpecV2`
  - [lib/domain/screens/templates/params/list_section_params_v2.dart](../../lib/domain/screens/templates/params/list_section_params_v2.dart)
- `InterleavedListSectionParamsV2.filters`: `SectionFilterSpecV2`
  - [lib/domain/screens/templates/params/interleaved_list_section_params_v2.dart](../../lib/domain/screens/templates/params/interleaved_list_section_params_v2.dart)

`SectionFilterSpecV2` is intentionally *small* and controls only:
- which controls are visible (e.g. projects-only toggle, value picker)
- how value filtering behaves (e.g. any-values vs primary-only)

Important: enabling `filters` does **not** change interpreter behavior or data
fetching. The domain produces the same `items` stream.

#### 6.6.2 What is owned by presentation (state + UI)

Filter state is ephemeral and owned by the renderer (presentation layer). It is
not persisted and does not flow through `ScreenSpecDataInterpreter`.

Current implementation notes:
- The interleaved list renderer holds filter state (e.g. selected value id,
  projects-only toggle) and filters `ScreenItem`s in-memory.
  - [lib/presentation/screens/templates/renderers/interleaved_list_renderer_v2.dart](../../lib/presentation/screens/templates/renderers/interleaved_list_renderer_v2.dart)
- Reusable filter UI belongs in template-level widgets under presentation:
  - [lib/presentation/screens/templates/widgets/section_filter_bar_v2.dart](../../lib/presentation/screens/templates/widgets/section_filter_bar_v2.dart)

**Important exception (current state):** `entityDetailScaffoldV1` has a
project-only task completion filter implemented at the *template* level (with
local persistence via `PageStorage`) rather than as a Query-family module.

Refactor target:
- Prefer expressing this as a shared Query/List module concern (or a small
  reusable “query filter bar” module) so entity detail screens do not carry
  bespoke filter logic in the template.
- Current implementation reference:
  [lib/presentation/screens/templates/screen_template_widget.dart](../../lib/presentation/screens/templates/screen_template_widget.dart)

Rationale:
- The unified screen model stays typed/config-driven.
- The domain remains the source of truth for *what exists*; filters are a local
  view concern for *what to show right now*.

#### 6.6.3 When not to use this pattern

Use a different mechanism when:
- The filter must affect the underlying query/data source.
  - Prefer encoding it into `DataConfig`/query params so the interpreter fetches
    the correct data.
- The filter must persist across sessions/screens.
  - Prefer screen preferences persistence or a dedicated domain setting.

### 6.7 Common nested config types (used by multiple templates)

These configs show up inside section params (especially list templates) and are the primary knobs for reuse.

#### 6.7.1 `DataConfig` (what to fetch)

See: [lib/domain/screens/language/models/data_config.dart](../../lib/domain/screens/language/models/data_config.dart)

| Variant | Fields | When to use |
|---|---|---|
| `task` | `query: TaskQuery` (required) | When the section's primary entity is tasks. |
| `project` | `query: ProjectQuery` (required) | When the section's primary entity is projects. |
| `value` | `query: ValueQuery?` (optional) | When the section's primary entity is values; omit `query` to use defaults. |
| `journal` | `query: JournalQuery?` (optional) | When fetching journal entries (not used by the current V2 list modules). |

#### 6.7.2 `ListSeparatorV2` and `EnrichmentPlanV2`

Many V2 list-like sections use:

- `ListSeparatorV2` to control separator/spacing behavior in list renderers
- `EnrichmentPlanV2` to request computed metadata (e.g. value stats, agenda tags)

Structural UI differences (for example, hierarchy vs flat list) are expressed
via **module selection** (for example `hierarchyValueProjectTaskV2` vs
`interleavedListV2`) rather than a layout-discriminator union.

Enrichment is **opt-in** per section. A section that does not request an
enrichment will not pay its compute cost and will not observe its behavior.

See:
- [lib/domain/screens/templates/params/list_section_params_v2.dart](../../lib/domain/screens/templates/params/list_section_params_v2.dart)
- [lib/domain/screens/runtime/section_data_service.dart](../../lib/domain/screens/runtime/section_data_service.dart)

Current enrichment items include:
- Value stats (`EnrichmentPlanItemV2.valueStats`) and open task counts
- Agenda tags (`EnrichmentPlanItemV2.agendaTags`) derived from a selected date field
- Allocation snapshot membership (`EnrichmentPlanItemV2.allocationMembership`)

##### Allocation snapshot membership enrichment

`allocationMembership` exposes **global allocation state** derived from the
latest allocation snapshot for the **current UTC day**.

Intended use:
- My Day requests it to render allocation-driven grouping and stable ordering.
- Screens like Someday do not request it, so allocation semantics do not leak
  into query-driven screens.

Provided fields (keyed by `taskId`) in `EnrichmentResultV2`:
- `isAllocatedByTaskId`: whether the task is present in the latest snapshot
- `allocationRankByTaskId`: stable ordering hint for allocated tasks
- `qualifyingValueIdByTaskId`: optional Value grouping override for allocated tasks

Renderer rule of thumb:
- If these fields are absent/empty, renderers must behave as if allocation does
  not exist.

**Full-screen templates**

Some templates are full-screen feature UIs. They are defined by
`ScreenTemplateSpec` and rendered by `ScreenTemplateWidget`.

- [lib/domain/screens/language/models/screen_spec.dart](../../lib/domain/screens/language/models/screen_spec.dart)
- [lib/presentation/screens/templates/screen_template_widget.dart](../../lib/presentation/screens/templates/screen_template_widget.dart)

### 6.8 Decision guide: module vs template vs params vs enrichment

Use this to keep the unified screen model from turning into an ad-hoc feature
flag/config system.

| You want to… | Prefer | Why |
|---|---|---|
| Add a new type of section UI that can be reused across multiple screens | **New section module** (`ScreenModuleSpec` + interpreter + renderer) | Keeps UI composition declarative; reuse stays cheap and consistent |
| Build a standalone feature UI with its own layout and navigation | **Full-screen template** (`ScreenTemplateSpec`) | Avoids nested scaffolds and one-off per-screen widget trees |
| Make a small, localized visual tweak (density / tile variant) | **`EntityStyleV1`** (resolver default) or **`EntityStyleOverrideV1`** | Keeps tile modes consistent across screens |
| Offer a small set of named presentation modes for a tile type | **Variant enum** (e.g. `TaskTileVariant`) | Ensures modes are explicit, testable, and renderer-driven |
| Add computed metadata used by multiple renderers (and it can be optional) | **Enrichment** (`EnrichmentPlanV2`) | Compute is opt-in; avoids bloating base models |
| Add a local “show/hide” control that should not affect the underlying query | **Presentation-only filters** | Keeps domain queries stable; avoids persistence and extra data fetch logic |

Rules of thumb:

- If it must change what data is fetched, it is not a presentation-only filter;
  encode it into `DataConfig`/queries and interpreter behavior.
- If it must persist across sessions, use preferences or a domain setting.
- If it is specific to one screen and unlikely to be reused, consider whether
  it belongs in a full-screen template (feature UI) rather than a new module.

---



## 7) Quick Start (Build System Screens)

This section shows concrete examples of how to compose screens using existing
configuration types.

> Note: system screens are authored in code under `SystemScreenSpecs`.

### 7.1 Example: "Inbox-like" system screen spec

Goal: a screen with an issues summary + task list, plus a task-create FAB.

```dart
import 'package:taskly_bloc/domain/screens/language/models/data_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/fab_operation.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_chrome.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_spec.dart';
import 'package:taskly_bloc/domain/screens/templates/params/attention_banner_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/entity_style_v1.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';

final screen = ScreenSpec(
  id: 'example_inbox_like',
  screenKey: 'example_inbox_like',
  name: 'Example Inbox',
  template: const ScreenTemplateSpec.standardScaffoldV1(),
  chrome: const ScreenChrome(
    iconName: 'inbox',
    fabOperations: [FabOperation.createTask],
  ),
  modules: SlottedModules(
    header: [
      ScreenModuleSpec.attentionBannerV2(
        params: AttentionBannerSectionParamsV2(
          buckets: const ['action', 'review'],
          entityTypes: const ['task'],
        ),
      ),
    ],
    primary: [
      ScreenModuleSpec.taskListV2(
        params: ListSectionParamsV2(
          config: DataConfig.task(query: TaskQuery.inbox()),
          // Optional, rare override (most screens rely on resolver defaults).
          entityStyleOverride: const EntityStyleOverrideV1(
            density: EntityDensityV1.compact,
          ),
          separator: ListSeparatorV2.divider,
        ),
      ),
    ],
  ),
);
```

### 7.2 Example: Multiple modules with titles

Use the optional `title:` on a module when you need to disambiguate repeated
instances.

### 7.3 Example: Full-screen templates (feature UIs)

Some templates render as a full-screen page (to avoid nested scaffolds).

```dart
import 'package:taskly_bloc/domain/screens/language/models/screen_spec.dart';

final screen = ScreenSpec(
  id: 'settings_example',
  screenKey: 'settings_example',
  name: 'Settings Example',
  template: const ScreenTemplateSpec.settingsMenu(),
);
```

When to use:
- Use these templates for "pages" that already have their own internal layout
  and should not be embedded within another scaffold.

---

## 8) How to Extend the System (Developer Guide)

### 8.1 Add a new module/template (checklist)

1. **Define/extend the typed API**
  - Add a new case to `ScreenModuleSpec` (or `ScreenTemplateSpec` if it is a
    full-screen feature UI).
  - If it is a section-style module, add a corresponding `SectionVm` variant.
2. **Define params (optional)**
  - Create a params model in `lib/domain/screens/templates/params/`.
3. **Implement the interpreter (domain)**
  - Add a typed interpreter under `lib/domain/screens/templates/interpreters/`.
  - Prefer `watch(...)` returning a stream so the UI stays reactive.
4. **Register the module interpreter (domain registry)**
  - Wire the new `ScreenModuleSpec` case into
    `DefaultScreenModuleInterpreterRegistry`.
  - Ensure errors are localized: map interpreter failures to a `SectionVm.*`
    with `error:` set, rather than failing the whole screen stream.
5. **Implement + register the renderer (presentation registry)**
  - Add a renderer under `lib/presentation/screens/templates/renderers/`.
  - Wire it into `DefaultSectionRendererRegistry` using `section.map(...)`.
6. **Wire DI**
  - Ensure DI provides the interpreter and the registries.
7. **Add tests**
  - Domain: interpreter outputs and error localization.
  - Presentation: renderer behavior for `isLoading` / `error` / missing data.

If the module needs mutations (create/edit/delete/pin/etc), add an event to
`ScreenActionsBloc` and execute it through the domain `EntityActionService`.

See also: “Mutations (UI actions) — `ScreenActionsBloc`” in this document.

### 8.2 Add/modify a system screen

- Edit/extend `SystemScreenSpecs` to add/modify a `ScreenSpec`.
- If it should appear in primary navigation order, update the default
  preferences/ordering logic (or seed initial preferences if needed).

See: [lib/domain/screens/catalog/system_screens/system_screen_specs.dart](../../lib/domain/screens/catalog/system_screens/system_screen_specs.dart)

### 8.3 Common change cookbooks (what to touch)

These recipes are intentionally explicit so new contributors don’t miss a
registry, DI wiring, or tests.

#### A) Add a new section module

- Add a new `ScreenModuleSpec` case and any typed params model.
- Add a corresponding `SectionVm` variant.
- Implement the domain interpreter and wire it into
  `DefaultScreenModuleInterpreterRegistry`.
- Implement the renderer and wire it into `DefaultSectionRendererRegistry`.
- Wire DI for interpreter/registries.
- Add tests:
  - interpreter output + error localization (section-level failures)
  - renderer handling of loading/error/empty states

#### B) Add a new full-screen template

- Add a `ScreenTemplateSpec` case.
- Implement template rendering in `ScreenTemplateWidget`.
- Prefer to keep the template internally BLoC-driven; do not have it call
  repositories directly from widgets.

#### C) Add a new system screen (no new UI)

- Add/modify a `ScreenSpec` in `SystemScreenSpecs`.
- Ensure `screenKey` is stable; if changing a shipped key, plan for routing and
  preference migration.
- If it must appear in navigation defaults, update default ordering/visibility
  seeding logic.

#### D) Add a new presentation-only filter

- Add to `SectionFilterSpecV2` (domain) only what is required to configure the
  filter’s *presence/behavior*.
- Keep filter state ephemeral in presentation (renderer/widget), and filter
  `ScreenItem`s in-memory.
- If you find yourself needing the filter to change data fetching, stop and
  move the behavior into `DataConfig`/queries/interpreters instead.

#### E) Add a new enrichment

- Add a new `EnrichmentPlanItemV2` and implement it in the domain enrichment
  pipeline.
- Keep enrichments optional and cheap by default; require explicit opt-in via
  `EnrichmentPlanV2` in section params.

---

## 9) Operational Notes & Common Pitfalls

- **Missing module wiring**: adding a new `ScreenModuleSpec` without updating
  `DefaultScreenModuleInterpreterRegistry` and `DefaultSectionRendererRegistry`
  will fail at runtime.
- **Screen key changes**: changing `screenKey` affects routing and preferences.
  Treat shipped keys as stable.
- **Gates**: when a gate is active, `ScreenSpecData` renders the gate template
  with no sections.

**Error semantics rule of thumb**
- Prefer section-local errors: interpreter failures should surface as
  `SectionVm.*(error: ...)` so the screen stays alive.
- Reserve `ScreenSpecData.error` for truly fatal screen-level failures.

---

## 10) References

- Unified UI entry point:
  [lib/presentation/screens/view/unified_screen_spec_page.dart](../../lib/presentation/screens/view/unified_screen_spec_page.dart)
- Template rendering:
  [lib/presentation/screens/templates/screen_template_widget.dart](../../lib/presentation/screens/templates/screen_template_widget.dart)
- Interpreter pipeline:
  [lib/domain/screens/runtime/screen_spec_data_interpreter.dart](../../lib/domain/screens/runtime/screen_spec_data_interpreter.dart)
- System screens:
  [lib/domain/screens/catalog/system_screens/system_screen_specs.dart](../../lib/domain/screens/catalog/system_screens/system_screen_specs.dart)
- Routing conventions:
  [lib/presentation/routing/routing.dart](../../lib/presentation/routing/routing.dart)
