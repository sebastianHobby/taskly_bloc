# 05 — Navigation + Icon Contracts Migration

## Objective

Keep the existing contract-test style for navigation, but align it with unified-screen config:
- Icons come from `ScreenDefinition.chrome.iconName` and `screen.screenKey`.
- Badge/navigation behavior must be computed from `ScreenDefinition.sections` + template IDs (if applicable).

## Files

### A) `test/contracts/icon_contracts_test.dart`

**Change**
- Replace `SystemScreenDefinitions.<x>.iconName` with `SystemScreenDefinitions.<x>.chrome.iconName`.

**Keep**
- The loop contract that calls `resolver.resolve(screenId: screen.screenKey, iconName: screen.chrome.iconName)`.

**Optionally improve**
- Use `verifyExhaustiveMapping` from `test/helpers/contract_test_helpers.dart` to simplify and standardize failures.

### B) `test/contracts/repository_bloc_contracts_test.dart`

**Change**
- Remove the `DataDrivenScreenDefinition` type gate.
- Replace with a contract that every system screen:
  - has non-empty `screenKey` and `name`
  - can be wrapped in `ScreenWithPreferences`
  - produces a non-default icon via `NavigationIconResolver`.

### C) `test/presentation/features/navigation/services/navigation_badge_service_test.dart`

This file currently constructs legacy screen definitions.

**Change**
- Replace builders to create `ScreenDefinition` with the needed `sections`.
- If a test needs a screen that should show a badge:
  - Construct `ScreenDefinition` sections with the template that drives badges.
  - Prefer using system screens where possible (e.g., `SystemScreenDefinitions.inbox`).

**Important**
- Do not reintroduce `NavigationOnlyScreenDefinition`.

### D) `test/presentation/features/navigation/bloc/navigation_bloc_test.dart`

**Change**
- Replace any usage of `DataDrivenScreenDefinition` with `ScreenDefinition`.
- When stubbing repository streams, use `TestStreamController` if the stream is long-lived.
- Wrap bloc tests in `blocTestSafe`.

## Recommended contract approach (keep existing philosophy)

For contracts, keep tests focused on interface agreement, not behavior:

- SystemScreenDefinitions ↔ NavigationIconResolver
- ScreenWithPreferences ↔ NavigationBloc destination building
- (If badge service exists) ScreenDefinition sections ↔ badge computation

Use `testContract` for these.

## Exit criteria

- No navigation tests refer to `DataDrivenScreenDefinition` or `NavigationOnlyScreenDefinition`.
- Icon contracts use `screen.chrome.iconName` everywhere.
- All navigation BLoC tests use `blocTestSafe`.
