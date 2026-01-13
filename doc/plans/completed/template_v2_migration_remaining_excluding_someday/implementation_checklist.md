# Template V2 Migration (Remaining Templates) — Implementation Checklist

Created at: 2026-01-13T00:00:00Z (UTC)
Last updated at: 2026-01-13T00:00:00Z (UTC)

## Locked constraints (from decisions)
- Keep existing template IDs (no `_v2` renames for these templates).
- Keep specialized `SectionDataResult` variants for non-list templates.
- Keep `SectionWidget` as the single template switchboard.
- Support-block style keys: no new **required** keys as part of this migration.
- Someday excluded (tracked separately in `doc/plans/completed/someday_v2_full_migration/`).

## Repo-specific wiring facts (useful when implementing)
- **Params decode/encode is already strict + centralized** in [lib/domain/screens/templates/interpreters/section_template_params_codec.dart](lib/domain/screens/templates/interpreters/section_template_params_codec.dart).
- **DI is already wired per template ID** in [lib/core/di/dependency_injection.dart](lib/core/di/dependency_injection.dart) via `instanceName: SectionTemplateId.*` and then collected into `SectionTemplateInterpreterRegistry`.
- **`SectionWidget` currently routes some templates by result-type only** (e.g. `IssuesSummarySectionResult` → `IssuesSummarySectionRenderer`) and not by `templateId`. This means *any* future template that returns the same result variant would render using the same widget.
  - Recommended for long-term safety: guard these cases with `when section.templateId == ...` so templateId remains the “primary key” and result type is secondary.
- **Support-block params include tile variants** (e.g. `attentionItemTileVariant`, `reviewItemTileVariant`) but the current UI widgets in [lib/presentation/screens/templates/renderers/attention_support_section_widgets.dart](lib/presentation/screens/templates/renderers/attention_support_section_widgets.dart) do not yet branch on variant (and the enums currently only have `standard`).
- **Support-block renderer titles are currently hard-coded** (`'Issues'`, `'Allocation Alerts'`, `'Reviews Due'`) instead of using `section.title` (section overrides).

## Shared “done” definition per migrated template
- Domain
  - Params are strict and typed (Freezed + JSON where already used).
  - Decode/encode is covered in `SectionTemplateParamsCodec`.
  - Interpreter is thin, delegates to a domain service.
  - DI registration exists and matches `SectionTemplateId.*`.
- Presentation
  - Renderer constructor follows a consistent shape.
    - For V2 list templates this is already `data + params + title + callbacks`.
    - For support blocks: target `data + params + title + (optional) callbacks` while preserving existing behavior.
  - `SectionWidget` switching is the only place routing `templateId -> renderer`.
- Tests
  - At minimum: params decode/encode strictness + `SectionWidget` routing for the template.

---

## Support blocks

### `issues_summary`
- Domain
  - Params: [lib/domain/screens/templates/params/issues_summary_section_params.dart](lib/domain/screens/templates/params/issues_summary_section_params.dart)
  - Codec: [lib/domain/screens/templates/interpreters/section_template_params_codec.dart](lib/domain/screens/templates/interpreters/section_template_params_codec.dart)
  - Interpreter: [lib/domain/screens/templates/interpreters/issues_summary_section_interpreter.dart](lib/domain/screens/templates/interpreters/issues_summary_section_interpreter.dart)
  - Result variant: `IssuesSummarySectionResult` in [lib/domain/screens/runtime/section_data_result.dart](lib/domain/screens/runtime/section_data_result.dart)
  - DI wiring: [lib/core/di/dependency_injection.dart](lib/core/di/dependency_injection.dart)
- Presentation
  - Renderer: [lib/presentation/screens/templates/renderers/issues_summary_section_renderer.dart](lib/presentation/screens/templates/renderers/issues_summary_section_renderer.dart)
  - Switchboard: [lib/presentation/widgets/section_widget.dart](lib/presentation/widgets/section_widget.dart)
  - Related widgets: [lib/presentation/screens/templates/renderers/attention_support_section_widgets.dart](lib/presentation/screens/templates/renderers/attention_support_section_widgets.dart)

  #### Current behavior (baseline)
  - `IssuesSummarySectionRenderer` takes only `IssuesSummarySectionResult` and renders a `SupportSectionCard(title: 'Issues', ...)`.
  - `SectionWidget` chooses this renderer via `switch (result)` matching `IssuesSummarySectionResult` (no templateId guard).

  #### V2-alignment tasks (low-risk)
  1) **Title override support**
    - Use `section.title` when present (from `SectionRef.overrides.title`).
    - Implementation: add `title` parameter to renderer (or set it in `SupportSectionCard`) and pass `section.title ?? 'Issues'` from `SectionWidget`.
  2) **TemplateId guard (recommended safety)**
    - Change the `switch (result)` case to `final IssuesSummarySectionResult d when section.templateId == SectionTemplateId.issuesSummary => ...`.
  3) **(Optional) Variant plumbing**
    - Pass `section.params as IssuesSummarySectionParams` into the renderer so future `AttentionItemTileVariant` values can be used.
    - Do not add new required params; keep current required fields only.
- Tests (recommended targets)
  - Params decode strictness: `IssuesSummarySectionParams.fromJson` rejects missing `attentionItemTileVariant`.
  - Rendering selection: a `SectionVm(templateId: issues_summary, data: SectionDataResult.issuesSummary(...))` renders the Issues card.
  - Test harness reference: mimic `_pumpSectionWidget` in [test/integration/section_checkbox_completion_test.dart](test/integration/section_checkbox_completion_test.dart) to render `SectionWidget` inside a `CustomScrollView`.

### `allocation_alerts`
- Domain
  - Params: [lib/domain/screens/templates/params/allocation_alerts_section_params.dart](lib/domain/screens/templates/params/allocation_alerts_section_params.dart)
  - Codec: [lib/domain/screens/templates/interpreters/section_template_params_codec.dart](lib/domain/screens/templates/interpreters/section_template_params_codec.dart)
  - Interpreter: [lib/domain/screens/templates/interpreters/allocation_alerts_section_interpreter.dart](lib/domain/screens/templates/interpreters/allocation_alerts_section_interpreter.dart)
  - Result variant: `AllocationAlertsSectionResult` in [lib/domain/screens/runtime/section_data_result.dart](lib/domain/screens/runtime/section_data_result.dart)
  - DI wiring: [lib/core/di/dependency_injection.dart](lib/core/di/dependency_injection.dart)
- Presentation
  - Renderer: [lib/presentation/screens/templates/renderers/allocation_alerts_section_renderer.dart](lib/presentation/screens/templates/renderers/allocation_alerts_section_renderer.dart)
  - Switchboard: [lib/presentation/widgets/section_widget.dart](lib/presentation/widgets/section_widget.dart)

  #### Current behavior (baseline)
  - Renderer hardcodes `title: 'Allocation Alerts'` and a “View all … alerts” button routes to `Routing.toScreenKey(context, 'focus_setup')`.
  - Renderer shows nothing when `data.alerts.isEmpty`.

  #### V2-alignment tasks (low-risk)
  1) **Title override support**
    - Prefer `section.title ?? 'Allocation Alerts'`.
  2) **TemplateId guard (recommended safety)**
    - Guard the `AllocationAlertsSectionResult` case with `when section.templateId == SectionTemplateId.allocationAlerts`.
  3) **(Optional) action injection**
    - To reduce hard-coded routing: allow an optional callback (`onViewAll`) from `SectionWidget`.
    - Default behavior should remain routing to `'focus_setup'` to avoid functional change.
- Tests (recommended targets)
  - Param decode strictness.
  - Switchboard routes to renderer.
  - Optional: verify the “View all … alerts” button exists when `alerts.length > 2`.

### `check_in_summary`
- Domain
  - Params: [lib/domain/screens/templates/params/check_in_summary_section_params.dart](lib/domain/screens/templates/params/check_in_summary_section_params.dart)
  - Codec: [lib/domain/screens/templates/interpreters/section_template_params_codec.dart](lib/domain/screens/templates/interpreters/section_template_params_codec.dart)
  - Interpreter: [lib/domain/screens/templates/interpreters/check_in_summary_section_interpreter.dart](lib/domain/screens/templates/interpreters/check_in_summary_section_interpreter.dart)
  - Result variant: `CheckInSummarySectionResult` in [lib/domain/screens/runtime/section_data_result.dart](lib/domain/screens/runtime/section_data_result.dart)
  - DI wiring: [lib/core/di/dependency_injection.dart](lib/core/di/dependency_injection.dart)
- Presentation
  - Renderer: [lib/presentation/screens/templates/renderers/check_in_summary_section_renderer.dart](lib/presentation/screens/templates/renderers/check_in_summary_section_renderer.dart)
  - Switchboard: [lib/presentation/widgets/section_widget.dart](lib/presentation/widgets/section_widget.dart)

  #### Current behavior (baseline)
  - Renderer hardcodes `title: 'Reviews Due'` and routes to `Routing.toScreenKey(context, 'check_in')`.
  - Overdue warning uses `data.hasOverdue`.

  #### V2-alignment tasks (low-risk)
  1) **Title override support**
    - Prefer `section.title ?? 'Reviews Due'`.
  2) **TemplateId guard (recommended safety)**
    - Guard the `CheckInSummarySectionResult` case with `when section.templateId == SectionTemplateId.checkInSummary`.
  3) **(Optional) action injection**
    - Allow an optional callback for “Start Check-in”; keep current routing as default.
- Tests (recommended targets)
  - Param decode strictness.
  - Switchboard routes to renderer.
  - Optional: verify overdue banner renders when `hasOverdue == true`.

---

## Allocation + entity header

### `allocation`
- Domain
  - Params: [lib/domain/screens/templates/params/allocation_section_params.dart](lib/domain/screens/templates/params/allocation_section_params.dart)
  - Codec: [lib/domain/screens/templates/interpreters/section_template_params_codec.dart](lib/domain/screens/templates/interpreters/section_template_params_codec.dart)
  - Interpreter: [lib/domain/screens/templates/interpreters/allocation_section_interpreter.dart](lib/domain/screens/templates/interpreters/allocation_section_interpreter.dart)
  - Data service: allocation methods in [lib/domain/screens/runtime/section_data_service.dart](lib/domain/screens/runtime/section_data_service.dart)
  - Result variant: `AllocationSectionResult` in [lib/domain/screens/runtime/section_data_result.dart](lib/domain/screens/runtime/section_data_result.dart)
  - DI wiring: [lib/core/di/dependency_injection.dart](lib/core/di/dependency_injection.dart)
- Presentation
  - Renderer: [lib/presentation/screens/templates/renderers/allocation_section_renderer.dart](lib/presentation/screens/templates/renderers/allocation_section_renderer.dart)
  - Switchboard: [lib/presentation/widgets/section_widget.dart](lib/presentation/widgets/section_widget.dart)

  #### Current behavior (baseline)
  - `SectionDataService` prefers persisted allocation snapshots; otherwise falls back to live allocation.
    - If `allocation.requiresValueSetup == true`, it returns `SectionDataResult.allocation(... requiresValueSetup: true, allocatedTasks: [], totalAvailable: 0 ...)`.
    - It computes `pinnedTasks` and `tasksByValue`, and flattens tasks into `allocatedTasks` for UI consumption.
    - It carries excluded-task info (`excludedCount`, `excludedUrgentTasks`, `excludedTasks`) but **the renderer does not currently surface this**.
  - `SectionWidget` renders allocation via `switch (result)` matching `AllocationSectionResult` (no templateId guard).
    - `onTaskToggle` resolves the task via `d.allocatedTasks.firstWhere((t) => t.id == taskId)`.
  - `AllocationSectionRenderer`:
    - If `data.allocatedTasks.isEmpty` it shows an empty state.
      - If `data.totalAvailable == 0`, it shows “No tasks yet” + “Add First Task” and directly calls `EditorLauncher.fromGetIt()`.
      - Otherwise it shows “No tasks allocated for today.”
    - It uses `displayMode` to choose flat/project/value grouping and renders tasks using `TaskView`.
    - It does **not** currently handle `requiresValueSetup`, `excluded*`, or `showExcludedSection`.

  #### V2-alignment tasks (low-risk)
  1) **TemplateId guard (recommended safety)**
    - Guard the `AllocationSectionResult` case with `when section.templateId == SectionTemplateId.allocation`.
  2) **(Optional) Title plumbing**
    - If design calls for allocation to respect section title overrides, add a `title` parameter to `AllocationSectionRenderer` and pass `section.title` from `SectionWidget`.
    - Keep default behavior visually stable (avoid introducing a second header if allocation is already embedded under a parent title).
  3) **(Recommended) `requiresValueSetup` UX**
    - Current fallback “No tasks yet” is misleading when `requiresValueSetup == true`.
    - Add a dedicated gateway state (e.g., a card with an action) when `requiresValueSetup` is set.
      - Keep routing stable: either reuse the existing focus setup flow (e.g., the same key used by allocation alerts) or inject an optional callback from `SectionWidget`.
  4) **(Optional) Excluded section rendering**
    - If `showExcludedSection == true`, consider rendering a minimal “Outside focus” / excluded list using `excludedTasks`.
    - Keep it optional and behind the existing `showExcludedSection` boolean.
- Tests (recommended targets)
  - Allocation params decode strictness (esp. displayMode, filters, etc.).
  - Switchboard routes to allocation only when `templateId == allocation` (after adding templateId guard).
  - Smoke widget test for allocation section rendering given a minimal `AllocationSectionResult`.
  - If implementing `requiresValueSetup` UX: widget test asserts gateway UI renders for `requiresValueSetup: true`.

### `entity_header`
- Domain
  - Params: [lib/domain/screens/templates/params/entity_header_section_params.dart](lib/domain/screens/templates/params/entity_header_section_params.dart)
  - Codec: [lib/domain/screens/templates/interpreters/section_template_params_codec.dart](lib/domain/screens/templates/interpreters/section_template_params_codec.dart)
  - Interpreter: [lib/domain/screens/templates/interpreters/entity_header_section_interpreter.dart](lib/domain/screens/templates/interpreters/entity_header_section_interpreter.dart)
  - Result variants: `EntityHeaderProjectSectionResult`, `EntityHeaderValueSectionResult`, `EntityHeaderMissingSectionResult` in [lib/domain/screens/runtime/section_data_result.dart](lib/domain/screens/runtime/section_data_result.dart)
  - DI wiring: [lib/core/di/dependency_injection.dart](lib/core/di/dependency_injection.dart)
- Presentation
  - Renderer: [lib/presentation/screens/templates/renderers/entity_header_section_renderer.dart](lib/presentation/screens/templates/renderers/entity_header_section_renderer.dart)
  - Switchboard: [lib/presentation/widgets/section_widget.dart](lib/presentation/widgets/section_widget.dart)

  #### Current behavior (baseline)
  - Params are stringly-typed: `entityType` is expected to be `'project'` or `'value'`.
  - Interpreter:
    - `'project'` → watches a project and returns `entityHeaderProject(...)` or `entityHeaderMissing`.
    - `'value'` → watches a value and then watches `TaskRepository.watchAllCount(TaskQuery.forValue(...))` to produce `entityHeaderValue(...)`.
    - Unknown types → `entityHeaderMissing`.
  - `SectionWidget` renders entity headers by result-type matching (`EntityHeader*SectionResult`) without guarding `templateId`.
  - `EntityHeaderSectionRenderer`:
    - Project → uses `EntityHeader.project(showCheckbox: showCheckbox, onCheckboxChanged: ...)`.
    - Value → uses `EntityHeader.value(value: ..., taskCount: ...)`.
    - Missing → renders “Missing <entityType>”.
  - `showMetadata` is carried in the result for project/value, but **is not currently respected by the UI**:
    - `EntityHeader.project(...)` has no `showMetadata` parameter.
    - `EntityHeader.value(...)` always shows its metadata widget.

  #### V2-alignment tasks (low-risk)
  1) **TemplateId guard (recommended safety)**
    - Guard entity header rendering in `SectionWidget` with `when section.templateId == SectionTemplateId.entityHeader`.
  2) **Honor `showMetadata` (recommended correctness)**
    - Either:
      - Plumb `showMetadata` into `EntityHeader` (e.g., `showMetadata: ...`) and conditionally render the metadata widget, or
      - Stop carrying `showMetadata` in the result and params (higher churn; not recommended under the “no ID churn / minimal risk” constraints).
    - Keep backward compatibility: default remains `true`.
- Tests (recommended targets)
  - Param decode strictness.
  - Switchboard routes to entity header only when `templateId == entity_header` (after adding templateId guard).
  - `entity_header` renders project/value/missing variants.
  - If implementing `showMetadata`: widget test asserts metadata hides when `showMetadata == false`.

---

## Static / full-screen templates (likely “done” already)
These templates are not “V2 list templates” by design (they are standalone screens). Only touch them if the migration introduces inconsistencies or dead code:
- IDs live in [lib/domain/screens/language/models/section_template_id.dart](lib/domain/screens/language/models/section_template_id.dart)
- Rendering is routed via [lib/presentation/widgets/section_widget.dart](lib/presentation/widgets/section_widget.dart) → `buildFullScreenTemplateSection`.

---

## Cross-cutting aggressive cleanup checklist (D8.B)
- Aggressive cleanup should be **scoped to code made dead by the migration**.
  - Do **not** remove required params like `attentionItemTileVariant`/`reviewItemTileVariant` just because current UI has only one variant.
  - Prefer removing: unused imports, unused constructor args, unreachable switch cases.
- Remove dead branches / unused helpers after refactors:
  - [lib/presentation/widgets/section_widget.dart](lib/presentation/widgets/section_widget.dart)
  - [lib/core/di/dependency_injection.dart](lib/core/di/dependency_injection.dart)
  - [lib/domain/screens/templates/interpreters/section_template_params_codec.dart](lib/domain/screens/templates/interpreters/section_template_params_codec.dart)
- Ensure system screen definitions still reference only valid template IDs:
  - [lib/domain/screens/catalog/system_screens/system_screen_definitions.dart](lib/domain/screens/catalog/system_screens/system_screen_definitions.dart)
- If any template catalog meaning changes, update:
  - [doc/architecture/UNIFIED_SCREEN_MODEL_ARCHITECTURE.md](doc/architecture/UNIFIED_SCREEN_MODEL_ARCHITECTURE.md)

## Final verification (D7.A)
- Run the recorded test runner task: `flutter_test_record`.
