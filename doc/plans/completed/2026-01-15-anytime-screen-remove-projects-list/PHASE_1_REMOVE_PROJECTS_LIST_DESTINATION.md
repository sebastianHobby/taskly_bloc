# Phase 1 — Remove Projects List Destination (Keep Project Detail)

Created at: 2026-01-15T00:00:00Z
Last updated at: 2026-01-15T00:00:00Z

## AI instructions

- Review `doc/architecture/` before implementing this phase.
- Run `flutter analyze` for this phase.
- Ensure any `flutter analyze` errors/warnings caused by this phase’s changes are fixed by the end of the phase.

## Goal

Remove the **Projects list** as a top-level navigation destination (routes/menu), while keeping:
- Project Detail screen (RD: project + related tasks)
- Project Create/Edit form

Optionally delete the **project list template** implementation *only if it is unused* after the navigation removal.

## Scope

In scope:
- Remove/hide the Projects list entry from navigation (left rail / bottom nav / screen catalog ordering).
- Remove any direct routes/aliases that take users to Projects list (e.g., `/projects` redirect/route), if appropriate.
- Ensure Project Detail route remains reachable (e.g., `/projects/:projectId`).
- Verify any in-app links that previously navigated to Projects list now navigate somewhere sensible (e.g., Anytime, Browse, or no-op) or are removed.

Out of scope:
- Changing Project Detail UX/content.
- Renaming “Someday” to “Anytime” (handled in later phases).

## Steps

1) Identify the Projects list destination wiring
- Find where the system Projects screen is included in the navigation model.
- Find router alias routes related to `/projects`.

2) Remove Projects list from navigation destinations
- Hide/remove the Projects list from any navigation UI and from any screen registries that drive nav.

3) Adjust routing
- Remove or change the `/projects` list route/redirect. Options:
  - Redirect `/projects` to Anytime (recommended once Anytime exists), or
  - Redirect to Browse, or
  - Remove alias entirely if deep-link stability isn’t required.
- Keep `/projects/:projectId` (Project Detail) untouched.

4) Remove project list template (conditional)
- Search for the “project list template” usage.
- If it is only used for the removed Projects list destination, remove it.
- If used elsewhere, keep it.

## Files likely touched

- `lib/core/routing/router.dart`
- `lib/presentation/features/navigation/...`
- `lib/domain/screens/catalog/system_screens/system_screen_specs.dart`
- `lib/presentation/screens/templates/...` (only if template becomes unused)

## Acceptance criteria

- There is no “Projects” list destination in navigation.
- Visiting Project Detail still works everywhere it is referenced.
- No dead routes to the Projects list remain (or they redirect to the chosen replacement).
- The project list template is removed only if verified unused.
