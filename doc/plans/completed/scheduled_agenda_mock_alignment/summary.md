# Scheduled agenda mock alignment — Summary

Implementation date (UTC): 2026-01-13

## What shipped
- Scheduled agenda items render using entity-level card variants (`TaskViewVariant.agendaCard`, `ProjectViewVariant.agendaCard`).
- Timeline dot is anchored per date group to the first rendered item, using post-layout measurement.
- Condensed multi-day (“in progress”) items render as a dashed-outline card with an accent bar and end-day hint.
- Spacing/typography tuned to reduce list-tile feel and better match the reference mock.

## Known issues / follow-ups
- If the mock requires a different anchor point (e.g., dot aligned to card title baseline vs card top), adjust the anchor offset calculation in `_DateTimelineGroupState._measureAnchor()`.
- If additional entity types appear in the agenda, add equivalent Scheduled variants or a fallback card wrapper.
