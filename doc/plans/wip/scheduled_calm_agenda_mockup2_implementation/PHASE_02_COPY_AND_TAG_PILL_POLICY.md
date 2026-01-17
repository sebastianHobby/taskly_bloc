# Phase 02 — Copy + Tag Pill Policy (UI-D001, part of UI-D002)

Created at: 2026-01-16T02:30:06Z
Last updated at: 2026-01-16T06:24:19.2555476Z

## Goal
Implement the confirmed copy change and ensure tag-pill presentation is calm and spec-driven.

## Scope
- UI-D001: change `AgendaDateTag.inProgress` label to “Ongoing”.
- UI-D002 (part): ensure whether tag pills are shown is driven by `EntityStyleV1.showAgendaTagPills` and defaults/overrides.

## Non-goals
- No row density / meta layout redesign yet.
- No tile action/mutation wiring changes.

Guardrail (USM alignment):
- Do not add any per-page SnackBars or widget-layer mutations while doing this copy/style pass.
- Actions/mutations are owned by the global tile actions system.

## Acceptance criteria
- Scheduled shows “Ongoing” (not “In progress”) wherever the agenda tag pill appears.
- If specs set `showAgendaTagPills=false`, Scheduled shows no pills without needing renderer forks.

## Completion
Completed at: 2026-01-16T06:24:19.2555476Z

Summary:
- Updated agenda tag label sources to show “Ongoing” (Scheduled renderer + list renderers + model label extension).
- Confirmed tag pill rendering remains spec-driven via `EntityStyleV1.showAgendaTagPills`.

## AI instructions (required)
- Run `flutter analyze` for the phase.
- Ensure any `flutter analyze` errors/warnings caused by this phase’s changes are fixed by the end of the phase.
- Review `doc/architecture/` before implementing the phase, and keep architecture docs updated if the phase changes architecture.
- When the phase is complete, update this file immediately (same day) with summary + completion date (UTC).
