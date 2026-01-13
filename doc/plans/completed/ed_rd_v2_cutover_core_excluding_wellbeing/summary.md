# ED/RD + V2 Cutover (Core, excluding wellbeing) — Summary

Implementation date (UTC): 2026-01-14

## What shipped

- Task is editor-only end-to-end: navigating to `/task/:id` opens the task editor modal and returns to the previous route when dismissed.
- Core entity detail routing remains consistent and centralized via `Routing` (entity builders registered at bootstrap).

## Notes / follow-ups

- This plan intentionally excludes journals/trackers; no journaling/tracking cutover work is included here.
