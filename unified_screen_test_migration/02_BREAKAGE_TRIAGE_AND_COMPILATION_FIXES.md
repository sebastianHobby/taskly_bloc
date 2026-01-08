# 02 — Breakage Triage + Compilation Fixes

## Objective

Get `flutter analyze` clean by removing/updating tests still referencing legacy unified-screen types.

This phase prioritizes **compilation correctness** over perfect coverage.

## Known failing legacy references (current repo state)

### 1) `SupportBlock` and related types

- File to remove/replace:
  - `test/domain/models/screens/support_block_test.dart`

**Action**
- Delete this test file OR rewrite it to target the new equivalents (see 06/07).
- There is no direct one-to-one model replacement; support blocks were removed.

**Replacement targets**
- If the test was about "summary/support content shown on screens":
  - Replace with tests for summary templates:
    - `SectionTemplateId.issuesSummary`
    - `SectionTemplateId.checkInSummary`
    - `SectionTemplateId.allocationAlerts`
  - Or tests for `ScreenChrome` actions/badges if that was the real intent.

### 2) `DataDrivenScreenDefinition` and `NavigationOnlyScreenDefinition`

These were replaced by a single `ScreenDefinition` model.

Known callsites in tests (non-exhaustive):
- `test/contracts/repository_bloc_contracts_test.dart` (type checks)
- `test/integration/screen_bloc_integration_test.dart` (fake implements + constructors)
- `test/presentation/features/navigation/services/navigation_badge_service_test.dart` (builders)
- `test/presentation/features/navigation/bloc/navigation_bloc_test.dart`
- `test/fixtures/test_data.dart` (factories)
- `test/domain/models/screens/system_screen_definitions_test.dart` (expects type)

**Action**
- Replace type checks with `ScreenDefinition` assertions.
- Replace any nav-only screen behavior tests with one of:
  - Screen with `sections: []` (empty sections)
  - Screen with all sections disabled via `SectionRef(overrides: enabled=false)`

### 3) `primaryEntityType` / `primaryEntities`

Legacy `SectionDataResult.data(primaryEntities, primaryEntityType)` has been replaced by:
- `SectionDataResult.data(items: List<ScreenItem>, relatedEntities: ...)`

Known callsites:
- `test/domain/services/screens/section_data_result_test.dart`
- Some integration tests building fake `SectionDataWithMeta` (if present)

**Action**
- Rewrite tests to construct typed `ScreenItem.*` lists.
- Assert via:
  - `result.allTasks / allProjects / allValues`
  - `result.primaryCount`
  - For data sections: `items.whereType<ScreenItemTask>()...`

### 4) `ScreenDefinition.iconName`

Icon name now lives at `ScreenDefinition.chrome.iconName`.

Known callsites:
- `test/contracts/icon_contracts_test.dart`
- `test/mocks/fake_repositories.dart`

**Action**
- Replace `definition.iconName` with `definition.chrome.iconName`.

## Concrete file-by-file patch list

### A) `test/contracts/icon_contracts_test.dart`

- Replace:
  - `SystemScreenDefinitions.<x>.iconName` → `SystemScreenDefinitions.<x>.chrome.iconName`
- Keep:
  - Contract loop calling `resolver.resolve(screenId: screen.screenKey, iconName: screen.chrome.iconName)`

### B) `test/contracts/repository_bloc_contracts_test.dart`

- Remove all references to `DataDrivenScreenDefinition`.
- Replace the "data-driven screens have sections" contract with:
  - For every system screen:
    - `expect(screen.sections, isNotNull)`
    - Optionally: `expect(screen.sections, isNotEmpty)` only for screens that are supposed to render sections.

### C) `test/domain/services/screens/section_data_result_test.dart`

- Rewrite all `SectionDataResult.data(primaryEntities: ..., primaryEntityType: ...)` to:
  - `SectionDataResult.data(items: [...])`
- Replace all assertions about `primaryEntityType` with typed assertions about `ScreenItem`.

### D) `test/domain/models/screens/system_screen_definitions_test.dart`

- Remove import of removed `section.dart`.
- Replace:
  - `isA<DataDrivenScreenDefinition>()` with `isA<ScreenDefinition>()`.
- Replace section assertions to use `SectionRef` + template params:
  - `myDay.sections` should contain `SectionRef(templateId: SectionTemplateId.allocation, ...)` etc.
  - Decode allocation params using `AllocationSectionParams.fromJson(ref.params!)`.

### E) `test/integration/screen_bloc_integration_test.dart`

- Replace `FakeDataDrivenScreenDefinition` with `FakeScreenDefinition extends Fake implements ScreenDefinition`.
- Replace `_createScreenDefinition()` to return `ScreenDefinition(...)` with `sections: [SectionRef(...)]`.
- Remove `NavigationOnlyScreenDefinition` and instead create:
  - a `ScreenDefinition` with `sections: []` to test error/edge behavior.
- Update `ScreenData` construction helper:
  - `ScreenData(definition: definition, sections: const [])`
  - Remove `supportBlocks` argument (no longer exists).

## Exit criteria for this phase

- `flutter analyze` no longer fails due to missing legacy types.
- No tests import deleted domain models (notably `support_block.dart`, legacy `section.dart`).

Next: migrate tests to config-driven semantics (see 03–07).
