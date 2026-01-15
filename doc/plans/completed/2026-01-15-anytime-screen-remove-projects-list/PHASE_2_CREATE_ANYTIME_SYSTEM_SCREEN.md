# Phase 2 — Create the “Anytime” System Screen (Replacement for Someday)

Created at: 2026-01-15T00:00:00Z
Last updated at: 2026-01-15T00:00:00Z

## AI instructions

- Review `doc/architecture/` before implementing this phase.
- Run `flutter analyze` for this phase.
- Ensure any `flutter analyze` errors/warnings caused by this phase’s changes are fixed by the end of the phase.

## Goal

Replace the current Someday concept with **Anytime**:
- Anytime is the canonical actionable backlog view.
- It shows **tasks + projects** in a mixed list.
- It includes focus (My Day / allocated) items but visually marks them (implemented in Phase 3).
- It supports a filter to hide “start later” items (implemented in Phase 3).

## Product contract (from architecture)

- Title: “Anytime”
- Description line:
  - “Your actionable backlog. Use filters to hide ‘start later’ items.”
- Scheduled remains a date-based lens that includes focus.
- “Today” semantics use local day boundaries.

## Scope

In scope:
- Add/rename the system screen spec from “Someday” to “Anytime”.
- Ensure navigation icon mapping supports Anytime.
- Ensure the screen’s section/module sources include **both tasks and projects**.
- Ensure Project Detail remains available for drill-in.

Out of scope:
- Implementing the new filter chips and focus cues (Phase 3).

## Steps

1) Decide key strategy (migration)
- Prefer keeping route key stable if deep links matter (e.g., keep `screenKey='someday'` but rename label/icon), OR
- Introduce `screenKey='anytime'` and add a compatibility redirect from old someday routes.

2) Update SystemScreenSpecs
- Update the system screen spec definition:
  - name: Anytime
  - icon: a new icon (or reuse Someday’s)
  - add the description line (wherever the standard scaffold template renders it)

3) Make the section data mixed
- Ensure the module sources include:
  - Task source: incomplete tasks (regardless of dates)
  - Project source: active projects
- Keep the default template layout as the existing hierarchy view if it supports mixed items.

## Files likely touched

- `lib/domain/screens/catalog/system_screens/system_screen_specs.dart`
- `lib/presentation/features/navigation/services/navigation_icon_resolver.dart`
- Potentially screen template renderers if they need to display the description line.

## Acceptance criteria

- The new system screen “Anytime” exists and is reachable.
- It loads both tasks and projects (mixed).
- It displays the description line exactly.
- No regressions to Project Detail drill-in from project tiles.
