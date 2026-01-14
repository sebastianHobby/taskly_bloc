# full_ed_rd_core_migration — Completion Summary

Implementation date (UTC): 2026-01-14

## What shipped
- Confirmed NAV-01 entity editor routes are in place (route-backed editor pages).
- Implemented Draft → Command → Handler pipeline for task/project/value editors.
- Added domain-first validation (`ValidationFailure` with field-addressable errors) and mapped it back to FormBuilder field errors.
- Standardized editor field IDs via typed domain `FieldKey` constants (task/project/value) and ensured editors use them.

## Verification
- `flutter analyze`: clean.
- Recorded test run executed: `build_out/test_runs/20260114_013904Z/`.
  - The recorded run reported 1 failing test (`system_screen_specs_phase4_test.dart`).
  - The expectation was updated (check `journal` instead of deprecated `check_in`).
  - Tests were not re-run to keep to the “single recorded run” workflow.

## Known gaps / follow-ups
- ED-B2-A (“template owns actions; form module fields-only”) is not fully implemented yet: the current form widgets still include some close/delete chrome.
- One validation message key in `TaskCommandHandler` still uses a raw string (`Repeat rule is too long`) instead of an `l10n` key.
