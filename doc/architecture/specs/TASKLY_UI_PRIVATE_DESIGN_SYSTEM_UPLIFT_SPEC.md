# Taskly UI Private Design System Uplift Spec

## Purpose

Redefine `packages/taskly_ui` from a generic shared-UI package into Taskly's
private design system package.

This uplift exists to make Taskly easier to theme, restyle, and evolve without
leaving appearance logic scattered across app screens.

## Decision

`packages/taskly_ui` is Taskly-only.

It owns:

- design tokens
- semantic theme extensions
- shared chrome
- visual primitives
- visual presets/variants
- render-only entity/section wrappers

The app owns:

- BLoCs and screen state
- routing and navigation decisions
- side-effects
- data shaping and feature orchestration

## Non-goals

- Do not move routing, repositories, DI, analytics, or BLoC logic into
  `taskly_ui`.
- Do not make `taskly_ui` generic or reusable outside Taskly.
- Do not change product behavior as part of the theming uplift.

## Target architecture

### `taskly_ui` owns

- `TasklyTokens`
- semantic theme extensions:
  - app chrome
  - page header
  - cards
  - chips
  - filters
  - empty states
  - sheets/modals
  - insight panels
  - entity-row chrome
- render-only primitives:
  - page header
  - chrome icon button
  - page surface
  - card surface
  - chip
  - empty state shell
  - error state shell
  - sheet chrome
- render-only section/entity wrappers and feed chrome

### app presentation owns

- view models and mappers
- feature-specific content ordering
- callbacks and actions
- route-specific icon resolution
- screen-local state and transient behavior

## Variant model

Use named variants/presets instead of boolean appearance flags.

Initial variant families:

- cards: `summary`, `insight`, `maintenance`, `editor`, `subtle`
- chips: `filter`, `metric`, `status`, `selection`
- sheets: `default`, `editor`, `supporting`
- headers: `screen`, `section`, `hero`, `compact`
- entity row chrome: `standard`, `compact`, `highlighted`, `bulkSelection`

## Migration plan

### Wave 1

- Update docs/invariants to declare `taskly_ui` as Taskly-only.
- Move existing semantic theme extensions into `taskly_ui`.
- Move current shared chrome primitives into `taskly_ui`.
- Migrate current consumers and delete replaced app-owned duplicates.

Delivered in this uplift:

- semantic themes now live under `packages/taskly_ui/lib/src/foundations/theme/`
- shared chrome is exported from `taskly_ui_chrome.dart`
- card/chip/sheet primitives are exported from `taskly_ui_primitives.dart`
- top-level app screens consume package-owned page header/chrome
- app-owned semantic/chrome duplicates were deleted

### Wave 2

- Add semantic themes for cards, chips, filters, empty states, sheets, insight
  panels, and entity-row chrome.
- Migrate high-visibility shared package widgets to semantic theme reads.
- Expand page surface semantics to support ambient layered backgrounds for
  branded top-level and editor/detail screens.

### Wave 3

- Migrate top-level app screens to consume package-owned chrome and surface
  primitives only.
- Remove duplicated screen-local appearance helpers.

### Wave 4

- Migrate feed/entity row chrome and remaining repeated shared-section styling.
- Run broad regression and remove legacy paths.

## Guardrails

- `taskly_ui` remains render-only.
- No BLoCs, service locators, repositories, routing, or analytics in
  `taskly_ui`.
- If a style appears in two or more places, prefer a semantic theme role or a
  shared design-system primitive.
- Avoid flag creep; add variants/presets instead.

## Validation

Minimum validation after each wave:

- `dart analyze`
- relevant widget tests for touched screens/components
- package tests for `taskly_ui`
- broad regression sweep when public package surfaces change
