# Plan — Anytime Screen + Remove Projects List Destination

Created at: 2026-01-15T00:00:00Z
Last updated at: 2026-01-15T00:00:00Z

## Summary

This plan implements two product changes:

1) **Remove Projects list destination**
- Remove Projects list from navigation/routes.
- Keep Project Detail screen (RD: project + related tasks) and Project Create/Edit form.
- Remove the project list template only if it becomes unused.

2) **Update Someday → Anytime**
- Anytime becomes the canonical actionable backlog view.
- Mixed tasks + projects.
- Adds a description line and filters.
- Adds focus cues and sorting to improve clarity across Anytime and Scheduled.

## Phases

- Phase 1: Remove Projects list destination (keep Project Detail)
- Phase 2: Create “Anytime” system screen spec (replacement for Someday)
- Phase 3: Filters + focus cues + focus sorting within project
- Phase 4: Docs, cleanup, verification

## Notes

- “Blocked” concept is not part of this plan.
- “Today” semantics use local day boundaries for filtering.
- Scheduled remains a date lens and includes focus.
