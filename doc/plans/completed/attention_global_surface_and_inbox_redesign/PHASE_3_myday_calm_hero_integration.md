# Plan Phase 3: My Day calm hero integration (focus + progress + summary + bell)

Created at: 2026-01-16T00:00:00Z
Last updated at: 2026-01-16T00:30:50.0664016Z

## Goal

Implement the **calm My Day hero** layout direction:
- Focus choice + “Change” entrypoint.
- Subtle progress (done/total) as My Day-specific content.
- Attention summary integrated into the hero area (or directly below it), aligned
  with the placement matrix.
- Bell in AppBar remains the global entrypoint.

Aligned decisions:
- [doc/plans/ui_decisions/2026-01-16_attention-surface-and-myday-calmness.md](../../ui_decisions/2026-01-16_attention-surface-and-myday-calmness.md)
- [doc/plans/ui_decisions/2026-01-16_attention-placement-matrix.md](../../ui_decisions/2026-01-16_attention-placement-matrix.md)

## Scope

- Update the My Day presentation renderer(s) to match the accepted calm header.
- Ensure global attention copy remains global (avoid “My Day progress” language
  inside shared attention components).

## Non-goals

- Do not redesign task row UI beyond what is required to support the new header.

## Likely touch points

- `lib/presentation/screens/templates/renderers/my_day_ranked_tasks_v1_section.dart`
- Any My Day header BLoC/view models used by the section.
- Shared attention widgets only as needed to prevent “global vs My Day” leakage.

## Acceptance criteria

- My Day renders a calm header/hero with focus selection and subtle progress.
- Attention summary location matches the placement matrix.
- Bell remains global and navigates to inbox.
- No new analyzer issues introduced.

## AI instructions

- Review `doc/architecture/` before implementing.
- Run `flutter analyze` for this phase.
- Fix any `flutter analyze` errors/warnings caused by this phase’s changes.
- Do not run tests unless explicitly requested.
- When complete, update:
  - `Last updated at:` (UTC)
  - Summary of changes
  - Phase completion timestamp (UTC)

## Phase completion

Completed at: 2026-01-16T00:30:50.0664016Z

Summary:
- Added a dedicated `myDayHeroV1` header module and section (focus selection + subtle progress).
- Reordered My Day header modules so the hero appears above the attention Summary Strip.
- Simplified the My Day ranked tasks section by removing the old inline focus banner.
- Ran code generation and verified `flutter analyze` is clean.
