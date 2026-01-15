# Phase 05 — Delete Timeline Model (Repository-wide)

Created at: 2026-01-15T05:10:06Z
Last updated at: 2026-01-15T05:18:37Z

## Objective
Remove the legacy timeline model (`timelineMonthSections` and any related rendering/data-shaping code) after migrating all references to the new layout.

This phase exists to ensure we don’t accidentally delete something still in use by another screen/template.

## Steps
1) Inventory (already partially confirmed)
- Confirmed references (as of 2026-01-15):
  - `lib/domain/screens/catalog/system_screens/system_screen_specs.dart` (Scheduled spec)
  - `lib/domain/screens/templates/params/list_section_params_v2.dart` (layout union definition)
  - `lib/presentation/screens/templates/renderers/task_list_renderer_v2.dart` (layout switch)
  - `lib/presentation/screens/templates/renderers/interleaved_list_renderer_v2.dart` (layout switch)
- After Phase 01, Scheduled spec must no longer reference `timelineMonthSections`.

2) Migration
- No other screen should use `timelineMonthSections`.
- Therefore migration is only:
  - Scheduled spec -> `agendaDayCardsFeed` (Phase 01)

3) Deletion (deterministic order)

3.1) Delete the layout variant
- File: `lib/domain/screens/templates/params/list_section_params_v2.dart`
  - Remove `SectionLayoutSpecV2.timelineMonthSections` union case.
  - Re-run codegen: `dart run build_runner build --delete-conflicting-outputs`.

3.2) Remove renderer branches that pattern-match timelineMonthSections
- File: `lib/presentation/screens/templates/renderers/task_list_renderer_v2.dart`
  - Remove the `timelineMonthSections` branch.
- File: `lib/presentation/screens/templates/renderers/interleaved_list_renderer_v2.dart`
  - Remove the `timelineMonthSections` branch.

3.3) Remove legacy timeline UI from agenda renderer
- File: `lib/presentation/screens/templates/renderers/agenda_section_renderer.dart`
  - Delete the timeline-month implementation:
    - horizontal date picker
    - scroll-sync logic
    - month navigation driven by timeline
  - The file must only implement the `agendaDayCardsFeed` UI once this phase completes.

3.4) Remove dead tests/fixtures
- Update or delete any tests that assume timeline rendering. Primary candidates:
  - `test/presentation/features/screens/view/scheduled_screen_build_regression_test.dart`
  - Any golden/widget tests that assert timeline UI.

4) Verification
- Run `flutter analyze` and fix any issues.
- Update docs if the USM layout catalog changed.

## Acceptance criteria
- No references to `timelineMonthSections` remain in the repository.
- Scheduled renders correctly with `agendaDayCardsFeed`.
- Analyzer is clean.

## AI instructions (strict)
- Review `doc/architecture/` before implementing.
- Run `flutter analyze` for this phase.
- Fix analyzer issues caused by this phase.
