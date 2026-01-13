# Stitch Prompts (Refined Declarative Style) — 13 Jan 2026

Each prompt below is standalone and should be copy/pasted on its own.

Global constraints (applies to every prompt):
- Use ONLY the data explicitly provided in that prompt.
- Do NOT invent any additional Values, Projects, Tasks, alerts, issues, reviews, dates, counts, labels, or placeholder text.
- Do NOT modify any provided field values.
- You MUST show every field that is specified for an item.

Conventions:
- Date format: `EEE, d MMM yyyy` (example: `Tue, 13 Jan 2026`).
- Priority format: `P0` (highest) to `P3` (lowest).

---

## Prompt 1 — My Day (Tue, 13 Jan 2026)

Data constraints for this prompt:
- You MUST use exactly the data below.
- You MUST show every field specified.

Display a screen named `My Day`.
Display a top header area with the following data:
- Date label: `Tue, 13 Jan 2026`
- Screen title: `My Day`
- Avatar chip initials: `SH`

Display an alternate state (Focus Mode Required gate) with the following content, in this order:
- Display a hero area with a gradient background.
- Display hero date text: `Tue, 13 Jan 2026`.
- Display hero title text: `My Day`.
- Display hero avatar chip: `SH`.
- Display a pill label with text: `SET UP FOCUS MODE`.
- Display a headline with text: `Pick a Focus Mode to Generate Today’s Plan`.
- Display a description paragraph with text: `My Day is powered by Focus Mode. Choose what you want to prioritize, and Taskly will build today’s task list grouped by your Values—plus highlight what’s excluded and why.`
- Display a mission sentence with text: `Taskly helps you consistently spend your time on what matters most—your values, your wellbeing, and your commitments.`
- Display a primary full-width button with label: `Choose Focus Mode`.

Display the main state (Focus Mode Enabled) with exactly the following entities.

Display a Values dataset with the following items:
- Value: `Health & Energy`
- Value: `Life Admin`
- Value: `Relationships`

Display a Projects dataset with the following items:
- Project: `Get a passport`
- Project: `Exercise Routines`
- Project: `Organise birthday for Sam`

Display a Tasks dataset with the following items:
- Task: `Book passport photo`
- Task: `Submit application`
- Task: `Plan workouts for next week`
- Task: `Book dinner reservation`

Display a card titled `Reviews Due`.
Display a warning banner row with the following data:
- Icon: `warning`
- Text: `2 reviews due today`

Display a review row with the following data:
- Type label: `Project review`
- Title: `Get a passport`
- Description: `Confirm next steps and deadlines.`
- Due date: `Tue, 13 Jan 2026`

Display another review row with the following data:
- Type label: `Value review`
- Title: `Health & Energy`
- Description: `Check if this week’s plan supports recovery + movement.`
- Due date: `Tue, 13 Jan 2026`

Display a full-width button with label: `Start Check-in`.

Display a card titled `Alerts`.
Display a summary row with the following data:
- Text: `2 alerts`

Display an alert row with the following data:
- Severity: `Warning`
- Title: `Plan workouts for next week`
- Description: `Overallocated: 80 min planned, 30 min available.`

Display another alert row with the following data:
- Severity: `Info`
- Title: `Book dinner reservation`
- Description: `Has both Values set; verify it’s in the right category.`

Display a footer link row with the following data:
- Link text: `View all 2 alerts`

Display a main allocation list (not a card) with groups and items in this exact order.

Display a group header with the following data:
- Title: `Pinned`
- Count: `1`

Display a task list item with the following data:
- Checkbox: `unchecked`
- Pin: `shown`
- Title: `Book passport photo`
- Priority: `P1`
- Status tag: `—`
- Project: `Get a passport`
- Date token: `DUE Tue, 13 Jan 2026`
- Repeat: `Monthly`
- Primary value: `Life Admin`
- Secondary values: `Relationships`

Display a group header with the following data:
- Title: `Health & Energy`
- Count: `1`

Display another task list item with the following data:
- Checkbox: `unchecked`
- Pin: `hidden`
- Title: `Plan workouts for next week`
- Priority: `P0`
- Status tag: `—`
- Project: `Exercise Routines`
- Date token: `START Tue, 13 Jan 2026`
- Repeat: `Weekly`
- Primary value: `Health & Energy`
- Secondary values: `Life Admin`

Display a group header with the following data:
- Title: `Life Admin`
- Count: `1`

Display another task list item with the following data:
- Checkbox: `unchecked`
- Pin: `hidden`
- Title: `Submit application`
- Priority: `P0`
- Status tag: `—`
- Project: `Get a passport`
- Date token: `START Tue, 13 Jan 2026`
- Repeat: `Yearly`
- Primary value: `Life Admin`
- Secondary values: `Health & Energy`

Display a group header with the following data:
- Title: `Relationships`
- Count: `1`

Display another task list item with the following data:
- Checkbox: `unchecked`
- Pin: `hidden`
- Title: `Book dinner reservation`
- Priority: `P2`
- Status tag: `—`
- Project: `Organise birthday for Sam`
- Date token: `DUE Tue, 13 Jan 2026`
- Repeat: `Weekly`
- Primary value: `Relationships`
- Secondary values: `Health & Energy`

---

## Prompt 2 — Scheduled (Agenda)

Data constraints for this prompt:
- You MUST use exactly the data below.
- You MUST show every field specified.

Display a screen named `Scheduled`.
Display an agenda list grouped by month and day.

Display a Values dataset with the following items:
- Value: `Life Admin`
- Value: `Relationships`
- Value: `Health & Energy`

Display a Projects dataset with the following items:
- Project: `Get a passport`
- Project: `Exercise Routines`

Display a Tasks dataset with the following items:
- Task: `Book passport photo`
- Task: `Submit application`
- Task: `Plan workouts for next week`

Display the following agenda tag rules as part of the specification (because they determine visible labels):
- Display tag `DUE` when a task deadline date equals the day header date.
- Display tag `START` when a task start date equals the day header date (and it is not due that same day).
- Display tag `IN PROGRESS` when a task start date is before the day header date and it is not completed.
- If both start and deadline exist on the same day, display tag `DUE`.

Display a month header with text: `January 2026`.

Display a day header with the following data:
- Date label: `Tue, 13 Jan 2026`
- Count: `2`

Display a task agenda item with the following data:
- Checkbox: `unchecked`
- Pin: `shown`
- Priority: `P1`
- Status tag: `START`
- Title: `Book passport photo`
- Project: `Get a passport`
- Date token: `START Tue, 13 Jan 2026`
- Repeat: `Monthly`
- Primary value: `Life Admin`
- Secondary values: `Relationships`

Display a project agenda item with the following data:
- Title: `Exercise Routines`
- Priority: `P2`
- Progress: `1/4 tasks`
- Values: `Health & Energy` (secondary: `Life Admin`)
- Start date: `Mon, 12 Jan 2026`
- Deadline date: `Fri, 16 Jan 2026`
- Repeat: `Weekly`

Display a day header with the following data:
- Date label: `Wed, 14 Jan 2026`
- Count: `2`

Display another task agenda item with the following data:
- Checkbox: `unchecked`
- Pin: `hidden`
- Priority: `P0`
- Status tag: `DUE`
- Title: `Submit application`
- Project: `Get a passport`
- Date token: `DUE Wed, 14 Jan 2026`
- Repeat: `Yearly`
- Primary value: `Life Admin`
- Secondary values: `Health & Energy`

Display another task agenda item with the following data:
- Checkbox: `unchecked`
- Pin: `hidden`
- Priority: `P0`
- Status tag: `IN PROGRESS`
- Title: `Plan workouts for next week`
- Project: `Exercise Routines`
- Date token: `START Mon, 12 Jan 2026`
- Repeat: `Weekly`
- Primary value: `Health & Energy`
- Secondary values: `Life Admin`

---

## Prompt 3 — Someday (Backlog)

Data constraints for this prompt:
- You MUST use exactly the data below.
- You MUST show every field specified.

Display a screen named `Someday`.

Display a Values dataset with the following items:
- Value: `Home & Comfort`
- Value: `Learning & Curiosity`

Display a Projects dataset with the following items:
- Project: `Home chores`
- Project: `Learn capital city names`

Display a Tasks dataset with the following items:
- Task: `Declutter “misc” drawer`
- Task: `Organize cleaning supplies`
- Task: `Europe capitals: set 1 (15)`

Display a card titled `Issues`.
Display severity badges with the following data:
- `Critical 0`
- `Warning 1`
- `Info 0`

Display an issue row with the following data:
- Severity: `Warning`
- Title: `Declutter “misc” drawer`
- Description: `Has multiple Values; confirm it’s intentional.`

Display a filter bar with the following controls:
- Display a toggle labeled `Projects only` with value `Off`.
- Display a dropdown labeled `Value` with selected value `All values`.

Display a backlog list.
Display a value group header with the following data:
- Title: `Home & Comfort`
- Count: `2`

Display a project row with the following data:
- Title: `Home chores`
- Priority: `P2`
- Progress: `0/6 tasks`
- Values: `Home & Comfort` (secondary: `Learning & Curiosity`)
- Start date: `Tue, 20 Jan 2026`
- Deadline date: `Tue, 3 Feb 2026`
- Repeat: `Monthly`

Display a task list item with the following data:
- Checkbox: `unchecked`
- Pin: `hidden`
- Title: `Declutter “misc” drawer`
- Priority: `P2`
- Status tag: `—`
- Project: `Home chores`
- Date token: `DUE Tue, 3 Feb 2026`
- Repeat: `Monthly`
- Primary value: `Home & Comfort`
- Secondary values: `Learning & Curiosity`

Display another task list item with the following data:
- Checkbox: `unchecked`
- Pin: `hidden`
- Title: `Organize cleaning supplies`
- Priority: `P3`
- Status tag: `—`
- Project: `Home chores`
- Date token: `START Tue, 20 Jan 2026`
- Repeat: `Weekly`
- Primary value: `Home & Comfort`
- Secondary values: `Learning & Curiosity`

Display another value group header with the following data:
- Title: `Learning & Curiosity`
- Count: `1`

Display a project row with the following data:
- Title: `Learn capital city names`
- Priority: `P3`
- Progress: `0/8 tasks`
- Values: `Learning & Curiosity` (secondary: `Home & Comfort`)
- Start date: `Mon, 19 Jan 2026`
- Deadline date: `Fri, 30 Jan 2026`
- Repeat: `Weekly`

Display another task list item with the following data:
- Checkbox: `unchecked`
- Pin: `hidden`
- Title: `Europe capitals: set 1 (15)`
- Priority: `P3`
- Status tag: `—`
- Project: `Learn capital city names`
- Date token: `START Mon, 19 Jan 2026`
- Repeat: `Daily`
- Primary value: `Learning & Curiosity`
- Secondary values: `Home & Comfort`

---

## Prompt 4 — Components (Entity View Variations)

Data constraints for this prompt:
- You MUST use exactly the component list and the field values specified below.
- You MUST NOT make up any additional data or change any provided field values.
- You MUST show every field listed for every component example (no omissions).

Display a screen named `Components`.

Display 3 variations of this same screen:
- Variation A: `Compact` density, `Light` style.
- Variation B: `Comfortable` density, `Light` style.
- Variation C: `Spacious` density, `Dark` style.

Display the following Values:

Display a value card with the following data:
- Name: `Health & Energy`
- Stats chips: `Active 12`, `Due 3`, `Weekly 2`, `Streak 5d`

Display another value card with the following data:
- Name: `Life Admin`
- Stats chips: `Active 8`, `Due 1`, `Pinned 1`, `Alerts 2`

Display the following Projects:

Display a project list item with the following data:
- Title: `Get a passport`
- Priority: `P1`
- Progress: `2/5 tasks`
- Values: `Life Admin` (secondary: `Relationships`)
- Start date: `Mon, 12 Jan 2026`
- Deadline date: `Fri, 30 Jan 2026`
- Repeat: `Monthly`

Display another project list item with the following data:
- Title: `Exercise Routines`
- Priority: `P2`
- Progress: `1/4 tasks`
- Values: `Health & Energy` (secondary: `Life Admin`)
- Start date: `Mon, 12 Jan 2026`
- Deadline date: `Fri, 16 Jan 2026`
- Repeat: `Weekly`

Display the following Tasks:

Display a task list item with the following data:
- Title: `Book passport photo`
- Checkbox: `unchecked`
- Pin: `shown`
- Priority: `P1`
- Project: `Get a passport`
- Start date: `Tue, 13 Jan 2026`
- Deadline date: `Tue, 13 Jan 2026`
- Date token: `DUE Tue, 13 Jan 2026`
- Repeat: `Monthly`
- Primary value: `Life Admin`
- Secondary values: `Relationships`

Display another task list item with the following data:
- Title: `Submit application`
- Checkbox: `unchecked`
- Pin: `hidden`
- Priority: `P0`
- Project: `Get a passport`
- Start date: `Mon, 12 Jan 2026`
- Deadline date: `Wed, 14 Jan 2026`
- Date token: `DUE Wed, 14 Jan 2026`
- Repeat: `Yearly`
- Primary value: `Life Admin`
- Secondary values: `Health & Energy`

Display another task list item with the following data:
- Title: `Plan workouts for next week`
- Checkbox: `checked`
- Pin: `hidden`
- Priority: `P0`
- Project: `Exercise Routines`
- Start date: `Mon, 12 Jan 2026`
- Deadline date: `Fri, 16 Jan 2026`
- Date token: `START Mon, 12 Jan 2026`
- Repeat: `Weekly`
- Primary value: `Health & Energy`
- Secondary values: `Life Admin`

Display a section header with text: `TaskView — List`.
Display a list containing the 3 tasks above using the TaskView list variant.

Display a section header with text: `TaskView — Agenda`.
Display a list containing the 3 tasks above using the TaskView agenda variant.
Display agenda tags with the following rules:
- Display tag `DUE` if the Date token begins with `DUE`.
- Display tag `START` if the Date token begins with `START`.
- Display tag `IN PROGRESS` for the task titled `Plan workouts for next week` ONLY.

Display a section header with text: `ProjectView — List`.
Display a list containing the 2 projects above using the ProjectView list variant.

Display a section header with text: `ProjectView — Agenda`.
Display a list containing the 2 projects above using the ProjectView agenda variant.

Display a section header with text: `ValueView — Compact`.
Display a row/grid containing the 2 values above using the ValueView compact card variant.

