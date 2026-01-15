# WIP Plan — Phase 3: Flat ranked list rendering (tasks-only)

Created at: 2026-01-15T05:09:10.4635911Z
Last updated at: 2026-01-15T06:30:00Z

## Purpose
Change My Day’s primary content from value-group hierarchy to a flat ranked list that clearly communicates “start at the top”.

## Planned behavior
- Data source remains allocation snapshot-driven (same semantics as before).
- Order uses allocation rank when available (from the My Day interpreter’s outputs).
- UI renders tasks only (no project rows/groups).
- Show a subtle rank gutter (RANK-1).
- Preserve the existing task tile component, but apply the chosen density option:
  - T2-B (chosen): calm by default; tap-to-expand reveals the existing full-detail chips inline.

## Implementation approach (architecture-aligned)
Render the My Day list through the USM section pipeline (no template branching):

- The My Day module interpreter outputs a dedicated `SectionVm` variant (e.g. `SectionVm.myDayRankedTasksV1(...)`).
- `SectionWidget` switches on that `SectionVm` and renders a dedicated section widget/renderer.

## Concrete implementation map
- Render path:
  - Implement the widget in the section rendering path:
    - either directly in `lib/presentation/widgets/section_widget.dart` (as a private widget), or
    - via `lib/presentation/screens/templates/renderers/section_renderer_registry.dart` if this repo centralizes section renderers there.
  - Avoid special-casing `screenKey == 'my_day'` in `_StandardScaffoldV1Template` for list shaping.
- Data extraction:
  - Use only the fields exposed by the My Day `SectionVm` (tasks + stable IDs + rank + optional value metadata).
  - If value name/color are needed, ensure the `SectionVm` includes lookup-ready metadata so the section widget does not read repositories.
- Sorting:
  - Stable sort tasks by rank ascending (lower rank first).
  - If rank missing for a task, place it after ranked tasks (secondary sort by task title/id for stability).
- Tasks-only definition (enforced here):
  - The renderer must only render task rows.
  - Any non-task entities included in the VM (e.g. value lookup metadata) must be lookup-only.

## Notes
- If the existing shared list renderers contain My Day-specific behavior today, prefer deleting/retiring that special-casing and moving My Day behavior behind the dedicated My Day `SectionVm` renderer.

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
