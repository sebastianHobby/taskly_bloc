# 06 — Screen Pipeline + BLoC Test Migration

## Objective

Update screen pipeline / screen BLoC tests to target unified-screen flow:

`ScreenDefinition` → `ScreenDataInterpreter` → `ScreenData(definition, sections: List<SectionVm>)` → `ScreenBloc` states.

Remove legacy constructs:
- `DataDrivenScreenDefinition`
- `NavigationOnlyScreenDefinition`
- `supportBlocks`

## File: `test/integration/screen_bloc_integration_test.dart`

This is currently a hybrid unit/integration style (mock interpreter + mock repo + ScreenBloc).

### Exact edits

1) Replace fake fallback types

**Before**
- `class FakeDataDrivenScreenDefinition extends Fake implements DataDrivenScreenDefinition {}`

**After**
- `class FakeScreenDefinition extends Fake implements ScreenDefinition {}`

Update `registerFallbackValue(...)` accordingly.

2) Replace `_createScreenDefinition()`

**Before**
- Returns a `DataDrivenScreenDefinition(...)` with legacy `Section.data(...)` models.

**After**
- Return a `ScreenDefinition(...)` using:
  - `sections: [SectionRef(templateId: SectionTemplateId.taskList, params: ...)]`

Use real param objects when possible:
- `DataListSectionParams(config: DataConfig.task(query: TaskQuery.all())).toJson()`

3) Replace nav-only test

**Before**
- Constructs a `NavigationOnlyScreenDefinition` and expects an error.

**After**
- Construct a `ScreenDefinition` with **no enabled sections**. Two options:
  - `sections: const []`
  - Or a section list where all `SectionRef.overrides.enabled == false`

Then assert the expected state:
- If ScreenBloc treats empty sections as error, assert error.
- If it treats it as an empty loaded screen, assert loaded with 0 sections.

(Choose based on the actual current behavior of ScreenBloc; update expectation to match.)

4) Remove `ScreenData` supportBlocks

**Before**
- `ScreenData(definition: definition, sections: const [], supportBlocks: const [])`

**After**
- `ScreenData(definition: definition, sections: const [])`

5) Ensure tests use safe infrastructure

- Keep `blocTestSafe` usage (already present).
- For any stream mocks used by `watchScreen`, ensure `when(() => mockInterpreter.watchScreen(any()))` returns:
  - `Stream.value(testScreenData)` (finite) for simple cases, OR
  - a `TestStreamController` stream if multiple emissions are needed.

## Additional pipeline tests to add (recommended)

### A) `ScreenDataInterpreter.watchScreen` unit tests

Create `test/domain/services/screens/screen_data_interpreter_test.dart` (new):

- Use `testSafe`.
- Use fakes/stubs for `SectionTemplateInterpreterRegistry` and `SectionTemplateParamsCodec`.

Tests:
1. Empty sections → returns `ScreenData(definition, sections: [])`.
2. Disabled sections via overrides → returns empty.
3. Multiple sections combine → `sections.length == enabledSections.length`.
4. Section stream error → results in `ScreenData.error(...)`.

### B) Section VM correctness

Create `test/domain/services/screens/section_vm_test.dart` (if needed):
- Ensure `SectionVm(index, templateId, title, data)` has expected values.

## Exit criteria

- No tests import removed legacy screen/section models.
- Screen integration tests construct `ScreenDefinition` + `SectionRef`.
- No tests mention `supportBlocks`.
- All BLoC tests use `blocTestSafe`.
