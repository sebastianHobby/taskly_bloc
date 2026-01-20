# Screen Purpose Concepts (My Day / Anytime / Scheduled)

> Audience: product + design + engineering
>
> This document defines the intended *product meaning* of key workspace screens.
> It clarifies what each screen is for, what it contains, and how the screens
> relate to each other so that changes to navigation, filters, and rendering
> remain coherent.

## Definitions

### Naming / routing note (engineering)

- The **Anytime** screen is implemented under the legacy system screen key
  `someday`.
- Canonical route path is `/anytime`.
- Legacy `/someday` deep links redirect to `/anytime`.

- **Focus / Allocated / In My Day**: An item selected into the user’s curated
  focus list for the day (My Day). Focus is an *overlay* state, not a separate
  entity type.
- **Scheduled**: A **date-based lens** (timeline/agenda grouping), not a bucket.
  It shows the same underlying tasks, presented by date.
- **Planned day (start date)**: A **soft plan-to-start signal** (not a hard
  blocker).
- **Due date (deadline)**: A **hard must-finish-by signal**.
- **Local day boundary**: “Today” semantics use the user’s local calendar day
  boundary for comparisons and filtering (not UTC).

## Screen Contracts

### My Day (Focus)

**Primary purpose**: The user’s curated focus list for today.

**Key questions it answers**
- “What am I doing today?”
- “What should I work on now?”

**Contract**
- My Day is intentionally **not exhaustive**.
- My Day represents **user intent** and should feel stable for the day.

**Relationship to other screens**
- My Day is a **subset overlay** on top of the overall task set.
- Items may appear in other screens (Anytime/Scheduled) but must be visually
  identifiable as “In Focus”.

### Anytime (Actionable Backlog)

**Primary purpose**: The canonical list view of the user’s actionable backlog.

**Description line (UI copy)**
- “Your actionable backlog. Use filters to hide ‘start later’ items.”

**Key questions it answers**
- “What can I work on (now or soon), regardless of due dates?”
- “What’s in my backlog across projects?”

**Contract**
- Anytime includes **tasks and projects**.
- Tasks/projects may have due dates or planned days.
- Focus (My Day) items are included, but must be visually differentiated.

**Filter: hide future planned day**
- Provide a simple toggle to include/exclude items with a planned day in the
  future.
- This toggle applies to **both tasks and projects**.
- When toggled off, items with `startDate (planned day) > today (local day)`
  are hidden.

**Focus ordering within projects**
- When displaying tasks under a project grouping, **focus (My Day) tasks sort to
  the top within that project**.
- Within each bucket (focus/non-focus), use the existing secondary ordering.

### Scheduled (Date Lens)

**Primary purpose**: A date-based view lens over tasks.

**Key questions it answers**
- “What’s coming up and when?”
- “What’s overdue?”

**Contract**
- Scheduled **includes focus** tasks (My Day items are not excluded).
- Scheduled does not “own” tasks; it changes the presentation to group/sort by
  date fields.

## Cross-Screen Visual Language

### Focus cues (applies to Anytime and Scheduled)

To avoid confusion when the same task appears on multiple screens, focus must
be visually consistent across lenses.

**Primary cue**
- A small “In Focus” icon/badge on the row.

**Secondary cue**
- A subtle accent (thin left border or light background tint).

**Accessibility**
- Provide a semantic label (e.g., “In Focus”) so the status is perceivable via
  screen readers.

## Notes / Non-goals

- “Blocked” is not modeled yet. Anytime is defined as an actionable backlog in
  spirit, but no explicit blocked gating is applied until the product has a
  blocking concept.
- This document defines product intent; implementation details may vary as long
  as the contracts above remain true.
