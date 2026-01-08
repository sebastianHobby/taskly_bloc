# 04 — ScreenDefinition + SystemScreenDefinitions Migration

## Objective

Update system screen tests to validate **configuration** (sections + params) instead of legacy screen subclasses.

## Primary target

- `test/domain/models/screens/system_screen_definitions_test.dart`

## Exact changes

### 1) Fix imports

- Remove legacy import:
  - `package:taskly_bloc/domain/models/screens/section.dart` (no longer exists)
- Add/ensure:
  - `package:taskly_bloc/domain/models/screens/section_ref.dart`
  - `package:taskly_bloc/domain/models/screens/section_template_id.dart`
  - `package:taskly_bloc/domain/models/screens/templates/allocation_section_params.dart`
  - Any other `*SectionParams` needed by expectations.

### 2) Replace type assertions

**Before**
- `expect(myDay, isA<DataDrivenScreenDefinition>())`

**After**
- `expect(myDay, isA<ScreenDefinition>())`

### 3) Replace "section" assertions with `SectionRef` assertions

The new model is `ScreenDefinition.sections: List<SectionRef>`.

For `SystemScreenDefinitions.myDay`, validate:
- It includes:
  - `SectionRef(templateId: SectionTemplateId.checkInSummary)`
  - `SectionRef(templateId: SectionTemplateId.allocationAlerts)`
  - `SectionRef(templateId: SectionTemplateId.allocation, params: ...)`

### 4) Decode params to validate configuration flags

Find the allocation section ref:
- `final allocationRef = myDay.sections.firstWhere((s) => s.templateId == SectionTemplateId.allocation);`

Decode:
- `final params = AllocationSectionParams.fromJson(allocationRef.params!);`

Assert:
- `params.showExcludedSection == true`
- `params.showExcludedWarnings == true`
- `params.displayMode == AllocationDisplayMode.pinnedFirst`

### 5) Replace removed legacy screen key expectations if needed

If existing tests assert old screens removed (e.g. `today`, `next_actions`), keep them **only if** the current `SystemScreenDefinitions` still uses `getByKey` returning `null` for those keys.

## Secondary targets (likely)

These tests commonly drift during the refactor and should be updated using the same pattern:

- `test/domain/models/screens/screen_definition_test.dart`
  - Ensure icon assertions use `screen.chrome.iconName`.
  - Ensure JSON roundtrip includes `chrome`.

- `test/fixtures/test_data.dart`
  - Replace factories that create `DataDrivenScreenDefinition`/`NavigationOnlyScreenDefinition`.
  - Replace legacy section constructs with `SectionRef` + `SectionTemplateId` + params.

## Exit criteria

- No test imports `domain/models/screens/section.dart`.
- No test references `DataDrivenScreenDefinition`.
- System screen tests assert configuration via `SectionRef` and `*SectionParams.fromJson`.
