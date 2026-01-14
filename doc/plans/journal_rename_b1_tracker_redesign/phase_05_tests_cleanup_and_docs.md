# Phase 05 — Tests, cleanup, and docs

Created at: 2026-01-13T12:16:40Z
Last updated at: 2026-01-13T12:25:20Z

## Goal

Finish the cutover with confidence:

- tests updated to the new Journal naming and data model
- remove temporary aliases/deprecations
- documentation aligned

## Scope

- Update/replace tests that referenced legacy wellbeing journal/tracker behavior.
- Remove `wellbeing` tag alias (if kept temporarily).
- Ensure PowerSync rules are aligned with the final tracker tables.
- Final architecture doc updates.

## Delta checklist

- Ensure no lingering imports/reference paths to removed wellbeing/journal-v1 code remain.
- Verify no route aliases/screenKey aliases exist (plan assumes no compatibility).
- Verify legacy `SystemScreenDefinitions` is not referenced anywhere in runtime wiring.
- Verify local schema matches OPT-A tracker tables:
	- PowerSync client schema contains `tracker_definitions`, `tracker_preferences`,
		`tracker_definition_choices`, `tracker_events`, `tracker_state_day`,
		`tracker_state_entry`
	- Drift tables match the above and legacy tables are deleted
- Update test tags/docs:
	- add/standardize `journal` tag
	- remove `wellbeing` tag (or keep only as historical alias if required)

## Documentation touchpoints

- If new screen templates/modules were introduced:
	- [doc/architecture/UNIFIED_SCREEN_MODEL_ARCHITECTURE.md](../../architecture/UNIFIED_SCREEN_MODEL_ARCHITECTURE.md)
- If PowerSync/Drift schemas changed:
	- [doc/architecture/POWERSYNC_SUPABASE_DATA_SYNC_ARCHITECTURE.md](../../architecture/POWERSYNC_SUPABASE_DATA_SYNC_ARCHITECTURE.md)
- If attention/review terminology changed:
	- [doc/architecture/ATTENTION_SYSTEM_ARCHITECTURE.md](../../architecture/ATTENTION_SYSTEM_ARCHITECTURE.md)

## Acceptance criteria

- Test run output captured via `flutter_test_report`.
- No “wellbeing” references remain (except possibly historical migration notes).
- `flutter analyze` clean.

## AI instructions

- Review doc/architecture/ before implementing.
- Run `flutter analyze` for this phase.
- Ensure any errors or warnings introduced (or discovered) are fixed by the end of the phase.
- Run the recorded test runner once at the end.

## Verification

- `flutter analyze`
- Tests: use the VS Code task `flutter_test_report` (once).

