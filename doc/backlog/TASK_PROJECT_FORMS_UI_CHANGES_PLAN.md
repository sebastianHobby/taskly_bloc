# Task + Project Forms — UI Changes Plan (Backlog)

> Goal: capture proposed UI changes for Task and Project create/edit forms,
> aligned with Material 3 best practices and user theme preferences.
>
> Constraints:
> - No hardcoded colors; use `ThemeData` / `ColorScheme`.
> - Keep `flutter_form_builder`.
> - Forms must work in adaptive modals (bottom sheet on mobile, dialog on larger).

## 1) Global UI Principles

- Use Material 3 components and token-based theming.
- Prefer consistent spacing + typography scales.
- Accessibility:
  - ensure contrast; avoid using color alone as meaning
  - dynamic type / text scaling should not overflow critical controls
- Responsive:
  - mobile: primary CTA full width
  - tablet/desktop: CTA constrained and centered (or right-aligned within a
    constrained content area)

## 2) Cross-Cutting Form UX Improvements

### 2.1 Consistent modal form chrome

- Use a shared form shell pattern across Task/Project forms:
  - consistent header/handle, close, delete, submit placement
  - sticky footer with safe-area + keyboard insets

- Align implementation with the standardized editor architecture:
  - EditorBloc for CRUD + reference data
  - EditorCoordinator for FormBuilder lifecycle glue
  - Field Catalog widgets for consistent inputs

### 2.2 Consistent validation UX

- Inline error messages under fields.
- Disable submit until form valid where practical.
- Ensure async operation states are visible (loading indicator / disabled CTA).

### 2.3 Dirty-state handling

- Prompt on close if there are unsaved changes.
- Ensure “save success” resets dirty flag.

## 3) Task Form UI Changes

### 3.1 Align “Create Task” content structure to the mock (non-layout)

- Header: remove any “EDIT” labeling; use title/subtitle semantics instead.
- Make metadata section more scannable:
  - prefer list-row/tile style over small chips when there are multiple fields
  - show clear labels and secondary text (e.g., “Deadline”, “Project”)

### 3.2 Values UX (Primary + Secondary)

- Replace the single `valueIds` concept in the UI with:
  - exactly one **Primary Value**
  - 0..M **Secondary Values**

- Inheritance behavior (strict override A):
  - if task has explicit values, it does not inherit project values
  - if task does not override values, it inherits the project’s primary value

- Editor requirements:
  - enforce exactly one primary (effective)
  - allow secondaries, excluding the primary
  - clear UX for switching between:
    - “Inherited from project”
    - “Override values”
  - provide “Reset to project values” action when overriding

- Architecture alignment:
  - implement this control as a Field Catalog widget (not ad-hoc UI)
  - drive constraint rules via a small editor subcubit (not the CRUD bloc)

### 3.3 Priority control

- Replace generic picker with a segmented/pill control (Material-aligned):
  - clear selected state
  - label + icon (optional)
  - no reliance on hardcoded colors

### 3.4 Dates and repeating

- Ensure date controls are consistent between task/project forms:
  - start date
  - deadline
  - repeat rule

- If these controls exist as reusable widgets, prefer using them rather than
  duplicating UI.

- Architecture alignment:
  - prefer a single reusable “date row” Field Catalog widget shared between
    Task and Project editors

### 3.5 CTA sizing

- Mobile: full-width submit button in sticky footer.
- Desktop: constrained max width and centered (or aligned within a constrained
  content container).

- Architecture alignment:
  - implement via a reusable footer/CTA helper so all editors behave
    consistently

## 4) Project Form UI Changes

### 4.1 Consistency with Task editor

- Match:
  - typography scale
  - spacing
  - sticky footer behavior
  - delete confirmation UX

### 4.2 Values and primary handling

- Projects already have values; align the UX with the “primary + secondary”
  model:
  - exactly one primary value at the project level
  - 0..M secondary values

- Ensure project “primary” is visually distinct and discoverable.

### 4.3 Project dates and completion

- Ensure completed toggle is consistent in placement and styling.
- Ensure date fields behave the same as Task (picker UX, clear button, etc).

## 5) Theming and Styling Cleanup

- Remove any hardcoded colors from chips, value badges, etc.
- Use:
  - `colorScheme.primary/secondary/tertiary`
  - `surface`, `surfaceContainer*`, `onSurfaceVariant`, `outlineVariant`
- Prefer `ThemeExtension` only if a stable design token is missing.

## 6) Localization (l10n)

Add/confirm strings for:

- Primary value label
- Secondary values label
- Inherited from project
- Override values
- Reset to project values
- Validation errors (e.g., “Select a primary value”)

## 7) Suggested Implementation Order

1) Refactor editor architecture (see editor plan) enough to support the values
  subcubit + Field Catalog additions cleanly.
2) Implement values UI + data model changes (primary/secondary + inheritance A).
3) Fix CTA sizing behavior.
4) Refine metadata presentation (list tiles / rows).
5) Polish theming + remove hardcoded colors.
6) Add l10n strings.

## 8) Validation Checklist

- Task editor: cannot submit without an effective primary value.
- Inbox task (no project): forces override mode.
- Task with override values: does not inherit project values.
- Task with no override: inherits project primary.
- CTA: full-width on mobile; constrained on desktop.
- No hardcoded colors introduced.
