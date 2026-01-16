# Plan Phase 4: Attention inbox redesign (no tabs, entity-first)

Created at: 2026-01-16T00:00:00Z
Last updated at: 2026-01-16T00:58:47Z

## Goal

Redesign the Attention inbox (`review_inbox`) to remove tabs and make entities
center stage.

Accepted direction (from chat):
- D-NT-001A: single feed, grouped by severity.
- One row per entity; if multiple reasons exist, show 1 reason line + `+n more`.
- Headline reason selection is severity-driven.
- Dismiss semantics: **dismiss until state changes** (state changes treated as a
  new situation). This aligns with the attention engine suppression semantics.

## Scope

- Presentation-only redesign of the inbox screen rendering.
- Keep domain engine / resolution semantics unchanged.
- Provide:
  - Search + Filter sheet (replaces tabs)
  - Overflow menu per row with:
    - Open entity
    - Snooze…
    - Dismiss… (with per-reason selection and “dismiss all reasons”)
  - Expand/collapse reasons inline or via a sheet.

## Dependencies / prerequisites

- Confirm what metadata is available on `AttentionItem` to:
  - navigate to the target entity (task/project)
  - identify which rule(s)/reason(s) apply

If additional metadata is required, treat that as an architecture-affecting
change and get explicit confirmation before modifying domain models.

## Likely touch points

- `lib/presentation/screens/templates/renderers/attention_inbox_section_renderer_v1.dart`
- `lib/presentation/screens/templates/renderers/attention_support_section_widgets.dart`
- Potentially Attention feature pages/widgets if `review_inbox` uses them.

## Acceptance criteria

- Inbox has no tabs.
- Entities are the primary list items; reasons are supporting.
- Multiple reasons show as one line + `+n more`.
- Dismiss UI copy matches “until state changes” semantics.
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

## Notes

This phase includes UI/UX details agreed in chat but not currently captured in
an accepted UI decision log. If you want a durable record, create a new entry in
`doc/plans/ui_decisions/` before implementing, or add an addendum to an existing
accepted decision (with explicit approval).

## Completion

Completed at: 2026-01-16T00:58:47Z

Summary:
- Implemented entity-first inbox rendering with no tabs (filters sheet replaces tabs).
- Added reasons affordance (`+n more`) and a reasons sheet to inspect all reasons.
- Added action menu per entity with snooze/dismiss flows and copy aligned to “dismiss until state changes”.
- Updated inbox state shaping to emit entity/reason view-models to support the UI.
