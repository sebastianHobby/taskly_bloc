# Guided Tour Migration (Tutorial Coach Mark + Demo Data)

Status: draft
Owner: Codex
Last updated: 2026-01-28

## Summary

Replace the legacy guided tour overlay/preview implementation with a full-screen, demo-data-backed guided tour powered by `tutorial_coach_mark`. The tour must be safe on empty accounts and must show the same demo content for all users regardless of their real data. Remove legacy guided tour targets/preview cards and update routing, UI, and tests.

## Goals

- Provide a deterministic, full-screen guided tour that always shows demo data.
- Keep the tour safe for empty accounts and consistent for all users.
- Use `tutorial_coach_mark` for coachmarks and overlays.
- Remove legacy guided tour overlay/target registry/preview card wiring.
- Maintain BLoC-only application state boundaries.
- Keep Taskly UI packages pure UI (no domain access).
- Ensure guided tour flow remains accessible from Settings and onboarding auto-start.

## Non-Goals

- Do not persist or mutate real domain data during the tour.
- Do not modify core data models or storage schemas.
- Do not change global navigation structure beyond adding tour routes.
- Do not introduce non-BLoC state for app-level tour flow.

## Architecture Constraints (from invariants)

- Widgets/pages must not call repositories/services directly.
- Widgets/pages must not subscribe to domain/data streams directly.
- Shared UI remains in `packages/taskly_ui` and stays UI-only.
- Guided tour state remains in BLoC.

## User Experience (Full Screen Option B)

The guided tour uses full-screen demo screens for each step. Coachmarks are overlaid on the demo screen elements. Some steps are full-screen “concept cards” (no target highlight), rendered as full-screen overlays.

The tour is always deterministic and shows the same demo data for all users. It never depends on actual user content.

### Tour Sequence (Final)

1. Welcome (card)
2. Anytime overview (coachmark)
3. Inbox capture (coachmark)
4. Values framing (card)
5. Values list focus (coachmark)
6. Routines focus (coachmark)
7. Plan My Day entry (coachmark)
8. My Day focus list (coachmark)
9. Scheduled horizon (coachmark)
10. Finish (card)

## Copy (Final)

Use the following copy in the tour steps:

1) Welcome
- Title: "Welcome to Taskly"
- Body: "You are seeing a demo workspace so every tour looks the same. You will return to your real tasks when the tour ends."

2) Anytime (coachmark)
- Title: "Anytime is your home base"
- Body: "Everything starts here. Projects group related tasks so My Day can pull the right work forward."

3) Inbox (coachmark)
- Title: "Inbox for capture"
- Body: "Drop tasks here fast. Sort and organize them into projects when you are ready."

4) Values (card)
- Title: "Values guide your focus"
- Body: "Values keep your days balanced. They shape suggestions and help you choose what matters most."

5) Values list (coachmark)
- Title: "Define what matters"
- Body: "Add a few values so Taskly can recommend the right tasks and routines."

6) Routines (coachmark)
- Title: "Routines build momentum"
- Body: "Create habits tied to values. They can show up when you plan your day."

7) Plan My Day (coachmark)
- Title: "Plan My Day"
- Body: "Review suggestions and pick the tasks you want to focus on today."

8) My Day focus list (coachmark)
- Title: "Today’s focus list"
- Body: "This is the short list you commit to. Keep it realistic and move what is done to completed."

9) Scheduled
- Title: "Scheduled looks ahead"
- Body: "See upcoming tasks by date so nothing sneaks up on you."

10) Finish
- Title: "You are ready"
- Body: "The tour is done. Open Settings > Guided tour anytime to replay it."

## Demo Data Requirements

All tour screens must render from static demo data (no repositories).

### Demo Projects
- Inbox (special)
- "Website Refresh"
- "Spring Routine"

### Demo Tasks
- "Draft homepage copy" (project: Website Refresh)
- "Review sitemap" (project: Website Refresh)
- "Buy protein bars" (project: Spring Routine)
- "Water plants" (project: Spring Routine)

### Demo Inbox Tasks
- "Book dentist appointment"
- "Read Deep Work"
- "Schedule laptop repair"

### Demo Values
- "Focus"
- "Health"
- "Relationships"
- "Creativity"

### Demo Routines
- "Morning walk"
- "Weekly review"
- "Call a friend"

### Demo My Day Picks
- "Draft homepage copy"
- "Morning walk"
- "Review sitemap"

### Demo Scheduled
- Today: "Weekly review"
- Tomorrow: "Schedule laptop repair"
- Later: "Call a friend"

## Routing & Navigation

Add explicit demo routes under the authenticated shell:

- `/tour/anytime`
- `/tour/inbox`
- `/tour/values`
- `/tour/routines`
- `/tour/my-day`
- `/tour/scheduled`

These routes should map to demo-only pages. They should not affect navigation highlights or shell behavior outside the tour. The shell should map `/tour/<screen>` to the corresponding activeScreenId so the correct nav item is highlighted during the tour.

## Guided Tour Flow (BLoC + Host)

### BLoC
- Keep existing `GuidedTourBloc` as the source of truth for steps.
- Update `buildGuidedTourSteps()` to use the new demo routes and new step IDs/copy.
- Steps must include metadata needed by the host to build coachmark targets:
  - `step.id`
  - `step.route`
  - `step.kind` (card or coachmark)
  - `step.coachmark.targetId` (only for coachmarks)

### Host (Overlay Controller)
- Replace the legacy overlay with a new host that:
  - listens to BLoC for current step
  - navigates to `step.route` when the step changes
  - shows a `TutorialCoachMark` overlay when active
  - uses full-screen card targets for card steps
- The host must handle showing, advancing, skipping, and finishing.

### Coachmark Targets
- Use `GlobalKey` anchors for each target in demo screens.
- Centralize keys in a `GuidedTourAnchors` class with stable IDs.

Example target IDs:
- `anytime_create_project`
- `inbox_quick_add`
- `values_add_value`
- `routines_add`
- `my_day_plan_button`
- `my_day_focus_task_1`
- `scheduled_section_today`

## Demo Screens (Full Screen)

Create demo screens under `lib/presentation/features/guided_tour/demo/` using `TasklyFeedRenderer` and Taskly UI models to compose static rows.

Each screen must:
- be a self-contained widget
- render static TasklyFeedSpec data
- expose coachmark target keys on relevant widgets
- avoid any repo/service or stream subscriptions

### Demo Anytime Screen
- Use a standard list section with project rows
- Include a floating action button (or speed dial) anchored for coachmark

### Demo Inbox Screen
- Use task rows for inbox entries
- Anchor a quick-add button for coachmark

### Demo Values Screen
- Use value rows; anchor an add button for coachmark

### Demo Routines Screen
- Use routine rows; anchor add action

### Demo My Day Screen
- Show a "Plan My Day" button and a list of focus tasks
- Anchor plan button and first task row

### Demo Scheduled Screen
- Use scheduled day sections (Today/Tomorrow/Later)
- Anchor the Today section header or first row

## Concept Cards (Full Screen)

Concept cards are full-screen overlays rendered inside tutorial_coach_mark using a full-screen `TargetPosition` and a centered card UI with the copy above.

Card layout guidelines:
- Use Taskly tokens for spacing
- Respect safe areas
- Provide explicit "Next" and "Back" actions within the card
- Provide "Skip" as a secondary action

## Legacy Removal

Remove the following legacy components and all wiring:

- `guided_tour_targets.dart`
- `guided_tour_previews.dart`
- legacy overlay logic in `guided_tour_overlay.dart`
- any `GuidedTourTarget` usage in live screens
- any preview card logic tied to the old flow

## Testing Strategy

### Unit Tests
- Update guided tour bloc tests for new steps and routes.

### Widget Tests
- Replace existing guided tour overlay widget test with a test that ensures:
  - tour host navigates to the demo route when activated
  - tutorial overlay is shown for a coachmark step

### Regression
- Run `dart analyze` after changes.
- Run guided tour tests and any other impacted tests.
- Update/repair mocks as needed for final class constraints (OccurrenceReadService, ProjectWriteService, ValueRatingsWriteService).

## Risks & Mitigations

- Risk: tutorial_coach_mark throws NotFoundTargetException if a key is missing.
  - Mitigation: ensure each demo screen has the correct key and is mounted before showing overlay.

- Risk: overlay stacks with modal/route transitions.
  - Mitigation: schedule tutorial show after navigation via post-frame, and reuse one overlay per step.

- Risk: tests fail due to final class mocks.
  - Mitigation: replace mocks with fakes or wrap usage in adapters for tests, or mock via repository/service contracts instead.

## Rollout Plan

1) Add demo routes and demo screen widgets.
2) Update GuidedTour steps and copy.
3) Replace overlay host with tutorial_coach_mark host.
4) Remove legacy guided tour targets/previews.
5) Update tests and mocks.
6) Run `dart analyze` and guided tour regression tests.

## File Checklist

- Update:
  - `lib/presentation/features/guided_tour/model/guided_tour_step.dart`
  - `lib/presentation/features/guided_tour/view/guided_tour_overlay.dart`
  - `lib/presentation/routing/router.dart`

- Add:
  - `lib/presentation/features/guided_tour/demo/` (new demo screen widgets)
  - `lib/presentation/features/guided_tour/demo/guided_tour_anchors.dart`

- Remove:
  - `lib/presentation/features/guided_tour/view/guided_tour_targets.dart`
  - `lib/presentation/features/guided_tour/view/guided_tour_previews.dart`
  - GuidedTourTarget usage in live screens

## Open Questions

- Confirm final tour copy and step order (this doc assumes current agreed copy).
- Confirm exact targets for each coachmark and their UI anchor widgets.
- Confirm if demo screens should be marked as "tour" mode for analytics.

