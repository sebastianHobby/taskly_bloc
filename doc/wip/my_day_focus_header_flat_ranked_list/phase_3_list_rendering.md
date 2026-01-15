# WIP Plan — Phase 3: Flat ranked list rendering (tasks-only)

Created at: 2026-01-15T05:09:10.4635911Z
Last updated at: 2026-01-15T05:29:39.3878277Z

## Purpose
Change My Day’s primary content from value-group hierarchy to a flat ranked list that clearly communicates “start at the top”.

## Planned behavior
- Data source remains `allocationSnapshotTasksToday`.
- Order uses allocation rank via `DataV2SectionResult.enrichment.allocationRankByTaskId`.
- UI renders tasks only (no project rows/groups).
- Show a subtle rank gutter (RANK-1).
- Preserve the existing task tile component, but apply the chosen density option:
  - T2-B (chosen): calm by default; tap-to-expand reveals the existing full-detail chips inline.

## Implementation approach (high level)
## Concrete implementation map
- Render path:
  - Implement in `_StandardScaffoldV1Template._buildPrimarySlivers` in `lib/presentation/screens/templates/screen_template_widget.dart`.
  - When `spec.screenKey == 'my_day'` and `primary.length == 1` and `primary.single.data is DataV2SectionResult`:
    - Do not call `_ModuleSliver(...)` for the list.
    - Instead render a My Day-only sliver list widget (new private widget in the same file is fine).
- Data extraction:
  - Tasks: `listData.items.whereType<ScreenItemTask>()`.
  - Optional value lookup: `listData.items.whereType<ScreenItemValue>()` (used to resolve `valueId -> Value` for dots/names).
  - Rank: `listData.enrichment?.allocationRankByTaskId`.
  - Qualifying value override: `listData.enrichment?.qualifyingValueIdByTaskId`.
- Sorting:
  - Stable sort tasks by rank ascending (lower rank first).
  - If rank missing for a task, place it after ranked tasks (secondary sort by task title/id for stability).
- Tasks-only definition (enforced here):
  - Do not render `ScreenItemProject`, `ScreenItemValue`, `ScreenItemHeader`, or `ScreenItemDivider` as list rows.
  - Only tasks become rows; other items may be used as lookup-only.

## Notes
- The existing shared renderer `InterleavedListRendererV2` contains My Day-specific behavior today; this phase should avoid modifying shared renderers by rendering the My Day list directly in the My Day template branch.

## Acceptance criteria
- My Day list is tasks-only and ordered.
- Each task shows:
  - subtle rank gutter number
  - existing task tile layout (with the agreed density)
  - value dot + value name is present in-row (as metadata) without overwhelming the layout
- No “Up Next” pill is shown.

## AI instructions
- Review `doc/architecture/` before implementing this phase.
- Run `flutter analyze` for this phase.
- Fix any `flutter analyze` errors/warnings caused by this phase’s changes by the end of the phase.
- Keep changes localized to My Day; avoid changing shared renderers unless strictly required.
