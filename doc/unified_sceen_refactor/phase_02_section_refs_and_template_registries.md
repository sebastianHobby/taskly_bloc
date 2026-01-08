# Phase 02 — Replace `Section` With `SectionRef` + Introduce Template Registries

## Goal

- Replace persisted `sections: List<Section>` with `sections: List<SectionRef>`.
- Introduce a **template registry** model:
  - `templateId` identifies a template.
  - `params` is typed per template.
- Remove the legacy `Section` union and all switch-based section interpretation.

Repo-verified high-churn areas you should expect to update in this phase:

- `lib/domain/models/screens/system_screen_definitions.dart` (screen definitions)
- `lib/domain/services/screens/screen_data_interpreter.dart` (iterating/combining sections)
- `lib/domain/services/screens/section_data_service.dart` (old section interpretation)
- `lib/presentation/widgets/section_widget.dart` (old result-based branching)
- Screen creation/management UIs that construct sections (e.g. `screen_creator_page.dart`, `focus_screen_creator_page.dart`, `screen_management_page.dart`)

## AI Instructions
- Delete legacy code; do not keep adapters.
- Ensure `flutter analyze` is clean at end.

## New core types

### `SectionRef`
Create: `lib/domain/models/screens/section_ref.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'section_ref.freezed.dart';
part 'section_ref.g.dart';

@freezed
class SectionRef with _$SectionRef {
  const factory SectionRef({
    required String templateId,
    @Default({}) Map<String, dynamic> params,
    SectionOverrides? overrides,
  }) = _SectionRef;

  factory SectionRef.fromJson(Map<String, dynamic> json) =>
      _$SectionRefFromJson(json);
}

@freezed
class SectionOverrides with _$SectionOverrides {
  const factory SectionOverrides({
    String? title,
    @Default(true) bool enabled,
  }) = _SectionOverrides;

  factory SectionOverrides.fromJson(Map<String, dynamic> json) =>
      _$SectionOverridesFromJson(json);
}
```

### Template IDs
Create: `lib/domain/models/screens/section_template_id.dart`

```dart
abstract final class SectionTemplateId {
  static const taskList = 'task_list';
  static const projectList = 'project_list';
  static const valueList = 'value_list';
  static const agenda = 'agenda';
  static const allocation = 'allocation';

  static const issuesSummary = 'issues_summary';
  static const checkInSummary = 'check_in_summary';
  static const allocationAlerts = 'allocation_alerts';
  static const entityHeader = 'entity_header';

  // Amendments (2026-01-08): attention banners
  static const attentionBanner = 'attention_banner';
  static const reviewBanner = 'review_banner';

  static const settingsMenu = 'settings_menu';
  static const workflowList = 'workflow_list';
  static const journalTimeline = 'journal_timeline';
  static const navigationSettings = 'navigation_settings';
  static const allocationSettings = 'allocation_settings';
  static const attentionRules = 'attention_rules';
  static const screenManagement = 'screen_management';
}

## Amendments (2026-01-08)

### Attention banners are first-class templates

Introduce template(s) that implement the banner UX:

- `review_banner`: surfaces the review ritual due state; click launches **Review**.
- `attention_banner`: surfaces all non-review attention items; click expands if $\le \texttt{workflow\_threshold}$,
  click launches **Resolve** if $> \texttt{workflow\_threshold}$.

These templates must be implemented via the same interpreter/renderer registries as all
other templates (no special-case screen builder logic).

**Implementation note (accepted):**

- `review_banner` should evaluate a single global ritual due-state (via the
  `review_ritual` rule + constant entityId) and include all enabled review types
  (enabled = corresponding per-type review rule has `active == true`).

**Template params (accepted):**

- `attention_banner` params include:
  - `workflow_threshold` (int, default `5`)

Suggested typed params model (example):

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'attention_banner_params.freezed.dart';
part 'attention_banner_params.g.dart';

@freezed
class AttentionBannerParams with _$AttentionBannerParams {
  const factory AttentionBannerParams({
    @Default(5) int workflowThreshold,
  }) = _AttentionBannerParams;

  factory AttentionBannerParams.fromJson(Map<String, dynamic> json) =>
      _$AttentionBannerParamsFromJson(json);
}
```

Encoding/decoding guidance:

- Persist as JSON key `workflow_threshold` to match other persisted snake_case keys.
- Codec maps `workflow_threshold` ↔ `workflowThreshold`.

**Workflow grouping (accepted):**

- Workflow grouping logic groups by entity type and then by project where possible.
- Unparented tasks appear under a pseudo parent group "Inbox".

Resolve grouping algorithm sketch (implementation guidance):

1. Partition attention items into:
  - Review (handled elsewhere via `review_banner`)
  - Non-review items eligible for Resolve
2. For each non-review item:
  - Determine `entityType` (task/project/...)
  - Determine `projectId` if available (for tasks: their parent project)
3. Group into `ResolveGroup`s by:
  - `entityType` first
  - within tasks: by `projectId`, using a synthetic `projectId = "inbox"` when null
4. Within each group:
  - Sort by severity desc, then rule sortOrder (if available), then stable secondary
    key (e.g. entity name or id)
5. Render group headers:
  - Project-backed groups show the project name
  - Synthetic group shows "Inbox"

**Allocation note (accepted):**

- Allocation warnings are evaluated via an imperative call from the allocation service
  (not via unified attention streaming), using allocation engine outputs.
```

## Step-by-step Implementation

### 1) Update ScreenDefinition to use SectionRef

Files:
- `lib/domain/models/screens/screen_definition.dart`

Actions:
- Replace `List<Section> sections` with `List<SectionRef> sections`.
- Remove any JSON parsing logic for the old `Section` union.

Also update any intermediate config containers that embed sections (if any) so the persisted screen shape is consistent.

### 2) Delete `Section` union and related types

Delete files:
- `lib/domain/models/screens/section.dart`
- Any `section.freezed.dart`, `section.g.dart` generation references will update automatically via build_runner.

Also delete any code that switches on `Section`.

### 3) Introduce typed params per template

Create Freezed param models for each template. Suggested location:
- `lib/domain/models/screens/templates/*.dart`

Examples:

`task_list_params.dart`
```dart
@freezed
class TaskListParams with _$TaskListParams {
  const factory TaskListParams({
    required TaskQuery query,
    DisplayConfig? display,
    @Default(TaskTileVariant.standard) TaskTileVariant tileVariant,
  }) = _TaskListParams;

  factory TaskListParams.fromJson(Map<String, dynamic> json) =>
      _$TaskListParamsFromJson(json);
}
```

Repeat for project/value/agenda/allocation/etc.

### 4) Add template param codec

Create: `lib/domain/services/screens/section_template_params_codec.dart`

Responsibilities:
- `decode(templateId, paramsJson) -> typed params`
- `encode(templateId, params) -> json`

No reflection.

### 5) Replace SectionDataService with template interpreters

Create:
- `lib/domain/services/screens/templates/section_template_interpreter.dart`

```dart
abstract interface class SectionTemplateInterpreter<P, VM> {
  String get templateId;
  Stream<VM> watch(P params);
  Future<VM> fetch(P params);
}
```

Create a registry:
- `SectionTemplateInterpreterRegistry` (map templateId -> interpreter)

Each old section becomes a template interpreter class:
- Task list interpreter
- Project list interpreter
- Agenda interpreter
- Allocation interpreter
- Support sections interpreters

### 6) Update ScreenDataInterpreter to iterate SectionRefs

Files:
- `lib/domain/services/screens/screen_data_interpreter.dart`

Actions:
- Accept the interpreter registry + params codec.
- For each SectionRef:
  - decode params
  - call interpreter.watch(params)
  - combine results in order

### 7) Update presentation rendering to be templateId-based

Replace `SectionWidget`’s switch with:
- `SectionVm` carrying `templateId` and typed VM.
- `SectionRendererRegistry` mapping templateId -> widget builder.

### 8) Update all screen definitions and creator pages

Files:
- `lib/domain/models/screens/system_screen_definitions.dart`
- `lib/presentation/features/screens/view/screen_creator_page.dart`
- `lib/presentation/features/screens/view/focus_screen_creator_page.dart`

Actions:
- Replace `Section.data(...)` with `SectionRef(templateId: ..., params: ...)`

Repo-verified grep checks for completion:

- `\bSection\b(?!Ref)` (after the phase, only `SectionRef` should remain)
- `switch\s*\(section\)` / `when\s*\(.*Section` (remove switch-based interpretation)

## Validation

Run:
- `flutter analyze`

Fix all errors/warnings.

## Completion criteria
- No `Section` union remains.
- All screens compile and render via `SectionRef` pipeline.
- `flutter analyze` clean.
