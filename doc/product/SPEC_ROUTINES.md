# Spec: Routines V2 (Daily + Scheduled Dates)

Created at: 2026-01-26
Updated at: 2026-02-12
Status: Implemented
Owner: TBD

## Summary

Routines are value-linked practices with daily, weekly, or monthly cadence.
They support flexible targets or scheduled days/dates, multi-completion for
daily routines, and consistent tile presentation across the app. Plan My Day
can pick routines for today, but does not mark completions.

## Goals

- Make cadence and progress clear in a two-line routine tile.
- Support daily routines with multiple completions per day.
- Support weekly scheduled day picks and monthly scheduled date picks.
- Keep the UI calm and supportive (no streaks, no warning banners).
- Make routine actions consistent across all surfaces.

## Non-goals

- No reminders UI until notifications are implemented.
- No streak displays or competitive mechanics.
- No legacy routine_type support or migration.

## Cadence and schedule model

- period_type: day | week | fortnight | month
- schedule_mode: flexible | scheduled
- Daily is always flexible (scheduled not offered).
- Fortnight is flexible-only.
- Weekly/monthly can be flexible or scheduled.

Week window convention (canonical):
- Weekly routine windows use local date semantics.
- Week starts on Monday and ends on Sunday.
- Weekly period key/window key is the Monday date for that week.
- Fortnight windows use local date semantics and are Monday-anchored 14-day windows.
- Fortnight period key/window key is the first Monday of that 14-day window.

Target counts:
- Daily flexible: user selected target (1-10) per day.
- Weekly flexible: target (1-7) per week.
- Fortnight flexible: target (1-14) per fortnight.
- Monthly flexible: target (1-31) per month.
- Monthly scheduled: target inferred from selected dates.

## Routine tiles (single density)

Routines use one standard 2-line tile everywhere (no compact variant).
Primary value icon is leading and 2 rows tall.

Line 1 (title line):
- Value icon + routine name.

Line 2 (action line only):
- Weekly scheduled: weekday chips only.
  - Completed vs missed vs upcoming states.
  - If completed on an unscheduled day, add a chip with day initial and a
    small marker (e.g., T*).
- Monthly scheduled: "X/Y this month - Next: 15th".
- Weekly/monthly flexible: "X/Y done - N days left".
- Daily flexible: dot row + "Daily goal: Nx".

Primary action label:
- Always "Log" / "Done" (except Plan My Day picker uses +/tick).

## Create/Edit routine form

- Segmented control: Flexible / Scheduled.
- Repeat dropdown: Daily / Weekly / Monthly.
- Target stepper with -/+ and large number.
- Scheduled weekly: circular weekday chips in one row.
- Scheduled monthly: 1-31 grid, multi-select, no calendar context.
- Value picker: large card with icon, prompt, helper text, chevron.
- Name field: large input with inline edit icon and placeholder.
- Create/edit uses bottom CTA; delete in overflow (edit only).
- Active toggle: edit only.
- Reminders section: hidden until notifications exist.

Defaults:
- Flexible + Weekly + target=3.

Validation:
- Inline errors on interaction.
- Save disabled until valid.
- Scroll to first invalid on submit.

## Plan My Day integration

- Routines can be picked for today; pick is stored in my_day_picks.
- Plan My Day picker keeps +/tick affordance (no Log button).
- Daily routines are eligible for Plan My Day.
- Plan My Day renders scheduled routines before flexible routines.
- Deselecting a scheduled routine uses a two-step flow:
  - Step 1: `Skip this instance`, `More options`, `Keep scheduled`.
  - Step 2: `Skip this week/month` (cadence-based) or `Pause routine`.
- Routine picks are planned work; completion is logged from My Day or Routines.

## Data model (Supabase + local)

Routines:
- period_type: text enum (day, week, month)
- schedule_mode: text enum (flexible, scheduled)
- schedule_days: int[] (weekday 1-7)
- schedule_month_days: int[] (date 1-31)
- schedule_time_minutes: smallint (0-1439, stored only)
- target_count: int

Routine completions:
- completed_at (timestamptz)
- completed_day_local (date)
- completed_time_local_minutes (smallint)

No legacy routine_type support; assume data reset.

## Stats (habit strength)

Initial metrics (computed via analytics snapshots):
- Completion rate per period.
- Consistency score (gap variance).
- Day-of-week distribution.
- Time-of-day distribution (data only for now).

## Testing

- Domain tests for daily/weekly/monthly schedule evaluation.
- Repository tests for new persistence fields.
- Widget tests for routine tile variants and form states.
