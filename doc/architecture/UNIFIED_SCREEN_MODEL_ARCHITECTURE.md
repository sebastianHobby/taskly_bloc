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

System screens are defined in code via `SystemScreenSpecs`. Screen ordering and
visibility preferences are persisted separately.

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
  - [lib/data/screens/repositories/screen_definitions_repository_impl.dart](../../lib/data/screens/repositories/screen_definitions_repository_impl.dart)

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
|  Routing.buildScreen         |
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
8) ScreenTemplateWidget renders ScreenSpecData.template:
   - standardScaffoldV1: builds scaffold and renders header/primary sections
   - full-screen templates: render a dedicated feature page
9) SectionWidget renders each SectionVm by section.templateId
```

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
- Full-screen feature templates: `settingsMenu`, `journalTimeline`, `browseHub`, …

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
  [lib/data/screens/repositories/screen_definitions_repository_impl.dart](../../lib/data/screens/repositories/screen_definitions_repository_impl.dart)
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
| `journalTimeline` | none | Journal feature UI. |
| `navigationSettings` | none | Navigation settings UI. |
| `allocationSettings` | none | Allocation/focus setup UI. |
| `attentionRules` | none | Attention rules UI. |
| `focusSetupWizard` | none | Focus setup wizard UI. |
| `trackerManagement` | none | Tracker management UI. |
| `wellbeingDashboard` | none | Wellbeing dashboard UI. |
| `statisticsDashboard` | none | Statistics dashboard UI (placeholder at the moment). |
| `browseHub` | none | Browse hub UI. |
| `myDayFocusModeRequired` | none | Gate screen shown when My Day focus mode is missing. |

**Guidance**
- Prefer *parameterized* templates (`*_list_v2`, `agenda_v2`, `allocation`) for screens where the primary purpose is "show data in a consistent, configurable way".
- Prefer *no-params* templates for screens that are effectively standalone "apps within the app" (settings dashboards, management screens). If these start needing data-driven variation, promote them to typed params instead of encoding flags into unrelated configs.

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
