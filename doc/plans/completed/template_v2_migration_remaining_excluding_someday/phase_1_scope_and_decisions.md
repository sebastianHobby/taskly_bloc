# Template V2 Migration (Remaining Templates) — Phase 1: Scope + Decisions

Created at: 2026-01-13T00:00:00Z (UTC)
Last updated at: 2026-01-13T00:00:00Z (UTC)

## Objective
Define what “V2” means for the remaining non-V2 section templates and lock the migration strategy.

## Explicitly out of scope
- Someday migration (`someday_backlog`) — tracked separately in `doc/plans/completed/someday_v2_full_migration/`.

## Inventory (current, non-V2 templates)
### Data-ish templates (have typed params + interpreter + renderer)
- `allocation`
- `issues_summary`
- `allocation_alerts`
- `check_in_summary`
- `entity_header`

### Static/full-screen templates (no params; effectively standalone screens)
- `settings_menu`
- `journal_timeline`
- `navigation_settings`
- `allocation_settings`
- `attention_rules`
- `focus_setup_wizard`
- `tracker_management`
- `wellbeing_dashboard`
- `statistics_dashboard`
- `browse_hub`
- `my_day_focus_mode_required`

## Decisions to lock
1) **Naming strategy**
   - Decision: keep existing IDs and migrate implementations to V2 conventions internally.
   - Rationale: avoid template ID churn and any persisted-config migration.

2) **Success criteria per template**
   - Decision: keep specialized `SectionDataResult` variants for non-list templates (e.g. issues summary, alerts, check-in), but align params + renderer conventions with V2.
   - Rationale: preserve strong domain semantics and reduce refactor risk.

3) **Backward compatibility contract**
   - Whether persisted/custom screens may reference these templates.
   - If template IDs change, define the migration path (codec accepts both IDs; optional DB cleanup later).

## Deliverables
- Written decision on Option A vs Option B.
- A per-template target-state table (template -> V2 target -> breaking changes?).

## AI instructions
- Re-read `doc/architecture/` before implementing the phase.
- Run `flutter analyze` during the phase and ensure any errors/warnings introduced (or discovered) are fixed by the end of the phase.
- If this phase changes module boundaries, responsibilities, or data flow, update the relevant files under `doc/architecture/` in the same PR.
