# WIP Plan — My Day: Focus Header + Mix + Flat Ranked List

Created at: 2026-01-15T05:09:10.4635911Z
Last updated at: 2026-01-15T05:24:01.3710619Z

## Goal
Implement the agreed My Day experience:

- Mobile-first, calm, modern.
- Clear “today’s focus with the why (value)” via a header.
- Flat ranked list that reads as “start at the top” (no “Next up” concept).
- “Today’s mix” summary row (collapsed by default; inline expand).
- Remove My Day app bar settings/focus controls; configuration entry-point lives in the header’s `Change` action.

Non-goals:
- Do not change allocation algorithms or snapshot generation.
- Do not change other screens’ list/grouping behavior (Anytime/Scheduled/etc).
- Do not introduce a brand-new screen template; keep `standardScaffoldV1`.

## Decisions (locked)
- Remove My Day app bar settings + focus selector/indicator (My Day only).
- List is tasks-only.
- “Today’s mix” = MIX-B (single-line summary, inline expand).
- Rank display = RANK-1 (subtle number gutter).
- “Change” goes straight to Focus Setup wizard’s Focus Mode step.
- “Today’s mix” percentages based on task-count per value.
- “Today’s mix” expansion is inline.
- Task tile density = T2-B (calm default, tap-to-expand).

Implementation constraints:
- Keep Unified Screen Model layering: widgets do not read repositories; use existing BLoC/interpreted section data.
- Prefer My Day-specific rendering inside the existing My Day branch of `ScreenTemplateWidget` rather than modifying shared renderers.
- Keep copy changes scoped to My Day.

## Task tile density (chosen)
Task tile density for the flat list is **T2-B**:

- Default row uses a calm density layout (optimized for scanning).
- Tapping the row expands inline to reveal the existing full-detail chips/metadata.

Expanded state rules:
- Expanded row is per-task (track by `taskId`).
- Expansion is ephemeral (in-memory only) and resets when leaving the screen.
- Tapping another row expands that row but does not auto-collapse others (unless implementation simplicity requires “single expanded at a time”; if so, document it in Phase 5).

## Acceptance criteria
- My Day shows a “Focus rationale” header card with:
  - focus mode name + tagline
  - 2–3 chips derived from the mode (no “Stable today” copy)
  - a `Change` action that navigates directly to focus-mode selection
- My Day shows a collapsed “Today’s mix” row:
  - `Today’s mix: ● Value (xx%) • ● Value (yy%) • +N` and a chevron
  - tapping expands inline to show a simple breakdown (top 3 by default)
- Primary content is a tasks-only list:
  - subtle rank gutter (1,2,3…)
  - existing task tile preserved via T2-B (calm default + tap-to-expand)
- My Day app bar no longer shows settings/focus controls
- No UI/UX changes leak into other screens unintentionally

Definition of “tasks-only list” for this project:
- Render only `ScreenItemTask` items; do not render `ScreenItemProject` or `ScreenItemValue` tiles.
- Still show the task’s project name as secondary metadata where available.

## AI instructions
- Review `doc/architecture/` before implementing this phase.
- Run `flutter analyze` for this phase.
- Fix any `flutter analyze` errors/warnings caused by this phase’s changes by the end of the phase.
- Keep changes aligned to the Unified Screen Model (USM) boundaries.
