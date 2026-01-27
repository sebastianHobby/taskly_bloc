# Taskly UI Material Alignment (Option B) -- Audit + Spec

> Audience: engineers + design
>
> Purpose: concrete migration plan for a Material-aligned UI layer in
> `packages/taskly_ui` with long-term maintainability and consistency.
>
> This is a descriptive spec. Normative rules remain in
> `doc/architecture/INVARIANTS.md`.

## 1) Goals

- Consolidate visual tokens (spacing, radius, type, elevation, motion) into a
  single source of truth inside `taskly_ui`.
- Normalize component behavior to Material 3 expectations (states, tap targets,
  focus/hover/pressed).
- Preserve current UI identity while removing ad-hoc styling drift.
- Keep public API stable for app consumers; minimize app-level churn.

## 2) Non-goals

- No product redesign or new UX flows.
- No change to BLoC boundaries or routing.
- No changes to domain or data layers.

## 3) Current state audit (Option B implementation)

### 3.1 Existing theme/token surfaces

- `packages/taskly_ui/lib/src/foundations/tokens/taskly_tokens.dart`
  - `TasklyTokens` is the single source of truth for spacing, radii, elevation,
    motion, tap-target sizing, and Taskly semantic colors.
- Legacy theme extensions removed:
  - `TasklyEntityTileTheme` and `TasklyFeedTheme` deleted.
  - `AppSpacing`, `AppRadius`, `TasklyChromeTheme`, and `TasklyTypography`
    deleted from app theme.

### 3.2 Hard-coded values inside `taskly_ui` (representative, not exhaustive)

#### Feed + renderer
- `packages/taskly_ui/lib/src/feed/taskly_feed_renderer.dart`
  - Fixed padding/margins/radii (e.g., 4, 6, 8, 10, 12, 14, 16, 20, 24).
  - Inline `TextStyle` letterSpacing tweaks.
  - `MaterialTapTargetSize.shrinkWrap` used for action buttons.
- `packages/taskly_ui/lib/src/feed/taskly_feed_theme.dart`
  - Typography overrides (`fontSize`, `letterSpacing`) with hard-coded values.

#### Tiles (entities)
- `packages/taskly_ui/lib/src/tiles/task_entity_tile.dart`
  - Mixed use of `TasklyEntityTileTheme` + hard-coded radii, padding, letterSpacing.
  - Multiple `MaterialTapTargetSize.shrinkWrap` usages.
  - Direct `fontSize` overrides.
- `packages/taskly_ui/lib/src/tiles/project_entity_tile.dart`
  - Hard-coded padding, font sizes, tap target shrinkWrap.
- `packages/taskly_ui/lib/src/tiles/routine_entity_tile.dart`
  - Hard-coded padding, tap target shrinkWrap.
- `packages/taskly_ui/lib/src/tiles/value_entity_tile.dart`
  - Hard-coded padding, tap target shrinkWrap.

#### Primitives
- `packages/taskly_ui/lib/src/primitives/*`
  - Many `BorderRadius.circular(...)` literals (4, 8, 12, 14, 16, 18, 99, 999).
  - Multiple fixed padding values.
  - Form field widgets with explicit radii and padding.

#### Sections + templates
- `packages/taskly_ui/lib/src/sections/*`
  - Hard-coded padding/radius/spacing and chip sizes.
  - Additional shrinkWrap tap targets in sections.
- `packages/taskly_ui/lib/src/templates/form_shell.dart`
  - Hard-coded padding, handle sizes, and radii.

### 3.3 Tap target policy

- All `MaterialTapTargetSize.shrinkWrap` usages in `taskly_ui` removed.
- Minimum interactive target size aligned to >= 40dp via tokens.
- `packages/taskly_ui/lib/src/tiles/project_entity_tile.dart`
- `packages/taskly_ui/lib/src/tiles/routine_entity_tile.dart`
- `packages/taskly_ui/lib/src/tiles/value_entity_tile.dart`
- `packages/taskly_ui/lib/src/feed/taskly_feed_renderer.dart`
- `packages/taskly_ui/lib/src/sections/value_distribution_section.dart`

### 3.4 Folder taxonomy drift

- The package contains both `entities/` and `tiles/`.
  - `tiles/` functions as entity UI but is outside the 4-tier taxonomy.
  - This complicates enforcement of the primitives/entities/sections model.

## 4) Option B target architecture

### 4.1 New foundation layer (tokens)

Add a token layer under `taskly_ui`:

```
packages/taskly_ui/lib/src/foundations/tokens/
  taskly_tokens.dart
  taskly_motion_tokens.dart
  taskly_color_tokens.dart (optional if needed)
```

`TasklyTokens` becomes the single source of truth for:
- spacing scale
- radii scale
- elevation/shadow tokens
- typography roles (wrapping ThemeData.textTheme)
- tap target sizing defaults

### 4.2 Material-aligned component layer

Introduce a `material/` layer for standardized behaviors:

```
packages/taskly_ui/lib/src/material/
  components/
  behaviors/
```

Responsibilities:
- Provide consistent interaction states and sizing.
- Ensure consistent Material 3 defaults across components (buttons, chips,
  inputs, cards, dialogs, sheets, menus).

### 4.3 Entity/tile consolidation

Move `src/tiles/*` into `src/entities/*`:
- Keep public API stable (`TasklyTaskRowSpec`, presets, actions).
- Internals should use tokens + material components for consistency.

## 5) Public API proposal (stable with additions)

Keep all existing entrypoints and add tokens:

- `package:taskly_ui/taskly_ui_feed.dart`
  - unchanged API surface
- `package:taskly_ui/taskly_ui_sections.dart`
  - unchanged API surface
- `package:taskly_ui/taskly_ui_forms.dart`
  - unchanged API surface
- `package:taskly_ui/taskly_ui_models.dart`
  - unchanged API surface
- New: `package:taskly_ui/taskly_ui_tokens.dart`
  - exports `TasklyTokens` ThemeExtension

## 6) Migration plan (phased)

### Phase 0: Token baseline
- Create `TasklyTokens` ThemeExtension in `taskly_ui`.
- Map existing `TasklyEntityTileTheme` and `TasklyFeedTheme` values into tokens.
- Add motion tokens (default durations/curves).
- Update app theme (`lib/presentation/theme/app_theme.dart`) to register
  `TasklyTokens` (no visual change).
Status: completed.

### Phase 1: Feed + entity tiles
- Update `taskly_feed_renderer.dart` to use tokens for spacing, typography,
  radii, and chip styling.
- Update task/project/value/routine entity tiles to:
  - remove hard-coded padding/radius/fontSize/letterSpacing
  - use tokenized text styles
  - remove `MaterialTapTargetSize.shrinkWrap`
Status: completed.

### Phase 2: Primitives + forms
- Migrate primitives and form fields to use tokens instead of literals.
- Introduce `material/components` wrappers where appropriate.
- Normalize form input paddings and radii to tokenized values.
Status: in progress (partial).

### Phase 3: Sections + templates
- Replace hard-coded spacing and radii in sections/templates.
- Align dialog/sheet layout with Material defaults via tokens + wrappers.
Status: in progress (partial).

### Phase 4: Cleanup + legacy removal
- Move `src/tiles/*` to `src/entities/*` and update imports internally.
- Remove unused legacy files (see Section 8).
Status: partially completed (legacy themes removed; folder move pending).

## 7) Token taxonomy (initial shape)

### Spacing (sample)
- `spacing.xs = 4`
- `spacing.sm = 8`
- `spacing.md = 12`
- `spacing.lg = 16`
- `spacing.xl = 24`
- `spacing.xxl = 32`
Note: the implemented token set also includes intermediate values
(`2, 3, 6, 10, 14, 18, 20`) to preserve current UI density.

### Radius (sample)
- `radius.xs = 4`
- `radius.sm = 8`
- `radius.md = 12`
- `radius.lg = 16`
- `radius.xxl = 28`
- `radius.pill = 999`

### Typography
- Wrap `ThemeData.textTheme` with Taskly-specific tweaks in one place.
- Remove per-widget `fontSize` and `letterSpacing` overrides in favor of tokens.

### Motion (planned)
- Motion tokens are intentionally deferred until there is a concrete usage
  surface in shared UI.

### Interaction
- Tap target min size (>= 40dp per invariant) exposed as token.
- Standard padding for icon buttons and chips.

## 8) Legacy removals (completed)

- `packages/taskly_ui/lib/main.dart` removed (placeholder).
- `TasklyEntityTileTheme` and `TasklyFeedTheme` removed.
- `AppSpacing`, `AppRadius`, `TasklyChromeTheme`, and `TasklyTypography`
  removed from app theme.
- `TasklyDesignExtension` removed; semantic colors live in `TasklyTokens`.

## 9) Risks / trade-offs

- Visual drift during migration if tokens are not mapped carefully.
- Tap target changes could impact layout density.
- Refactors may touch many files; avoid mixing with feature work.

## 10) Decisions (locked)

1) `TasklyTokens` is the SSOT for spacing/radii/elevation/motion/tap targets.
2) Legacy theme extensions removed; no adapters remain.
3) Tap targets are >= 40dp; shrinkWrap is not allowed in shared UI.
4) Typography flows through `ThemeData.textTheme` (no `TasklyTypography`).
5) `taskly_ui/lib/main.dart` removed as unused placeholder.
