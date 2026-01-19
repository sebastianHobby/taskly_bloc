# Journal uplift (plan)

> Purpose: consolidate all Journal UI/UX + functionality changes discussed in chat into a single implementation plan.
>
> Product intent (primary): **behavior change / “what makes a difference?”** via structured data, without prescribing experiments.
>
> Secondary intent: self-reflection journaling.

## 0) Non-negotiable constraints (from discussion)

- Remove Journal tabs; adopt a Daylio-like experience.
- Main Journal page is a timeline feed of entries with a small summary.
- Add Entry flow shows **factors by default** (can be collapsed).
- **No pinned trackers**: all trackers are equally important.
- Users can create trackers and define **user-defined groups** (name + ordering).
- Trackers are **immutable** after creation for: type and scope (user can edit name only).
- Mood is **per-entry**; multiple mood entries per day; stats use daily averages.
- Daily quantities should support **incremental add** with negative adjustments; **no “reset today”.
- Choice trackers: treat values as **per-event** (do not force one daily value).

Decisions (locked in):

- Phase 2 does not require search/filter inside Add Entry.

## 1) Current architecture alignment

- Journal is event-log + projections:
  - `TrackerEvent` appended for interactions.
  - Projections: `TrackerStateEntry`, `TrackerStateDay`.
- Tracker definition fields already exist (stringly typed): `scope`, `valueType`, `valueKind`, `unitKind`, `opKind`, `minInt/maxInt/stepInt`, and optional choices.

This uplift keeps the event-log model and makes the UI more explicit about **scope** (daily vs momentary) and **measurement type** (toggle/rating/quantity/choice).

## 2) Navigation: remove tabs (JRN-NAV-01)

### Target UX

- Replace the tabbed hub with a single Journal home focused on “Today” and the timeline.
- Secondary destinations become routes:
  - History / all entries (search/filter)
  - Manage trackers (definitions, groups, ordering)

Decisions (locked in):

- Keep app-level navigation bar/rail.
- No Journal-internal tabs.
- No week strip.
- No filter chips on Journal Home.
- Journal Home header includes “settings-style” actions for History/Search and Manage Trackers.
- Journal Home date label uses an explicit date (e.g. “Mon 19 Jan”), not “Today”.
- Day navigation: tap the date label to open a date picker (Journal Home shows the selected day).

### Rationale

- Eliminates mode-switching overhead.
- Keeps the primary action (log) always obvious.

## 3) Journal home: layout + behavior

### 3.1 Header area

- Date label + small status summary.
- Day navigation via date picker (tap date label).

### 3.2 Small “Today summary” module (Daylio-like)

- Shows:
  - Daily mood average for the selected day (derived from per-entry mood events).
  - Entry count for the day.
  - Optional: compact daily totals preview (only for day-scoped totals, if present).

### 3.3 Timeline feed

- Timeline of entries (most recent first):
  - Time
  - Mood value (per entry)
  - Compact factor chips/summary (limit to a few to avoid noise)
  - Tap entry opens entry detail/editor.

## 4) Add Entry flow (JRN-ADD-GRP-01)

### 4.1 Form structure

- Mood (required)
- Note (optional)
- Factors (shown by default)
  - Two scopes rendered as separate sections:

1) **Daily (applies to the day)**
- Only includes trackers with `scope = day` (and optionally `sleep_night`).
- Shows current state and allows editing from any entry.
- Quantity daily totals are always incremental (`opKind = add`) with negative adjustments.

2) **This entry (momentary)**
- Includes trackers with `scope = entry`.
- Shows no prior state by default; selection/values apply only to the current entry.

### 4.2 Collapsing behavior

- Factors are visible by default.
- Allow collapse at:
  - Section level (Daily / This entry)
  - Group level (user-defined groups)
- Collapse state is not persisted (resets to expanded by default).

### 4.3 “All trackers easily accessible”

- Within each scope, all trackers are present (organized by groups).
- Search/filter inside Add Entry is out of scope for Phase 2 (see decisions).

## 5) User-defined groups (organizational, not semantic categories)

### 5.1 What a group is

- User-created label + ordering.
- Grouping is primarily a UI affordance; it should not block analytics.

### 5.2 Editing UX

- “Manage groups” screen:
  - Create/rename groups
  - Reorder groups
  - Move trackers between groups
  - Reorder trackers within group
  - “Ungrouped” fallback section

## 6) Supported tracker measurement types (current system)

> Only types already supported by schema and domain models.

### 6.1 Toggle (yes/no)

- Definition: `valueType = yes_no`, `valueKind = boolean`.
- UI:
  - Entry: toggle chip / switch.
  - Daily: same, but labeled as day-wide.
- Stats daily signal:
  - `anyTrue` → 0/1.

### 6.2 Rating (discrete scale)

- Definition: `valueType = rating`, `valueKind = rating`, use `minInt/maxInt/stepInt`.
- UI:
  - Entry: segmented rating picker.
  - Sleep-night: same (night-anchored).
- Stats daily signal:
  - daily average.

### 6.3 Quantity (daily incremental)

- Definition: `valueType = quantity`, `valueKind = number`, `scope = day`, `opKind = add`.
- UI:
  - Increment chips + custom delta + visible running total.
  - Support negative adjustments; avoid reset.
- Stats daily signal:
  - daily sum of adds.

### 6.4 Quantity (entry set)

- Definition: `valueType = quantity`, `valueKind = number`, `scope = entry`, `opKind = set`.
- UI:
  - Inline stepper for small numbers; tap-to-type for large.
  - Clear removes value from this entry.
- Stats usage:
  - Daily derived features: event count, daily sum, average per event, max per day.

### 6.5 Choice (single select)

- Definition: `valueType = choice`, `valueKind = single_choice` with `TrackerDefinitionChoice` rows.
- UI:
  - Small N: chips.
  - Large N: bottom sheet list + search.
- Stats daily signal:
  - per-event distributions.
  - Also allow day-level derived “choice occurred today” signals per option.

### 6.6 Explicitly out of scope for now (not supported)

- Multi-pick (multi-select choices)
- Free-text tracker values
- Composite values (structured objects)
- Float sliders with non-integer steps (current constraints are int-centric)

## 7) Tracker creation UX (type/scope cannot change later)

### 7.1 Creation wizard (required)

- Step 1: Name
- Step 2: Scope
  - Daily total (day)
  - Momentary (entry)
  - Sleep/night (sleep_night) (first-class option)
- Step 3: Measurement type (choices depend on scope)
  - Daily: Toggle, Rating, **Quantity (incremental)**, Choice
  - Entry: Toggle, Rating, **Quantity (set)**, Choice

> Hide “quantity set vs incremental” as a separate concept.
> The app selects the correct opKind automatically based on scope.

### 7.2 Constraints configuration (when applicable)

- Rating: choose range (min/max/step).
- Quantity: choose unit (unitKind) + step defaults.
- Choice: define options.

### 7.3 Stats preview (lightweight)

Show a single line under each type:
- Toggle: “Stats compare days with vs without.”
- Rating: “Stats use daily average.”
- Daily quantity: “Stats use daily total.”
- Entry quantity: “Stats can use total + frequency + typical amount.”
- Choice: “Stats compare outcomes by option (per event).”

## 8) Aggregation policies (for behavior change)

- Outcome (mood): per-entry rating; daily average.
- Boolean: daily anyTrue.
- Rating factors: daily average.
- Daily incremental quantity: daily sum.
- Entry quantity: daily derived (sum, count, avg-per-event), exposed in stats views.
- Choice: per-event distributions and conditional outcome comparisons.

## 9) Implementation phases (suggested)

### Phase 1 — Navigation + core flow

- Remove tabs; journal home becomes the primary.
- Ensure Add Entry is the main action.
- Timeline is the main content.

### Phase 2 — Add Entry: scoped factor sections + groups

- Add Daily vs This entry sections in the add flow.
- Add group rendering + collapse patterns.
- Remove pinned/quick-add concept in Journal UI.

Phase 2 decisions (locked in):

- Daily factors are editable inline using “quick adjust” controls where applicable.
- New tracker creation prompts for choosing a group (default Ungrouped).
- Manage UX: a single “Manage trackers” destination includes groups + ordering.
- Phase 2 input coverage includes all tracker types (toggle/rating/quantity/choice).

### Phase 3 — Tracker creation wizard and type-specific inputs

- Introduce scope-first + type selection.
- Add type-specific controls for quantity/rating/choice.

### Phase 4 — Stats surfaces

- Add a “What changed?” view driven by the aggregation policies.
- Keep it descriptive and user-controlled (no experiment prescription).

## 10) Open decisions (need confirmation before coding)

Decisions (locked in):

- Entry quantity daily rollups: default is minimal (sum only), with additional metrics behind “details”.
- Sleep/night scope: offered as a first-class option in the creation wizard.
- Choice stats: support both per-event distributions and derived per-day presence signals, with guardrails (minimum sample size + denominators + low-confidence messaging) to avoid false signals.
