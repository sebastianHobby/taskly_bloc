# Unified Screen Model — Architecture Summary

> Audience: developers + architects
>
> Scope: the *current* unified screen system in this repo (routing → persistence → interpretation → rendering).

## 1) Executive Summary

Taskly renders most "screens" (Inbox, My Day, Projects, user-created screens, etc.) through a single, declarative model:

- **`ScreenDefinition`**: describes *what* a screen is (identity + sections + chrome).
- **`SectionRef`**: a screen is composed of ordered, templated sections.
- **`ScreenDataInterpreter`**: turns a `ScreenDefinition` into runtime **`ScreenData`** by decoding section params and executing template interpreters.
- **`UnifiedScreenPage` + `SectionWidget`**: renders the resulting section view-models via template-specific renderers.

The system supports:
- **System screens** (templated, shipped by the app) and **custom screens** (user-created).
- **Reactive rendering**: sections can update independently (streams combined into a single screen view).
- **Config-driven composition**: most UX variations are expressed by changing template params and chrome config.

---

## 2) Where Things Live (Folder Map)

### Domain model (screen "language")
- `ScreenDefinition`, `SectionRef`, `ScreenChrome`, template IDs + params
  - [lib/domain/screens/language/models/](../../lib/domain/screens/language/models/)

### Domain pipeline (definition -> data)
- Interpreters, params codec, registries, `ScreenData`, `SectionVm`
  - [lib/domain/screens/runtime/](../../lib/domain/screens/runtime/)
  - [lib/domain/screens/templates/interpreters/](../../lib/domain/screens/templates/interpreters/)

### Persistence + maintenance
- Custom screen persistence, preferences, cleanup, repository implementation
  - [lib/data/screens/maintenance/screen_seeder.dart](../../lib/data/screens/maintenance/screen_seeder.dart)
  - [lib/data/screens/maintenance/system_data_cleanup_service.dart](../../lib/data/screens/maintenance/system_data_cleanup_service.dart)
  - [lib/data/screens/repositories/screen_definitions_repository_impl.dart](../../lib/data/screens/repositories/screen_definitions_repository_impl.dart)

### Presentation (UI + BLoCs)
- Unified screen view + renderers + tiles
  - [lib/presentation/screens/](../../lib/presentation/screens/)
- Per-section rendering switchboard
  - [lib/presentation/widgets/section_widget.dart](../../lib/presentation/widgets/section_widget.dart)

### Routing
- Single place for conventions and screen construction
  - [lib/presentation/routing/routing.dart](../../lib/presentation/routing/routing.dart)
  - [lib/presentation/routing/router.dart](../../lib/presentation/routing/router.dart)

### Tests + migration guidance
- Core tests: `test/domain/models/screens/*`, `test/presentation/features/screens/*`
- Migration history/reference: [doc/plans/completed/unified_screen_model_v2_full_cutover/](../plans/completed/unified_screen_model_v2_full_cutover/)

---

## 3) High-Level Architecture

### 3.1 Component Diagram

The following diagram uses plain text so it renders in any Markdown viewer:

```text
+------------------------------+
|            Routing           |
|  GoRouter '/:segment'        |
|  Routing.buildScreen(key)    |
+--------------+---------------+
               |
               v
+------------------------------+
|         Presentation         |
|  UnifiedScreenPage(*)        |
|    -> ScreenBloc             |
|    -> SectionWidget(s)       |
|    -> template renderers     |
+--------------+---------------+
               |
               v
+------------------------------+
|         Domain services      |
|  ScreenDataInterpreter       |
|    -> ParamsCodec            |
|    -> InterpreterRegistry    |
|       -> SectionInterpreters |
+--------------+---------------+
               |
               v
+------------------------------+
|           Data layer         |
|  ScreenDefinitionsRepository |
|    -> SystemScreenDefinitions|
|    <-> Drift/PowerSync DB    |
|       (custom + prefs +      |
|        legacy fallback)      |
|  Cleanup (orphans)           |
+------------------------------+

(*) Either UnifiedScreenPage(definition) or UnifiedScreenPageById(screenKey)
```

### 3.2 End-to-End Runtime Flow (Sequence)

Plain-text sequence (portable Markdown):

```text
1) User navigates to '/:segment' (URL uses hyphens)
2) Routing.parseScreenKey(segment) -> screenKey (convert '-' back to '_')
3) Routing.buildScreen(screenKey)
   - if screenKey is a system template -> UnifiedScreenPage(definition)
   - else -> UnifiedScreenPageById(screenKey)
4) ScreenBloc receives:
   - load(definition) OR loadById(screenKey)
5) If loadById:
   - ScreenDefinitionsRepository.watchScreen(screenKey).first
   - null -> error/not-found state
6) ScreenBloc subscribes to ScreenDataInterpreter.watchScreen(definition)
7) For each enabled SectionRef (in order):
   - ParamsCodec.decode(templateId, paramsJson)
   - InterpreterRegistry.get(templateId)
   - interpreter.watch(params) emits SectionVm
8) ScreenDataInterpreter combines all section streams -> ScreenData
9) ScreenBloc emits ScreenLoadedState(ScreenData)
10) UnifiedScreenPage renders Scaffold + SectionWidget for each section
```

---

## 4) Core Concepts (What each piece is responsible for)

### 4.1 `ScreenDefinition`

A `ScreenDefinition` is a *pure configuration model*:
- Identity: `id`, `screenKey`, `name`
- Audit: `createdAt`, `updatedAt`
- Composition: `sections: List<SectionRef>`
- Source: `screenSource` (system template vs user-defined)
- Chrome: `chrome: ScreenChrome`

See: [lib/domain/screens/language/models/screen_definition.dart](../../lib/domain/screens/language/models/screen_definition.dart)

### 4.2 `SectionRef` (the "screen AST node")

A `SectionRef` points at:
- `templateId`: which section template to render
- `params`: template params encoded as JSON
- `overrides`: optional overrides applied on top (title, enabled)

See: [lib/domain/screens/language/models/section_ref.dart](../../lib/domain/screens/language/models/section_ref.dart)

### 4.3 Interpreters

A section template interpreter is the domain-side implementation that can:
- `fetch(params)` - one-shot data load
- `watch(params)` - reactive data stream

The interpreter registry resolves `templateId -> interpreter`, and the params codec resolves `templateId -> params type`.

See:
- [lib/domain/screens/templates/interpreters/section_template_interpreter_registry.dart](../../lib/domain/screens/templates/interpreters/section_template_interpreter_registry.dart)
- [lib/domain/screens/templates/interpreters/section_template_params_codec.dart](../../lib/domain/screens/templates/interpreters/section_template_params_codec.dart)

### 4.4 Rendering

- `UnifiedScreenPage` owns the page-level scaffold/chrome and hosts a `ScreenBloc`.
- `SectionWidget` performs the template switch, delegating to specific renderers.

See:
- [lib/presentation/screens/view/unified_screen_page.dart](../../lib/presentation/screens/view/unified_screen_page.dart)
- [lib/presentation/widgets/section_widget.dart](../../lib/presentation/widgets/section_widget.dart)

---

## 5) Persistence & System Template Lifecycle

### 5.1 Screens in the database

In the current codebase (Option B):

- **System screens** are defined in code via `SystemScreenDefinitions` (their structure is not read from the DB).
- **Custom screens** are stored in Drift (`screen_definitions` with `source=user_created`).
- **Preferences** (visibility + sort order) are stored in Drift (`screen_preferences`).
- **Legacy fallback**: older `screen_definitions` rows with `source=system_template` may exist and are treated as preference-like fallbacks (`isActive` / `sortOrder`) when a dedicated `screen_preferences` row is missing.

Key entry points:
- Merge definitions + apply preferences: [lib/data/screens/repositories/screen_definitions_repository_impl.dart](../../lib/data/screens/repositories/screen_definitions_repository_impl.dart)
- System templates: [lib/domain/screens/catalog/system_screens/system_screen_definitions.dart](../../lib/domain/screens/catalog/system_screens/system_screen_definitions.dart)
- Cleanup of orphaned legacy rows: [lib/data/screens/maintenance/system_data_cleanup_service.dart](../../lib/data/screens/maintenance/system_data_cleanup_service.dart)

Note: [lib/data/screens/maintenance/screen_seeder.dart](../../lib/data/screens/maintenance/screen_seeder.dart) exists but is not currently invoked by the runtime code path.

---

## 6) Configuration Catalog (What you can configure, and when to use it)

This section summarizes the "configuration surface area" available to build screens without adding new UI code.

> Note on strictness: template params are decoded with `SectionTemplateParamsCodec` and are intentionally strict.
> If a required field is missing (including "style keys" like tile variants), decode will fail and the section will not render.

### 6.1 Screen identity & composition (`ScreenDefinition`)

| Field | Meaning | When to set / notes |
|---|---|---|
| `screenKey` | Stable key used in routing and lookups | Treat as immutable once shipped; used for deterministic IDs and URL segments. |
| `name` | Display name (AppBar + navigation) | User-facing; avoid changing for system screens unless you also consider migration/UX. |
| `sections` | Ordered list of sections | The main way to create/modify a screen. |
| `screenSource` | System vs user-defined | System screens typically use `ScreenSource.systemTemplate`. |
| `chrome` | UI chrome configuration | Use for icon/FAB/app bar actions/badges. |

### 6.2 Chrome configuration (`ScreenChrome`)

See: [lib/domain/screens/language/models/screen_chrome.dart](../../lib/domain/screens/language/models/screen_chrome.dart)

| Option | Type | Description | When to use |
|---|---|---|---|
| `iconName` | `String?` | Icon identifier for navigation | Set for any screen that appears in nav. Custom screens usually must provide it. |
| `badgeConfig` | `BadgeConfig` | How navigation badge is computed | Use when nav badge needs to reflect a specific section/query; defaults to `fromFirstSection()`. |
| `fabOperations` | `List<FabOperation>` | Which FAB actions are available | Use for create actions like task/project/value. |
| `appBarActions` | `List<AppBarAction>` | AppBar action buttons | Use for settings/help or other global actions. |
| `settingsRoute` | `String?` | Route to open for settingsLink action | Use when `appBarActions` includes `settingsLink`. |

**Guidance**
- Prefer one primary FAB per screen; if you need multiple, consider a different interaction pattern (or explicitly extend `UnifiedScreenPage`).
- Keep chrome declarative: avoid hardcoding per-screen app bars in renderers unless the section is a full-screen legacy page.

### 6.3 Section configuration (`SectionRef` + overrides)

| Option | Type | Description | When to use |
|---|---|---|---|
| `templateId` | `String` | Which section template to instantiate | Required; must match an interpreter + renderer. |
| `params` | `Map<String, dynamic>` | Serialized params for the template | Used to configure queries, grouping, display modes, etc. |
| `overrides.title` | `String?` | Override section title in UI | Use to label multiple instances of the same template (e.g., two task lists). |
| `overrides.enabled` | `bool` | Whether section is enabled | Use for feature flags, experiments, or temporarily disabling a section without deleting config. |

**Enabled/disabled semantics**
- Disabled sections are skipped by the interpreter and do not contribute to `ScreenData.sections`.

### 6.4 Section template catalog (existing configuration options)

The params codec is the canonical source of which templates accept which params.

See: [lib/domain/screens/templates/interpreters/section_template_params_codec.dart](../../lib/domain/screens/templates/interpreters/section_template_params_codec.dart)

| Template ID | Params type | What it renders | When to use |
|---|---|---|---|
| `task_list_v2` | `ListSectionParamsV2` | Task list driven by `TaskQuery` with typed layout + enrichment | Default for task-based screens (Inbox, etc.). |
| `project_list_v2` | `ListSectionParamsV2` | Project list driven by `ProjectQuery` with typed layout + enrichment | Project overviews, dashboards, selection. |
| `value_list_v2` | `ListSectionParamsV2` | Value list driven by `ValueQuery?` with typed enrichment | Value-centric dashboards and selection. |
| `interleaved_list_v2` | `InterleavedListSectionParamsV2` | A mixed list sourced from multiple V2 list configs | When you need one feed combining tasks/projects/values. |
| `agenda_v2` | `AgendaSectionParamsV2` | Date-grouped agenda view with typed enrichment | Upcoming/scheduled screens, calendar-like views. |
| `allocation` | `AllocationSectionParams` | Allocation/focus view for tasks | "My Day" / focus experiences. |
| `issues_summary` | `IssuesSummarySectionParams` | Issues/warnings summary (attention items) | Top-of-screen "what needs attention" summary. |
| `check_in_summary` | `CheckInSummarySectionParams` | Check-in summary (review items) | Focus onboarding/summary at top of focus screens. |
| `allocation_alerts` | `AllocationAlertsSectionParams` | Allocation-related alerts (attention items) | Warning banners/alerts near allocation sections. |
| `entity_header` | `EntityHeaderSectionParams` | Header for an entity detail screen (project/value) | Top section for detail screens to show metadata/controls. |
| `settings_menu` | *(no params)* | Settings menu screen | Use as a full-screen settings entry point. |
| `journal_timeline` | *(no params)* | Journal timeline screen | Full-screen template. |
| `navigation_settings` | *(no params)* | Navigation settings screen | Full-screen template. |
| `allocation_settings` | *(no params)* | Allocation settings screen | Full-screen template. |
| `attention_rules` | *(no params)* | Attention rules screen | Full-screen template. |
| `tracker_management` | *(no params)* | Tracker management screen | Full-screen template. |
| `wellbeing_dashboard` | *(no params)* | Wellbeing dashboard screen | Full-screen template. |
| `statistics_dashboard` | *(no params)* | Statistics dashboard screen | Full-screen template. |
| `browse_hub` | *(no params)* | Browse hub screen | Full-screen template. |
| `focus_setup_wizard` | *(no params)* | Focus setup wizard screen | Full-screen template. |
| `my_day_focus_mode_required` | *(no params)* | My Day gate screen (focus mode required) | Screen-level gate template. |

**Guidance**
- Prefer *parameterized* templates (`*_list_v2`, `agenda_v2`, `allocation`) for screens where the primary purpose is "show data in a consistent, configurable way".
- Prefer *no-params* templates for screens that are effectively standalone "apps within the app" (settings dashboards, management screens). If these start needing data-driven variation, promote them to typed params instead of encoding flags into unrelated configs.

### 6.5 Styles & Tile Variants (mandatory style keys)

To keep "what we display" separate from "how we display it", templates that render entities require explicit **tile variant** fields.

**Related backlog**
- Someday consolidated inbox alignment (post-migration UI alignment): [doc/backlog/SOMEDAY_CONSOLIDATED_INBOX_ALIGNMENT.md](../backlog/SOMEDAY_CONSOLIDATED_INBOX_ALIGNMENT.md)

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

**Which templates require which style keys**
| Template | Required style keys | Notes |
|---|---|---|
| `*_list_v2` (`ListSectionParamsV2`) | `tiles.task`, `tiles.project`, `tiles.value` | Required even if the underlying `DataConfig` only yields one entity type. This is an intentional "explicit style" rule. |
| `interleaved_list_v2` (`InterleavedListSectionParamsV2`) | `tiles.task`, `tiles.project`, `tiles.value` | Applied to the mixed list items shared across all sources. |
| `agenda_v2` (`AgendaSectionParamsV2`) | `tiles.task`, `tiles.project`, `tiles.value` | Agenda renders tasks; project/value variants are used when those entities appear as context/links. |
| `allocation` | `taskTileVariant` | Allocation shows tasks. |
| `issues_summary` | `attentionItemTileVariant` | Controls which attention-item widget style is used. |
| `allocation_alerts` | `attentionItemTileVariant` | Controls which alert widget style is used. |
| `check_in_summary` | `reviewItemTileVariant` | Controls which review-item widget style is used. |

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
| `journal` | `query: JournalQuery?` (optional) | When rendering journal entries (currently not used by list templates in the codec). |

#### 6.6.2 `DisplayConfig` (legacy list grouping/sort/filter)

See: [lib/domain/screens/language/models/display_config.dart](../../lib/domain/screens/language/models/display_config.dart)

| Option | Meaning | When to use |
|---|---|---|
| `groupBy` | Grouping strategy (`none`, `project`, `value`, `label`, `date`, `priority`) | Use when the list needs structure (e.g., tasks grouped by project). |
| `sorting` | List of `(field, direction)` | Prefer sorting over adding more specialized templates. |
| `problemsToDetect` | Problem detectors to run | Use to power issue surfacing and section-level warnings. |
| `showCompleted` / `showArchived` | Filtering toggles | Default values are usually correct; override when building "logbook" or archive-like screens. |
| `groupByCompletion` / `completedCollapsed` | Completed grouping UX | Use when mixing completed and active tasks within one section. |
| `enableSwipeToDelete` | Swipe delete affordance | Use sparingly; only on screens where delete is the primary action. |

Notes:
- V2 list templates (`*_list_v2`, `interleaved_list_v2`, `agenda_v2`) use typed layout via `SectionLayoutSpecV2` and typed computed metadata via `EnrichmentPlanV2` (not `DisplayConfig`).

#### 6.6.3 Related data (removed)

The legacy "related entities sidecar" (`RelatedDataConfig` / `relatedEntities`) has been removed.

Use one of:
- `SectionLayoutSpecV2.hierarchyValueProjectTask` when you need a structured Value → Project → Task presentation.
- `EnrichmentPlanV2` / `EnrichmentResultV2` when you need computed, typed metadata (counts, value stats, agenda tags).

#### 6.6.4 `EnrichmentConfig` (legacy computed statistics)

See: [lib/domain/screens/language/models/enrichment_config.dart](../../lib/domain/screens/language/models/enrichment_config.dart)

| Variant | Fields | When to use |
|---|---|---|
| `valueStats` | `sparklineWeeks`, `gapWarningThreshold` | When value cards need computed progress/trend metadata. |

**Full-screen templates**
- Some templates are treated as "full-screen legacy pages" and are rendered without nesting a second Scaffold.
- The list of full-screen template IDs is maintained in:
  - [lib/presentation/screens/view/unified_screen_page.dart](../../lib/presentation/screens/view/unified_screen_page.dart)
  - [lib/presentation/widgets/section_widget.dart](../../lib/presentation/widgets/section_widget.dart)

---



## 7) Quick Start (Build Screens with Configuration)

This section shows concrete examples of how to compose screens using existing
configuration types.

> Note: system screens are authored in code under `SystemScreenDefinitions`.
> Custom screens are created/updated via `ScreenDefinitionsRepositoryContract`.

### 7.1 Example: "Inbox-like" task list screen

Goal: a screen with an issues summary + task list, plus a task-create FAB.

```dart
import 'package:taskly_bloc/domain/screens/language/models/data_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_ref.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/screen_item_tile_variants.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/screens/language/models/fab_operation.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_chrome.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_definition.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_ref.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/screens/templates/params/attention_tile_variants.dart';
import 'package:taskly_bloc/domain/screens/templates/params/data_list_section_params.dart';
import 'package:taskly_bloc/domain/screens/templates/params/issues_summary_section_params.dart';
import 'package:taskly_bloc/domain/screens/templates/params/screen_item_tile_variants.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';

final screen = ScreenDefinition(
  id: 'example_inbox_like',
  screenKey: 'example_inbox_like',
  name: 'Example Inbox',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
  chrome: const ScreenChrome(
    iconName: 'inbox',
    fabOperations: [FabOperation.createTask],
  ),
  sections: [
    SectionRef(
      templateId: SectionTemplateId.issuesSummary,
      params: const IssuesSummarySectionParams(
        attentionItemTileVariant: AttentionItemTileVariant.standard,
        entityTypes: ['task'],
      ).toJson(),
    ),
    SectionRef(
      templateId: SectionTemplateId.taskListV2,
      params: ListSectionParamsV2(
        config: DataConfig.task(query: TaskQuery.inbox()),
        tiles: const TilePolicyV2(
          task: TaskTileVariant.listTile,
          project: ProjectTileVariant.listTile,
          value: ValueTileVariant.compactCard,
        ),
        layout: const SectionLayoutSpecV2.flatList(),
      ).toJson(),
    ),
  ],
);
```

When to use:
- Use `issuesSummary` when you want guardrails/alerts near the top.
- Use `taskListV2` with a `TaskQuery` when the screen's primary content is tasks.

### 7.2 Example: Two task lists, labeled via section overrides

Goal: one screen showing two different task lists with clear titles.

```dart
import 'package:taskly_bloc/domain/screens/language/models/data_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_ref.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/screen_item_tile_variants.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';

final sections = <SectionRef>[
  SectionRef(
    templateId: SectionTemplateId.taskListV2,
    params: ListSectionParamsV2(
      config: DataConfig.task(query: TaskQuery.inbox()),
      tiles: const TilePolicyV2(
        task: TaskTileVariant.listTile,
        project: ProjectTileVariant.listTile,
        value: ValueTileVariant.compactCard,
      ),
      layout: const SectionLayoutSpecV2.flatList(),
    ).toJson(),
    overrides: const SectionOverrides(title: 'Inbox'),
  ),
  SectionRef(
    templateId: SectionTemplateId.taskListV2,
    params: ListSectionParamsV2(
      config: DataConfig.task(query: TaskQuery.scheduled()),
      tiles: const TilePolicyV2(
        task: TaskTileVariant.listTile,
        project: ProjectTileVariant.listTile,
        value: ValueTileVariant.compactCard,
      ),
      layout: const SectionLayoutSpecV2.flatList(),
    ).toJson(),
    overrides: const SectionOverrides(title: 'Scheduled'),
  ),
];
```

When to use:
- Use multiple instances of the same template when the UI is similar but the
  query/meaning differs.
- Use `SectionOverrides.title` to disambiguate in the UI.

### 7.3 Example: Full-screen templates (settings-style pages)

Some templates render as a full-screen page (to avoid nested scaffolds).

```dart
import 'package:taskly_bloc/domain/screens/language/models/section_ref.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';

final definition = ScreenDefinition(
  id: 'settings_example',
  screenKey: 'settings_example',
  name: 'Settings Example',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
  sections: const [
    SectionRef(templateId: SectionTemplateId.navigationSettings),
  ],
);
```

When to use:
- Use these templates for "pages" that already have their own internal layout
  and should not be embedded within another scaffold.

---

## 8) How to Extend the System (Developer Guide)

### 8.1 Add a new section template (checklist)

1. **Define a template ID**
   - Add to `SectionTemplateId`.
2. **Define params (optional)**
   - Create a params model in `lib/domain/screens/templates/params/` (Freezed + JSON).
   - Update the params codec switch in `SectionTemplateParamsCodec`.
3. **Implement the interpreter**
   - Add an interpreter in `lib/domain/screens/templates/interpreters/`.
   - Ensure it supports `fetch` and/or `watch` (prefer `watch` for reactive UI).
4. **Register interpreter in DI**
   - Ensure `SectionTemplateInterpreterRegistry` is constructed with the new interpreter.
5. **Implement the renderer**
  - Add a renderer widget in `lib/presentation/screens/templates/renderers/`.
   - Wire it into `SectionWidget` (switch on `templateId` / result type).
6. **Add tests**
   - Domain: params round-trip + interpreter behavior where feasible.
   - Presentation: contract tests if navigation/rendering depends on it.

### 8.2 Add/modify a system screen

- Edit/extend `SystemScreenDefinitions` to return a new `ScreenDefinition` with `sections`.
- If it should appear in primary navigation order, update default sort order logic in `SystemScreenDefinitions`.
- Ensure the seeder + cleanup semantics are considered (renames/removals create "orphans" that cleanup may delete).

See: [lib/domain/screens/catalog/system_screens/system_screen_definitions.dart](../../lib/domain/screens/catalog/system_screens/system_screen_definitions.dart)

---

## 9) Operational Notes & Common Pitfalls

- **Unknown template IDs**: the interpreter registry throws if a template isn't registered. Add codec + interpreter + renderer together.
- **Params mismatch**: if you add a params type but forget to update the codec, decoding will fall back to `EmptySectionParams`.
- **System template renames**: changing a system `screenKey` affects deterministic IDs and routing paths; treat as a migration.
- **Disabled sections**: `SectionOverrides.enabled=false` removes the section from the rendered `ScreenData`.

---

## 10) References

- Unified UI entry point: [lib/presentation/screens/view/unified_screen_page.dart](../../lib/presentation/screens/view/unified_screen_page.dart)
- Interpreter pipeline: [lib/domain/screens/runtime/screen_data_interpreter.dart](../../lib/domain/screens/runtime/screen_data_interpreter.dart)
- System screens: [lib/domain/screens/catalog/system_screens/system_screen_definitions.dart](../../lib/domain/screens/catalog/system_screens/system_screen_definitions.dart)
- Seeding/cleanup: [lib/data/screens/maintenance/screen_seeder.dart](../../lib/data/screens/maintenance/screen_seeder.dart), [lib/data/screens/maintenance/system_data_cleanup_service.dart](../../lib/data/screens/maintenance/system_data_cleanup_service.dart)
- Routing conventions: [lib/presentation/routing/routing.dart](../../lib/presentation/routing/routing.dart)
