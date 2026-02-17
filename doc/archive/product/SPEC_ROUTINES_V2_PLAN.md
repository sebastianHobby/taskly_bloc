# Spec Plan: Routines V2 (Daily + Multi-Completion + Monthly Dates)

Created at: 2026-02-12
Status: Implemented
Owner: TBD

## Summary

Introduce daily routines with multiple completions per day, expand monthly
scheduled routines to support multiple dates, and store one preferred time of
day (domain + DB only for v1). Add local day/time completion fields to enable
habit strength stats and day/time insights. UI v1 remains day-only but must
support multi-completion logging.

## Decisions (confirmed)

- Cadence: day, week, month.
- Weekly scheduled routines allow picking specific days of week.
- Monthly scheduled routines allow multiple dates.
- Preferred time of day: single time stored in DB/domain; UI v1 does not expose.
- Daily routines must support multiple completions per day.
- Routines tiles only: apply changes across the app (Routines list, My Day,
  Plan My Day). Tasks/other tiles remain unchanged.
- Single density for routine tiles: one 2-line standard variant. Remove compact
  routine tile variants and remove the density toggle from the Routines list
  page (routine tiles only).
- Leading icon: primary value icon, leading position, two-row height (mock-like);
  remove value meta from routine tiles.
- Weekly scheduled: weekday chips only (no text line); chips show completed vs
  missed vs scheduled, and add an extra chip for completions on unscheduled days.
- Monthly scheduled: "this month" count + next date (e.g., "2/4 this month - Next: 15th").
- Weekly/monthly flexible: "X/Y done - N days left".
- Daily flexible: dots + "Daily goal: Nx" (N from user cadence).
- Action labels: always "Log" / "Done" on routine tiles, except Plan My Day
  picker which keeps +/tick affordance.
- Completed visual: disabled "Done" button with subtle line-through; no highlight.
- Missed chip: low-contrast with icon indicator; completed in primary; upcoming neutral.
- No streak display.
- Routine form: use full-mock frequency controls (segmented Flexible/Scheduled,
  stepper for target count, Repeat dropdown for Daily/Weekly/Monthly).
- Scheduled selection UI: weekly weekday chips + monthly date grid.
- Form layout: bottom CTA for create/edit; remove Active toggle for create;
  keep Active toggle for edit only; delete in overflow on edit.
- Value selector: use large tappable "Why is this important?" card with icon,
  helper text, and chevron (mock style). Apply same pattern to project value
  picker.
- Name field: large text input with inline edit icon and placeholder.
- Reminders: add section only after notifications are implemented; hide for now.
- Target count control: stepper with -/+ and large number.
- Scheduled weekly: large circular weekday chips in a single row.
- Monthly scheduled: 1-31 grid, multi-select, no calendar context.
- Create vs edit: bottom CTA for both create and edit; delete in overflow on edit.
- Defaults: Flexible + Weekly + target=3.
- Scheduled cadence: scheduled applies only to weekly/monthly; daily is always flexible.
- Monthly scheduled target count: inferred from selected dates.
- Plan My Day: daily routines are eligible.
- Validation: inline errors on user interaction; keep Save disabled until valid;
  scroll to first invalid on submit.
- Legacy cleanup: remove `routine_type` from domain/data/presentation; assume
  all user data deleted and migrate schema to `period_type` + `schedule_mode`
  only.
- Routines are project-scoped (no "No project" option). Routine value context
  is derived from the parent project primary value, and routine tile visuals
  remain unchanged.
- Routine project selection reuses the task project picker (search + recents)
  and shows the project primary value in picker rows.
- Routine create flow: project detail preselects the project; global entry
  opens the project picker first.
- FAB behaviors: My Day task-only; Projects add project-only; Project Detail
  task or routine (Inbox task-only); Inbox task-only; Scheduled task-only.

## Implemented data model changes (Supabase + local)

### Routines

New fields:
- period_type: 'day' | 'week' | 'month'
- schedule_mode: 'flexible' | 'scheduled'
- schedule_month_days: int[] (1-31)
- schedule_time_minutes: smallint (0-1439)

Remove routine_type; assume user data deleted and migrate to
period_type + schedule_mode only.

### Routine completions

New fields:
- completed_day_local: date
- completed_time_local_minutes: smallint (0-1439)

Use completed_at (timestamptz) as the source-of-truth timestamp. Local day/time
fields enable accurate day-of-week and time-of-day stats.

### Routine skips

Allow period_type = 'day' to enable daily skip semantics.

## Implemented domain changes

### Models

- Routine: add periodType, scheduleMode, scheduleMonthDays, scheduleTimeMinutes.
- RoutineCompletion: add completedDayLocal, completedTimeLocal.

### Schedule + eligibility

- RoutineScheduleService: add day-period snapshot support and scheduled-month
  date evaluation.
- RoutineDayPolicy (presentation helper): day-based eligibility and multi-day
  completion rules (daily routines always eligible until target met).

### Commands + validators

- Extend routine form validators and draft handling for new cadence/schedule
  fields, multi-date monthly schedules, and daily target counts.

## Implemented data layer changes

### PowerSync schema

Update `packages/taskly_data/lib/src/infrastructure/powersync/schema.dart`
for new columns in routines and routine_completions.

### Drift schema + mapper

Update `packages/taskly_data/lib/src/infrastructure/drift/drift_database.dart`,
regenerate `drift_database.g.dart`, and update
`packages/taskly_data/lib/src/mappers/drift_to_domain.dart`.

### Repository

Update `packages/taskly_data/lib/src/repositories/routine_repository.dart` to
read/write new columns and to persist local day/time for completions.

## Implemented presentation changes (UI v1)

### Routines list

- Add daily cadence display with multi-completion affordance.
- For monthly scheduled routines, display multiple dates (e.g., "1st, 15th").
- Keep preferred time hidden for v1.
- Remove routine density toggle; routine tiles are single standard density.
- Leading primary value icon replaces value meta row.
- Weekly scheduled tiles show chips only (no text) with missed/completed states.
- Monthly scheduled uses "this month" count + next date in action line.

### My Day + Plan My Day

- Ensure daily routines can be picked and logged multiple times per day.
- Daily routines appear in Plan My Day by default.
- Plan My Day routine picker retains +/tick affordance (no Log button).
- Routine tiles use the same single-density 2-line layout everywhere.

## Stats and habit strength

### Metrics (initial set)

- Completion rate per period (daily/weekly/monthly).
- Consistency score (variance of completion gaps).
- Day-of-week distribution and strongest days.
- Time-of-day distribution (future UI).
- No streaks in UI.

### Storage

- Use `analytics_snapshots.metrics` for routine stats.
- Optional: add routine-specific snapshot keys (e.g., `habit_strength`,
  `dow_histogram`, `tod_histogram`, `consistency_score`).

## UX/design tasks (to be decided)

- Routine tile layout changes (resolved; see Decisions above).
- Multi-completion UI (counter vs log sheet).
- Today-focused vs all-routines list framing.

## Documentation updates

- Update `doc/product/ROUTINES_CONCEPT.md`.
- Update `doc/product/SPEC_ROUTINES.md` with new cadence and stats behaviors.
- Update `doc/architecture/deep_dives/MY_DAY_PLAN_MY_DAY.md` if daily routine
  selection changes the ritual flow.

## Testing (expected)

- Domain unit tests for daily/monthly scheduling and multi-date evaluation.
- Data tests for repository persistence of new fields.
- Presentation tests for routine list + My Day logging behavior.

## Rollout

- Phase 1: schema + domain + data changes, UI v1 (day-only).
- Phase 2: time-of-day UI + prompts based on habit strength signals.

## Open questions

- None (all current decisions resolved).


