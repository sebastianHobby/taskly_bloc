# Weekly Values Ratings + Suggestions Signal Plan

Date: 2026-01-28
Owner: Product/Design
Status: Draft (not implemented)

## 1) Goals

- Add a weekly values ratings ritual that drives suggestions when enabled.
- Provide trustable, explainable recommendations via smoothing and history.
- Keep a clear mode switch between behavior-based and ratings-based signals.
- Cap values at 8 and enforce it at creation time.

## 2) User Decisions (Locked)

- Ratings are required weekly when ratings mode is enabled.
- Fallback: last known ratings can be used for up to 2 weeks, then suggestions are blocked.
- Stats snapshot window: 4 weeks.
- Stats snapshot includes both tasks and routines, shown as split view.
- Ratings history is stored per week.
- EMA smoothing window: 4 weeks.
- Max values: 8 total (validation to prevent creation beyond 8).

## 3) UX + UI (Weekly Review)

### 3.1 Ratings prompt copy

- Prompt: "Rate this past week."
- Subtext: "We blend weekly check-ins over time to keep suggestions steady."

### 3.2 Ratings interaction (wheel)

- Remente-inspired grid + radial spokes, distinct styling.
- 8 slices, 8 rings, rounded segment ends, thicker slice gaps.
- Anchor ticks at 1/4/7/8.
- Center hub shows selected value + rating.
- Value-specific user-chosen icons at slice tips + short labels.
- Tap tile to select value; tap ring to set rating.
- Selected slice subtly expands; optional snap handle indicator.

### 3.3 Anchoring + feedback

- Legend: "1 Neglected • 4 Low • 7 Steady • 8 Thriving."
- Last rating cue: "Last rating X (Y weeks ago)."
- Progress indicator: "N/8 values rated."

### 3.4 Progressive disclosure / stats

- Default view: wheel + legend + prompt.
- Completion share snapshot (last 4 weeks) shown under wheel.
- Split stats view (tasks vs routines).
- Per-value details via bottom sheet:
  - Completion count
  - Routine count
  - 4-week trend sparkline
  - History access (last 3–4 ratings)

### 3.5 Flow + gating

- Continue disabled until all values rated.
- If in fallback week 1–2: show banner indicating last ratings are used.

## 4) Settings (Suggestion signal)

Setting: "Suggestion signal"

- Behavior-based (Completions + balance)
  - "Stable and objective. Follows what you actually did."
- Ratings-based (Values + ratings)
  - "More personal and reflective. Uses your weekly check-ins."

Helper text:
- "Ratings mode requires weekly ratings and may change suggestions more quickly."

## 5) Allocation changes

### 5.1 Ratings-based mode

- Source weights from per-value ratings (weekly history).
- Apply EMA smoothing over 4 weeks before quotas are computed.
- Priority is NOT used in ratings mode.

### 5.2 Behavior-based mode (current)

- Keep existing completions + priority + balance logic.

### 5.3 Explainability

- In My Day / Plan My Day, show "Based on your ratings" when ratings mode is active.
- Maintain existing reason codes for behavior-based mode.

## 6) Fallback behavior (Plan My Day)

- If ratings are stale beyond 2 weeks and ratings mode is active:
  - Block suggestions.
  - Show CTA:
    - "Rate values" (opens Weekly Review ratings)
    - "Switch to behavior-based suggestions"

## 7) Data + storage

- Persist weekly ratings per value with week key + timestamp.
- Provide accessors for:
  - Last rating
  - Last 4 weeks history
  - Staleness detection

## 8) Validation: max 8 values

- Enforce in value creation flow (presentation validation + domain guard as needed).
- Ensure error copy is user-friendly (e.g., "You can have up to 8 values.").

## 9) Code touchpoints (expected)

- Presentation:
  - Weekly review UI (new ratings step)
  - Plan My Day CTA for blocked suggestions
  - Settings UI for suggestion signal
- Domain:
  - Ratings model + storage contract
  - Allocation orchestrator/engine ratings mode
  - Ratings history + EMA smoothing
- Data:
  - Persistence for weekly ratings

## 10) Open questions (if any remain)

- None pending; decisions locked as above.
