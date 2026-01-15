# Phase 3 — Anytime Filters + Focus Cues + Focus Sorting

Created at: 2026-01-15T00:00:00Z
Last updated at: 2026-01-15T00:00:00Z

## AI instructions

- Review `doc/architecture/` before implementing this phase.
- Run `flutter analyze` for this phase.
- Ensure any `flutter analyze` errors/warnings caused by this phase’s changes are fixed by the end of the phase.

## Goal

Implement the interaction and visual language we agreed:
- Add a filter to **show/hide future start date items** (tasks + projects).
- Include My Day / focus items and visually differentiate them.
- Apply the same focus cues to Scheduled.
- Sort focus tasks to the top within each project.

## Scope

In scope:
- “Include future starts” toggle (default ON).
  - When OFF, hide items with `startDate > today` using local day boundaries.
  - Applies to tasks and projects.
- Focus cues:
  - Primary cue: “In Focus” icon/badge.
  - Secondary cue: subtle accent (left border or background tint).
  - Applied consistently in Anytime + Scheduled.
- Sorting:
  - Within each project grouping, focus tasks first, then non-focus tasks.

Out of scope:
- A “blocked” concept (does not exist yet).

## Steps

1) Add filter UI
- Extend the existing section filter bar to include a toggle chip:
  - Label: “Include future starts”
- Decide whether it appears inline with existing entity/value filters or in a bottom sheet.

2) Implement filtering logic (local-day boundary)
- Implement `startDate > todayLocal` logic.
- Apply to both:
  - Task items
  - Project items

3) Focus marking
- Identify how allocation/focus membership is represented (existing enrichment, allocation snapshot membership, etc.).
- Expose an `isInFocus` signal to tile rendering.

4) Apply cues in tile UI
- Add primary icon/badge + secondary accent to task tiles.
- Apply the same cues in Scheduled task rendering.

5) Sorting focus tasks within project
- In the hierarchy renderer’s project task list builder, stable-partition tasks:
  - focus first
  - then others
- Preserve existing ordering within each partition.

## Files likely touched

- Section filter UI components (e.g., `section_filter_bar_v2.dart`)
- Anytime renderer logic / interleaved list renderer
- Scheduled renderer logic
- Task tile widgets

## Acceptance criteria

- Anytime shows the description line and the “Include future starts” toggle.
- Toggling OFF hides future-start tasks and projects using local-day boundaries.
- Focus items display the primary + secondary cues on Anytime and Scheduled.
- Within a project, focus tasks are always listed above non-focus tasks.
