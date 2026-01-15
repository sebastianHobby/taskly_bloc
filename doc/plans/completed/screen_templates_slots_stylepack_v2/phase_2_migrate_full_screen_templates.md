# Phase 2 — Migrate Full-Screen Templates to Screen Templates

Created at: 2026-01-13T00:00:00Z  
Last updated at: 2026-01-13T00:30:00Z

## AI instructions
- Before implementing this phase, review `doc/architecture/`.
- Run `flutter analyze` during this phase.
- Ensure any errors or warnings introduced (or discovered) are fixed by the end of the phase.
- If this phase changes architecture (module boundaries, responsibilities, data flow), update the relevant files under `doc/architecture/`.

## Objective
Eliminate the category mismatch where some **section templates behave as full screens** by promoting them into **screen templates**.

This reduces complexity in `SectionWidget` and makes the mental model consistent:
- screen templates render pages
- section templates render modules

## Implementation outline
1) **Identify full-screen section templates**
   - From the existing section template catalog and `SectionWidget` routing, collect the templates that render whole pages.

   Hard requirement for the simplified approach:
   - This inventory becomes the deletion list for any “full-screen module”
     special-casing once migrated.

2) **Create screen template equivalents**
   - Add matching entries in the typed `ScreenTemplateSpec`.
   - Implement their shell widgets under the screen-template presentation folder.

3) **Update system screen specs**
   - For screens that are currently a single section pointing at a full-screen section template:
     - set `template: ScreenTemplateSpec.*` to the new screen template
     - remove the full-screen module from `modules` (or leave modules empty if
       the template is fully self-contained)

4) **Simplify section routing**
   - Remove special cases from the module/widget routing for full-screen
     behavior.
   - Ensure any navigation/settings hooks previously wired via section templates remain reachable (may stay in `ScreenChrome`).

## Acceptance criteria
- `SectionWidget` contains only true section/module renderers.
- System screens that were previously full-screen section templates now use screen templates.
- `flutter analyze` clean.

## Notes
- If the repo contains multiple parallel screen routers (or multiple
   SystemScreenDefinitions sources), do not migrate both; migrate the canonical
   one and delete the other in Phase 5.

## Notes
- This phase should not introduce new UI behavior; it should be a re-home and simplification.
