# Unified Screen Model V2 — Implementation Reference

Created at: 2026-01-12T00:00:00Z (UTC)
Last updated at: 2026-01-12T00:00:00Z (UTC)

This document is a “single source of truth” reference for the implementation.

It exists to:
- remove ambiguity for an AI implementing Phases 2–5
- standardize naming, JSON shapes, and responsibilities
- list exact file touchpoints/checklists

## 0) Hard constraints (do not violate)

- Full cutover with new template IDs (no compatibility decode): see `decisions.md`.
- Related-data sidecar is removed; no `Map<String, List<Object>> relatedEntities` in V2.
- Layout modes are **only**:
  - `flat_list`
  - `timeline_month_sections`
  - `hierarchy_value_project_task`
- Sticky headers are supported for timeline + grouped lists.
- Agenda tag pills must be available anywhere `TaskTileVariant.agenda` is used.
- `ValueDataConfig(query: ...)` must be honored end-to-end.

## 1) New template IDs (V2)

Add to `lib/domain/screens/language/models/section_template_id.dart`:

- `task_list_v2`
- `project_list_v2`
- `value_list_v2`
- `interleaved_list_v2`
- `agenda_v2`

## 2) Canonical V2 params + JSON schemas

This section defines the recommended Dart shapes. Minor renaming is fine as long as:
- JSON is strict + stable
- types stay explicit
- responsibilities stay aligned (domain computes enrichment)

### 2.1 Common spec: tiles + enrichment + layout

**Tile policy**

Recommended: reuse existing tile variant enums, but bundle into a single typed policy.

```dart
@freezed
class TilePolicyV2 with _$TilePolicyV2 {
  const factory TilePolicyV2({
    required TaskTileVariant task,
    required ProjectTileVariant project,
    required ValueTileVariant value,
  }) = _TilePolicyV2;
}
```

JSON example:

```json
{"task":"agenda","project":"listTile","value":"compactCard"}
```

**Enrichment plan**

Recommended: a typed union + list (keeps it extensible without “flag creep”).

```dart
@Freezed(unionKey: 'type')
sealed class EnrichmentPlanItemV2 with _$EnrichmentPlanItemV2 {
  @FreezedUnionValue('value_stats')
  const factory EnrichmentPlanItemV2.valueStats() = _ValueStatsItem;

  @FreezedUnionValue('open_task_counts')
  const factory EnrichmentPlanItemV2.openTaskCounts() = _OpenTaskCountsItem;

  @FreezedUnionValue('agenda_tags')
  const factory EnrichmentPlanItemV2.agendaTags({
    required AgendaDateField dateField,
  }) = _AgendaTagsItem;
}

@freezed
class EnrichmentPlanV2 with _$EnrichmentPlanV2 {
  const factory EnrichmentPlanV2({
    @Default(<EnrichmentPlanItemV2>[]) List<EnrichmentPlanItemV2> items,
  }) = _EnrichmentPlanV2;
}
```

Notes:
- `agendaTags(dateField: ...)` is the mechanism that makes tags available outside `agenda_v2`.
- For `agenda_v2`, the plan can be implicit (renderer always expects tags) but *still* keep it explicit in params for clarity.

**Enrichment result**

Keep typed payloads. Recommended shape:

```dart
enum AgendaTagV2 { starts, due, inProgress }

@freezed
class OpenTaskCountsV2 with _$OpenTaskCountsV2 {
  const factory OpenTaskCountsV2({
    @Default({}) Map<String, int> byProjectId,
    @Default({}) Map<String, int> byValueId,
  }) = _OpenTaskCountsV2;
}

@freezed
class EnrichmentResultV2 with _$EnrichmentResultV2 {
  const factory EnrichmentResultV2({
    ValueStats? valueStats,
    OpenTaskCountsV2? openTaskCounts,
    @Default({}) Map<String, AgendaTagV2> agendaTagByTaskId,
  }) = _EnrichmentResultV2;
}
```

Notes:
- `agendaTagByTaskId` is a map because it’s cheap to consume in tiles.
- If you prefer, store as `Map<String, AgendaTagV2?>` but avoid nullable values unless needed.

### 2.2 Layout spec (3 modes only)

Use a discriminated union with an explicit JSON tag.

```dart
@Freezed(unionKey: 'type')
sealed class SectionLayoutSpecV2 with _$SectionLayoutSpecV2 {
  @FreezedUnionValue('flat_list')
  const factory SectionLayoutSpecV2.flatList({
    @Default(ListSeparatorV2.divider) ListSeparatorV2 separator,
  }) = _FlatList;

  @FreezedUnionValue('timeline_month_sections')
  const factory SectionLayoutSpecV2.timelineMonthSections({
    @Default(true) bool pinnedSectionHeaders,
  }) = _TimelineMonthSections;

  @FreezedUnionValue('hierarchy_value_project_task')
  const factory SectionLayoutSpecV2.hierarchyValueProjectTask({
    @Default(true) bool pinnedValueHeaders,
    @Default(false) bool pinnedProjectHeaders,
    @Default(false) bool singleInboxGroupForNoProjectTasks,
  }) = _HierarchyValueProjectTask;
}

enum ListSeparatorV2 { divider, spaced8, interleavedAuto }
```

Mapping to current UI:
- Task list ≈ `flat_list + divider`
- Project/value list ≈ `flat_list + spaced8`
- Interleaved list ≈ `flat_list + interleavedAuto`
- Scheduled ≈ `timeline_month_sections + pinnedSectionHeaders`

### 2.3 Section params

**List templates** (`task_list_v2`, `project_list_v2`, `value_list_v2`)

```dart
@freezed
class ListSectionParamsV2 with _$ListSectionParamsV2 {
  const factory ListSectionParamsV2({
    required DataConfig config,
    required TilePolicyV2 tiles,
    required SectionLayoutSpecV2 layout,
    @Default(EnrichmentPlanV2()) EnrichmentPlanV2 enrichment,
  }) = _ListSectionParamsV2;
}
```

**Interleaved** (`interleaved_list_v2`)

```dart
@freezed
class InterleavedListSectionParamsV2 with _$InterleavedListSectionParamsV2 {
  const factory InterleavedListSectionParamsV2({
    required List<DataConfig> sources,
    required TilePolicyV2 tiles,
    required SectionLayoutSpecV2 layout,
    @Default(EnrichmentPlanV2()) EnrichmentPlanV2 enrichment,
  }) = _InterleavedListSectionParamsV2;
}
```

**Agenda** (`agenda_v2`)

```dart
@freezed
class AgendaSectionParamsV2 with _$AgendaSectionParamsV2 {
  const factory AgendaSectionParamsV2({
    required AgendaDateField dateField,
    required TilePolicyV2 tiles,
    required SectionLayoutSpecV2 layout,
    @Default(EnrichmentPlanV2()) EnrichmentPlanV2 enrichment,
    @NullableTaskQueryConverter() TaskQuery? additionalFilter,
  }) = _AgendaSectionParamsV2;
}
```

Notes:
- `layout` for agenda should be `timeline_month_sections`.
- `enrichment` should include `agendaTags(dateField: ...)`.

## 3) Runtime contracts (domain owns enrichment)

### 3.1 Where enrichment is computed

- Prefer: interpreter → runtime service (`SectionDataService` or V2-specific service) computes enrichment.
- Renderers only read typed outputs.

### 3.2 Recommended V2 result payload

To avoid breaking legacy while V2 is introduced:
- Add a new union variant to `SectionDataResult` for V2 list sections (recommended name: `dataV2`).
- Keep legacy `data(...)` intact until Phase 5.

Recommended payload:

```dart
const factory SectionDataResult.dataV2({
  required List<ScreenItem> items,
  EnrichmentResultV2? enrichment,
}) = DataV2SectionResult;
```

## 4) Presentation contracts (sticky headers + agenda tags)

### 4.1 Sticky headers

- Use `SliverPersistentHeader(pinned: true, delegate: ...)`.
- Follow the existing `agenda_section_renderer.dart` delegate pattern.

### 4.2 Agenda tags anywhere

- Tile-building path already supports `titlePrefix` via `ScreenItemTileRegistry`.
- V2 renderers should derive `titlePrefix` when:
  - current item is a task
  - `tiles.task == TaskTileVariant.agenda`
  - `enrichment.agendaTagByTaskId` contains the task id

## 5) File touchlists (per phase)

This is the “don’t forget these” list.

### Phase 2 (models/codecs)

- Add template IDs:
  - `lib/domain/screens/language/models/section_template_id.dart`
- Add V2 params/models (new files):
  - `lib/domain/screens/templates/params/list_section_params_v2.dart`
  - `lib/domain/screens/templates/params/interleaved_list_section_params_v2.dart`
  - `lib/domain/screens/templates/params/agenda_section_params_v2.dart`
- Wire codec:
  - `lib/domain/screens/templates/interpreters/section_template_params_codec.dart`
- Run codegen:
  - VS Code task `build_runner`

### Phase 3 (runtime/interpreters)

- Interpreter registry wiring:
  - `lib/domain/screens/templates/interpreters/section_template_interpreter_registry.dart`
  - `lib/core/di/dependency_injection.dart` (interpreter registrations)
- Add V2 interpreters (new files):
  - `lib/domain/screens/templates/interpreters/data_list_section_interpreter_v2.dart`
  - `lib/domain/screens/templates/interpreters/interleaved_list_section_interpreter_v2.dart`
  - `lib/domain/screens/templates/interpreters/agenda_section_interpreter_v2.dart`
- Runtime services:
  - `lib/domain/screens/runtime/section_data_service.dart` (add V2 entry points)
  - Possibly add `lib/domain/screens/runtime/enrichment/` helpers to keep logic contained
- Result model:
  - `lib/domain/screens/runtime/section_data_result.dart` (add `dataV2` variant)

### Phase 4 (presentation)

- Section switch:
  - `lib/presentation/widgets/section_widget.dart`
- Add V2 renderers (new files):
  - `lib/presentation/screens/templates/renderers/task_list_renderer_v2.dart`
  - `lib/presentation/screens/templates/renderers/project_list_renderer_v2.dart`
  - `lib/presentation/screens/templates/renderers/value_list_renderer_v2.dart`
  - `lib/presentation/screens/templates/renderers/interleaved_list_renderer_v2.dart`
  - `lib/presentation/screens/templates/renderers/agenda_section_renderer_v2.dart`
- Shared sticky header delegate (optional, recommended):
  - `lib/presentation/screens/templates/renderers/shared/pinned_section_header_delegate.dart`

### Phase 5 (cutover/cleanup/docs)

- Cut system screens:
  - `lib/domain/screens/catalog/system_screens/system_screen_specs.dart`
- Generated detail screen defs:
  - whichever file defines `forProject()` / `forValue()` in the screen catalog
- Delete legacy:
  - legacy params/interpreters/renderers
  - related-data sidecar types + runtime plumbing
- Docs:
  - `doc/architecture/UNIFIED_SCREEN_MODEL_ARCHITECTURE.md`

## 6) Validation workflow (repo rules)

- During Phases 2–4: run `flutter analyze` and keep it clean.
- Run tests only once at the very end of Phase 5 using `flutter_test_record`.

## 7) Common pitfalls / “gotchas”

- Freezed union JSON tags: ensure consistent `unionKey` and `@FreezedUnionValue` values.
- Don’t accidentally wire V2 to legacy params in `SectionTemplateParamsCodec`.
- Avoid introducing “generic groupBy enums” that will never be applied.
- Be careful with sliver composition when adding sticky headers to grouped lists.
- Ensure `ValueDataConfig(query)` is honored in **both** fetch and watch paths.
