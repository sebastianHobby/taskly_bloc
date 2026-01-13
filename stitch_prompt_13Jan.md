# Stitch Prompts — 13 Jan 2026

This file contains **three standalone prompts** (one per screen). Each prompt is intended to be copy/pasted on its own.

Conventions used in all prompts:
- Date format: `EEE, d MMM yyyy` (example: `Tue, 13 Jan 2026`).
- Priority format: `P0` (highest) to `P3` (lowest).
- For this version, every task and project must have values for all optional fields that can be displayed.

Global data constraints (applies to every prompt):
- Use ONLY the data explicitly listed in the prompt.
- Do NOT invent any additional Values, Projects, Tasks, alerts, issues, reviews, dates, counts, labels, or placeholder text.
- If the UI would normally require more items than provided, leave that part empty or reuse the provided items exactly as written (do not create new ones).

Shared row schemas (used across all prompts):

Task row shows these fields:
- Checkbox: `checked` / `unchecked`
- Pin: `shown` / `hidden`
- Title
- Priority
- Status tag (agenda only): `START` / `DUE` / `IN PROGRESS`
- Meta fields: Project, Date token, Repeat, Primary value, Secondary values (0–2)

Project row shows these fields:
- Title
- Priority
- Progress (completed/total)
- Values (primary + secondary 0–2)
- Start date
- Deadline date
- Repeat

---

## Prompt 1 — My Day (Tue, 13 Jan 2026)

Create a mobile screen mockup named **“My Day”**.

Data constraints for this prompt:
- You MUST use exactly the Values/Projects/Tasks and the field values specified below.
- You MUST follow the data requirements strictly - use the provided data.
- You MUST NOT make up any additional data or change any provided field values.
- You MUST render every row exactly as specified, showing every field listed for that row (do not omit fields, do not rename fields, do not simplify).

### Global header (always visible at top)

- Date label: `Tue, 13 Jan 2026`
- Screen title: `My Day`
- Avatar chip: initials `SH`

### State A: Focus Mode Required (gate screen)

Layout order (top to bottom):

1) Hero area
- Background: gradient
- Date text (small): `Tue, 13 Jan 2026`
- Title text: `My Day`
- Avatar chip: `SH`

2) Pill label (under hero)
- Text: `SET UP FOCUS MODE`

3) Headline
- Text: `Pick a Focus Mode to Generate Today’s Plan`

4) Description paragraph
- Text: `My Day is powered by Focus Mode. Choose what you want to prioritize, and Taskly will build today’s task list grouped by your Values—plus highlight what’s excluded and why.`

5) Mission (single sentence)
- Text: `Taskly helps you consistently spend your time on what matters most—your values, your journal, and your commitments.`

6) Primary CTA button (full width)
- Label: `Choose Focus Mode`

### State B: Focus Mode Enabled (main My Day plan)

Use **exactly these Values**:
- `Health & Energy`
- `Life Admin`
- `Relationships`

Use **exactly these Projects**:
- `Get a passport`
- `Exercise Routines`
- `Organise birthday for Sam`

Use **exactly these Tasks** (from the demo seeder):
- `Book passport photo`
- `Submit application`
- `Plan workouts for next week`
- `Book dinner reservation`

Section order (top to bottom):

#### 1) Reviews Due (card)

Card header:
- Title: `Reviews Due`

Warning banner (single row):
- Icon: warning
- Text: `2 reviews due today`

Exactly 2 review rows (each review row shows: Type label, Title, Description, Due date):

Review row
- Type label: `Project review`
- Title: `Get a passport`
- Description: `Confirm next steps and deadlines.`
- Due date: `Tue, 13 Jan 2026`

Review row
- Type label: `Value review`
- Title: `Health & Energy`
- Description: `Check if this week’s plan supports recovery + movement.`
- Due date: `Tue, 13 Jan 2026`

Footer CTA (single full-width button):
- Label: `Start Check-in`

#### 2) Allocation Alerts (card)

Card header:
- Title: `Alerts`

Summary row:
- Text: `2 alerts`

Exactly 2 alert rows (each alert row shows: Severity, Title, Description):

Alert row
- Severity: `Warning`
- Title: `Plan workouts for next week`
- Description: `Overallocated: 80 min planned, 30 min available.`

Alert row
- Severity: `Info`
- Title: `Book dinner reservation`
- Description: `Has both Values set; verify it’s in the right category.`

Footer row:
- Link text: `View all 2 alerts`

#### 3) Allocation (main list; not a card)

List grouping order:

##### Group header
- Title: `Pinned`
- Count: `1`

Task row
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

##### Group header
- Title: `Health & Energy`
- Count: `1`

Task row
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

##### Group header
- Title: `Life Admin`
- Count: `1`

Task row
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

##### Group header
- Title: `Relationships`
- Count: `1`

Task row
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

Create a mobile screen mockup named **“Scheduled”** using a vertically scrollable agenda layout.

Data constraints for this prompt:
- You MUST use exactly the Values/Projects/Tasks and the field values specified below.
- You MUST NOT make up any additional data or change any provided field values.
- You MUST follow the data requirements strictly - use the provided data.
- You MUST render every row exactly as specified, showing every field listed for that row (do not omit fields, do not rename fields, do not simplify).

Use **exactly these Values**:
- `Life Admin`
- `Relationships`
- `Health & Energy`

Use **exactly these Projects**:
- `Get a passport`
- `Exercise Routines`

Use **exactly these Tasks** (from the demo seeder):
- `Book passport photo`
- `Submit application`
- `Plan workouts for next week`

Agenda status tag rules (encode this because it determines visible labels):
- Tag `DUE` when a task’s deadline date equals the day header date.
- Tag `START` when a task’s start date equals the day header date (and it is not due that same day).
- Tag `IN PROGRESS` when a task’s start date is before the day header date and it is not completed.
- If both start and deadline exist on the same day, prefer tag `DUE`.

Agenda grouping structure (exactly):

### Month: January 2026

#### Day header
- Date label: `Tue, 13 Jan 2026`
- Count: `2`

Items (in this order):

Task item
- Checkbox: `unchecked`
- Pin: `shown`
- Status tag: `START`
- Title: `Book passport photo`
- Priority: `P1`
- Project: `Get a passport`
- Date token: `START Tue, 13 Jan 2026`
- Repeat: `Monthly`
- Primary value: `Life Admin`
- Secondary values: `Relationships`

Project item
- Title: `Exercise Routines`
- Priority: `P2`
- Progress: `1/4 tasks`
- Values: `Health & Energy` (secondary: `Life Admin`)
- Start date: `Mon, 12 Jan 2026`
- Deadline date: `Fri, 16 Jan 2026`
- Repeat: `Weekly`

#### Day header
- Date label: `Wed, 14 Jan 2026`
- Count: `2`

Items (in this order):

Task item
- Checkbox: `unchecked`
- Pin: `hidden`
- Status tag: `DUE`
- Title: `Submit application`
- Priority: `P0`
- Project: `Get a passport`
- Date token: `DUE Wed, 14 Jan 2026`
- Repeat: `Yearly`
- Primary value: `Life Admin`
- Secondary values: `Health & Energy`

Task item
- Checkbox: `unchecked`
- Pin: `hidden`
- Status tag: `IN PROGRESS`
- Title: `Plan workouts for next week`
- Priority: `P0`
- Project: `Exercise Routines`
- Date token: `START Mon, 12 Jan 2026`
- Repeat: `Weekly`
- Primary value: `Health & Energy`
- Secondary values: `Life Admin`

---

## Prompt 3 — Someday (Backlog)

Create a mobile screen mockup named **“Someday”** using a vertically scrollable layout.

Data constraints for this prompt:
- You MUST use exactly the Values/Projects/Tasks and the field values specified below.
- You MUST NOT make up any additional data or change any provided field values.
- You MUST render every row exactly as specified, showing every field listed for that row (do not omit fields, do not rename fields, do not simplify).

Use **exactly these Values**:
- `Home & Comfort`
- `Learning & Curiosity`

Use **exactly these Projects**:
- `Home chores`
- `Learn capital city names`

Use **exactly these Tasks** (from the demo seeder):
- `Declutter “misc” drawer`
- `Organize cleaning supplies`
- `Europe capitals: set 1 (15)`

Section order (top to bottom):

### 1) Issues (card)

Card header:
- Title: `Issues`

Summary row shows severity badges (with counts):
- `Critical 0`
- `Warning 1`
- `Info 0`

Exactly 1 issue row (shows: Severity, Title, Description):

Issue row
- Severity: `Warning`
- Title: `Declutter “misc” drawer`
- Description: `Has multiple Values; confirm it’s intentional.`

### 2) Filter bar

Exactly 2 control rows:

Toggle row
- Label: `Projects only`
- Value: `Off`

Dropdown row
- Label: `Value`
- Selected: `All values`

### 3) Backlog list (main content)

Render groups exactly in the following order and with the following items.

#### Value group header
- Title: `Home & Comfort`
- Count: `2`

Project row (subgroup)
- Title: `Home chores`
- Priority: `P2`
- Progress: `0/6 tasks`
- Values: `Home & Comfort` (secondary: `Learning & Curiosity`)
- Start date: `Tue, 20 Jan 2026`
- Deadline date: `Tue, 3 Feb 2026`
- Repeat: `Monthly`

Task row
- Checkbox: `unchecked`
- Pin: `hidden`
- Title: `Declutter “misc” drawer`
- Priority: `P2`
- Project: `Home chores`
- Date token: `DUE Tue, 3 Feb 2026`
- Repeat: `Monthly`
- Primary value: `Home & Comfort`
- Secondary values: `Learning & Curiosity`

Task row
- Checkbox: `unchecked`
- Pin: `hidden`
- Title: `Organize cleaning supplies`
- Priority: `P3`
- Project: `Home chores`
- Date token: `START Tue, 20 Jan 2026`
- Repeat: `Weekly`
- Primary value: `Home & Comfort`
- Secondary values: `Learning & Curiosity`

#### Value group header
- Title: `Learning & Curiosity`
- Count: `1`

Project row (subgroup)
- Title: `Learn capital city names`
- Priority: `P3`
- Progress: `0/8 tasks`
- Values: `Learning & Curiosity` (secondary: `Home & Comfort`)
- Start date: `Mon, 19 Jan 2026`
- Deadline date: `Fri, 30 Jan 2026`
- Repeat: `Weekly`

Task row
- Checkbox: `unchecked`
- Pin: `hidden`
- Title: `Europe capitals: set 1 (15)`
- Priority: `P3`
- Project: `Learn capital city names`
- Date token: `START Mon, 19 Jan 2026`
- Repeat: `Daily`
- Primary value: `Learning & Curiosity`
- Secondary values: `Home & Comfort`

---

## Prompt 4 — Components (Entity View Variations)

Create a **component preview screen** named **“Components”**.

Data constraints for this prompt:
- You MUST use exactly the component list and the field values specified below.
- You MUST NOT make up any additional data or change any provided field values.
- You MUST show every field listed for every component example (no omissions).
- You MUST follow the data requirements strictly - use the provided data.

Output requirements:
- Produce **3 variations** of the same Components screen:
	- Variation A: `Compact` density, `Light` style.
	- Variation B: `Comfortable` density, `Light` style.
	- Variation C: `Spacious` density, `Dark` style.
- All three variations MUST show the same components and the same data.

### Provided data (use ONLY this)

Values:
1) Value
- Name: `Health & Energy`
- Stats chips (render all): `Active 12`, `Due 3`, `Weekly 2`, `Streak 5d`

2) Value
- Name: `Life Admin`
- Stats chips (render all): `Active 8`, `Due 1`, `Pinned 1`, `Alerts 2`

Projects:
1) Project
- Title: `Get a passport`
- Priority: `P1`
- Progress: `2/5 tasks`
- Values: `Life Admin` (secondary: `Relationships`)
- Start date: `Mon, 12 Jan 2026`
- Deadline date: `Fri, 30 Jan 2026`
- Repeat: `Monthly`

2) Project
- Title: `Exercise Routines`
- Priority: `P2`
- Progress: `1/4 tasks`
- Values: `Health & Energy` (secondary: `Life Admin`)
- Start date: `Mon, 12 Jan 2026`
- Deadline date: `Fri, 16 Jan 2026`
- Repeat: `Weekly`

Tasks:
1) Task
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

2) Task
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

3) Task
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

### Components to show (in this order)

#### 1) Section header row
- Title: `TaskView — List`

#### 2) TaskView — List variant (3 rows)

Render three task rows using the Tasks data above.

Each TaskView (list) row MUST show these fields:
- Checkbox, Pin, Title, Priority
- Project, Date token, Repeat, Primary value, Secondary values

#### 3) Section header row
- Title: `TaskView — Agenda`

#### 4) TaskView — Agenda variant (3 rows)

Render the same three tasks again, but with an agenda tag.

Agenda tag rules (encode this because it determines visible labels):
- Show tag `DUE` if the Date token begins with `DUE`.
- Show tag `START` if the Date token begins with `START`.
- Show tag `IN PROGRESS` for the task `Plan workouts for next week` ONLY.

Each TaskView (agenda) row MUST show these fields:
- Checkbox, Tag, Title
- Project, Date token, Repeat, Primary value, Secondary values
- Priority (still visible)
- Pin (still visible)

#### 5) Section header row
- Title: `ProjectView — List`

#### 6) ProjectView — List variant (2 rows)

Render two project rows using the Projects data above.

Each ProjectView (list) row MUST show these fields:
- Title, Priority, Progress
- Values (primary + secondary)
- Start date, Deadline date, Repeat

#### 7) Section header row
- Title: `ProjectView — Agenda`

#### 8) ProjectView — Agenda variant (2 rows)

Render the same two projects again, but in the agenda-card style.

Each ProjectView (agenda) row MUST show these fields:
- Title, Priority, Progress
- Values (primary + secondary)
- Start date, Deadline date, Repeat

#### 9) Section header row
- Title: `ValueView — Compact`

#### 10) ValueView — Compact card variant (2 cards)

Render two value cards using the Values data above.

Each ValueView card MUST show these fields:
- Name
- All listed stats chips (exact text)
