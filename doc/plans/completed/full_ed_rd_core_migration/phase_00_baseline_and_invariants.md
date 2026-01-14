# full_ed_rd_core_migration — Phase 00: Baseline + invariants

Created at: 2026-01-14 (UTC)
Last updated at: 2026-01-14 (UTC)

## Goal
Establish a clean starting point and lock in the invariants/decisions that the
rest of the migration must preserve.

This plan is for **core entities only**:
- Task (editor-only)
- Project (detail + edit)
- Value (detail + edit)

## Locked decisions (do not change without explicit user approval)

### Routing / deep links
- Task canonical edit URL: `/task/:id/edit`.
- `/task/:id` **redirects** to `/task/:id/edit`.
- NAV-01 create/edit routes exist:
  - `/task/new`, `/task/:id/edit`
  - `/project/new`, `/project/:id/edit`
  - `/value/new`, `/value/:id/edit`
- Edit routes are **route-backed editor pages**: they open the modal editor and
  then return to the previous page.
- Editor dismiss behavior:
  - If router can pop: pop.
  - Else: `go('/my-day')` (always).

### Surface policy
- Task: `editorOnly` (no RD page).
- Project/value: `detailAndEdit` and **keep the existing RD pages** (no new
  generic detail template system as part of this migration).

### Editor architecture
- Draft: explicit `*Draft` objects; draft is the source of truth (B1a).
- Commands: domain-owned `Create*/Update*Command`.
- Validation: **domain-first**, validated in handler (C1a).
- Validation errors are rich (C2b): `{ code, messageKey, args }` (shape TBD).
- Field keys: A3 sealed typed key objects stored in domain (L2), with a short
  comment explaining this pragmatic location choice.

## Constraints
- Keep changes scoped to core entities.
- Preserve existing user-facing UX as much as possible while aligning contracts.
- Do not introduce new architectural patterns without explicit user confirmation.

## AI instructions (required)
- Review `doc/architecture/` before implementing this phase.
- Run `flutter analyze` for this phase.
- Fix any `flutter analyze` errors/warnings **caused by this phase’s changes** by
  the end of the phase.

## Checklist

### 00.1 Repo health
- [ ] Run `flutter analyze` and record that it starts clean.
- [ ] Note any existing analyzer issues (if present) but do not fix unrelated
      items unless in the final phase.

### 00.2 Migration acceptance criteria (global)
The migration is considered complete only if:
- All NAV-01 routes work (new/edit) for task/project/value.
- `/task/:id` redirects to `/task/:id/edit`.
- Route-backed editor pages always return (pop or my-day fallback).
- No core editor uses ad-hoc string field names.
- Core create/update flows are Draft → Command → handler.
- Domain-first validation produces field-addressable errors mapped to
  FormBuilder fields.
- `flutter analyze` is clean and one recorded test run has been executed.

### 00.3 Known touch points (for later phases)
- Router: `lib/presentation/routing/router.dart`
- Routing helpers: `lib/presentation/routing/routing.dart`
- Task editor route page: `lib/presentation/features/tasks/view/task_editor_route_page.dart`
- Editor launcher: `lib/presentation/features/editors/editor_launcher.dart`
- Project RD page: `lib/presentation/features/projects/view/project_detail_unified_page.dart`
- Value RD page: `lib/presentation/features/values/view/value_detail_unified_page.dart`
- Current editors/forms:
  - Task: `lib/presentation/features/tasks/view/task_detail_view.dart`,
    `lib/presentation/features/tasks/widgets/task_form.dart`
  - Project: `lib/presentation/features/projects/view/project_create_edit_view.dart`,
    `lib/presentation/features/projects/widgets/project_form.dart`
  - Value: `lib/presentation/features/values/view/value_detail_view.dart`,
    `lib/presentation/features/values/widgets/value_form.dart`

## Notes
- This phase should not introduce product behavior changes; it only locks plan
  invariants and ensures a clean baseline.
