# full_ed_rd_core_migration — Phase 04: Domain-first validation + FormBuilder field mapping

Created at: 2026-01-14 (UTC)
Last updated at: 2026-01-14 (UTC)

## Goal
Implement domain-first validation for core commands and map structured
field-addressable validation failures back onto FormBuilder fields.

## AI instructions (required)
- Review `doc/architecture/` before implementing this phase.
- Run `flutter analyze` for this phase.
- Fix any `flutter analyze` errors/warnings **caused by this phase’s changes** by
  the end of the phase.

## Design (locked)
- Validation happens in the handler (C1a).
- Validation errors are rich (C2b): include stable code + messageKey + args.
- Errors are field-addressable using domain field keys (A3 + L2).

## Implementation steps

### 04.1 Define validation error model
Add types such as:
- `ValidationError` (code, messageKey, args)
- `ValidationFailure` (Map<FieldKey, List<ValidationError>> fieldErrors,
  List<ValidationError> formErrors)

Keep the shape minimal but future-proof for i18n.

### 04.2 Apply validation in command handlers
For each command handler:
- Validate command and return either:
  - success (persist) or
  - failure (do not persist)

### 04.3 Presentation mapping
Update editor UI submission pipeline to:
- Clear previous field errors
- Apply new field errors:
  - locate FormBuilder field by `FieldKey.id`
  - call invalidate / set error text
- Surface form-level errors in a consistent place (banner/inline text)

Rules:
- Snackbars remain for unexpected infra errors.
- Expected validation errors must be mapped to fields.

### 04.4 UX consistency
- Ensure create/edit behave the same.
- Ensure errors do not disappear immediately if the user doesn’t change fields.

## Acceptance criteria
- Triggering a domain validation failure results in:
  - field-level errors on the correct fields
  - optional form-level error displayed
  - no persistence side effects
- Works for task, project, value.

## Notes / risks
- Ensure mapping does not depend on widget build timing; use safe access to
  FormBuilder state.
- Avoid duplicating business rules in UI validators; UI validators should be
  “fast feedback only”.
