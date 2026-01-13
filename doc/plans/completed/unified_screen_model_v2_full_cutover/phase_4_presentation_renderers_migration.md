# Unified Screen Model V2 — Full Cutover Plan (Phase 4: Presentation Renderers)

Created at: 2026-01-12T00:00:00Z (UTC)
Last updated at: 2026-01-12T06:10:00Z (UTC)

## Objective
Migrate the list-like renderers and tile wiring to interpret the V2 layout and tile specs consistently, while keeping entity rendering centralized in canonical entity views.

Plan references:
- Decisions: `decisions.md`
- Open issues: `open_issues.md`
- Implementation reference: `implementation_reference.md`

## Implementation guide (Phase 4)

Goal: render `*_v2` templates in the UI, including sticky headers and agenda tag pills driven by variant + typed derived outputs.

### 1) Wire new template IDs into section switching

- Update: `lib/presentation/widgets/section_widget.dart`
  - Add switch cases for `SectionTemplateId.*_v2`.
  - Route each to a V2 renderer (or adapt existing renderers if types align).

### 2) Implement V2 renderers

Create new renderers under `lib/presentation/screens/templates/renderers/`:

- `task_list_renderer_v2.dart`
- `project_list_renderer_v2.dart`
- `value_list_renderer_v2.dart`
- `interleaved_list_renderer_v2.dart`
- `agenda_section_renderer_v2.dart`

Each renderer should:
- interpret `SectionLayoutSpecV2` (3 modes only)
- use `ScreenItemTileRegistry` for actual entity tiles
- consume typed `EnrichmentResultV2` for:
  - counts/stats
  - agenda tag pills mapping when `TaskTileVariant.agenda` is used

### 3) Sticky headers (grouped lists + timeline)

Use the agenda renderer’s existing approach as the reference pattern:
- `SliverPersistentHeader(pinned: true, delegate: ...)`

For `hierarchy_value_project_task`:
- emit a pinned header for each Value group
- optionally emit pinned headers for Project sub-groups (evaluate UX; value-level pinning is the minimum)
- render group bodies as slivers (list sliver per group) to preserve scroll performance

### 4) Remove per-screen “showTitlePrefixTags”

- Do not read `AgendaSectionParams.showTitlePrefixTags` in any V2 renderer.
- For V2, the presence of a tag pill comes from:
  - `TaskTileVariant.agenda`
  - `EnrichmentResultV2.agendaTagsByTaskId`

### 5) Keep Scheduled scroll ownership behavior intact

- Preserve existing “single agenda section special-case” behavior.
- When swapping to `agenda_v2`, ensure the same widget structure is used where scroll ownership depends on it.

### 6) Verify (analysis)

- Run `flutter analyze` and fix all issues introduced in this phase.
- Do not run tests yet.

## Work items
- Update renderers:
  - `task_list_renderer.dart`
  - `project_list_renderer.dart`
  - `value_list_renderer.dart`
  - `interleaved_list_renderer.dart`
  - `agenda_section_renderer.dart` (largest; keep scroll sync intact)
- Add V2 renderer wiring for new template IDs (`*_v2`). Prefer new renderer entry points if it keeps legacy removal simple.
- Ensure chrome (prefix/suffix/badges) comes from tile variants/layout spec, not per-screen flags.
- Keep casting out of templates: continue routing through `ScreenItemTileRegistry` into `TaskView`/`ProjectView`/`ValueView`.

Sticky headers:
- Implement sticky headers for grouped list layouts (not only agenda timeline). This will likely require rendering groups as multiple slivers (header sliver + list sliver per group), similar to how `agenda_section_renderer.dart` already uses `SliverPersistentHeader`.

## Removal targets
- Remove any remaining usage of superseded flags (e.g. `AgendaSectionParams.showTitlePrefixTags`).
- Consolidate duplicated list layout logic into shared helpers where it reduces complexity without hiding behavior.

## Acceptance criteria
- Visual behavior remains equivalent for existing system screens.
- Scheduled retains agenda scroll ownership.
- `flutter analyze` is clean.

## AI instructions
- Re-read `doc/architecture/` before implementing the phase.
- Run `flutter analyze` during the phase and ensure any errors/warnings introduced (or discovered) are fixed by the end of the phase.
- If this phase changes module boundaries, responsibilities, or data flow, update the relevant files under `doc/architecture/` in the same PR.
