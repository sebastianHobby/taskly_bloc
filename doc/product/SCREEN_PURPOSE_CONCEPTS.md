# Screen Purpose Concepts (My Day / Anytime / Scheduled)

> Audience: product + design + engineering
>
> This document defines the intended *product meaning* of key workspace screens.
> It clarifies what each screen is for, what it contains, and how the screens
> relate to each other so that changes to navigation, filters, and rendering
> remain coherent.

## Definitions

### Naming / routing note (engineering)

- The **Anytime** screen is currently implemented under the historical system
  screen key `someday`.
- Canonical route path is `/anytime`.
- `/someday` deep links redirect to `/anytime`.

- **In My Day**: An item the user chose for today's plan (My Day). This is a
  planning state tied to the day, not a separate entity type.
- **Scheduled**: A **date-based lens** (timeline/agenda grouping), not a bucket.
  It shows the same underlying tasks, presented by date.
- **Planned day (start date)**: A **soft plan-to-start signal** (not a hard
  blocker).
- **Due date (deadline)**: A **hard must-finish-by signal**.
- **Local day boundary**: "Today" semantics use the user's local calendar day
  boundary for comparisons and filtering (not UTC).

## Screen Contracts

### My Day

**Primary purpose**: The user's plan for today.

**Key questions it answers**
- "What am I doing today?"
- "What should I work on now?"

**Contract**
- My Day is intentionally **not exhaustive**.
- My Day represents **user intent** and should feel stable for the day.

**Relationship to other screens**
- My Day is a **daily plan** drawn from the broader set of tasks and routines.
- Items may also appear in other screens (Anytime/Scheduled).

### Anytime (Actionable Backlog)

**Primary purpose**: The canonical list view of the user's actionable backlog.

**Description line (UI copy)**
- "Your project backlog. Open a project to work on its tasks."

**Key questions it answers**
- "Which projects should I work on next?"
- "What's in my backlog across projects?"

**Contract**
- Anytime includes **projects and their tasks**.
- Project detail is part of Anytime and is where tasks are viewed and managed
  in context.
- Tasks/projects may have due dates or planned days.
- My Day items are included when they appear in Anytime.

**Filter: hide future planned day**
- Provide a simple toggle to include/exclude items with a planned day in the
  future.
- This toggle applies to **projects and their tasks** (task visibility is
  scoped within the project detail view).
- When toggled off, items with `startDate (planned day) > today (local day)`
  are hidden.

**My Day ordering within projects**
- When displaying tasks under a project grouping, **My Day tasks sort to the top
  within that project**.
- Within each bucket (My Day/non-My Day), use the existing secondary ordering.

### Scheduled (Date Lens)

**Primary purpose**: A date-based view lens over tasks.

**Key questions it answers**
- "What's coming up and when?"
- "What's overdue?"

**Contract**
- Scheduled **includes My Day** items (My Day tasks are not excluded).
- Scheduled does not "own" tasks; it changes the presentation to group/sort by
  date fields.

**User-facing framing (candidate copy)**
- "Your date lens for upcoming tasks and projects so you can plan ahead."
- "See what's coming up next across tasks and projects, grouped by day."
- "A timeline view of tasks and projects that helps you spot what's next."

## Cross-Screen Visual Language

### My Day cues (applies to Anytime and Scheduled)

To avoid confusion when the same task appears on multiple screens, My Day
status must be visually consistent across lenses.

**Primary cue**
- A small "In My Day" icon/badge on the row.

**Secondary cue**
- A subtle accent (thin left border or light background tint).

**Accessibility**
- Provide a semantic label (e.g., "In My Day") so the status is perceivable via
  screen readers.

### Layout consistency

**Feed edge padding**
- Feed screens use 16dp horizontal padding on mobile. Apply this consistently
  to feed rows, section headers, and empty-state rows.

## Notes / Non-goals

- "Blocked" is not modeled yet. Anytime is defined as an actionable backlog in
  spirit, but no explicit blocked gating is applied until the product has a
  blocking concept.
- This document defines product intent; implementation details may vary as long
  as the contracts above remain true.
