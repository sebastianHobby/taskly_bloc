# Semantic Theming Contract

## Purpose

Defines how Taskly keeps the current UI visually stable while making app
chrome, panels, and shared component appearance easy to restyle later.

## Core rules

- `ThemeData.colorScheme` and `TasklyTokens` remain the foundation.
- App-level visual roles must be expressed through semantic theme extensions,
  not repeated screen-local color and decoration literals.
- Shared chrome/widgets must read semantic theme extensions first and use raw
  `ColorScheme`/token values only inside the extension defaults.
- Screen code should select shared themed components/presets rather than
  rebuilding equivalent header/panel styling inline.

## Current semantic layers

- `TasklyAppChromeTheme`
  - navigation surfaces
  - navigation indicator
  - chrome icon button colors
  - brand foreground
- `TasklyPageHeaderTheme`
  - page header padding
  - header icon/title treatment
  - header surface variants
  - header chip colors
- `TasklyPanelTheme`
  - panel surfaces
  - panel borders
  - page gradient colors
  - ambient page accent glows
  - soft shadow color
- `TasklyCardTheme`
  - summary/insight/subtle card surfaces
  - shared card borders and shadows
- `TasklyChipTheme`
  - filter/metric/status/selection chip variants
- `TasklyEmptyStateTheme`
  - empty and error state icon/title/body roles
- `TasklySheetTheme`
  - sheet/modal surface variants
- `TasklyInsightTheme`
  - shared insight highlights and badges
- `TasklyEntityRowChromeTheme`
  - feed/header/divider/empty-row hierarchy

## Ownership

- Foundation tokens live in `packages/taskly_ui`.
- Semantic theme extensions live in `packages/taskly_ui`.
- Shared chrome/primitives live in `packages/taskly_ui`.
- App presentation consumes package-owned themed components.
- `packages/taskly_ui` remains render-only and Taskly-only.

## Migration rule

When touching existing UI:

- Prefer reusing an existing semantic theme role.
- If the styling is app-wide or repeated across screens, add or extend a
  semantic theme extension.
- If the styling is truly one-off and local to a feature, keep it local.

## Current shared chrome components

- `TasklyPageHeader`
- `TasklyHeaderChip`
- `TasklyChromeIconButton`
- `TasklyPageGradientSurface`
- `TasklyCardSurface`
- `TasklyChip`
- `TasklySheetChrome`

These components are the preferred entry points for top-level page chrome and
repeated page surface treatments.

## Header usage guidance

- Top-level landing pages should prefer `TasklyHeaderVariant.hero` or
  `TasklyHeaderVariant.screen`.
- Deeper drill-in/detail/settings pages should prefer
  `TasklyHeaderVariant.compact` to preserve density while keeping branded
  hierarchy.
