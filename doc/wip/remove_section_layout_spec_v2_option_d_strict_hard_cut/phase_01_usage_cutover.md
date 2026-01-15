# Phase 01 — Usage cutover (stop using layout)

Created at: 2026-01-15T00:00:00Z
Last updated at: 2026-01-15T00:00:00Z

## Intent
Remove *runtime usage* of `SectionLayoutSpecV2` by migrating any screens that currently express hierarchy via `InterleavedListSectionParamsV2(layout: SectionLayoutSpecV2.hierarchyValueProjectTask(...))` to instead use the specialized `hierarchyValueProjectTaskV2` module.

This phase should not delete types yet. The goal is to make Phase 02 a safe deletion.

## AI instructions (required)
- Review `doc/architecture/` before implementing.
- Run `flutter analyze` for this phase.
- Ensure any `flutter analyze` errors/warnings caused by this phase are fixed by the end of the phase.

## What to change

### 1) Identify all current `SectionLayoutSpecV2` usages
Search in `lib/` and `test/` for:
- `SectionLayoutSpecV2.`
- `layout:` where the type is `SectionLayoutSpecV2`

Expected current known usage:
- Anytime/Someday system screen specs still using `interleavedListV2(layout: hierarchyValueProjectTask(...))`.

### 2) Migrate Anytime/Someday to `hierarchyValueProjectTaskV2`
Edit system screen catalog:
- File: `lib/domain/screens/catalog/system_screens/system_screen_specs.dart`

Target outcome:
- The relevant screen(s) (Anytime and Someday) use module `hierarchyValueProjectTaskV2(...)` instead of `interleavedListV2(...)`.

Guidelines:
- Preserve the visible behavior:
  - Pinned headers configuration
  - “Inbox” grouping behavior (if present)
  - Any task query/filtering semantics and section title strings
  - Any selection/interaction mode
- Prefer passing the appropriate specialized params type `HierarchyValueProjectTaskSectionParamsV2` rather than adapting via interleaved.

### 3) Confirm no other screen specs still depend on layout
Files to verify (expected; adjust based on actual grep results):
- `lib/domain/screens/catalog/system_screens/system_screen_specs.dart`
- `lib/domain/screens/catalog/entity_screens/entity_detail_screen_specs.dart`

If any other screens still reference `SectionLayoutSpecV2.flatList` or `.hierarchyValueProjectTask`:
- Decide whether they should:
  - stay as `flatList` but without layout (likely by using a flat module type that has no layout param), or
  - migrate to a specialized module (hierarchy module).

Do not implement broad UI changes here—only module selection/config changes.

## Acceptance criteria
- `SystemScreenSpecs` has no remaining usage of `SectionLayoutSpecV2.*`.
- The app compiles (via analyzer) with no new errors introduced in this phase.

## Notes / likely follow-ups
- After cutover, `InterleavedListSectionParamsV2.layout` may still exist and be required, but should no longer be used by screen specs.
- Do not delete layout union yet; that is Phase 02.
