# Spec: Routine Detail + Behavioral Support V1

Created at: 2026-02-14
Status: Proposed
Owner: TBD

## Summary

Introduce a full routine detail experience with trajectory-focused stats and
lightweight behavioral support. Weekly Review will show routine support cards
only when meaningful, with user-chosen support actions and minimal prompt load.

Selected product decisions:
- Q1-C: Full routine detail page.
- Q2-B: If-then plan available in Weekly Review and Routine Detail.
- Q3-B: Balanced thresholds.
- Q4-B: Building prompts only when meaningful and sparse.
- Q5-B: Store last 3 plans plus outcome.

## Goals

- Add a read-first routine detail surface separate from routine editing.
- Support users during routine decline with low-pressure, actionable prompts.
- Support early routine formation only when it is likely to help.
- Keep Weekly Review low-noise and psychologically safe.
- Let users choose support actions; do not auto-choose actions.

## Non-goals

- No badges or achievements in this phase.
- No push notification delivery changes in this phase.
- No mandatory journaling/reflection flow.
- No automatic schedule/target mutation without explicit user commit.

## Product copy (locked)

Support subtitle:
- "Small changes restore momentum. Tune this routine for this week."

Weekly Review positive header (example):
- "2 routines are steady this week."

## UX model

## Navigation (NAV-01)

- Add routine detail route: `/routine/:id`.
- Keep edit route separate: `/routine/:id/edit`.
- Routines list row tap opens routine detail.
- Routine row primary action remains quick log/unlog.
- Weekly Review support card tap opens routine detail.

## Weekly Review routine section

- Show full cards only for routines needing support.
- Show one compact positive header line if any routines are steady.
- No full "going well" section/cards.
- Routine support checks must be user-configurable in Settings, aligned with
  other weekly-review maintenance checks.

Example layout:
- Header line: "2 routines are steady this week."
- Support cards:
  - routine title + signal summary
  - support subtitle (locked copy)
  - action buttons (user chooses one):
    - Create if-then plan
    - Reschedule one day
    - Lower target for 1 week

## If-then plan placement

If-then plan can be opened from:
- Weekly Review support card.
- Routine Detail support section.

Shared UI:
- Use one shared plan composer surface (mobile-first bottom sheet).

## Prompt cadence and overload policy

- Max routine support cards per Weekly Review: 2.
- Max prompts per routine per review: 1.
- Suppress new prompt for 14 days after user applies a plan.
- Suppress new prompt for 14 days after dismiss, unless state worsens by
  another 10 percentage points.

## Settings integration

Add a weekly review maintenance toggle:
- `maintenanceRoutineSupportEnabled` (default: `true`)

Behavior:
- When turned off, routine support cards do not render in Weekly Review.
- When turned off, the corresponding attention rule (`problem_routine_support`)
  is set inactive through the same settings-to-attention-rule path used by
  other maintenance checks.

## Meaningful prompt policy

Only show routine prompts in two states:
- Building (early formation window, sparse + useful).
- Needs help (clear decline signal).

Do not show routine prompts outside these states.

## Thresholds (balanced profile)

## Global eligibility

All must be true:
- Routine is active.
- Routine is not paused.
- Routine age >= 7 days.

## Building state

All must be true:
- Routine age is between 7 and 28 days.
- At least 1 completion in last 14 days.
- 14-day adherence is between 20% and 70%.
- Routine is not in Needs Help state.

Building prompt behavior:
- Show only one suggested support action card.
- No repeated weekly prompting if user took an action in last 14 days.
- Skip building prompt if 14-day adherence > 70%.

## Needs Help state

All must be true:
- At least 4 full weeks of history.
- 2-week adherence is down >= 15 percentage points from personal 8-week
  baseline.
- Trend is down for 2 consecutive weeks.
- Last 14-day adherence < 60%.

Pause/resume guard:
- If routine was intentionally paused during most of evaluation window, do not
  trigger Needs Help prompt.

Severity:
- Info: 10-14 pp drop.
- Warning: >= 15 pp drop.

## Action selection policy

- User always selects the action.
- System may show a targeted suggestion only when backed by explicit pattern
  data.

Example targeted suggestion:
- If missed-day distribution shows Friday highest misses and Wednesday highest
  success in recent 6 weeks, suggest moving one session from Friday to
  Wednesday.

If no clear pattern:
- Show neutral action options without recommendation bias.

## Routine detail (RD-02, no badges)

Sections:
- Header: routine title + cadence metadata + edit button.
- Trajectory:
  - Strength score
  - Delta vs prior window
  - 8-week adherence sparkline
- Behavior Support:
  - locked support subtitle
  - one user action row (if-then/reschedule/lower target)
  - optional targeted suggestion when evidence exists
- Recent support plans (last 3):
  - plan summary
  - outcome tag (Helped / Somewhat / Not)

## If-then plan and outcome tracking

## Data retained

Store last 3 support plans per routine:
- Plan type (if-then, reschedule, lower-target)
- Structured plan payload
- Created timestamp
- Source (weekly_review, routine_detail)
- Optional note (short text)
- Status (active, archived)

Store next-review outcome:
- helped | somewhat | not
- Recorded timestamp

## Prefill behavior

- Prefill plan composer only if prior outcome = helped.
- If prior outcome is somewhat/not, do not prefill.

## Outcome prompt timing

- Ask "Did this help?" at next Weekly Review only.
- No same-week outcome prompt.

## Missed-day contextual nudge

Allowed but non-blocking:
- Trigger only after meaningful pattern (e.g., 2 misses in 7 days or repeated
  same weekday miss over 2 weeks).
- Use inline card style; do not use blocking modal.

## Analytics and metrics (for this feature)

Use these routine-level derived stats:
- 14-day adherence.
- 2-week adherence.
- 8-week baseline adherence.
- 8-week weekly adherence series.
- 2-week trend direction.
- Missed-day distribution by weekday.
- Success distribution by weekday.

## Acceptance criteria

- Users can open `/routine/:id` and view trajectory + support sections.
- Edit remains in `/routine/:id/edit` and is not mixed into detail content.
- Weekly Review shows routine support cards only when routine is in Building or
  Needs Help state.
- Weekly Review shows at most 2 support cards.
- Support subtitle uses locked copy exactly.
- If-then plan can be created from Weekly Review and Routine Detail.
- Plan prefill occurs only when previous outcome is helped.
- Outcome question appears only in next Weekly Review.
- Last 3 plans and outcomes are visible in Routine Detail.

## Open implementation questions

- Whether "Reschedule one day" and "Lower target 1 week" run as:
  - direct editor open + explicit save, <=== user selected ths option
- Final naming for "Strength" label in localized copy.
