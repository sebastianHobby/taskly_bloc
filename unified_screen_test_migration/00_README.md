# Unified Screen Test Migration

This folder contains a **step-by-step migration plan** to bring `test/**` into alignment with the unified-screen architecture:

- `ScreenDefinition` + `ScreenChrome`
- `SectionRef(templateId, params, overrides)`
- Typed list payloads via `ScreenItem` (no `List<dynamic>`)
- Section template interpreters → `SectionDataResult` variants
- Screen pipeline via `ScreenDataInterpreter` → `ScreenData` + `SectionVm`

## Non-negotiables

1. Use the existing "safe" test infrastructure everywhere:
   - Unit tests: `testSafe` from `test/helpers/test_helpers.dart`
   - Contract tests: `testContract` from `test/helpers/contract_test_helpers.dart`
   - BLoC tests: `blocTestSafe` from `test/helpers/bloc_test_patterns.dart`
   - Integration tests: `testIntegration` from `test/helpers/integration_test_helpers.dart`
   - Widget tests: `testWidgetsSafe` + `pumpForStream()` (avoid `pumpAndSettle()` for stream-driven widgets)

2. Tests must be **configuration-driven**.
   - Build screens using `ScreenDefinition` + `SectionRef`s.
   - Do not reintroduce legacy model concepts removed by the refactor (`SupportBlock`, `NavigationOnlyScreenDefinition`, `primaryEntityType`, `DataDrivenScreenDefinition`).

3. Keep the migration incremental.
   - First, make the suite compile + `flutter analyze` clean.
   - Then improve coverage and reduce duplication.

## Recommended execution order

1. 01_TEST_POLICY_AND_HELPERS.md
2. 02_BREAKAGE_TRIAGE_AND_COMPILATION_FIXES.md
3. 03_SECTION_DATA_RESULT_TEST_MIGRATION.md
4. 04_SCREEN_DEFINITION_AND_SYSTEM_SCREENS_TEST_MIGRATION.md
5. 05_NAVIGATION_AND_ICON_CONTRACTS_MIGRATION.md
6. 06_SCREEN_PIPELINE_AND_BLOC_TEST_MIGRATION.md
7. 07_INTEGRATION_TEST_STRATEGY.md
8. 08_INFRA_UPDATES_AND_NEW_BUILDERS.md
9. 09_ACCEPTANCE_CHECKLIST.md
