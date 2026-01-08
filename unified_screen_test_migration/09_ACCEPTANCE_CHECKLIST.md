# 09 — Acceptance Checklist

## Phase 1: Compile + analyze clean

- [ ] `flutter analyze` passes with 0 errors.
- [ ] No test files reference removed legacy unified-screen types:
  - [ ] `SupportBlock` / `supportBlocks` / `support_blocks`
  - [ ] `NavigationOnlyScreenDefinition`
  - [ ] `DataDrivenScreenDefinition`
  - [ ] `primaryEntityType`

## Phase 2: Architecture consistency

- [ ] All BLoC tests use `blocTestSafe`.
- [ ] All async unit tests use `testSafe`.
- [ ] All widget tests use `testWidgetsSafe`.
- [ ] No widget tests use `pumpAndSettle()` for stream-driven widgets.
- [ ] Stream-based widget tests use `pumpForStream()`.

## Phase 3: Config-based correctness

- [ ] `SystemScreenDefinitions` tests assert `SectionRef` config and decode params.
- [ ] `SectionDataResult.data` tests use typed `ScreenItem` lists.
- [ ] Screen pipeline tests validate `ScreenDataInterpreter` behavior with:
  - [ ] empty sections
  - [ ] disabled sections
  - [ ] multiple sections combine
  - [ ] error handling

## Phase 4: Reduced duplication

- [ ] A single builder module exists (planned: `test/helpers/unified_screen_builders.dart`).
- [ ] New builders are used consistently across tests.
- [ ] No duplicate ad-hoc test builders remain in multiple files.

## Phase 5: Quality gates

- [ ] Tests do not hang (timeouts enforced).
- [ ] Integration tests use `IntegrationTestContext` and dispose correctly.
- [ ] Contracts use `testContract` and remain fast.

## Optional: Coverage expansion

- [ ] Add interpreter tests per template ID (one golden test each).
- [ ] Add regression tests for any bugs found during Phase 05 cleanup.
