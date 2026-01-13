# Phase 5 — Delete Legacy Code + Docs

Created at: 2026-01-13T00:00:00Z  
Last updated at: 2026-01-13T00:30:00Z

## AI instructions
- Before implementing this phase, review `doc/architecture/`.
- Run `flutter analyze` during this phase.
- Ensure any errors or warnings introduced (or discovered) are fixed by the end of the phase.
- If this phase changes architecture (module boundaries, responsibilities, data flow), update the relevant files under `doc/architecture/`.

## Objective
Complete the cutover by deleting superseded legacy code paths and updating
documentation.

## Documentation updates
- Update the unified screen architecture documentation to include:
  - screen templates (purpose, registry)
  - slot model (`header`/`primary`)
  - pack-only styling model (`StylePackV2`) and removal of tile policy knobs
- Update any internal references that still describe full-screen templates as section templates.
- Update docs to reflect the simplified approach:
   - typed specs instead of `templateId + params JSON`
   - removal of params codec + interpreter registry as a configuration surface

## Delete legacy code (required)
Delete code that is superseded by the new system.

Minimum deletion scope:
1) **Duplicate screen systems**
    - The repo currently contains multiple parallel stacks for screen
       definitions/routing/repos.
    - Choose the canonical stack (see Phase 0 clarifications) and delete the
       other stack entirely (including its routing entry points).

2) **Template-ID configuration surface**
    - Remove `templateId -> params codec -> interpreter registry` wiring for
       system screens if it is no longer used.
    - Remove any template ID catalogs that remain only for configuration.

3) **Custom screens**
    - Delete any UI and persistence for creating/updating custom screens.
    - Delete any repository methods that exist solely to support custom screens.
    - Delete any “screen management” pages that are no longer reachable.

   Also delete remaining fallback routing/UI that assumes user-defined screens
   exist:
   - Remove the `UnifiedScreenPageById` / “load by id” screen fallback route
     construction.
   - Make screen construction system-only (unknown keys = not found).

4) **Data reset leftovers**
    - Remove any temporary migration flags / fallback logic once the hard reset
       is the only supported path.

## Open issues (remaining)
1) **Allocation + packs (optional future)**
   - Decide whether `allocation` should adopt `StylePackV2` or remain specialized due to excluded-task UX.

2) **Pack evolution guardrails**
   - If future styling needs arise, define a policy for introducing additional packs without pack explosion.

## Future enhancements (post-cutover)
This section is intentionally forward-looking. It lists items that are *not*
required to complete the hard cutover, but are useful to track for subsequent
iterations.

### Screens likely not fully switched over initially
Meaning: they may remain as **standalone templates/pages** (not expressed as a
`StandardScaffoldTemplate` + `header/primary` modules), even after the core
system screens are migrated.

- `browse` (Browse hub)
- `settings` (Settings menu)
- `statistics` (Statistics dashboard)
- `journal` (Journal timeline)
- `trackers` (Tracker management)
- `wellbeing_dashboard` (Wellbeing dashboard)
- `navigation_settings` (Navigation settings)
- `focus_setup` (Focus setup wizard)
   - Includes legacy aliases (`allocation_settings`, `attention_rules`) that
      route to the canonical wizard.

Rationale: these screens are feature-UIs in their own right and may not benefit
from the moduleized list/hierarchy machinery; they can be migrated later if we
want consistent chrome/slots/packs and analytics hooks.

### Starting point: future-state table for all current screens
This table is a **baseline inventory** for future analysis. It should be
revisited once Phase 1–4 land (typed specs + screen templates + packs), because
names/IDs may change.

| Screen key | Screen name | Proposed screen template | Header slot modules | Primary slot modules | Relevant knobs (screen + modules) |
|---|---|---|---|---|---|
| `browse` | Browse | `BrowseHubTemplate` | — | — | **Screen:** (optional) `pack=standard` |
| `my_day` | My Day | `StandardScaffoldTemplate` + `Gate(allocationFocusModeNotSelected)` | `CheckInSummaryModule` | `AllocationAlertsModule`, `AllocationModule` | **Screen:** `appBarActions=[settingsLink]`, `settingsRoute=focus_setup`, `pack=standard`, `gate.fallbackTemplate=MyDayFocusModeRequiredTemplate` • **AllocationModule:** `displayMode=groupedByValue`, `showExcludedWarnings=true`, `showExcludedSection=true` |
| `scheduled` | Scheduled | `StandardScaffoldTemplate` | — | `AgendaModule` | **Screen:** `fab=[createTask]`, `pack=standard` • **AgendaModule:** `dateField=deadlineDate`, `layout=timelineMonthSections(pinnedSectionHeaders=true)`, `enrichment=[agendaTags(dateField=deadlineDate)]` |
| `someday` | Someday | `StandardScaffoldTemplate` | `IssuesSummaryModule(entityTypes=[task])` | `HierarchyValueProjectTaskModule` | **Screen:** `fab=[createTask]`, `pack=standard` • **Hierarchy module:** `pinnedValueHeaders=true`, `pinnedProjectHeaders=false`, `singleInboxGroupForNoProjectTasks=true`, `filters={valueDropdown=true, projectsOnlyToggle=true, valueFilterMode=anyValues}` • **Query:** tasks where `completed=false`, `startDate=null`, `deadlineDate=null` |
| `logbook` | Logbook | `StandardScaffoldTemplate` | — | `TaskListModule(title=Completed)` | **TaskListModule:** filter `completed=true`, `layout=flatList(separator=divider)`, `pack=standard` |
| `projects` | Projects | `StandardScaffoldTemplate` | — | `ProjectListModule` | **Screen:** `fab=[createProject]`, `pack=standard` • **ProjectListModule:** `layout=flatList(separator=spaced8)` |
| `values` | Values | `StandardScaffoldTemplate` | — | `ValueListModule` | **Screen:** `fab=[createValue]`, `pack=standard` • **ValueListModule:** `layout=flatList(separator=spaced8)`, `enrichment=[valueStats]` |
| `settings` | Settings | `SettingsMenuTemplate` | — | — | **Screen:** `pack=standard` |
| `statistics` | Statistics | `StatisticsDashboardTemplate` | — | — | **Screen:** `pack=standard` |
| `journal` | Journal | `JournalTimelineTemplate` | — | — | **Screen:** `pack=standard` |
| `trackers` | Trackers | `TrackerManagementTemplate` | — | — | **Screen:** `pack=standard` |
| `wellbeing_dashboard` | Wellbeing | `WellbeingDashboardTemplate` | — | — | **Screen:** `pack=standard` |
| `allocation_settings` | Allocation Settings | `FocusSetupWizardTemplate` (alias route) | — | — | **Screen:** treat as alias → `focus_setup` (canonical) |
| `navigation_settings` | Navigation | `NavigationSettingsTemplate` | — | — | **Screen:** `pack=standard` |
| `focus_setup` | Focus Setup | `FocusSetupWizardTemplate` | — | — | **Screen:** `iconName=tune`, `pack=standard` |
| `check_in` | Check In | `StandardScaffoldTemplate` | — | `CheckInSummaryModule` | **Module:** `reviewItemPresentation=pack-driven` (no tile variant knob), `pack=standard` |
| `attention_rules` | Attention Rules | `FocusSetupWizardTemplate` (alias route) | — | — | **Screen:** treat as alias → `focus_setup` (canonical) |
| `project_detail` | *(dynamic)* Project detail | `EntityDetailTemplate(entityType=project)` | `EntityHeaderModule(entityType=project)` | `TaskListModule(title=Tasks)` | **Header:** `showCheckbox=true`, `showMetadata=true` • **TaskListModule:** `query=TaskQuery.forProject(projectId)` |
| `value_detail` | *(dynamic)* Value detail | `EntityDetailTemplate(entityType=value)` | `EntityHeaderModule(entityType=value)` | `TaskListModule(title=Tasks)`, `ProjectListModule(title=Projects)` | **Header:** `showCheckbox=false`, `showMetadata=true` • **Modules:** `TaskQuery.forValue(valueId)`, `ProjectQuery.byValues([valueId])` |

## Acceptance criteria
- Architecture docs reflect the new mental model.
- Legacy code is deleted; the build does not reference removed stacks.
- `flutter analyze` clean.
- Open issues are tracked with clear next steps.
