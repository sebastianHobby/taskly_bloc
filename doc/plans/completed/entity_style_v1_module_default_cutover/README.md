# EntityStyleV1 Cutover (Module-Default Styling)

Created at: 2026-01-16T00:00:00Z
Last updated at: 2026-01-16T01:56:49Z

## Summary
This plan replaces `StylePackV2` with a domain-resolved `EntityStyleV1` contract keyed by `(ScreenTemplateSpec, SectionTemplateId)` and enforces consistent tile styling by requiring renderers to use a `ScreenItemTileBuilder`.

## Key Decisions
- No backwards compatibility or legacy code is retained (explicitly requested).
- Styling defaults are attached to module type (with minimal overrides).
- Presentation renderers must not instantiate `TaskView`/`ProjectView` directly.

## Phases
- Phase 01: Design + domain models + resolver + doc update
- Phase 02: Wire resolved style into USM runtime (SectionVm + interpreters) + update specs/params
- Phase 03: Presentation enforcement via tile builder + delete `StylePackV2` + final doc update

## Completion
Completed at: 2026-01-16T01:56:49Z
