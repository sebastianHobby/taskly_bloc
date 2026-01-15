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
- **`UnifiedScreenPageFromSpec` → `ScreenSpecBloc` → `ScreenTemplateWidget`**:
  builds UI from interpreted `ScreenSpecData`.

Presentation boundary (normative): widgets/pages do not call repositories or
domain/data services directly and do not subscribe to non-UI streams directly.
All cross-layer interaction for unified screens happens inside `ScreenSpecBloc`
(or other presentation BLoCs), which subscribes to domain-level
streams and emits widget-friendly state.

System screens are defined in code via `SystemScreenSpecs`. Screen ordering and
visibility preferences are persisted separately.

Routing follows two supported URL patterns:

- **Screens**: `/:segment` → `Routing.buildScreen(screenKey)` → `SystemScreenSpecs` → unified rendering.
- **Entity editors (NAV-01)**:
  - Create: `/<entityType>/new` (e.g. `/task/new?projectId=abc`)
  - Edit: `/<entityType>/:id/edit`
  - Legacy task detail route: `/task/:id` redirects to `/task/:id/edit`
- **Entity detail (read/composite)**: `/<entityType>/:id` (only for entities with a detail surface)

As of the core ED/RD cutover, **tasks are editor-only**: navigating to
`/task/:id` opens the task editor modal (there is no read-only task detail
page).

The supported entity route types are `task`, `project`, and `value`.

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
- Per-section rendering switchboard
  - [lib/presentation/widgets/section_widget.dart](../../lib/presentation/widgets/section_widget.dart)

### Routing
- Single place for conventions and screen construction
  - [lib/presentation/routing/routing.dart](../../lib/presentation/routing/routing.dart)
  - [lib/presentation/routing/router.dart](../../lib/presentation/routing/router.dart)

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
2) Routing.parseScreenKey(segment) -> screenKey (convert '-' back to '_')
3) Router calls Routing.buildScreen(screenKey)
4) Routing.buildScreen(screenKey) selects a ScreenSpec from SystemScreenSpecs
   (or returns a "Screen not found" widget if unknown)
5) UI builds UnifiedScreenPageFromSpec(spec)
6) ScreenSpecBloc subscribes to ScreenSpecDataInterpreter.watchScreen(spec)
7) ScreenSpecDataInterpreter:
   - evaluates optional screen gate criteria
   - if gate is active: emits ScreenSpecData with gate template and no sections
   - otherwise interprets modules:
     a) for each slotted module, routes typed params to a typed interpreter
     b) wraps interpreter output into SectionVm (with a SectionTemplateId)
     c) combines streams into one ScreenSpecData
8) ScreenSpecBloc converts domain/runtime outputs into widget-friendly state
  (and owns any stream subscriptions).
9) ScreenTemplateWidget renders ScreenSpecBloc state:
   - standardScaffoldV1: builds scaffold and renders header/primary sections
   - full-screen templates: render a dedicated feature page
10) SectionWidget renders each SectionVm by section.templateId
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

| SectionTemplateId | Params type | What it renders | When to use |
|---|---|---|---|
| `issues_summary` | `IssuesSummarySectionParams` | Issues/warnings summary | Top-of-screen attention summary. |
| `check_in_summary` | `CheckInSummarySectionParams` | Check-in summary | Summary section on focus screens. |
| `allocation_alerts` | `AllocationAlertsSectionParams` | Allocation-related alerts | Warning banners near allocation sections. |
| `allocation` | `AllocationSectionParams` | Allocation/focus view for tasks | "My Day" / focus experiences. |
| `task_list_v2` | `ListSectionParamsV2` | Task list driven by `TaskQuery` | Default for task-based screens. |
| `project_list_v2` | `ListSectionParamsV2` | Project list driven by `ProjectQuery` | Project overviews and selection. |
| `value_list_v2` | `ListSectionParamsV2` | Value list driven by `ValueQuery` | Value dashboards and selection. |
| `interleaved_list_v2` | `InterleavedListSectionParamsV2` | Mixed list feed (tasks/projects/values) | When one feed combines multiple sources. |
| `hierarchy_value_project_task_v2` | `HierarchyValueProjectTaskSectionParamsV2` | Hierarchical Value → Project → Task view | When you need a structured hierarchy view. |
| `agenda_v2` | `AgendaSectionParamsV2` | Date-grouped agenda view | Upcoming/scheduled/calendar-like screens. |
| `entity_header` | `EntityHeaderSectionParams` | Entity header section (project/value) | Top section for entity detail screens. |

#### 6.4.2 Full-screen templates (rendered by `ScreenTemplateWidget`)

These correspond to `ScreenTemplateSpec` cases. They render dedicated pages and
do not rely on section modules.

| ScreenTemplateSpec | Params | What it renders |
|---|---|---|
| `settingsMenu` | none | Settings feature UI. |
| `journalHub` | none | Journal hub UI (Today / History / Trackers). |
| `journalTimeline` | none | Legacy placeholder Journal timeline UI (being phased out). |
| `navigationSettings` | none | Navigation settings UI. |
| `allocationSettings` | none | Allocation/focus setup UI. |
| `attentionRules` | none | Attention rules UI. |
| `focusSetupWizard` | none | Focus setup wizard UI. |
| `trackerManagement` | none | Tracker management UI. |
| `statisticsDashboard` | none | Statistics dashboard UI (placeholder at the moment). |
| `myDayFocusModeRequired` | none | Gate screen shown when My Day focus mode is missing. |

**Guidance**
- Prefer *parameterized* templates (`*_list_v2`, `agenda_v2`, `allocation`) for screens where the primary purpose is "show data in a consistent, configurable way".
- Prefer *no-params* templates for screens that are effectively standalone "apps within the app" (settings dashboards, management screens). If these start needing configurable variation, promote them to typed params/modules instead of encoding flags into unrelated configs.

### 6.5 Styles (`StylePackV2`) and module-specific variants

For most list-like modules, styling is driven by `StylePackV2` (spacing,
typography, density).

Some modules have module-specific UI knobs (e.g. allocation’s `taskTileVariant`).
Keep these narrowly scoped and prefer extending `StylePackV2` when a choice is
broadly applicable.

**Implementation note (UI architecture)**
- Screen renderers should map these variants onto the canonical, entity-level UI entrypoints:
  - `TaskView`: [lib/presentation/entity_views/task_view.dart](../../lib/presentation/entity_views/task_view.dart)
  - `ProjectView`: [lib/presentation/entity_views/project_view.dart](../../lib/presentation/entity_views/project_view.dart)
  - `ValueView`: [lib/presentation/entity_views/value_view.dart](../../lib/presentation/entity_views/value_view.dart)
- Field-level rendering policies (like date labeling) should not be duplicated per-tile; use the field catalog:
  - `DateLabelFormatter`: [lib/presentation/field_catalog/formatters/date_label_formatter.dart](../../lib/presentation/field_catalog/formatters/date_label_formatter.dart)

**Where variants are defined**
- Screen item tiles: [lib/domain/screens/templates/params/screen_item_tile_variants.dart](../../lib/domain/screens/templates/params/screen_item_tile_variants.dart)
- Attention/review tiles: [lib/domain/screens/templates/params/attention_tile_variants.dart](../../lib/domain/screens/templates/params/attention_tile_variants.dart)

**Common style inputs**
- `StylePackV2`: present on most V2 params models
- Allocation modules: `taskTileVariant`
- Summary/alerts modules: summary tile variants (attention/review)

**Current supported variants**
- `TaskTileVariant`: `list_tile`
- `ProjectTileVariant`: `list_tile`
- `ValueTileVariant`: `compact_card`
- `AttentionItemTileVariant`: `standard`
- `ReviewItemTileVariant`: `standard`

**When to add a new variant**

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

- Add a new enum value only when a *real* screen requires a distinct presentation and there is already (or will be) a concrete widget renderer for it.
- Keep variants narrowly scoped to the entity they render (task/project/value/attention/review). Avoid "mega variants" that implicitly change multiple unrelated UI decisions.

### 6.6 Common nested config types (used by multiple templates)

These configs show up inside section params (especially list templates) and are the primary knobs for reuse.

#### 6.6.1 `DataConfig` (what to fetch)

See: [lib/domain/screens/language/models/data_config.dart](../../lib/domain/screens/language/models/data_config.dart)

| Variant | Fields | When to use |
|---|---|---|
| `task` | `query: TaskQuery` (required) | When the section's primary entity is tasks. |
| `project` | `query: ProjectQuery` (required) | When the section's primary entity is projects. |
| `value` | `query: ValueQuery?` (optional) | When the section's primary entity is values; omit `query` to use defaults. |
| `journal` | `query: JournalQuery?` (optional) | When fetching journal entries (not used by the current V2 list modules). |

#### 6.6.2 `SectionLayoutSpecV2` and `EnrichmentPlanV2`

Many V2 list-like sections use:

- `SectionLayoutSpecV2` to control layout (list/timeline separators, pinning)
- `EnrichmentPlanV2` to request computed metadata (e.g. value stats, agenda tags)

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
import 'package:taskly_bloc/domain/screens/templates/params/issues_summary_section_params.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/style_pack_v2.dart';
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
      ScreenModuleSpec.issuesSummary(
        params: IssuesSummarySectionParams(
          pack: StylePackV2.standard,
          entityTypes: const ['task'],
        ),
      ),
    ],
    primary: [
      ScreenModuleSpec.taskListV2(
        params: ListSectionParamsV2(
          config: DataConfig.task(query: TaskQuery.inbox()),
          pack: StylePackV2.standard,
          layout: const SectionLayoutSpecV2.flatList(),
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
  template: const ScreenTemplateSpec.navigationSettings(),
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
2. **Define params (optional)**
  - Create a params model in `lib/domain/screens/templates/params/` (Freezed).
3. **Implement the interpreter**
  - Add a typed interpreter in `lib/domain/screens/templates/interpreters/`.
  - Prefer `watch(...)` to keep the UI reactive.
4. **Wire it into the spec interpreter**
  - Add a mapping in `ScreenSpecDataInterpreter._watchModule(...)` to route the
    new module type to the new interpreter.
5. **Implement the renderer**
  - Add a renderer widget in `lib/presentation/screens/templates/renderers/`.
  - Wire it into `SectionWidget`.
6. **Register interpreter in DI**
  - Ensure dependency injection provides the interpreter.
7. **Add tests**
  - Domain: params correctness + interpreter behavior where feasible.
  - Presentation: widget tests for loading/error rendering and key UI.

### 8.2 Add/modify a system screen

- Edit/extend `SystemScreenSpecs` to add/modify a `ScreenSpec`.
- If it should appear in primary navigation order, update the default
  preferences/ordering logic (or seed initial preferences if needed).

See: [lib/domain/screens/catalog/system_screens/system_screen_specs.dart](../../lib/domain/screens/catalog/system_screens/system_screen_specs.dart)

---

## 9) Operational Notes & Common Pitfalls

- **Missing module wiring**: adding a new `ScreenModuleSpec` without updating
  `ScreenSpecDataInterpreter` and `SectionWidget` will fail at runtime.
- **Screen key changes**: changing `screenKey` affects routing and preferences.
  Treat shipped keys as stable.
- **Gates**: when a gate is active, `ScreenSpecData` renders the gate template
  with no sections.

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
