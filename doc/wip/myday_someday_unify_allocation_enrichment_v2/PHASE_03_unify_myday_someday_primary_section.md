# Phase 03 — Unify My Day + Someday primary section UI

Created at: 2026-01-14T00:00:00Z
Last updated at: 2026-01-14T00:12:00Z

## Goal
Make My Day “look like Someday” by reusing the same Value → Project → Task hierarchy/list primary section, while keeping My Day allocation semantics.

## Design constraints
- UI alignment: same renderer/layout path for both screens.
- Semantics preserved:
  - My Day membership + stable ordering comes from allocation snapshot.
  - My Day gating (focus-mode required) stays.
  - Allocation alerts/check-in summary headers stay.
- Someday semantics remain query-driven (e.g. “no dates” inbox logic).

## Work items
1. Update system screen specs to align primary section template usage:
   - Someday continues to use the hierarchy/list section params.
   - My Day switches primary section to the same hierarchy/list template.
2. Ensure My Day’s underlying data source is allocation-driven:
   - Produce `items` based on snapshot membership (tasks + required related entities for hierarchy rendering).
   - Request the new allocation enrichment item(s) to carry ordering/grouping hints.
3. Verify My Day-specific states still exist:
   - focus-mode gate page behavior
   - allocation alerts header
   - value setup gateway behavior (move into Focus Wizard gating)

## Focus Wizard integration (locked)

### Desired behavior
- Single gating rule for My Day: block entry when **no focus mode configured OR no values exist**.
- Show a dynamic wizard that only presents the missing steps.
  - If focus mode missing: show focus-mode selection steps.
  - If values missing: show value-creation step.
  - If focus mode present but values missing: show only the value-creation step (reusing the same wizard route).

### Option A — One route, dynamic step list (chosen)

#### Step ordering rules
- If focus mode is not configured, show focus-mode setup steps first.
- If values are missing, show the Values CTA page.
- The wizard is dynamic: only show what is missing.

#### Values page: single CTA page (reusable)
- Replace/remove the legacy “review” page.
- Use a single Values CTA page (no separate “bulk/final values setup” page).
- This page is both:
  - the “sell the idea / mission-aligned why” entrypoint, and
  - the place to quickly create values.
- Allow the user to add as many values as they want on this one page before continuing.
- Reuse the same Values CTA page when:
  - focus mode is configured but values are missing (values-only flow)
  - focus mode is not configured and values are missing (focus setup then values)

#### Copy / UX guidance (suggested)
- Title: “Define your Values”
- Mission-aligned why (2–3 lines):
  - “Taskly helps you spend your time on what matters. Values are how Taskly groups your day and keeps your focus aligned.”
- Helper bullets:
  - “Start with 3–5 values you care about most.”
  - “Examples: Health, Family, Learning, Deep Work.”
- Interaction:
  - quick-add input + add button
  - optional suggestion chips (tap to add)
  - allow repeated adds without leaving the page
- Primary CTA: “Continue” (disabled until at least 1 value exists)

### Deferred / not chosen
- Option B (two routes) and Option C (dialog flow) are not planned unless Option A proves too complex.

### Implementation notes (for AI)
- The wizard should compute its step list at runtime from two booleans:
  - `needsFocusModeSetup = !hasFocusMode`
  - `needsValuesSetup = values.isEmpty`
- The Values CTA page must support multiple additions without restarting the wizard.
- Completion should route back to My Day automatically.

## Acceptance criteria
- Someday and My Day share the same primary section renderer/layout.
- My Day’s set and order of tasks matches allocation snapshot expectations.
- No allocation UI leaks into Someday (because Someday does not request allocation enrichment).
- My Day gating uses a single rule: no values OR no focus mode configured.
- Focus Wizard flow supports dynamic pages based on missing prerequisites.
- When focus mode is missing, wizard shows focus setup steps before the Values CTA page.
- Values CTA page replaces the old review page and supports creating multiple values.
- Clean `flutter analyze`.

## Risks / notes
- Hydration: hierarchy renderer may expect values/projects present; ensure My Day pipeline provides enough entities without reintroducing heavy query coupling.

## AI instructions (required)
- Review `doc/architecture/` before implementing this phase; update docs if this phase changes architecture.
- Run `flutter analyze` during this phase.
- Fix any `flutter analyze` errors/warnings caused by this phase’s changes by the end of this phase.
