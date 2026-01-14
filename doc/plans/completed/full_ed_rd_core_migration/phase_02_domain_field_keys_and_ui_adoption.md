# full_ed_rd_core_migration — Phase 02: Domain field keys (A3 + L2) + UI adoption

Created at: 2026-01-14 (UTC)
Last updated at: 2026-01-14 (UTC)

## Goal
Introduce sealed typed field keys in the domain layer and update core editors to
use them for all FormBuilder field names and validation routing.

## AI instructions (required)
- Review `doc/architecture/` before implementing this phase.
- Run `flutter analyze` for this phase.
- Fix any `flutter analyze` errors/warnings **caused by this phase’s changes** by
  the end of the phase.

## Design (locked)
- Field keys use A3: sealed typed key objects with stable IDs.
- Location is L2: keys live in `lib/domain/`.
- Include a short comment explaining the pragmatic domain location choice:
  domain-first validation needs to return field-addressable errors without
  duplicating string keys in UI.

## Proposed structure

### 02.1 Common base type
Create something like:
- `lib/domain/forms/field_key.dart`

With:
- `sealed class FieldKey { const FieldKey(this.id); final String id; }`

Decision: Use `FieldKey.id` directly as the FormBuilder `name`.
- Example: `task.name`, `project.deadlineDate`, `value.color`

### 02.2 Per-entity key sets
Create:
- `lib/domain/core/forms/task_field_keys.dart`
- `lib/domain/core/forms/project_field_keys.dart`
- `lib/domain/core/forms/value_field_keys.dart`

Each exports a namespace with `static const` keys.

Example shape:
- `TaskFieldKeys.name = TaskFieldKey._('task.name')`

### 02.3 UI adoption (core editors)
Update:
- Task:
  - `lib/presentation/features/tasks/widgets/task_form.dart`
  - `lib/presentation/features/tasks/view/task_detail_view.dart`
- Project:
  - `lib/presentation/features/projects/widgets/project_form.dart`
  - `lib/presentation/features/projects/view/project_create_edit_view.dart`
- Value:
  - `lib/presentation/features/values/widgets/value_form.dart`
  - `lib/presentation/features/values/view/value_detail_view.dart`

Rules:
- No raw string literals for FormBuilder `name`.
- Patch/initial values use the same `FieldKey.id`.

### 02.4 Extraction helpers
If needed, add shared extraction helpers that accept `FieldKey` (instead of a
String) to avoid repeated `formValues[key.id]` casts.

Keep this small and avoid creating a new “form framework”.

## Acceptance criteria
- All core editor forms register fields using typed keys.
- All patchValue/initialValue maps use typed keys.
- Submit handlers extract values using typed keys.
- No ad-hoc form field strings remain in the core editors.

## Notes / risks
- Changing field names affects FormBuilder’s internal state; ensure any use of
  `patchValue` uses the updated keys consistently.
- Keep key IDs stable and intentionally named; treat them as part of the UI/ED
  contract.
