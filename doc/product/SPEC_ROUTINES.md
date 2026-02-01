# Spec: Routines (Plan My Day)

Created at: 2026-01-26
Status: Implemented (core flow), with deferred actions
Owner: TBD

## Summary

Add a Routines step to the Plan My Day wizard within a 4-step flow (Values,
Routines, Urgent/Planned, Summary). Routines are separate from the suggestion
engine, but an optional setting can count routine selections against value
quotas for suggestions. Routines selected for today are stored in
my_day_picks using routine_id (planned pick, not completion).
The allocation engine must not output routines as suggestions.

## Goals

- Show routines when they are eligible for today with clear target and
  remaining info.
- Keep UX calm and supportive (no prompts or warnings).
- Routines are linked to values only (value is required).
- Keep routines out of Scheduled view.
- Report routine analytics separately from task stats.
- Show routine picks in the My Day list for today (distinct look vs tasks).

## Non-goals

- Do not turn routines into alerts or deadline warnings.
- Do not add prompts or banners outside Plan My Day.

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

Routines are presented in two panels:
- Scheduled Today (weekly scheduled routines)
- Flexible Focus (weekly/monthly flexible routines)

Panel limits and "Show more":
- Scheduled Today shows up to 3 items, then "Show more (X)".
- Flexible Focus shows up to 4 items, then "Show more (X)".

Each routine row shows:
- Cadence prefix: "Scheduled" or "Flexible" on the meta line.
- Target: "3x/week" or "1x/month"
- Remaining: "2 left"
- Window: "4 days left (Mon-Sun)" or "Window ends {date}"
- Status chip: "On track" or "Catch-up day"
- Supportive line on catch-up days: "Small steps still count."

Primary action:
- Picker icon (adds a planned pick for today; does not mark completion)

Secondary actions:
- "Pause routine" (hide until resumed)
- "Edit schedule"

Deferred (not implemented in the current flow):
- "Not today" (hide until tomorrow)
- "Later this week" (hide until next recommended day; see logic below)
- "Skip this week" (sets remaining = 0 and marks status as "Rest week")

Routines step summary lines are intentionally not shown.

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
- My Day lists routines and tasks inline (no value headers).

#### Routines list (backlog)

- Always shows all routines regardless of today/window.
- Grouped by Scheduled vs Flexible.
- Uses cadence prefix in the meta line.

### Monthly routines (Option M1)

Monthly routines are flexible only and always visible within the month, with a
window label:
- "Window ends {date}" with days remaining.

No prompts or warnings.

## Recurrence Options

Week starts Monday.

Weekly scheduled days:
- Pick days (Mon-Sun)

Weekly flexible:
- Target count 1-7 per week
- Optional suggested days (weekly only)
- Suggested days are not shown as badges on routine tiles.

Monthly flexible:
- Target count 1-4 per month
- Preferred weeks (Week 1, Week 2, Week 3, Week 4, or last week)
- No suggested days UI

## Pacing and Status Logic

Weekly flexible routines:
- Remaining = target - completed this week
- Days left = count of days remaining in the week
- Recommended days are spaced across days left (spacing as a floor)
- Status chip rules:
  - "On track": remaining <= daysLeft
  - "Catch-up day": remaining > daysLeft

Weekly scheduled routines:
- Remaining = fixed days not completed this week
- Status based on remaining vs days left

Monthly routines:
- Remaining = target - completed this month
- Always visible within the month
- Status:
  - "On track" when remaining fits the days left
  - "Catch-up day" when remaining > days left

### Spacing rules (hard vs soft)

- min_spacing_days = hard spacing (cannot recommend before this gap).
  - Example: min_spacing_days = 1 means at least 1 day off between completions.
- rest_day_buffer = soft spacing (try to leave buffer days off, but can break
  the buffer if the user is behind).

### Suggested days vs spacing (weekly flexible)

- Suggested days are preferred only when they respect spacing.
- If a suggested day is earlier than the next recommended day, skip it.
- If no suggested day fits, use the next recommended day.

### Catch-up behavior (B3)

- Missed = not completed by end of local day.
- After a miss, show the routine daily until the next recommended day.
- If still missed on the next recommended day, hide until the following
  recommended day.
- Never show a routine twice on the same day.

### Scheduled weekly catch-up

- Scheduled days are the primary rhythm.
- If a scheduled day is missed, show the routine on each day until the next
  scheduled day.
- The next scheduled day counts as the next occurrence (the missed occurrence
  remains missed even if completed late).

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

## Value Slot Interaction

Routine selections for today decrement the value quotas used by the suggestion
engine. Only routines selected for today are counted (not all routines listed).

## Data Model (Decision Needed)

### Routines storage (Decision: new tables)

Use dedicated routine tables (already created in Supabase schema).

Tables:
- routines: id, name, value_id (required), type,
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
- Selecting a routine for today inserts my_day_picks row with routine_id and bucket = routine.
- Completion inserts routine_completions and updates routine counts.
- routine picks set qualifying_value_id = routines.value_id (for value quotas).

## Analytics (Separate)

- Weekly adherence: completed / target
- Consistency: average spacing between completions
- Recovery: time to resume after a skip
- Mood correlation: routine completion days vs mood days (optional)
- Scheduled lateness: on-time vs late completion (future)

## Edge Cases

- Skipped week: remaining cleared, status becomes "Rest week"
- Paused routine: hidden until resumed
- "Not today": hidden until next day
- "Later this week": hidden until next recommended day

## Sorting & Limits (Plan My Day)

Scheduled Today:
- Show up to 3 items, then "Show more (X)".
- Sorting:
  1) Catch-up first
  2) Value priority (break ties within catch-ups)
  3) Last scheduled day (oldest missed first)
  4) Name

Flexible Focus:
- Show up to 4 items, then "Show more (X)".
- Sorting:
  1) Fewest days left
  2) Remaining count (highest first)
  3) Value priority
  4) Name

## Future Enhancements

- Daily target count (multiple times per day) cadence (e.g., brush teeth 2x/day).
- Catch-up light version suggestions (micro-goals such as 10-minute gym or
  5-minute walk) when behind.
- Option to remove spacing and rely on flexible daily visibility.

## Open Questions

- None.

## Implementation Status (2026-01-27)

Completed:
- Routine pause semantics: `pausedUntil` is exclusive (routine is paused on day D only if pausedUntil is after D).
- Allocation setting default on: routine selections count 1:1 against value quotas.
- Routine validators updated to allow optional weekly suggested days (validated if present).
- Routine form simplified to weekly/monthly flexible only; monthly fixed removed; suggested days UI added for weekly flexible; spacing inputs removed.
- Routine detail view updated to keep suggested days for weekly flexible.
- Routine tile mapping updated: monthly window label uses period end date; suggested days rendered as badges; "skip" label removed.
- Plan My Day BLoC: routine items filtered to remaining > 0; routine skip event removed.
- Plan My Day UI rewritten to 4-step wizard (Values -> Routines -> Triage -> Summary), auto-skip empty steps, summary shows "No ..." lines for skipped sections.
- Plan My Day pause sheet limited to "Pause until next window (date)" and "Pick a date" (monthly uses start of next month).
- L10n additions for routine + plan-my-day strings; localizations regenerated.
- Legacy Plan My Day card UI removed (wizard is now the only flow).

Remaining:
- Optional: add "Not today" / "Later this week" / "Skip this week" actions if re-scoped.
- Optional: add routines step summary line ("Routines selected today" / "Reserving Y value slots") if re-scoped.

## Prompt for Next AI

You are continuing implementation in `c:\Users\User\FlutterProjects\taskly_bloc`.

Goal: optional follow-ups only (see Remaining).

Must-do (optional, if re-scoped):
1) Add "Not today" / "Later this week" / "Skip this week" actions.
2) Add routines step summary line for routine counts/value slots.

Notes:
- BLoC boundary is strict: widgets must not call repositories directly.
- Shared UI changes in `taskly_ui` require explicit approval.
