
Status: draft
Owner: Codex
Last updated: 2026-01-29

## Summary

Replace the legacy guided tour overlay/preview implementation with a live-screen guided tour powered by `tutorial_coach_mark`. The tour runs on real screens with live anchors while demo data is injected via `DemoModeService` to keep the experience deterministic and safe on empty accounts. Remove demo routes/screens and legacy preview wiring.

## Goals

- Provide a deterministic guided tour on **live screens** with real layouts.
- Keep the tour safe for empty accounts via demo-mode data injection.
- Use `tutorial_coach_mark` for coachmarks and overlays.
- Remove demo routes/screens plus legacy overlay/target registry/preview wiring.
- Maintain BLoC-only application state boundaries.
- Keep Taskly UI packages pure UI (no domain access).
- Ensure guided tour flow remains accessible from Settings and onboarding auto-start.

## Non-Goals

- Do not persist or mutate real domain data during the tour.
- Do not modify core data models or storage schemas.
- Do not change global navigation structure; tour uses existing routes.
- Do not introduce non-BLoC state for app-level tour flow.
- Do not introduce demo-only routes or demo-only screen widgets.

## Architecture Constraints (from invariants)

- Widgets/pages must not call repositories/services directly.
- Widgets/pages must not subscribe to domain/data streams directly.
- Shared UI remains in `packages/taskly_ui` and stays UI-only.
- Guided tour state remains in BLoC.

## User Experience (Full Screen Option B)

The guided tour uses the **live screens** for each step. Coachmarks are overlaid on the real UI elements. Some steps are full-screen concept cards (no target highlight), rendered as full-screen overlays.

The tour is deterministic by enabling demo-mode data while active, so the same demo content appears regardless of user data.

### Tour Sequence (Final)

1. Welcome (card)
2. Projects overview (card)
3. Add via FAB (coachmark)
4. Inbox capture (coachmark)
5. Task project + value (coachmark)
6. Project detail (card)
7. Values framing (card)
8. Values list focus (coachmark)
9. Routines overview (card)
10. Scheduled horizon (coachmark)
11. Plan My Day entry (coachmark)
12. Plan My Day - time sensitive (coachmark)
13. Plan My Day - scheduled routines (coachmark)
14. Plan My Day - flexible routines (coachmark)
15. Plan My Day - value picks (coachmark)
16. Plan My Day - summary (card)
17. My Day summary (card)
18. My Day focus list (coachmark)
19. Finish (card)

## Copy (Final)

Use the following copy in the tour steps:

1) Welcome
- Title: "Welcome to Taskly"
- Body: "You are seeing a demo workspace for this tour. You will return to your real tasks when the tour ends."

2) Projects overview (card)
- Title: "Build your project list"
- Body: "Projects is the source for today's plan in My Day."

3) Add via FAB (coachmark)
- Title: "Add tasks here..."
- Body: "Use the + button to add a project or task from anywhere."

4) Inbox capture (coachmark)
- Title: "Inbox for capture"
- Body: "Capture now, organize later. Move tasks into projects when you are ready."

5) Task project + value (coachmark)
- Title: "Set the project"
- Body: "Set the project to connect this task to a value. Taskly uses that to suggest the right work. You can also add extra values to a task."

6) Project detail (card)
- Title: "Projects hold the work"
- Body: "Open a project to see its tasks, deadlines, and priorities in one place."

7) Values framing (card)
- Title: "Values guide your focus"
- Body: "Values shape your weekly ratings and help you choose what matters most."

8) Values list (coachmark)
- Title: "Define what matters"
- Body: "Add a few values so Taskly can recommend the right tasks and routines."

9) Routines overview (card)
- Title: "Routines build momentum"
- Body: "Routines can be flexible or scheduled. Use them to keep progress steady."

10) Scheduled horizon (coachmark)
- Title: "Scheduled looks ahead"
- Body: "See upcoming tasks by date so nothing sneaks up on you."

11) Plan My Day entry (coachmark)
- Title: "Plan My Day"
- Body: "Review suggestions and pick the tasks you want to focus on today."

12) Plan My Day - time sensitive (coachmark)
- Title: "Time-sensitive tasks"
- Body: "Review overdue and due-today items and choose what you'll handle now."

13) Plan My Day - scheduled routines (coachmark)
- Title: "Scheduled routines"
- Body: "Pick the scheduled habits you're committing to today."

14) Plan My Day - flexible routines (coachmark)
- Title: "Flexible routines"
- Body: "Pick flexible routines to make progress on your weekly targets."

15) Plan My Day - value picks (coachmark)
- Title: "Value-based tasks"
- Body: "Add tasks that support your values. Suggestions follow your weekly value ratings."

16) Plan My Day - summary (card)
- Title: "Review and confirm"
- Body: "Review your selections and confirm today's plan."

17) My Day summary (card)
- Title: "Your plan for today"
- Body: "Here is the list you just chose, mixing tasks and routines."

18) My Day focus list (coachmark)
- Title: "Today's focus list"
- Body: "This is the short list you commit to. Keep it realistic and move what is done to completed."

19) Finish
- Title: "You are ready"
- Body: "The tour is done. Open Settings > Guided tour to replay it."

## Demo Data Requirements

While the tour runs on live screens, demo data must be injected via
`DemoModeService` + `DemoDataProvider` so the experience is deterministic and
safe on empty accounts. Live screens should consume demo data through their
normal presentation services/BLoCs (not demo-only widgets).

### Demo Projects
- Inbox (special)
- "Japanese Basics"
- "Photography Practice"
- "Gym Routine"
- "Dinner Party Menu"
- "Studio Jam Demo"

### Demo Inbox Tasks
- "Renew gym membership"
- "Create country flashcards"
- "Schedule photo walk"
- "Draft grocery list for new recipe"
- "Watch 1 lesson video"

### Demo Values
- "Learning"
- "Health"
- "Social"

### Demo Routines
- "Gym session"
- "Weekly photo share"
- "15-min vocab drill"
- "20-min guitar practice"

### Demo Project Detail Tasks (Japanese Basics)
- "Complete Lesson 3" (deadline + priority)
- "Review Hiragana" (deadline + priority)
- "Create country flashcards" (deadline + priority)

### Demo My Day Picks
- "15-min vocab drill"
- "Gym session"
- "Complete Lesson 3"
- "Edit 10 photos"
- "Learn intro riff"

### Demo Scheduled
- Today: "Gym session"
- Tomorrow: "Weekly photo share"
- Later: "Create country flashcards"

### Demo Plan My Day
- Time sensitive: due and planned sections with 2 selected examples
- Scheduled routines: 1 selected, 1 unselected
- Flexible routines: 1 selected, 1 unselected (with progress captions)
- Values focus: learning tasks with one selected
- Summary: mixed tasks and routines

## Routing and Navigation

Use existing authenticated routes (no demo-only routes):

- `/projects`
- `/task/new`
- `/project/inbox/detail`
- `/values`
- `/routines`
- `/scheduled`
- `/my-day`

Plan My Day steps are driven inside the `/my-day` screen by the `GuidedTourBloc`
state (switching the My Day page into plan mode and selecting the appropriate
step).

## Guided Tour Flow (BLoC + Host)

### BLoC
- Keep existing `GuidedTourBloc` as the source of truth for steps.
- Update `buildGuidedTourSteps()` to use live routes and new step IDs/copy.
- Steps must include metadata needed by the host to build coachmark targets:
  - `step.id`
  - `step.route`
  - `step.kind` (card or coachmark)
  - `step.coachmark.targetId` (only for coachmarks)
- When the tour starts, enable demo mode; disable it on finish/skip.
- Guardrails:
  - Auto-disable demo mode on app background/paused.
  - Abort and disable demo mode if a step cannot resolve (route/anchor/plan).
  - Use a watchdog timeout to avoid stuck demo mode in-session.

### Host (Overlay Controller)
- Replace the legacy overlay with a new host that:
  - listens to BLoC for current step
  - navigates to `step.route` when the step changes
  - shows a `TutorialCoachMark` overlay when active
  - uses full-screen card targets for card steps
- The host must handle showing, advancing, skipping, and finishing.

### Coachmark Targets

Target IDs and anchors:
- `projects_create_project`
- `projects_inbox_row`
- `task_project_value`
- `values_list`
- `scheduled_section_today`
- `my_day_plan_button`
- `plan_my_day_triage`
- `plan_my_day_routines_scheduled`
- `plan_my_day_routines_flexible`
- `plan_my_day_values_card`
- `my_day_focus_task_1`

## Live Screen Anchors

Anchors are added to existing screens (no demo pages). Each target ID maps to a
stable widget key on the live screen:

- `projects_create_project` → Projects add FAB/speed dial
- `projects_inbox_row` → Projects inbox row
- `task_project_value` → Task editor project/value section
- `values_list` → first Values list row
- `scheduled_section_today` → Scheduled “Today” section
- `my_day_plan_button` → My Day “Plan My Day” button
- `plan_my_day_triage` → Plan My Day triage step container
- `plan_my_day_routines_scheduled` → Plan My Day scheduled routines header
- `plan_my_day_routines_flexible` → Plan My Day flexible routines header
- `plan_my_day_values_card` → first Plan My Day values card
- `my_day_focus_task_1` → first My Day focus row

## Concept Cards (Full Screen)

Concept cards are full-screen overlays rendered inside tutorial_coach_mark using a full-screen target and a centered card UI with the copy above.

Card layout guidelines:
- Use Taskly tokens for spacing
- Respect safe areas
- Provide explicit Next/Back actions within the card
- Provide Skip as a secondary action

## Legacy Removal

Remove the following legacy components and all wiring:

- `guided_tour_targets.dart`
- `guided_tour_previews.dart`
- legacy overlay logic in `guided_tour_overlay.dart`
- any `GuidedTourTarget` usage in live screens
- any preview card logic tied to the old flow
- demo-only guided tour routes and demo screen widgets

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
- Update/repair mocks as needed for final class constraints.

## Risks and Mitigations

- Risk: tutorial_coach_mark throws NotFoundTargetException if a key is missing.
  - Mitigation: ensure each live screen has the correct key and is mounted before showing overlay.

- Risk: overlay stacks with modal/route transitions.
  - Mitigation: schedule tutorial show after navigation via post-frame, and reuse one overlay per step.

- Risk: tests fail due to final class mocks.
  - Mitigation: replace mocks with fakes or wrap usage in adapters for tests, or mock via repository/service contracts instead.

## Rollout Plan

1) Wire guided tour demo mode on start/finish and add live-screen anchors.
2) Update GuidedTour steps and copy to use live routes.
3) Replace overlay host with tutorial_coach_mark host.
4) Add live-screen anchors.
5) Remove demo routes/screens and legacy guided tour targets/previews.
6) Update tests and mocks.
7) Run `dart analyze` and guided tour regression tests.

## File Checklist

- Update:
  - `lib/presentation/features/guided_tour/model/guided_tour_step.dart`
  - `lib/presentation/features/guided_tour/view/guided_tour_overlay.dart`
  - `lib/presentation/routing/router.dart`
  - `doc/architecture/specs/GUIDED_TOUR_MIGRATION.md`

- Add:
  - `lib/presentation/features/guided_tour/guided_tour_anchors.dart`

- Remove:
  - `lib/presentation/features/guided_tour/view/guided_tour_targets.dart`
  - `lib/presentation/features/guided_tour/view/guided_tour_previews.dart`
  - `lib/presentation/features/guided_tour/demo/`
  - GuidedTourTarget usage in live screens

## Open Questions

- Confirm final tour copy and step order.
- Confirm exact targets for each coachmark and their UI anchor widgets.
- Confirm if demo mode should be marked as "tour" mode for analytics.
