# Editor Forms — Bloc/Cubit Design Plan

> Goal: define a consistent, maintainable architecture for create/edit forms
> across the app (Task/Project/Value/etc), compatible with:
>
> - Flutter + Material 3
> - `flutter_form_builder`
> - unified screen model (screens render; editors mutate)
> - adaptive modals (mobile bottom sheet / desktop dialog)

## 1) Problem Statement

Editors currently follow similar but not fully standardized patterns:

- Each entity has a “detail bloc” that loads + performs CRUD operations.
- Forms are implemented with `FormBuilder` and a `GlobalKey<FormBuilderState>`.
- Each editor view wires patching, submit mapping, snackbars, and closing logic.

This works, but long-term maintenance suffers because:

- Lifecycle glue (patching, close confirmation, “busy” state, result passing)
  is duplicated inconsistently across forms.
- Cross-field / constraint-heavy UI state has no standard home (it is tempting
  to cram it into the CRUD bloc or leave it as ad-hoc widget state).
- Navigation entry points differ (FAB modal vs detail route), and it’s easy to
  duplicate modal configuration and result handling.

## 2) Design Goals

- Consistent responsibilities (SRP) across all editors.
- Minimal duplication of “coordinator” glue.
- Keep CRUD orchestration testable and UI-agnostic.
- Keep complex editor-only UI state localized and reusable.
- Support both:
  - create/edit in adaptive modals
  - view detail in routes with an “Edit” modal
- Smooth migration: refactor one editor at a time.

## 3) Non-Goals

- Replacing `flutter_form_builder`.
- Fully schema-driven/dynamic forms.
- Moving domain validation into the presentation layer.

## 4) Proposed Pattern (Canonical “Editor Architecture”)

### 4.1 Layered responsibilities

**A) EditorBloc (CRUD / orchestration)**

For each entity type, keep a bloc responsible for:

- load entity by id (or initial data for creation)
- load reference lists used by the editor (projects, values, etc)
- perform create/update/delete via repositories
- emit:
  - `loadInProgress`
  - `loadSuccess` / `initialDataLoadSuccess`
  - `operationSuccess` / `operationFailure`

Rules:

- The bloc must not depend on `FormBuilder` or widget lifecycle.
- The bloc must not keep UI-only state (selection toggles, dirty flags, etc).

**B) EditorCoordinator (Stateful widget that owns form lifecycle + glue)**

A stateful widget that:

- owns `GlobalKey<FormBuilderState>`
- patches form values on load success
- maps `formState.value` → `UpsertRequest`
- dispatches create/update/delete events to the EditorBloc
- handles snackbars and close behavior
- optionally handles unsaved-changes confirmation

This is where most current duplication lives today; the plan is to standardize
it.

**C) FormWidget (pure UI)**

The `...Form` widget should:

- render fields only
- accept `formKey`, `initialData`, `onSubmit`, `onClose`, `onDelete`
- not perform repository reads
- not own navigation concerns

Use a shared shell where possible to keep layout consistent.

**D) EditorSubCubit (only for complex editor-only state)**

When editor UI has constraint-heavy state that is not “just a field”, add a
small Cubit that is UI-focused and reusable.

Examples:

- “values override vs inherit”
- “exactly one primary value”
- chip-based selection interactions
- multi-step editor subflows

Rules:

- SubCubit must be deterministic and synchronous where possible.
- SubCubit may depend on static reference lists already loaded by EditorBloc
  (available values, available projects).
- SubCubit should expose derived validation like `canSubmit`.

### 4.2 Standard folder structure

Proposed conventions:

- `lib/presentation/features/<entity>/bloc/<entity>_editor_bloc.dart`
  (existing detail blocs can be renamed later)
- `lib/presentation/features/<entity>/view/<entity>_editor_sheet.dart`
  (coordinator)
- `lib/presentation/features/<entity>/widgets/<entity>_form.dart`
  (pure UI)
- `lib/presentation/features/<entity>/cubit/<entity>_<concern>_cubit.dart`
  (optional)
- `lib/presentation/features/editors/editor_launcher.dart`
  (shared)

### 4.3 Field Catalog (Reusable Form Elements)

We discussed a “field catalog” concept to keep editor UI consistent and
maintainable.

Definition: a curated set of reusable, themed form widgets that wrap
`flutter_form_builder` fields and encode common UX decisions.

This repo already has the beginnings of this in:

- `lib/presentation/widgets/form_fields/` (modern FormBuilder fields)

Field catalog rules:

- Fields are presentation-only: no repository reads and no navigation.
- Fields must respect theming (no hardcoded colors).
- Fields expose a small API surface:
  - `name` (FormBuilder field key)
  - `initialValue`
  - `validator` (optional)
  - UX callbacks (optional)
- Prefer composition:
  - “date row” = one field widget used in multiple editors
  - “value picker” = one widget, with behavior controlled by a subcubit

Practical outcome:

- Task and Project editors reuse the same date + repeat + priority controls.
- Values UI (primary/secondary) becomes a catalog widget that is used anywhere
  we edit value associations.

#### 4.3.1 Current inventory (already in repo)

Existing catalog exports (centralized barrel):

- `lib/presentation/widgets/form_fields/form_fields.dart`

Notable reusable field widgets present today:

- Text: `FormBuilderTextFieldModern`
- Date: `FormBuilderDatePickerModern`
- Project picker: `FormBuilderProjectPickerModern`
- Completion toggle: `FormBuilderCompletionToggleModern`
- Priority: `FormBuilderPriorityPicker`
- Values (legacy): `FormBuilderValuePicker`
- Misc: color, emoji, icon pickers; enum/radio/slider/number fields
- Sections: `FormSectionHeader`

#### 4.3.2 Gaps to add (to support the planned UX)

High-value additions (recommended next):

1) Primary/Secondary values selector (Task + Project)
  - Renders “Primary value” and “Secondary values” controls
  - Works with strict override (A) and enforces exactly one effective primary
  - Backed by an editor subcubit (not a single list field)

2) Date row field set (Task + Project)
  - A single reusable widget that composes:
    - start date picker
    - deadline picker
    - repeat rule selector
  - Avoids duplicating layout, icons, clear actions

3) Footer CTA sizing helper
  - A reusable footer action builder that implements:
    - mobile full-width
    - desktop constrained/centered
  - Used by all modal editors for consistency

4) Metadata row/tile widgets
  - Reusable “editable list row” widgets for the mock-aligned layout
  - Keeps consistent spacing, touch targets, and theming

### 4.4 Integration With Unified Screen Model

We also discussed how editors should integrate with unified screens.

Key principles:

- Unified screens render data and trigger actions.
- Editors are separate UI flows that mutate data.
- Editor state must not live in `ScreenBloc`.

Recommended integration approach:

- Unified screens launch editors via a centralized `EditorLauncher`.
- FAB actions (e.g., create task) map to an editor args object:
  - `entityId` (null for create)
  - optional prefill context (e.g., `initialProjectId`)
  - optional origin context (e.g., `originScreenKey`)

Modal vs route guidance:

- View detail stays a route (deep-linkable).
- Create/edit stays an adaptive modal (compact sheet, larger dialog), launched
  consistently by the launcher.

## 5) Navigation & Data Passing

### 5.1 Rules

- Don’t pass full domain objects between screens/editors.
- Pass IDs + optional editor args (prefill + origin context).
- Let editors load what they need via repositories/blocs.

### 5.2 Editor args object

For each editor, define an args model (simple immutable class/record) that can
be passed from:

- FAB entry points on unified screens
- entity detail routes

Example fields:

- `String? entityId` (null = create)
- `String? initialParentId` (optional prefill)
- `String? originScreenKey` (optional analytics)

### 5.3 Modal vs Route

- Entity detail stays a route (deep-linkable).
- Create/edit uses an adaptive modal:
  - compact: bottom sheet
  - medium/expanded: dialog

Add a shared `EditorLauncher` (presentation service) to keep modal behavior
consistent and centralized.

## 6) Standard UX/Behavior Contracts (All Editors)

- Close behavior:
  - if dirty, confirm discard
  - else close
- Submit behavior:
  - validate form
  - disable while saving
  - on success: show snackbar + close
- Delete behavior (edit only):
  - confirm destructive action
  - on success: snackbar + close

## 7) Implementation Plan (Incremental Refactor)

### Phase 1 — Document + Utilities

- Introduce a shared `EditorLauncher`.
- Standardize a reusable coordinator base (optional but recommended):
  `EntityEditorCoordinator<TBloc, TState, TEntity>`.

### Phase 2 — Pick a reference editor and migrate

- Migrate one editor end-to-end (recommend Value editor because it’s smaller).

### Phase 3 — Roll out to Task/Project editors

- Migrate Task editor coordinator to the standardized base.
- Add a Task values subcubit for “inherit/override + primary/secondary”.
- Migrate Project editor similarly.

## 8) Acceptance Criteria

- All editors have the same structure:
  bloc (CRUD) + coordinator (form glue) + form widget (UI).
- Complex selection rules live in small, testable cubits.
- Modal opening behavior is centralized.
- No editor duplicates discard-confirmation logic.

## 9) Notes for the “Values Override (A)” requirement

For strict override (A) with “exactly one primary value”:

- Effective primary is always non-null.
- Task must either:
  - inherit primary from its project (no task override rows), or
  - store explicit task primary override.
- Inbox task (no project): must be in override mode.
