# Spec: Plan My Day Auto-Plan (Must-Include Due/Planned)

Created at: 2026-02-01
Status: Draft
Owner: TBD

## Summary

Plan My Day becomes an auto-plan flow with a compact, single-list UI. The system
automatically includes:
- routines scheduled today
- tasks due today or overdue
- tasks planned for today or earlier (start <= today)

Users can quickly bulk-reschedule due/planned items. Suggestions fill remaining
capacity using ratings-led allocation. My Day remains the execute screen, with
compact rows and cleaned copy.

## Goals

- Ensure due/planned items are never missed (auto-included by default).
- Make it fast to reschedule many items when over capacity.
- Keep Plan My Day lightweight and mobile-friendly.
- Preserve ratings-led suggestions without heavy UI chrome.
- Keep My Day calm and compact.

## Non-goals

- No scoring knobs for users (no urgency multipliers or sliders).
- No "recently active" candidate shelf.
- No "why" badges in the main list.
- No project-heavy metadata in the main list.

## Product copy (cleaned)

My Day subtitle:
- "Your plan for today."

Plan My Day subtitle:
- "Build today's plan."

Over-capacity banner:
- "Over capacity (X/8). Reschedule items or adjust limit."

## Daily limit

- Default daily limit: 8
- Adjustable per day via a quick stepper in Plan My Day.
- Suggestions are suppressed when over capacity.

## Auto-plan algorithm (ordered)

Inputs:
- dayKeyUtc
- routines scheduled today
- tasks due today or overdue
- tasks with start <= today (planned)
- previously selected items (if any)
- value rating summaries

Steps:
1) Start with auto-included items (base plan):
   - routines scheduled today
   - due today + overdue tasks
   - planned tasks (start <= today)
   - previously selected (if applicable)

2) If base plan count > daily limit:
   - show over-capacity banner
   - suppress suggestions until under capacity
   - provide bulk reschedule actions for Due Today and Planned shelves

3) If base plan count < daily limit:
   - fill remaining slots using ratings-led allocation
   - suggestions are drawn from the pool excluding already selected items

## Allocation details (fill stage)

- Compute value quotas proportional to value rating averages.
- Within each value, choose tasks with this tie-break order:
  1) due soon (next 7 days, excluding due today)
  2) priority
  3) oldest updated/created
  4) name

## Plan My Day UI

### Structure (single list, routines first)

- App bar title: "Plan My Day"
- Subtitle: "Build today's plan."
- Summary bar:
  - "Today's plan: X items"
  - "Limit: 8" (tap to adjust)
  - Over-capacity banner when needed

Sections (order):
1) Due Today (auto-included)
2) Planned (auto-included; start <= today)
3) Routines (auto-included when scheduled today)
4) Suggestions (value pools, only if under capacity)

Note: The list is single-column and mobile-first. Section headers are allowed
in Plan My Day to support bulk actions, but list items themselves are compact.

### Due Today shelf

- Includes overdue + due today tasks.
- All items are auto-included in the plan.
- Bulk action: "Reschedule all due".

### Planned shelf

- Includes tasks with start <= today (and not already in Due Today).
- All items are auto-included in the plan.
- Bulk action: "Reschedule all planned".

### Suggestions shelf

- Ratings-led suggestions to fill remaining slots.
- Value groups ordered by **lowest average rating first** (default), with an
  optional sort that prioritizes **most negative trend**.
- Each value group shows its average rating and trend delta.
- **Cap**: show a max of 3 items per value in the main list (mobile cap).
- **Show more** reveals the remaining pool for the value (no re-allocation).
- No "Recently active" shelf.

### No values state (Plan My Day)

- If the user has zero values configured:
  - Suggestions shelf is replaced by an empty state card.
  - Title: "No values yet."
  - Body: "Set up values to get ratings-led suggestions."
  - CTA: "Set up values"

### Bulk reschedule

- Triggered per shelf (Due Today, Planned).
- Options:
  - Tomorrow
  - This weekend
  - Next week
  - Pick a date
- Applies to all items in that shelf; optional multi-select exceptions if needed.

## My Day UI (execute)

- Subtitle: "Your plan for today."
- Summary strip (lightweight):
  - "Planned: X"
  - "Routines: Y"
- Single list with routines first, tasks below.
- No section headers needed; routine tiles are visually distinct.
- CTA (always visible):
  - No plan: primary "Build today's plan"
  - Plan exists: secondary/ghost "Edit today's plan"
- Row density toggle (compact/standard) in the app bar.

## Row density toggles (global)

- User-adjustable on:
  - My Day
  - Scheduled
  - Projects
- Not user-adjustable on:
  - Plan My Day
  - Values
- Persist per screen.
- Default density:
  - Compact on mobile widths
  - Standard on larger screens

### Empty state logic

If planned items exist in backlog:
- Title: "No plan yet."
- Body: "You have tasks ready to choose from."
- CTA: "Build today's plan"

If no tasks exist:
- Title: "All clear for today."
- Body: "Add a task to get started."
- CTA: "Add a task"

## Row design (tasks)

### Plan My Day task row (plan-pick)

- Compact, single-line layout (matches compact row).
- Value icon appears before the title to balance the add/check affordance.
- Uses add/check icon (no checkbox).
- Swipe to snooze remains available.
- Dates:
  - Flag icon before deadline.
  - Calendar icon before start/planned (only when no deadline).

### My Day task row (compact, single line)

- Title (flex, 1 line)
- Due label (fixed width)
  - Overdue / Due today / Due Tue
- Value icon (inline with title in Plan My Day; always visible)
- Actions:
  - My Day: completion toggle only (no trailing action slot)

### Routine rows

Compact / Plan-pick:
- Single-line title row with value icon + progress text (e.g., "1/3 · 4 days left").
- Scheduled routines add a second line of day circles (Mon–Sun).

Standard:
- Title line with value icon.
- Progress row (bar + counts) for flexible and scheduled routines.
- Scheduled routines show a second line of day circles.

Notes:
- Selection mode hides the primary "Log today" action and shows selection.

Notes:
- If behind, meta line may switch to "Catch-up day".

## Interaction rules

- Tap row opens editor (both tasks and routines).
- Completion uses checkbox/toggle (My Day only).
- Plan My Day selection uses add/check icon.
- Suggestions include a Swap action that replaces the current suggestion with
  another option from the same value (single-value swap).
- Due/Planned are pre-selected; tapping the add/check icon opens a
  "Reschedule / not today" sheet and removes the item from today's plan.
- When a reschedule sheet confirms, the row animates out of its shelf, the list
  recomputes immediately, and a small "Updated" toast appears for 1-2 seconds.

## Edge cases

- If due+planned+scheduled routines exceed limit, suggestions are hidden and
  over-capacity banner is shown until the user reschedules items or raises limit.
- Planned shelf excludes any items already in Due Today.
- If no suggestions are available, Suggestions shelf is hidden.

## Swap sheet (suggestions)

- Swap is single-value only (replacement options come from the same value).
- Swap sheet shows the full value list, prioritized by the allocation
  tie-break order (due soon → priority → oldest → name).
- List is scrollable; if no alternatives exist, show an empty state.

## Analytics (optional)

- Track bulk reschedule usage per shelf.
- Track average over-capacity count.
- Track acceptance rate of suggested items.

## UI wireframe map (component list + layout blocks)

### Plan My Day (Plan)

#### Layout blocks (top -> bottom)

1) App bar
   - Title: "Plan My Day"
   - Close action

2) Header block
   - Subtitle: "Build today's plan."

3) Summary bar
   - Planned count: "Today's plan: X items"
   - Daily limit stepper: "Limit: 8"
   - Over-capacity banner (conditional)

4) Due Today shelf (auto-included)
   - Header: "Due Today"
   - Bulk action: "Reschedule all due"
   - List of compact task rows

5) Planned shelf (auto-included)
   - Header: "Planned"
   - Bulk action: "Reschedule all planned"
   - List of compact task rows

6) Routines shelf (auto-included)
   - Header: "Routines"
   - List of compact routine rows

7) Suggestions shelf (conditional, only if under capacity)
   - Header: "Suggestions"
   - Flat list with inline value chips as dividers

8) Bottom action bar
   - Primary: "Save plan"

#### Component list

- App bar (title + close)
- Header text block (subtitle)
- Summary bar with:
  - planned count
  - limit stepper
  - over-capacity banner (inline)
- Shelf header component with:
  - title
  - count (optional)
  - bulk action button
- Compact task row (single line)
- Compact routine row (two line)
- Value divider chip
- Bottom action bar (primary)
- Reschedule sheet (modal)

#### Row slots (Plan My Day task row)

```
[Value icon + Title (flex, 1 line)]  [Date label w/ icon]  [Add/check]
```

---

### My Day (Execute)

#### Layout blocks (top -> bottom)

1) App bar
   - Title: "My Day"
   - Settings / overflow

2) Header block
   - Subtitle: "Your plan for today."
   - CTA (always visible):
     - No plan: primary "Build today's plan"
     - Plan exists: secondary/ghost "Edit today's plan"

3) Summary strip
   - "Planned: X"
   - "Routines: Y"

4) Single list (routines first)
   - Compact routine rows
   - Compact task rows

5) Empty state (conditional)
   - If tasks exist: "No plan yet." + "Build today's plan" CTA
   - If no tasks: "All clear for today." + "Add a task" CTA

#### Component list

- App bar (title + menu)
- Header text block (subtitle + CTA)
- Summary strip (counts)
- Compact routine row
- Compact task row
- Empty state component (title/body/CTA)

#### Row slots (compact tasks)

```
[✓]  [Title (flex, 1 line)]  [Due label]  [Value icon]
```

#### Row slots (compact routines)

```
[✓]  [Routine icon]  [Name (1 line)]  [Value icon]
      1/3 this week      [tiny progress bar ->]   [Scheduled/Flexible]
```


