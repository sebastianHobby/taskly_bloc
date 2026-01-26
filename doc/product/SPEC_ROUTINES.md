# Spec: Routines (Plan My Day)

Created at: 2026-01-26
Status: Draft
Owner: TBD

## Summary

Add a Routines step to the Plan My Day wizard within a 4-step flow (Values,
Routines, Urgent/Planned, Summary). Routines are separate from the suggestion
engine, but an optional setting can count routine selections against value
quotas for suggestions. Routines selected for today are stored in
my_day_picks using routine_id (planned pick, not completion).
The allocation engine must not output routines as suggestions.

## Goals

- Show routines every day in Plan My Day with clear target and remaining info.
- Keep UX calm and supportive (no prompts or warnings).
- Allow routines without projects (value is required).
- Keep routines out of Scheduled view.
- Report routine analytics separately from task stats.
- Show routine picks in the My Day list for today (distinct look vs tasks).

## Non-goals

- Do not turn routines into alerts or deadline warnings.
- Do not add prompts or banners outside Plan My Day.
- Do not require routines to belong to projects.

## UX Overview

### Plan My Day Wizard (4-step flow)

Steps:
1) Values picks (purely value-based suggestions)
2) Routines (as defined below)
3) Urgent/Planned not selected so far
4) Summary (single list with source badges)

Steps auto-hide when empty. Users select from curated flow presets:
- Values first: Values -> Routines -> Urgent -> Summary
- Routines first: Routines -> Values -> Urgent -> Summary
- Triage first: Urgent -> Values -> Routines -> Summary

#### Routines step ("This week's routines")

Each routine card shows:
- Target: "3x/week" or "1x/month"
- Remaining: "2 left"
- Window: "4 days left (Mon-Sun)" or "Window: this week / next week / later this month"
- Status chip: "On pace" / "Tight week" / "Catch-up window"

Primary action:
- "Do today" (adds a planned pick for today; does not mark completion)

Secondary actions:
- "Not today" (hide until tomorrow)
- "Later this week" (hide until next recommended day; see logic below)
- "Skip this week" (sets remaining = 0 and marks status as "Rest week")
- "Pause routine" (hide until resumed)
- "Edit schedule"

Step 2: "Suggested tasks"

Show a small summary line:
- "Routines selected today: X"
- If value slot counting is enabled: "Reserving Y value slots"

#### Urgent/Planned step

- Show items that are urgent or planned but not selected yet.
- This step does not include items already selected in previous steps.

#### Summary step (Option S2)

- One list of selected tasks (no buckets).
- Each item shows a small source badge: Values / Routine / Urgent.
- Users can remove items from the list.
- The same source badge appears in the My Day list after confirmation.

#### My Day list behavior (after the ritual)

- Routine picks appear in the My Day list as "routine" items (distinct visual
  style from tasks, but same list).
- Routine picks are planned work. Completion happens when the user marks the
  routine done in My Day, which creates a routine_completions row and updates
  remaining counts.
- Completed routines remain visible in the My Day list for the day (completed
  state).

### Monthly routines (Option M1)

Always visible in the routine list, with a window label:
- "Window: this week" (highlighted softly)
- "Window: next week"
- "Window: later this month"

No prompts or warnings. Highlight only when window is current.

## Recurrence Options

Week starts Monday.

Weekly fixed days:
- Pick days (Mon-Sun)

Weekly flexible:
- Target count 1-7 per week
- Optional rest day buffer 0-2

Monthly flexible:
- Target count 1-4 per month
- Preferred weeks (Week 1, Week 2, Week 3, Week 4, or last week)

Monthly fixed:
- Nth weekday (for example, 1st Saturday)
- Or exact date (1-31)

## Pacing and Status Logic

Weekly flexible routines:
- Remaining = target - completed this week
- Days left = count of days remaining in the week
- Recommended days are spaced across days left
- Status chip rules:
  - "On pace": remaining <= ceil(daysLeft / spacingGoal)
  - "Tight week": remaining == daysLeft or remaining == daysLeft - 1
  - "Catch-up window": remaining > daysLeft

Weekly fixed routines:
- Remaining = fixed days not completed this week
- Status based on remaining vs days left

Monthly routines:
- Remaining = target - completed this month
- Window label based on preferred week

### Spacing rules (hard vs soft)

- min_spacing_days = hard spacing (cannot recommend before this gap).
  - Example: min_spacing_days = 1 means at least 1 day off between completions.
- rest_day_buffer = soft spacing (try to leave buffer days off, but can break
  the buffer if the user is behind).

### "Later this week" logic (explicit)

Weekly fixed days:
- Next recommended day = next scheduled day in schedule_days.
- Example: Mon/Wed/Fri routine, user taps "Later this week" on Tue -> hide
  until Wed.

Weekly flexible:
- Compute days_left and remaining for this week.
- ideal_spacing = max(1, floor(days_left / remaining)).
- soft_spacing = if rest_day_buffer set, max(1, rest_day_buffer + 1) else 1.
- spacing = ideal_spacing.
- If remaining <= (days_left - rest_day_buffer), spacing = max(spacing, soft_spacing).
- If min_spacing_days is set, spacing = max(spacing, min_spacing_days + 1).
- Next recommended day = today + spacing (cap within the current week).
- Example A: Mon, target 3x/week, remaining 3, days_left 7 -> spacing 2 ->
  hide until Wed.
- Example B: Thu, target 3x/week, remaining 3, days_left 4 -> spacing 1 ->
  hide until Fri.

Monthly flexible:
- If window is "this week": next recommended day is tomorrow.
- If window is "next week" or "later this month": hide until the first day
  of that window.

## Value Slot Interaction (Optional)

Setting:
- "Count routine selections against value quotas" (global allocation setting)

Behavior:
- If enabled, routine selections for today decrement the value quotas used by
  the suggestion engine.
- If disabled, routine selections do not affect suggestion quotas.
- Only routines selected for today are counted (not all routines listed).

## Data Model (Decision Needed)

### Routines storage (Decision: new tables)

Use dedicated routine tables (already created in Supabase schema).

Tables:
- routines: id, name, value_id (required), project_id (optional), type,
  target_count, schedule_days, min_spacing_days, preferred_weeks,
  is_active, created_at, updated_at
- routine_completions: routine_id, completed_at, created_at

### Routine picks in My Day (Decision: R1)

Store routine picks inside my_day_picks using routine_id.

Schema requirements:
- my_day_picks.task_id becomes nullable.
- my_day_picks.routine_id (FK -> routines) is added.
- Constraint: task_id XOR routine_id (one must be set).
- Unique (day_id, task_id) where task_id is not null.
- Unique (day_id, routine_id) where routine_id is not null.
- Enum my_day_pick_bucket adds value "routine".
- Enforce bucket = routine for routine picks in app logic (no DB check).

Pick behavior:
- "Do today" inserts my_day_picks row with routine_id and bucket = routine.
- Completion inserts routine_completions and updates routine counts.
- routine picks set qualifying_value_id = routines.value_id (for value quotas).

## Analytics (Separate)

- Weekly adherence: completed / target
- Consistency: average spacing between completions
- Recovery: time to resume after a skip
- Mood correlation: routine completion days vs mood days (optional)

## Edge Cases

- Skipped week: remaining cleared, status becomes "Rest week"
- Paused routine: hidden until resumed
- Routine without project: allowed, value required
- "Not today": hidden until next day
- "Later this week": hidden until next recommended day

## Open Questions

- None.

## Implementation Status (2026-01-26)

Completed:
- Routine pause semantics: `pausedUntil` is exclusive (routine is paused on day D only if pausedUntil is after D).
- Allocation setting default on: routine selections count 1:1 against value quotas.
- Routine validators updated to allow optional weekly suggested days (validated if present).
- Routine form simplified to weekly/monthly flexible only; monthly fixed removed; suggested days UI added for weekly flexible; spacing inputs removed.
- Routine detail view updated to keep suggested days for weekly flexible.
- Routine tile mapping updated: monthly window label uses period end date; suggested days rendered as badges; “skip” label removed.
- Plan My Day BLoC: routine items filtered to remaining > 0; routine skip event removed.

Remaining:
- Plan My Day UI rewrite to 4-step wizard (Values → Routines → Triage → Summary), auto-skip empty steps, summary shows “No …” lines for skipped sections.
- Plan My Day pause sheet: only “Pause until next window (date)” and “Pick a date”.
- L10n additions for routine + plan-my-day strings; regenerate localizations.
- Legacy Plan My Day card UI removal and unused wiring cleanup after wizard is in place.

## Prompt for Next AI

You are continuing implementation in `c:\Users\User\FlutterProjects\taskly_bloc`.

Goal: finish SPEC_ROUTINES per latest decisions in this chat (these override spec text).

Must-do:
1) Rewrite `lib/presentation/screens/view/plan_my_day_page.dart` into a 4-step wizard driven by `PlanMyDayBloc.steps/currentStep`:
   - Steps: Values, Routines, Triage, Summary; auto-skip empty steps; summary shows “No …” for skipped steps.
   - Remove legacy card UI (time-sensitive banner, pinned/snoozed sections, etc.).
   - Use existing `taskly_ui` feed rows; do not introduce new app-owned section widgets.
2) Implement Plan My Day routine pause sheet with only:
   - “Pause until next window (date)” (compute next window start based on week/month).
   - “Pick a date”.
3) Add missing l10n keys referenced by routines and plan-my-day UI into:
   - `lib/l10n/arb/app_en.arb`
   - `lib/l10n/arb/app_es.arb` (English ok if needed)
   - Run `flutter gen-l10n` after updates.
4) Remove unused/legacy wiring once wizard is live, after confirming it’s unused.
5) Run `dart format` on edited files and `dart analyze` at the end.

Notes:
- BLoC boundary is strict: widgets must not call repositories directly.
- Shared UI changes in `taskly_ui` require explicit approval.
