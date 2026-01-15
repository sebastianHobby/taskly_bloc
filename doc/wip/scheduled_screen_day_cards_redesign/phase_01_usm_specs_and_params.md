# Phase 01 — USM Specs & Params (Day Cards Layout)

Created at: 2026-01-15T05:07:20Z
Last updated at: 2026-01-15T05:18:37Z

## Objective
Introduce a new USM layout variant that accurately represents the redesign and wire Scheduled’s system screen spec to use it.

## Key outcomes
- A new `SectionLayoutSpecV2` variant representing the day-cards feed.
- Scheduled system screen spec uses this layout instead of the timeline layout.
- No UI behavior changes yet beyond what is required to keep the app compiling.

## Proposed API / naming
- Add `SectionLayoutSpecV2.agendaDayCardsFeed`.

Naming criteria:
- Must describe the rendered structure, not how it used to work.
- Must be generic enough for reuse outside Scheduled.

## Target files (expected)
- `lib/domain/screens/templates/params/list_section_params_v2.dart`
  - Add the new layout variant.
  - Ensure any JSON serialization stays stable.
- `lib/domain/screens/catalog/system_screens/system_screen_specs.dart`
  - Switch Scheduled screen to `agendaDayCardsFeed`.
- `lib/presentation/widgets/section_widget.dart`
  - Pass `AgendaSectionParamsV2` into the agenda renderer so it can branch on `params.layout`.
- Any USM/template glue that pattern-matches on layout.

## Concrete edits (implementation checklist)

1) Add the new layout variant
- File: `lib/domain/screens/templates/params/list_section_params_v2.dart`
- Add a new `freezed` union case:
  - `const factory SectionLayoutSpecV2.agendaDayCardsFeed() = _AgendaDayCardsFeedV2;`
- Add a JSON value that matches the name:
  - `@JsonValue('agenda_day_cards_feed')`

2) Switch Scheduled spec
- File: `lib/domain/screens/catalog/system_screens/system_screen_specs.dart`
- Replace Scheduled’s layout:
  - FROM: `SectionLayoutSpecV2.timelineMonthSections(...)`
  - TO: `const SectionLayoutSpecV2.agendaDayCardsFeed()`

3) Plumb params into renderer
- File: `lib/presentation/widgets/section_widget.dart`
- Update the agenda section branch to call:
  - `AgendaSectionRenderer(data: d, params: section.params as AgendaSectionParamsV2, ...)`
- Update the `AgendaSectionRenderer` constructor to require `AgendaSectionParamsV2 params`.

4) Code generation
- Run: `dart run build_runner build --delete-conflicting-outputs`
- Rationale: new `freezed` union + JSON needs regenerated code.

## Legacy timeline cleanup (planned in this phase)
- Confirm repo usage status:
  - Scheduled is the only screen spec selecting `timelineMonthSections`.
  - Keep `timelineMonthSections` compiling until Phase 05 deletion.

## Acceptance criteria
- Scheduled spec clearly indicates `agendaDayCardsFeed`.
- Scheduled spec no longer references `timelineMonthSections`.
- No analyzer errors introduced.

## Implementation notes
- If `SectionLayoutSpecV2` is a `freezed` union, run `build_runner` after adding a new variant.
- Ensure default behavior for other screens remains unchanged.

## AI instructions (strict)
- Review `doc/architecture/UNIFIED_SCREEN_MODEL_ARCHITECTURE.md` before implementing.
- Run `flutter analyze` for this phase.
- Fix analyzer issues caused by this phase’s changes by end of phase.
