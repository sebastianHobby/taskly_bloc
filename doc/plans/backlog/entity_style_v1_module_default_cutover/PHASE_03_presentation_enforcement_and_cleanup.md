# Phase 03 — Presentation Enforcement (Tile Builder) + Cleanup (delete StylePackV2)

Created at: 2026-01-16T00:00:00Z
Last updated at: 2026-01-16T00:00:00Z

## Goal
Enforce consistent entity styling across all renderers by requiring a `ScreenItemTileBuilder` that takes `EntityStyleV1` and is the only allowed path for building Task/Project/Value tiles. Remove legacy/unused style code (`StylePackV2`) entirely.

## Work Items
### 1) Create ScreenItemTileBuilder that requires EntityStyleV1
- Introduce a builder (presentation layer), e.g.:
  - `lib/presentation/screens/tiles/screen_item_tile_builder.dart`
- Builder API should require `EntityStyleV1` and map it into widget variants:
  - `TaskTileVariant.listTile` -> `TaskViewVariant.list`
  - `TaskTileVariant.agenda` -> `TaskViewVariant.agendaCard`
  - `ProjectTileVariant.listTile` -> `ProjectViewVariant.list`
  - Future: add agenda project variant mapping if needed

### 2) Refactor ScreenItemTileRegistry to delegate to builder
- Update `ScreenItemTileRegistry` (or replace it) so that it cannot build tiles without a style.
- Call sites in:
  - list renderer(s)
  - interleaved renderer
  - hierarchy renderer

### 3) Refactor AgendaSectionRenderer to use the same builder
- Ensure Scheduled agenda no longer constructs TaskView/ProjectView directly.
- Agenda renderer passes `entityStyle` from its `SectionVm`.

### 4) Delete StylePackV2 + unused tile variant code
- Delete:
  - `lib/domain/screens/templates/params/style_pack_v2.dart`
- Remove all remaining imports/usages.
- Review `screen_item_tile_variants.dart` usage:
  - Keep enums if still meaningful in domain, or consolidate into `EntityStyleV1` enums.

### 5) Codegen + analysis
- Run `build_runner`.
- Run `flutter analyze` and fix any issues.

### 6) Update architecture docs (normative enforcement)
- Update USM doc to include:
  - Rule: renderers must not directly instantiate entity view widgets (TaskView/ProjectView/ValueView).
  - Required path: ScreenItemTileBuilder + EntityStyleV1.

## Acceptance Criteria
- No renderer constructs `TaskView` or `ProjectView` directly.
- `StylePackV2` file is deleted and no longer referenced.
- `flutter analyze` passes.

## AI Instructions
- Review `doc/architecture/` before implementing.
- Run `flutter analyze` for the phase.
- In this last phase, fix **any** `flutter analyze` error or warning (regardless of whether it is related to the plan).
- When the phase is complete, update this file immediately with:
  - `Last updated at:` (UTC)
  - a short summary of what was done
  - the phase completion timestamp (UTC)
