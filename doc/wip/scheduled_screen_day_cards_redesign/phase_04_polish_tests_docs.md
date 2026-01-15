# Phase 04 — Polish, Tests, Docs

Created at: 2026-01-15T05:07:20Z
Last updated at: 2026-01-15T05:18:37Z

## Objective
Stabilize the redesign with regression coverage, accessibility polish, and documentation updates if architecture surface changed.

## Tests to update/add (expected)
- Update Scheduled build regression test(s):
  - `test/presentation/features/screens/view/scheduled_screen_build_regression_test.dart`
- Validate no infinite loading integration test remains valid:
  - `test/integration/scheduled_screen_no_infinite_loading_db_integration_test.dart`
- Add targeted widget tests for:
  - grouping headers
  - range preset switching
  - in-progress collapse expand/collapse

## Test expectations (exact)
- Build regression test must assert Scheduled renders without exceptions and contains:
  - A “Range” affordance (button/menu label)
  - A day-card header including an absolute date string
- Widget test for presets must verify the range math boundaries exactly:
  - “Next 7 days” includes today and ends at today+8 days (end-exclusive)
  - “This month” ends at first day of next month
- Widget test for in-progress collapse must verify:
  - Collapsed state shows summary row
  - Expanded state reveals items tagged `AgendaDateTag.inProgress`

## A11Y and UX polish
- Ensure semantic labels for Today/Tomorrow follow the agreed policy:
  - Only use Today/Tomorrow when literally today/tomorrow.
  - Always include an absolute date string.
- Ensure touch targets and truncation behaviors are good on small screens.

## Documentation updates
- If Phase 01 introduced a new USM layout concept, update relevant architecture docs:
  - `doc/architecture/UNIFIED_SCREEN_MODEL_ARCHITECTURE.md` (only if needed; keep minimal)

Doc update must include (if the layout catalog is documented):
- Add `agendaDayCardsFeed` to the list of supported layout options.
- Remove/mark deprecated `timelineMonthSections` if Phase 05 deletes it.

## Legacy removal checklist
- Confirm there are no remaining references to `timelineMonthSections`.
- Delete timeline-specific UI/rendering code that was replaced by `agendaDayCardsFeed`.
- Remove any dead parameters, helpers, or tests that only exist for the timeline model.

## Acceptance criteria
- All targeted tests updated/passing locally.
- `flutter analyze` is clean (this is the last phase, so fix any remaining issues even if unrelated).
- Scheduled screen behavior matches approved UX.

## AI instructions (strict)
- Run `flutter analyze` in this final phase.
- Fix any remaining `flutter analyze` errors/warnings (even if unrelated) by end of phase.
- If architecture changes, update `doc/architecture/` accordingly.

## Test execution policy
- Do not run tests unless explicitly requested by the user.
- It is OK to update/add tests in this phase; the user can run:
  - `flutter test --preset=quick`
  - or the existing Scheduled regression test directly.
