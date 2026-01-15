# WIP Plan — Phase 4: Today’s mix (MIX-B) computation + UI

Created at: 2026-01-15T05:09:10.4635911Z
Last updated at: 2026-01-15T06:30:00Z

## Purpose
Implement the “Today’s mix” summary and inline expansion.

## Planned behavior
- Default (collapsed):
  - `Today’s mix: ● Health (52%) • ● Learning (30%) • +1` plus chevron
- Tap toggles inline expansion to show a simple breakdown (top 3 rows):
  - `● Value 52%` (with value color dot)
  - `● Value 30%`
  - `● Value 18%`

## Computation rules
- Base the mix on **task counts** (decision 4A).
- Attribute each task to a single value id in this priority order:
  1) `DataV2SectionResult.enrichment.qualifyingValueIdByTaskId[taskId]` (from allocation snapshot refs)
  2) task primary value id (if available in the model)
  3) first effective value id
  4) `No value`
- Compute percentages as `count / totalTasks`.
- Sort values by descending percentage (tie-break by value priority then name if needed).

## Concrete implementation map
- Render path:
  - Render inside the dedicated My Day section renderer/widget (same renderer that builds the ranked list).
  - The mix row sits above the ranked task list in that section widget.
- Data inputs (no repository reads in widgets):
  - Consume the My Day `SectionVm` for tasks and any value lookup metadata.
  - Do not re-read repositories/services for values/colors.

### Mix computation location (ARCH-002 B)
Compute the mix breakdown in a presentation BLoC (not in the widget tree):

- Introduce a `MyDayRankedListBloc` (or extend an existing My Day presentation BLoC) that:
  - takes the My Day `SectionVm` as input (or takes `ScreenSpecBloc` state and selects the My Day section)
  - computes the collapsed summary fields and expanded breakdown list
  - emits a widget-friendly `MyDayMixVm`.
- The section widget renders `MyDayMixVm` via `BlocBuilder` (or equivalent) and remains dumb.

UI-only state:
- Collapsed/expanded state is ephemeral UI state and may remain local to the widget (allowed exception), but the *computed breakdown* comes from the BLoC.
- Expansion must not write to settings/storage.

## Acceptance criteria
- Mix is stable for the visible list and updates when the list membership changes.
- Collapsed row uses top 2 values + “+N” for the remainder.
- Expanded view shows top 3 values with percent.

## AI instructions
- Review `doc/architecture/` before implementing this phase.
- Run `flutter analyze` for this phase.
- Fix any `flutter analyze` errors/warnings caused by this phase’s changes by the end of the phase.
- Keep the computation in presentation logic fed by existing BLoC state/enrichment (no direct repository reads in widgets).
