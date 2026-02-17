# Spec: Ratings-Only Value Recommendations + Value Priority Removal

Status: Proposed (locked defaults)
Owner: Product/Design
Date: 2026-02-10

## Summary

Taskly will use **value ratings only** to drive Plan My Day recommendations.
Value priority is removed from all user-facing surfaces and decision logic.
Task/routine completions remain **optional evidence** only (Weekly Review),
never a recommendation signal.

This spec also removes the Settings > Task Suggestions screen and updates
onboarding/guided tour copy to align with ratings-led suggestions.

## Goals

- Ratings drive all value recommendation ordering and visibility.
- Remove value priority from UI and logic (storage remains for compatibility).
- Keep completion stats as optional context only.
- Provide a stable, meaningful UX with a simple sort toggle.

## Non-Goals

- Data migrations for priority fields.
- New attention rules/prompts (TBC in follow-up).
- Removing task/project priority (only value priority is removed).

## Locked Defaults

- Rating window X: 4 weeks.
- Trend calculation: simple delta (last 4 weeks vs prior 4 weeks).
- Low average threshold: <= 4.5 (1-10 scale).
- Trend down emphasis threshold: delta <= -0.6.
- Needs Rating action: launch ratings wizard for selected value.
- Recompute: on rating change + new week boundary.

## UX: Plan My Day (Value Suggestions)

### Header

- Title: "Value suggestions"
- Subtext: "Based on your weekly ratings (last 4 weeks)."
- Control: Sort by with two options.

Sort options:
1) Lowest average (default)
2) Trending down

### Value Group Header (per value)

- Left: icon + value name
- Right: "Avg 5.6" + trend badge ("? 0.8" or "? 0.4")
- If no data: "Avg -" and no trend badge

### Ordering

Default (Lowest average):
1) Lowest average
2) Most negative trend
3) Alphabetical

Alternate (Trending down):
1) Most negative trend
2) Lowest average
3) Alphabetical

### Visible Count Rules (per value)

- Trending down (delta <= -0.6): 3 visible
- Low average (avg <= 4.5): 2 visible
- Stable/neutral: 1 visible
- No rating: 0 visible (in "Needs rating")

### Needs Rating Group

- Values with no rating in last 4 weeks appear in "Needs rating".
- Each value shows a Rate action that launches the ratings wizard.

### Sorting and Refresh

- Recompute ordering on rating change and on new week boundary.
- Do not re-sort on scroll/expand.

## UX: Weekly Review

### Supporting Activity Section

- Title: "Activity snapshot"
- No body text.

### Ratings remain primary driver

- Weekly ratings are the only recommendation signal.
- Task/routine completions remain visible as optional evidence only.

## UX: Values Screens

- Remove value priority field from create/edit forms.
- Remove priority badges/dots on value list items.
- Remove sort option for value priority.

## UX: Settings

- Remove Settings > Task Suggestions entry and page.

## Onboarding + Guided Tour

- Remove value priority references in copy.
- Update suggestion explanation to ratings-led model.

## Logic Changes (System)

### Allocation + Suggested Picks

- Ratings are the only weighting signal.
- Completion-based balancing and neglect deficits are removed.
- No spotlight based on completion deficits.
- Category weights come only from ratings.
- If no rated values exist, allocation requires ratings (ratings gate).
- If some values are rated and others are not, allocation uses rated values
  only; unrated values appear under "Needs rating" in Plan My Day UI.

### Value Priority Removal

- Value priority is not read for any UX or decision logic.
- Task/project priority is unchanged.

## UX Mockups (ASCII)

Plan My Day:

Value suggestions
Based on your weekly ratings (last 4 weeks).
Sort by: Lowest average ?

[?? Health]                     Avg 5.6  ? 0.8
  - Task A
  - Task B
  - Task C   (Show more)

[?? Learning]                   Avg 6.2  ? 0.4
  - Task D
  - Task E   (Show more)

Needs rating
[?? Creativity]  Avg -   (Rate)
[?? Calm]        Avg -   (Rate)

Weekly Review:

Activity snapshot

Tasks: 6   Routines: 3

## Acceptance Criteria

- No value priority UI remains (forms, lists, sorting, badges).
- Suggested picks are ratings-only, with no completion-based balancing.
- Plan My Day shows avg + trend and sort toggle.
- Settings Task Suggestions removed.
- Guided tour and onboarding reflect ratings-led suggestions.
- Task/project priority remains intact.

## Open Questions (TBC)

- Future targeted prompts on trending down values.
- Whether to add cadence settings for ratings windows.
