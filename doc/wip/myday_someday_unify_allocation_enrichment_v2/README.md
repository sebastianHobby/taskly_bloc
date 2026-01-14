# My Day / Someday — Unify UI with snapshot allocation enrichment (WIP)

Created at: 2026-01-14T00:00:00Z
Last updated at: 2026-01-14T00:00:00Z

## Summary
This plan aligns My Day’s primary section UI with Someday (Value → Project → Task hierarchy rendering) while preserving My Day’s allocation semantics by introducing a snapshot-backed allocation membership enrichment item in V2 enrichment.

## Key decisions
- V1 enrichment is deleted; V2 enrichment is the only enrichment mechanism.
- Allocation membership is global state derived from the latest allocation snapshot for the current UTC day.
- Screens opt in to allocation membership data by requesting V2 enrichment; screens can ignore it and show no allocation-related UI.
- Pinned remains global `Task.isPinned` and is presentation-opt-in.

## Phases
- Phase 01: Lock V2 enrichment contract
- Phase 02: Add snapshot allocation enrichment
- Phase 03: Unify My Day + Someday primary section UI
- Phase 04: Renderer/tile consumption rules
- Phase 05: Docs + verification
