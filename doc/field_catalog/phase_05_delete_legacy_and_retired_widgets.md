# Phase 05 — Delete legacy code + retired widgets + final verification

## Goal
Remove all code superseded by the field-catalog/entity-view architecture, including the widgets previously marked RETIRE.

## Deletions
- Delete the widgets in the RETIRE list from the audit:
  - `FocusIndicator`
  - `EntityCard`
  - `EntityTapHandler`
  - `showPageSettingsModal` / related modal content
  - `showSortBottomSheet` / related bottom sheet content
  - `TruncatedValueChips`
  - `ValuesSection`
  - `ValueEmojiIcons`
  - `SectionHeader` (was test-only usage; update tests accordingly)
- Delete/clean any legacy helper code made redundant by the new entrypoints.

## Tests
- This is the *only* phase where tests are run and test fixes are allowed.

## Steps
1. Delete retired widgets and remove references.
2. Remove legacy wrappers if no longer needed.
3. Update tests to reference new entrypoints (or to avoid referencing deleted widgets).
4. Run `flutter analyze` and fix any issues.
5. Run the test suite (or the previously failing integration test target) and fix test failures.

## Exit criteria
- No legacy code remains for replaced widgets.
- Retired widgets are deleted.
- `flutter analyze` passes with 0 issues.
- Tests pass.
