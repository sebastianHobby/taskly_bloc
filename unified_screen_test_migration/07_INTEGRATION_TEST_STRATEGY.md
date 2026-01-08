# 07 — Integration Test Strategy (Config-Based)

## Objective

Use integration tests to validate that **real repositories + real interpreters** work together given a purely-configured screen definition.

This complements unit tests by catching drift at the boundaries:
- DB ↔ repository
- repository ↔ interpreter
- interpreter ↔ BLoC/presentation

## Use the existing integration infra (mandatory)

File: `test/helpers/integration_test_helpers.dart`
- `testIntegration(...)`
- `IntegrationTestContext.create()`
- `ctx.seedSystemScreens()`
- `ctx.seedScreen(screen: ScreenDefinition(...))`

Do not roll your own DB bootstrapping.

## Recommended integration test types

### A) Screen definitions repository flow

Create/extend tests that:
1. Create a custom screen in the DB via `ctx.seedScreen(...)`.
2. Watch it via `ctx.screensRepository.watchScreen(screenKey)`.
3. Assert it emits a `ScreenWithPreferences` with:
   - screen matching the config
   - preferences matching what was seeded

Use `testIntegration` and ensure all streams are cleaned up.

### B) Interpreter + template registry flow (real interpreters)

If there is an integration path that wires real template interpreters:
1. Create a `ScreenDefinition` with 2+ sections:
   - e.g. `issuesSummary` + `taskList`
2. Run the real `ScreenDataInterpreter.watchScreen(definition)`.
3. Assert:
   - emits `ScreenData` with 2 `SectionVm`s
   - each `SectionVm.data` is the correct `SectionDataResult` variant

Where repositories are required, prefer the real context’s repos.

### C) Avoid widget-level E2E unless needed

Widget integration tests can be useful, but are the easiest to make flaky.
If needed:
- Use `testWidgetsSafe`.
- Avoid `pumpAndSettle()`; use `pumpForStream()`.

## Scope boundaries

Integration tests should validate:
- "Does the pipeline work end-to-end with this config?"

They should NOT validate:
- every tiny mapping case (those are unit/contract tests)
- UI layout details (those are widget tests, and should be minimal)

## Exit criteria

- Integration tests exercise at least one fully-configured `ScreenDefinition` round trip (DB → repo → pipeline output).
- All integration tests use `testIntegration` and `IntegrationTestContext`.
