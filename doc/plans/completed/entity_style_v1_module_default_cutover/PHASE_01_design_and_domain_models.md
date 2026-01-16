# Phase 01 — Design + Domain Models + Resolver

Created at: 2026-01-16T00:00:00Z
Last updated at: 2026-01-16T01:56:49Z

## Goal
Introduce a new, typed styling contract for entity tiles that is resolved in the domain layer by (ScreenTemplateSpec, SectionTemplateId), with a minimal override mechanism. This phase focuses on model design and domain-only implementation (no presentation renderer refactors yet).

## Non-goals
- No UI/UX redesign changes in this phase.
- No renderer refactors yet.
- No backwards-compat shims for StylePackV2 (explicitly requested to avoid legacy), but the actual deletion will occur after wiring is ready (phases 2–3).

## Architecture Context (USM)
- Screen composition is driven by ScreenSpec + typed modules; renderers must stay dumb.
- Styling should be declarative, discoverable, and resolved during spec interpretation, not ad-hoc in widgets.

## Work Items
### 1) Define new domain model: EntityStyleV1
- Add `EntityStyleV1` under a domain-appropriate location, likely:
  - `lib/domain/screens/templates/params/entity_style_v1.dart`
- Make it `freezed` + `json_serializable` (even if not persisted today) to keep model quality consistent with existing params.
- Fields (minimal, matches current needs):
  - `EntityDensityV1 density` (comfortable/compact)
  - `TaskTileVariant taskVariant` (reuse existing enum in `screen_item_tile_variants.dart` or replace with V1)
  - `ProjectTileVariant projectVariant`
  - `ValueTileVariant valueVariant`
  - `bool showAgendaTagPills`

### 2) Minimal override model
- Add `EntityStyleOverrideV1` (all fields nullable) to express rare, explicit overrides:
  - `EntityDensityV1? density`
  - `TaskTileVariant? taskVariant`
  - `ProjectTileVariant? projectVariant`
  - `ValueTileVariant? valueVariant`
  - `bool? showAgendaTagPills`

### 3) Domain resolver keyed by template + module
- Add `EntityStyleResolver` in domain runtime/templates, e.g.:
  - `lib/domain/screens/runtime/entity_style_resolver.dart`
- API:
  - `EntityStyleV1 resolve({required ScreenTemplateSpec template, required String sectionTemplateId, EntityStyleOverrideV1? override})`
- Resolver should be a simple, data-table mapping (no service dependencies):
  - Default for `SectionTemplateId.agendaV2`: task variant agenda, project variant agenda, showAgendaTagPills true, density comfortable.
  - Default for list-like sections (`taskListV2`, `interleavedListV2`, `hierarchyValueProjectTaskV2`, etc.): task variant listTile, project variant listTile, showAgendaTagPills false (unless overridden), density comfortable.

### 4) Update architecture docs (design-level only)
- Update USM architecture doc to describe:
  - Where entity style is resolved
  - Resolution precedence: override > (template,module) default > global default
  - Presentation enforcement rule: renderers must not construct TaskView/ProjectView directly; use a builder.

Files likely to update:
- `doc/architecture/UNIFIED_SCREEN_MODEL_ARCHITECTURE.md`

## Acceptance Criteria
- `EntityStyleV1`, `EntityStyleOverrideV1`, `EntityStyleResolver` exist in domain.
- Resolver mapping covers current modules used by My Day / Anytime / Scheduled.
- Architecture doc has a clear, normative section describing style resolution and renderer rule.

## Phase completion
Completed at: 2026-01-16T01:56:49Z

Summary:
- Added `EntityStyleV1` + `EntityStyleOverrideV1` and the template/module keyed `EntityStyleResolver`.
- Extended project tile variants to include an agenda variant.
- Updated USM architecture doc with entity style resolution + renderer enforcement rule.

## AI Instructions
- Review `doc/architecture/` before implementing.
- Run `flutter analyze` for the phase.
- Ensure any `flutter analyze` errors/warnings caused by this phase’s changes are fixed by the end of the phase.
- When the phase is complete, update this file immediately with:
  - `Last updated at:` (UTC)
  - a short summary of what was done
  - the phase completion timestamp (UTC)
