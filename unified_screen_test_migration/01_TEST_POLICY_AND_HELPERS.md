# 01 — Test Policy + Required Helpers

## Policy

### Always use safe wrappers

- **Unit tests**: Use `testSafe(...)` from `test/helpers/test_helpers.dart` for async tests.
- **Contract tests**: Use `testContract(...)` from `test/helpers/contract_test_helpers.dart`.
- **BLoC tests**: Use `blocTestSafe(...)` from `test/helpers/bloc_test_patterns.dart`.
- **Widget tests**: Use `testWidgetsSafe(...)` from `test/helpers/test_helpers.dart`.
- **Integration tests**: Use `testIntegration(...)` from `test/helpers/integration_test_helpers.dart`.

### Never allow hanging tests

- Do **not** use `pumpAndSettle()` for stream/BLoC driven widgets.
  - Use `await tester.pumpForStream();` (extension in `test/helpers/test_helpers.dart`).
- When mocking streams, prefer helpers that avoid race conditions:
  - `TestStreamController<T>` (in `test/helpers/bloc_test_patterns.dart`) for watch-streams.
  - `completingStream([...])` for streams that should complete.

### Unified-screen vocabulary only

Do not reintroduce:
- `SupportBlock`, `supportBlocks`, `support_blocks`
- `NavigationOnlyScreenDefinition`
- `DataDrivenScreenDefinition`
- `primaryEntityType`
- `List<dynamic> primaryEntities`

Replace with:
- `ScreenDefinition` + `ScreenChrome` + `SectionRef`
- Typed list items via `ScreenItem.task|project|value|header|divider`
- Section results via `SectionDataResult.*` variants.

## Helpers to lean on (existing)

### BLoC safety

File: `test/helpers/bloc_test_patterns.dart`
- `blocTestSafe` (hard timeout around `act()` + consistent setup)
- `kBlocTestTimeout`, `kBlocWaitDuration`
- `TestStreamController<T>` for race-free stream mocks

### General test safety

File: `test/helpers/test_helpers.dart`
- `testSafe`
- `testWidgetsSafe`
- `PumpHelpers.pumpForStream()`
- `PumpHelpers.pumpUntilFound()`

### Contract tests

File: `test/helpers/contract_test_helpers.dart`
- `testContract`
- `verifyExhaustiveMapping`, `verifyUniqueMapping`, `verifyRoundTrip`

### Integration tests

File: `test/helpers/integration_test_helpers.dart`
- `testIntegration`
- `IntegrationTestContext.create()` (real DB + repos, plus tracked cleanup)

## Minimal new test conventions

### Naming
- Keep existing naming and folder structure under `test/**`.
- Prefer `*_test.dart` files to stay where they already live.

### Structure
- Arrange/Act/Assert (or Given/When/Then) in each test.
- For interpreter tests, default to deterministic in-memory values + stubs.
- Integration tests are allowed to use real DB via `IntegrationTestContext`.

### Builder pattern (planned)

Add a dedicated builder layer (see 08_INFRA_UPDATES_AND_NEW_BUILDERS.md):
- `ScreenDefinition` builder
- `SectionRef` builder
- `SectionVm` / `SectionDataResult` helpers
- `ScreenItem` helpers

This reduces repetition and makes template changes cheaper to propagate.
