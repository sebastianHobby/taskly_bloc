# Taskly: Values-Aligned Task Management

Taskly is a comprehensive productivity app designed to help you prioritize and plan based on your personal values and wellbeing. Rather than just tracking what you need to do, Taskly helps you understand *why* you're doing it and ensures your daily actions align with what matters most to you.


Choose how you work with Focus Modes: Intentional for deep, value-aligned focus; Sustainable for balanced progress across all life areas; or Responsive when deadlines demand attention. The algorithm adapts, but your values stay central.

The result: productivity with purpose, not just busyness.




# Taskly UI Requirements

> Requirements specification for AI mockup and implementation generation.
> This document defines **what** the UI must display and **how** users interact with it.
> It does not prescribe implementation details, framework choices, or code patterns.


# Priority
When generating mockups do it in groups based on the following prioritized tiers
Screen Implementation Priority
Tier 1: Critical Path to My Day
Required for first-time user to reach My Day

#	Screen	Reason
1	Splash	App entry point, auth check
2	Welcome to Taskly	New user landing
3	Sign Up	Account creation
4	Sign In	Returning users
5	Onboarding / Focus Mode Wizard	Must select focus mode before My Day
6	My Day	Primary screen - core experience

Tier 2: Core Task Management
Essential for daily use after My Day is working

#	Screen	Reason
7	New/Edit Task	Can't use My Day without creating tasks
8	New/Edit Value	Tasks require primary value
9	My Values	View/manage values
10	Navigation Drawer	Access other screens on mobile
Tier 3: Organization & Planning
Extends task management beyond daily view

#	Screen	Reason
11	Someday	Unscheduled tasks need a home
12	Scheduled	Date-based task planning
13	Projects	Task organization
14	Project Detail	View tasks in project context
15	New/Edit Project	Create project containers
16	Value Detail	View tasks by value
Tier 4: Reflection & Insights
Wellbeing tracking and review features

#	Screen	Reason
17	Journal	Entry list
18	Journal Detail/Edit	Create reflections
19	Insights	Stats and insights
20	Review Run	Guided reflection
Tier 5: Configuration
Settings and customization

#	Screen	Reason
21	Settings	Hub for configuration
22	Allocation Settings	Focus mode tuning
23	Allocation Exception Rules	Alert configuration
24	Review Settings	Review frequency
25	Navigation Settings	Bottom nav order
26	Forgot Password	Account recovery



## 1. Document Conventions

### Terminology

| Term | Definition |
|------|------------|
| **Value** | Life area entity representing what matters to you (e.g., Career, Health, Family). User-created and assigned to tasks. |
| **Focus Mode** | Daily prioritization preset (Intentional, Sustainable, Responsive, Personalized) controlling how tasks are scored for My Day. |
| **Primary Value** | A task's main Value association (100% weight in scoring). Required for all tasks. |
| **Secondary Values** | A task's additional Value associations (30% weight, powers Synergy scoring). Optional. |
| **Value Priority** | A Value's importance level (High/Medium/Low) — configured per Value, affects long-term balance. |

> **Note:** Values and Focus Modes are distinct concepts. Values are *what* you invest time in. Focus Modes control *how* the algorithm selects today's tasks.

### Notation

- `⊕EntityName` references entity field rules defined in Part 3
- Constraint levels:
  - `[MUST]` = Required, non-negotiable
  - `[SHOULD]` = Recommended, deviate only with good reason
  - `[MAY]` = Optional, at implementer discretion
- Field visibility in entity tables:
  - `✅` = Show in this context
  - `⚠️` = Conditional (see Condition column)
  - `❌` = Hidden in this context
  - Cell text after symbol indicates rendering variant (e.g., `✅ faded`, `✅ chips`)

---

## 2. Global Design Requirements

### Floating Action Button (FAB) Actions

FAB appears on screens where users can create new entities. The action depends on context:

| Screen | FAB Visible | Primary Action | ID | Secondary Actions |
|--------|:-----------:|----------------|:---|-------------------|
| My Day | ✅ | Create Task | `fab_my_day` | — |
| Someday | ✅ | Create Task | `fab_someday` | — |
| Scheduled | ✅ | Create Task | `fab_scheduled` | — |
| Projects | ✅ | Create Project | `fab_projects` | — |
| Project Detail | ✅ | Create Task (in project) | `fab_project_detail` | — |
| My Values | ✅ | Create Value | `fab_values` | — |
| Value Detail | ✅ | Create Task (with value) | `fab_value_detail` | — |
| Journal | ✅ | Create Journal Entry | `fab_journal` | — |
| Insights | ❌ | — | — | — |
| Settings | ❌ | — | — | — |

**FAB Behavior Rules:**
- `[MUST]` FAB uses primary action directly (single tap creates)
- `[MUST]` When opened from context (project, value), pre-populate relevant fields
- `[SHOULD]` FAB hides when user scrolls down, reappears on scroll up
- `[MAY]` Provide extended FAB with label on larger screens

---

### Swipe Gesture Actions

Consistent swipe actions across all list-based screens:

| Direction | Action | Visual | Applies To |
|-----------|--------|--------|------------|
| Swipe Left | Delete | Red background with trash icon | Tasks, Projects, Values, Journal entries |
| Swipe Right | Complete/Uncomplete | Green background with check icon | Tasks only |

**Swipe Behavior Rules:**
- `[MUST]` Left swipe reveals delete action with confirmation
- `[MUST]` Right swipe on tasks toggles completion state
- `[MUST]` Projects do NOT support right-swipe completion (use detail view)
- `[SHOULD]` Show visual feedback during swipe (color reveal)
- `[SHOULD]` Provide undo snackbar after delete action
- `[MAY]` Support swipe thresholds (short swipe reveals, long swipe executes)

---

### Grouping and Sorting Rules

When items are grouped by value (My Day, Someday, Value Detail):

| Sort Level | Criteria | Order |
|------------|----------|-------|
| 1. Group | Value Priority | High → Medium → Low |
| 2. Within Group | Alphabetical by value name | A → Z |
| 3. Within Value | Item Priority | P1 → P2 → P3 → P4 → None |
| 4. Tie-breaker | Alphabetical by item name | A → Z |

**Grouping Rules:**
- `[MUST]` Group headers include value name, icon, color, and priority badge
- `[MUST]` High-priority values appear before medium, medium before low
- `[MUST]` Within same priority level, sort alphabetically by value name
- `[MUST]` Within each value group, sort by item priority then name

---

### Completed Items Policy

How completed tasks and projects are handled across the app:

| Aspect | Behavior |
|--------|----------|
| **Retention** | Forever — completed items are never auto-deleted |
| **Default visibility** | Hidden by filter (Active tab selected by default) on Projects/Values |
| **Completed section** | Collapsed by default in Project Detail |
| **Removal** | Completed items removed entirely from My Day, Scheduled, Someday |

**Completed Items Rules:**
- `[MUST]` Retain completed items indefinitely
- `[MUST]` Default to "Active" filter tab on screens with filter tabs (Projects, Values)
- `[MUST]` Provide "Completed" filter tab on screens with filter tabs to view completed items
- `[MUST]` Remove completed items entirely from My Day, Scheduled, and Someday views
- `[SHOULD]` Collapse completed section by default in Project Detail
- `[MAY]` Provide bulk archive/delete for old completed items in future

---

### My Day Allocation Refresh

When the allocation service recalculates today's task list:

| Trigger | Behavior |
|---------|----------|
| **Midnight** | Automatic refresh when date changes |
| **App open (stale)** | Refresh if last allocation was before today |
| **Manual refresh** | User can pull-to-refresh My Day screen |
| **Settings change** | Refresh when focus mode or weights changed |

**Allocation Refresh Rules:**
- `[MUST]` Recalculate allocation at midnight (if app is running)
- `[MUST]` Recalculate on app open if last allocation date < today
- `[MUST]` Recalculate when focus mode or allocation settings change
- `[SHOULD]` Provide pull-to-refresh gesture on My Day
- `[SHOULD]` Show "Last updated" timestamp in Focus Mode Banner

---

### Theming

- `[MUST]` Support Material Design 3 theming system
- `[MUST]` Generate color palette from a single seed color
- `[MUST]` Support light and dark themes
- `[MUST]` Allow user to toggle between light, dark, and system theme modes
- `[MUST]` Define centralized theme with consistent typography, spacing, and color usage
- `[SHOULD]` Use semantic color roles (primary, secondary, surface, error, etc.)
- `[SHOULD]` Ensure text contrast ratios meet WCAG 2.1 AA standards (4.5:1 minimum)
- `[MAY]` Support custom accent colors per user preference

### Typography

- `[MUST]` Define consistent text hierarchy (display, headline, title, body, label)
- `[SHOULD]` Use system fonts or Google Fonts for readability
- `[SHOULD]` Support dynamic text scaling for accessibility

### Spacing and Layout

- `[MUST]` Use consistent spacing scale throughout app
- `[SHOULD]` Adapt layouts responsively for different screen sizes
- `[SHOULD]` Provide adequate touch targets (minimum 48x48 dp)

### Empty States

- `[MUST]` Show illustrated empty state with single call-to-action when lists are empty
- `[SHOULD]` Provide contextual message explaining what the screen will show

### Accessibility

- `[MUST]` Provide semantic labels for all interactive elements
- `[MUST]` Ensure all interactive elements are keyboard/screen-reader accessible
- `[SHOULD]` Test with TalkBack and VoiceOver

---

### Component Specifications

#### Value Picker

Used for selecting primary and secondary values when creating/editing tasks and projects.

**Shows:**
- List of all user values with:
  - Value name
  - Value icon
  - Value color indicator
  - Value priority badge
- Clear visual distinction between primary and secondary selection
- Current selection state

**Selection Behavior:**
- First value selected becomes Primary (required)
- Additional values become Secondary (optional)
- Tapping primary value deselects it (and promotes first secondary if any)
- Tapping secondary value deselects it
- Maximum secondary values: No limit

**Visual States:**
| State | Visual Treatment |
|-------|------------------|
| Not selected | Default appearance |
| Primary | Full color, "Primary" badge, prominent border |
| Secondary | Faded (30% opacity), "Secondary" badge |

**Constraints:**
- `[MUST]` Require at least one value (primary)
- `[MUST]` Visually distinguish primary from secondary selection
- `[MUST]` Show value priority badge in picker
- `[SHOULD]` Show most recently used values at top
- `[MAY]` Support quick-add new value from picker

---

#### Priority Selector

Used for selecting task priority level.

**Options:**
| Priority | Label | Color | Description |
|----------|-------|-------|-------------|
| P1 | Highest | Red | Critical, must do today |
| P2 | High | Orange | Important, do soon |
| P3 | Medium | Yellow | Normal priority |
| P4 | Low | Blue | Nice to have |
| None | No Priority | Gray | Unset (default) |

**Shows:**
- Segmented button or chip group with P1, P2, P3, P4, None options
- Color-coded indicators
- Currently selected state

**Constraints:**
- `[MUST]` Default to "None" (no priority) for new items
- `[MUST]` Show color indicator for each priority level
- `[MUST]` Support single selection only
- `[SHOULD]` Use consistent priority colors throughout app

---

#### Repeat Rule Picker

Used for configuring recurrence patterns on tasks and projects.

**Frequency Options:**
| Frequency | Label | Example |
|-----------|-------|---------|
| None | Does not repeat | — |
| Daily | Every N day(s) | Every day, Every 3 days |
| Weekly | Every N week(s) | Every week, Every 2 weeks |
| Monthly | Every N month(s) | Every month, Every 3 months |
| Yearly | Every N year(s) | Every year |

**Configuration Fields:**
- Frequency selector (segmented button)
- Interval input (numeric, default: 1)
- Day-of-week selector (Weekly only, multi-select)
- End condition (optional):
  - Never (default)
  - After N occurrences
  - Until specific date

**Repeat From Completion Toggle:**
- When OFF: Fixed interval — recurs on fixed dates from original start
- When ON: After completion — recurs N days/weeks after last completion

**Shows:**
- Human-readable preview of rule (e.g., "Every 2 weeks on Mon, Wed, Fri")

**Constraints:**
- `[MUST]` Support daily, weekly, monthly, yearly frequencies
- `[MUST]` Support configurable interval (1-99)
- `[MUST]` Support day-of-week selection for weekly frequency
- `[MUST]` Support "repeat from completion" toggle
- `[MUST]` Show human-readable preview of configured rule
- `[SHOULD]` Default frequency to "None"
- `[MAY]` Provide preset shortcuts (e.g., "Biweekly", "Quarterly")

---

#### Date Picker

Used for selecting start date and deadline date on tasks and projects.

**Shows:**
- Date input field with calendar icon
- Calendar modal for date selection
- Clear button to remove date

**Validation Rules:**
- Deadline cannot be before start date (if both set)
- No time component — dates only
- No specific format enforced (use device/locale default)

**Constraints:**
- `[MUST]` Validate deadline ≥ start date when both are set
- `[MUST]` Use date-only selection (no time picker)
- `[MUST]` Allow clearing either date independently
- `[SHOULD]` Highlight invalid date combinations with error message
- `[SHOULD]` Use device locale for date display format
- `[MAY]` Provide quick shortcuts ("Today", "Tomorrow", "Next Week")

---

### AI Mockup Generation Guidelines

When generating UI mockups from these requirements:

- `[MUST]` Show representative mix of tasks AND projects on screens that display both
- `[MUST]` Include examples of all data combinations (with/without deadlines, all priority levels, pinned items, repeating items)
- `[MUST]` Show tasks with checkboxes and projects with progress rings (no checkbox)
- `[MUST]` Demonstrate completed items styling (strikethrough for tasks, "Completed ✓" badge for projects)
- `[SHOULD]` Show filter tabs in active and inactive states
- `[SHOULD]` Include value color variations to demonstrate value grouping
- `[SHOULD]` Show both empty states and populated states

---

## 3. Entity Field Requirements

### Completion Behavior: Tasks vs Projects

| Aspect | Tasks | Projects |
|--------|-------|----------|
| **Completion UI** | ☑️ Checkbox in list view | Progress ring in list, complete via detail |
| **How to complete** | Single tap on checkbox | Detail view action or prompt on last task |
| **Visual when completed** | Strikethrough + faded | "Completed ✓" badge, no progress bar |
| **Filter tabs** | All \| Active \| Completed | All \| Active \| Completed |
| **Last item prompt** | N/A | "All tasks done! Complete project?" |

**Rationale:** Projects are containers of work. Accidental completion is costly and progress visibility is more valuable than a binary checkbox. Tasks are atomic and benefit from quick completion.

---

### ⊕Task

> Core work item with value alignment and scheduling

| Field | List | Detail | Create | Edit | Condition |
|-------|:----:|:------:|:------:|:----:|----------|
| name | ✅ | ✅ | ✅ | ✅ | — |
| completed | ✅ checkbox | ✅ | ❌ | ✅ | Create: hidden (new tasks start incomplete) |
| primaryValue | ✅ color | ✅ full | ✅ required | ✅ required | — |
| secondaryValues | ✅ faded | ✅ list | ✅ optional | ✅ optional | — |
| deadlineDate | ✅ relative | ✅ | ✅ | ✅ | — |
| startDate | ✅ | ✅ | ✅ | ✅ | — |
| priority | ✅ badge | ✅ | ✅ | ✅ | — |
| isPinned | ⚠️ icon | ✅ | ✅ toggle | ✅ toggle | In list: only when true |
| project | ⚠️ | ✅ | ✅ picker | ✅ picker | Hidden when viewing within project context or My Day |
| description | ❌ | ✅ | ✅ | ✅ | — |
| repeatRule | ⚠️ icon | ✅ | ✅ picker | ✅ picker | In list: only when repeating |

**Display Rules:**

- `[MUST]` Checkbox always visible and tappable in all contexts
- `[MUST]` Primary value shown with full color saturation
- `[MUST]` Secondary values shown at reduced opacity (30% faded)
- `[SHOULD]` Hide project name when already in project context
- `[SHOULD]` Truncate name to 2 lines maximum in list views
- `[MAY]` Show deadline in relative format ("Tomorrow", "In 3 days")

---

### ⊕Project

> Container for related tasks with shared context

| Field | Card | Detail | Picker | Create | Edit | Condition |
|-------|:----:|:------:|:------:|:------:|:----:|----------|
| name | ✅ | ✅ | ✅ | ✅ | ✅ | — |
| primaryValue | ✅ color | ✅ full | ❌ | ✅ required | ✅ required | — |
| secondaryValues | ✅ faded | ✅ list | ❌ | ✅ optional | ✅ optional | — |
| taskCount | ✅ | ✅ | ✅ | ❌ | ❌ | Computed, read-only |
| completedCount | ✅ | ✅ | ❌ | ❌ | ❌ | Computed, read-only |
| progress | ✅ bar | ✅ bar | ❌ | ❌ | ❌ | Computed. Hidden when completed |
| deadlineDate | ⚠️ badge | ✅ | ❌ | ✅ | ✅ | In card: show badge if within 7 days |
| startDate | ❌ | ✅ | ❌ | ✅ | ✅ | — |
| priority | ✅ badge | ✅ badge | ❌ | ✅ | ✅ | — |
| isPinned | ⚠️ icon | ✅ | ❌ | ✅ toggle | ✅ toggle | In card: only when true |
| description | ❌ | ✅ | ❌ | ✅ | ✅ | — |
| completed | ❌ | ✅ | ❌ | ❌ | ✅ | Create: hidden (defaults to false). Card: shown as "Completed ✓" badge when true |
| repeatRule | ⚠️ icon | ✅ | ❌ | ✅ picker | ✅ picker | In card: only when repeating |

**Display Rules:**

- `[MUST]` Show task count on cards
- `[MUST]` Primary value shown with full color saturation (consistent with ⊕Task)
- `[MUST]` Secondary values shown at reduced opacity (30% faded, consistent with ⊕Task)
- `[MUST]` No checkbox on project cards — completion via detail view only
- `[MUST]` Show progress ring/indicator in place of checkbox on cards
- `[MUST]` Completed projects show "Completed ✓" badge, no progress bar
- `[SHOULD]` Show progress bar when project has tasks and is not completed
- `[SHOULD]` Prompt user when last task in project is completed: "All done! Complete project?"
- `[MAY]` Show deadline badge when urgent (within 7 days)

---

### ⊕Value

> Life area representing what matters to you (e.g., Career, Health, Family). Distinct from Focus Modes, which control daily task selection strategy.

| Field | Card | Detail | Picker | Create | Edit | Condition |
|-------|:----:|:------:|:------:|:------:|:----:|----------|
| name | ✅ | ✅ | ✅ | ✅ | ✅ | — |
| color | ✅ background | ✅ accent | ✅ indicator | ✅ picker | ✅ picker | — |
| icon | ✅ | ✅ | ✅ | ✅ picker | ✅ picker | — |
| priority | ✅ badge | ✅ badge | ✅ badge | ✅ selector | ✅ selector | Default: Medium |
| taskCount | ✅ | ✅ | ❌ | ❌ | ❌ | Computed, read-only |
| completionRate | ✅ | ⚠️ | ❌ | ❌ | ❌ | Computed. In detail: only when >0 tasks |
| lastReviewedAt | ⚠️ | ⚠️ | ❌ | ❌ | ❌ | System field. Show stale warning if >30 days |

**Display Rules:**

- `[MUST]` Priority badge visible in all contexts including group headers
- `[MUST]` Color distinguishes values visually
- `[SHOULD]` Show stale indicator if not reviewed in over 30 days

**Primary Value Deletion Behavior:**

When a value that is set as primary on tasks/projects is deleted:

| Scenario | Behavior |
|----------|----------|
| Task/project has secondary values | Highest priority secondary becomes new primary |
| Task/project has no secondary values | Task/project has no primary value (orphaned state) |
| Multiple secondaries, same priority | Alphabetically first becomes primary |

**Deletion Rules:**
- `[MUST]` Promote highest-priority secondary to primary when primary is deleted
- `[MUST]` Break ties alphabetically when multiple secondaries have same priority
- `[SHOULD]` Warn user about affected tasks/projects before deletion
- `[SHOULD]` Show count of affected items in confirmation dialog

---

### ⊕FocusMode

> Daily work style preset controlling how tasks are scored for My Day. Distinct from Values (life areas) which tasks are categorized into.

| Field | Indicator | Hero | Config | Condition |
|-------|:---------:|:----:|:------:|----------|
| name | ✅ | ✅ | ✅ | — |
| icon | ✅ | ✅ | ❌ | — |
| tagline | ❌ | ✅ | ❌ | — |
| description | ❌ | ✅ | ❌ | — |
| recoveryEnabled | ⚠️ icon | ✅ toggle | ✅ toggle | In indicator: only when enabled |
| importanceWeight | ❌ | ❌ | ✅ slider | Personalized mode only |
| urgencyWeight | ❌ | ❌ | ✅ slider | Personalized mode only |
| synergyWeight | ❌ | ❌ | ✅ slider | Personalized mode only |
| balanceWeight | ❌ | ❌ | ✅ slider | Personalized mode only |
| allocatedCount | ❌ | ✅ | ❌ | — |

**Display Rules:**

- `[MUST]` Show mode name in all contexts
- `[MUST]` Hero view shows allocated task count
- `[SHOULD]` Show recovery icon only when recovery mode enabled
- `[MAY]` Show weight preview visualization in hero view

---

### ⊕Alert

> System notification requiring user attention

| Field | Collapsed | Expanded | Condition |
|-------|:---------:|:--------:|-----------|
| severity | ✅ color | ✅ color+icon | — |
| title | ✅ | ✅ | — |
| message | ✅ truncated | ✅ full | — |
| taskCount | ✅ | ❌ | — |
| tasks | ❌ | ✅ list | — |
| actions | ❌ | ✅ buttons | — |

**Display Rules:**

- `[MUST]` Banner color reflects severity (error color for critical, warning color for warning, info color for notice)
- `[MUST]` Tapping collapsed banner expands inline (not navigation)
- `[SHOULD]` Show task count in collapsed state
- `[SHOULD]` Provide actionable buttons in expanded state

---

### ⊕Review

> Periodic reflection prompt for wellbeing and progress

| Field | Banner | Settings | Run | Condition |
|-------|:------:|:--------:|:---:|-----------|
| type | ✅ name | ✅ name+desc | ✅ name+desc | — |
| enabled | ❌ | ✅ toggle | ❌ | — |
| frequencyDays | ❌ | ✅ picker | ❌ | — |
| lastCompletedAt | ⚠️ due badge | ✅ date | ❌ | Show badge when overdue |
| steps | ❌ | ❌ | ✅ full | — |

**Display Rules:**

- `[MUST]` Review banner has same visual prominence as warning alerts
- `[MUST]` Tapping review banner navigates to review run screen (These are out of scope for UI design - future task)
- `[SHOULD]` Show "Due" indicator when review is overdue

---

### ⊕Journal

> Reflection entry linked to values and wellbeing. Journal values have no primary/secondary distinction — entries can tag multiple Values equally.

| Field | List | Detail | Create | Edit | Condition |
|-------|:----:|:------:|:------:|:----:|----------|
| date | ✅ | ✅ | ✅ | ⚠️ | Create: defaults to today. Edit: read-only (cannot change entry date) |
| content | ✅ preview | ✅ full | ✅ | ✅ | — |
| values | ✅ chips | ✅ chips | ✅ picker | ✅ picker | — |
| mood | ✅ icon | ✅ icon+label | ✅ picker | ✅ picker | — |
| trackerResponses | ⚠️ summary | ✅ full | ✅ | ✅ | In list: only when recorded |

**Mood Levels:**

| Level | Label | Emoji |
|-------|-------|-------|
| 1 | Very Low | 😢 |
| 2 | Low | 😕 |
| 3 | Neutral | 😐 |
| 4 | Good | 🙂 |
| 5 | Excellent | 😄 |

**Display Rules:**

- `[MUST]` Show date in all contexts
- `[MUST]` Show mood as emoji icon in list view
- `[SHOULD]` Preview first 2-3 lines in list view
- `[SHOULD]` Show tracker summary when trackers recorded
- `[MAY]` Group journal entries by week or month

---

### ⊕Tracker

> Custom tracking item for habits and metrics

| Field | List | Config | Condition |
|-------|:----:|:------:|-----------|
| name | ✅ | ✅ | — |
| type | ❌ | ✅ selector | — |
| scope | ✅ badge | ✅ selector | — |
| options | ❌ | ✅ list | Choice type only |
| minValue | ❌ | ✅ input | Scale type only |
| maxValue | ❌ | ✅ input | Scale type only |
| currentValue | ⚠️ | ❌ | Only if recorded today |

**Display Rules:**

- `[MUST]` Show tracker name in all contexts
- `[MUST]` Show scope badge (Daily/Per-entry) in list
- `[SHOULD]` Show current value if recorded today

---

## 4. Screen Requirements

### Welcome to Taskly

**Purpose:** Initial app introduction for new users (pre-authentication)

#### Shows

- App logo and branding
- Headline: "Welcome to Taskly"
- Brief description of value proposition
- **"Start Prioritizing"** primary call-to-action button
- **"Already have an account?"** link to Sign In

#### Behaviors

- Tapping "Start Prioritizing" navigates to Sign Up
- Tapping "Already have an account?" navigates to Sign In

#### Constraints

- `[MUST]` Show before any authentication for new installs
- `[MUST]` Provide clear paths to both sign up and sign in
- `[SHOULD]` Convey app's value-aligned task management purpose
- `[MAY]` Include subtle animation or illustration

---

### Navigation Drawer (Mobile)

**Purpose:** Provide access to all app sections on mobile devices

#### Shows

- User avatar/profile info (if signed in)
- Full menu list with icons and labels:
  1. My Day
  2. Scheduled
  3. Someday
  4. Journal
  5. Values
  6. Projects
  7. Insights
  8. Settings
- Current screen highlighted

#### Behaviors

- Slides in from left when Browse tapped in bottom nav
- Tapping menu item navigates to that screen and closes drawer
- Tapping outside drawer closes it
- Swipe right-to-left closes drawer

#### Constraints

- `[MUST]` Show all 8 menu items in specified order
- `[MUST]` Highlight currently active screen
- `[MUST]` Close after navigation
- `[SHOULD]` Show icons alongside labels
- `[MAY]` Show user profile section at top

---

### My Day

**Purpose:** Display daily allocated tasks and projects grouped by value

#### Shows

- **Focus Mode Banner** (top of screen) - clickable hero showing:
  - Current mode name and icon (⊕FocusMode hero context)
  - Mode tagline
  - Allocated item count (tasks + projects)
- Alert banner when alerts pending (⊕Alert banner context)
- Review prompt when reviews due (⊕Review banner context)
- Tasks and projects interspersed, grouped by primary value
  - Group headers show value name, icon, color, and priority badge (⊕Value header context)
  - Tasks display fields per ⊕Task list context
  - Projects display fields per ⊕Project card context
- Floating action to add new task or project

*Note: Allocation service determines which tasks and projects appear. Tasks and projects are scored separately using the same weighting formula. UI simply displays allocated items.*

#### Field Overrides

- ⊕Task.project: hidden (not relevant in daily view)

#### Behaviors

- **Tapping Focus Mode Banner launches Focus Mode Selection Wizard** (see below)
- Tapping task checkbox toggles completion
- Tapping task row opens task detail view
- Tapping project card opens project detail view
- Tapping value group header opens value detail
- Tapping alert banner expands inline to show details
- Tapping review banner navigates to review run
- Tapping filter tab shows items in that state
- 
#### Pinned Section

| Aspect | Specification |
|--------|---------------|
| **Position** | Above value-grouped items, below alert/review banners |
| **Default state** | Collapsed (shows count only, e.g., "📌 3 pinned items") |
| **Contents** | Both pinned tasks AND pinned projects |
| **Internal sort** | By priority (P1→P4), then alphabetical |
| **Visual treatment** | Same cards as main list, with subtle pin icon overlay |

**Pinned Section Rules:**
- `[MUST]` Include both pinned tasks and pinned projects
- `[MUST]` Position above main value-grouped list
- `[SHOULD]` Default to collapsed, expandable on tap
- `[SHOULD]` Show count when collapsed

#### Focus Mode Selection Wizard

Launched when user taps the Focus Mode Banner. Multi-step flow:

**Step 1: Choose Your Focus Style**
- Display all 4 focus modes as selectable cards:
  - Intentional - "Important over urgent"
  - Sustainable - "Growing all values" (Recommended)
  - Responsive - "Time-sensitive first"
  - Personalized - "Your own formula"
- Each card shows mode name, icon, tagline, and brief description
- Continue button proceeds to next step

**Step 2 (Personalized only): Custom Configuration**
- Only shown if Personalized mode selected
- Weight sliders for: Importance, Urgency, Synergy, Balance
- Recovery mode toggle
- **Weight preview**: Shows sample list of top 3-5 items (tasks and projects) that would be allocated with current weights
- Continue button proceeds to final step

**Step 3: Safety Net Rules**
- Configure alert rules for excluded tasks
- List of rules with severity and enabled toggle
- "Save & Continue to My Day" completes wizard

*Wizard hides global navigation. Shows step indicator (e.g., "Step 1 of 3").*

#### Constraints

- `[MUST]` Focus Mode Banner is tappable and launches wizard
- `[MUST]` Pinned items (tasks AND projects) displayed in separate section at top
- `[MUST]` Review banner has same prominence as warning alerts
- `[MUST]` Value groups include priority badge in header
- `[MUST]` Projects display with progress ring, no checkbox
- `[MUST]` Filter tabs work independently of grouping
- `[SHOULD]` Pinned section collapsed by default, expandable
- `[SHOULD]Remove completed items from My Day view

---

### Projects

**Purpose:** Browse and manage all projects

#### Shows

- **Search bar** at top for filtering projects by name
- **Filter tabs**: Active, Completed
- **Sort options**: By deadline, name, priority, recently updated
- List of projects (⊕Project card context)
- Floating action to create new project

#### Behaviors

- Typing in search bar filters projects in real-time
- Tapping filter tab shows only projects in that state
- Tapping sort option reorders list
- Tapping project opens project detail
- Can create new project via FAB
- Can delete project via context action (long press or swipe)

#### Constraints

- `[MUST]` Show task count and progress on each card
- `[MUST]` Search filters by project name
- `[MUST]` Filter tabs work independently of search
- `[SHOULD]` Remember last used sort option
- `[SHOULD]` Show empty state when no projects exist
- `[SHOULD]` Show "No results" state when search/filter has no matches

---

### Project Detail

**Purpose:** View and manage tasks within a single project

#### Shows

- Project header with name, description, values, deadline, progress (⊕Project detail context)
- **Complete Project button** in header (when project has tasks and is not already completed)
- **Pending Tasks section** - incomplete tasks for this project
- **Completed Tasks section** - completed tasks (collapsible)
- Floating action to add task to this project

#### Complete Project Action

| Trigger | Button Location | Behavior |
|---------|-----------------|----------|
| **Manual completion** | Header area, below progress bar | Marks project complete regardless of pending tasks |
| **Last task completed** | Inline prompt after completion | "All tasks done! Complete project?" with Yes/No |

**Complete Project Rules:**
- `[MUST]` Provide manual complete button in project header
- `[MUST]` Prompt user when last task is completed
- `[MUST]` Allow completing project even with pending tasks (user choice)
- `[SHOULD]` Show confirmation when completing with pending tasks
- `[SHOULD]` Hide complete button when project already completed

#### Field Overrides

- ⊕Task.project: hidden (already in project context)

#### Behaviors

- Tapping task checkbox toggles completion (moves between sections)
- Tapping task row opens task detail
- Tapping project header area opens edit mode
- Can add, edit, delete tasks
- Can expand/collapse Completed Tasks section

#### Constraints

- `[MUST]` New tasks pre-populate with project's values (user can edit before saving)
- `[MUST]` Separate pending and completed tasks into sections
- `[MUST]` Show project completion progress in header
- `[SHOULD]` Completed section collapsed by default
- `[SHOULD]` Show task count per section

---

### My Values

**Purpose:** View all values with health indicators

#### Shows

- List of values (⊕Value card context)
- Task count and completion rate per value

#### Behaviors

- Tapping value opens value detail
- Can create new value
- Can delete value via context action

#### Constraints

- `[MUST]` Show priority badge on each value
- `[MUST]` Show stale indicator if value not reviewed in >30 days
- `[SHOULD]` Show empty state when no values exist

---

### Value Detail

**Purpose:** View tasks and projects associated with a single value

#### Shows

- Value header with name, icon, color, priority, item count (⊕Value detail context)
- **Filter tabs**: All | Active | Completed
- Tasks and projects filtered to this value, interspersed and sorted by:
  - Primary associations first, then secondary
  - Within each group: by deadline, then priority
- Tasks display fields per ⊕Task list context
- Projects display fields per ⊕Project card context

#### Behaviors

- Tapping task checkbox toggles completion
- Tapping task row opens task detail
- Tapping project card opens project detail
- Tapping filter tab shows items in that state
- Can edit value details

#### Constraints

- `[MUST]` Include tasks where this value is primary OR secondary
- `[MUST]` Include projects where this value is primary OR secondary
- `[MUST]` Visually distinguish primary vs secondary association (e.g., badge or icon indicating "Primary" vs "Also tagged")
- `[MUST]` Projects display with progress ring, no checkbox
- `[SHOULD]` Sort primary associations before secondary

---

### Someday

**Purpose:** Browse unscheduled tasks and projects

#### Shows

- Tasks and projects interspersed, grouped by primary value
- Group headers (⊕Value header context)
- Tasks display fields per ⊕Task list context
- Projects display fields per ⊕Project card context

#### Behaviors

- Tapping task checkbox toggles completion
- Tapping task row opens task detail
- Tapping project card opens project detail
- Tapping filter tab shows items in that state
- 
#### Constraints

- `[MUST]` Only show tasks with no deadline and no start date
- `[MUST]` Only show projects with no deadline
- `[MUST]` Projects display with progress ring, no checkbox
- `[SHOULD]` Show empty state with guidance on using someday list
Remove completed items from Someday view
- `[MUST]` 
---

### Scheduled

**Purpose:** Timeline view of tasks and projects with dates for capacity planning. Shows items from today onwards only (no past items except overdue). Completed items are removed from this view.

#### Shows

- **Horizontal scrollable date picker** at top
  - Shows ~7 days with abbreviated day + number (e.g., "Mon 6", "Tue 7")
  - **Bidirectional sync**: Picker highlights earliest visible date as user scrolls content
- **"Today" button** to jump to current date
- **Overdue section** (collapsible) for past-due items (if any)
  - Shows top 2 items by default
  - If more than 2 overdue items, show "+N more" indicator with expand/collapse control
- **Semantic date groupings** with sticky headers:
  - "Overdue" (past deadline, not completed)
  - "Today"
  - "Tomorrow" 
  - "This Week" (remaining days)
  - "Next Week"
  - "Later" (beyond next week, grouped by week for next month, then by month)
  - Specific date headers within each group (formatted as "Mon, Jan 15")
- **Empty day handling** (hybrid approach):
  - Near-term (Today → +7 days): Show date header + subtle "No tasks scheduled" placeholder
  - Beyond 7 days: Skip empty days entirely (only show days with items)
- Tasks and projects with **date tags**:
  - **"Starts"** - item's start date is this day
  - **"In Progress"** - item spans this day (between start and deadline)
  - **"Due"** - item's deadline is this day
- Tasks display fields per ⊕Task list context
- Projects display fields per ⊕Project card context
- **Floating action button** to create new task

*Note: This is an agenda-style continuous scroll view. Date picker scrolls TO the selected date section, it does NOT filter the list.*

#### Repeating Items Display

Both tasks and projects support two types of repeating patterns, which display differently on the Scheduled view:

| Repeat Type | Backend Flag | Behavior | Display | Icon |
|-------------|--------------|----------|---------|------|
| **Fixed Interval** | `repeatFromCompletion = false` | Recurs on fixed dates from original start (e.g., "Every Monday", "1st of month") | Show **all instances** within loaded horizon | No special icon |
| **After Completion** | `repeatFromCompletion = true` | Recurs N days/weeks after last completion (e.g., "2 weeks after I finish") | Show **next instance only** | 🔁 Repeat icon |

**Fixed Interval Examples:**
- "Weekly team standup" (every Monday) — shows on Jan 6, Jan 13, Jan 20, Jan 27...
- "Pay rent" (1st of month) — shows on Feb 1, Mar 1, Apr 1...

**After Completion Examples:**
- "Haircut" (6 weeks after completion) — shows only Jan 26 with 🔁 icon
- "Deep clean kitchen" (2 weeks after completion) — shows only next due date with 🔁 icon

**Rationale:** Fixed interval items represent calendar commitments that WILL happen on those dates. After-completion items are speculative — the next occurrence depends on when the user actually completes the current one, so showing projected future instances would be misleading.

#### Data Loading (On-Demand Horizon)

- **Initial load**: Today + 1 month of data
- **On scroll/jump**: Load additional months as user navigates forward
- **Calendar modal jump**: Load data around selected date on demand
- Items are loaded progressively to prevent overwhelming the UI with distant future instances

#### Date Tag Logic

For tasks/projects with both start date and deadline:

| Day | Tag | Visual Priority |
|-----|-----|----------------|
| Start date | "Starts" | High |
| Days between start and deadline | "In Progress" | Lower (de-emphasized) |
| Deadline date | "Due" | High |

*Example: "Paint house" (Jan 1 - Jan 14)*
- Jan 1: Shows with "Starts" tag
- Jan 2-13: Shows with "In Progress" tag (lower visual hierarchy)
- Jan 14: Shows with "Due" tag

Items with only a deadline show on that date with "Due" tag.
Items with only a start date show on that date with "Starts" tag.

**Projects follow the same date tag logic as tasks** — a project with start date and deadline will show "Starts", "In Progress", and "Due" tags on the appropriate dates.

**In Progress Display:**
To avoid clutter on consecutive days, "In Progress" items display as condensed references showing task/project name + "In Progress" badge only. Full card metadata appears on "Starts" and "Due" dates.

#### Completed Items Behavior

- Completed tasks and projects are **removed** from the Scheduled view
- They do not remain on their scheduled date
- User can find completed items in the task/project detail or via search

#### Calendar Modal

Accessed via calendar icon. Allows:
- Jump to specific month/year
- Select a specific date to scroll to
- "Today" button to return to current date

#### Behaviors

- Scrolling date picker navigates timeline (scrolls to date, does not filter)
- Scrolling main content updates date picker to reflect earliest visible date (bidirectional sync)
- Tapping "Today" button scrolls to current date section
- Tapping date in picker scrolls to that date section
- Tapping task checkbox toggles completion (task removed from view)
- Tapping task row opens task detail
- Tapping project card opens project detail
- Tapping overdue section header expands/collapses if more than 2 items
- Tapping FAB opens standard New Task form
- Can navigate between dates/weeks via swipe or picker

#### Constraints

- `[MUST]` Display as continuous scrolling list with sticky date headers
- `[MUST]` Date picker scrolls to date section, does NOT filter the list
- `[MUST]` Show horizontal date picker at top
- `[MUST]` Provide "Today" button for quick navigation
- `[MUST]` Use semantic date groupings (Overdue, Today, Tomorrow, This Week, etc.)
- `[MUST]` Show date tags (Starts/In Progress/Due) on items
- `[MUST]` Show overdue items prominently at top, collapsible if more than 2 items
- `[MUST]` "In Progress" items have lower visual hierarchy than Starts/Due
- `[MUST]` Projects display with progress ring, no checkbox
- `[MUST]` Projects follow same date tag logic as tasks (Starts/In Progress/Due)
- `[MUST]` Remove completed items from Scheduled view
- `[MUST]` Show only items from today onwards (except overdue)
- `[MUST]` Fixed interval repeating items show all instances within loaded horizon
- `[MUST]` After-completion repeating items show only next instance with 🔁 icon
- `[MUST]` Load data on-demand (initial 1 month, more as user scrolls/jumps)
- `[MUST]` Provide FAB for creating new tasks
- `[SHOULD]` Show calendar icon to open full calendar modal
- `[SHOULD]` Highlight current date in picker
- `[MUST]` Date picker updates to reflect earliest visible date when user scrolls content (bidirectional sync)
- `[MUST]` In Progress items display as condensed references to avoid clutter
- `[MUST]` Show empty day placeholder for near-term dates (Today → +7 days) when no items scheduled
- `[MUST]` Skip empty days beyond 7-day horizon (only show days with items)
- `[SHOULD]` Date picker shows ~7 days with "Mon 6" format
- `[SHOULD]` Date headers use "Mon, Jan 15" format
- `[SHOULD]` "Later" section groups by week for next month, then by month beyond

---

### Journal

**Purpose:** Timeline view of all reflection entries

#### Shows

- Entries grouped by date (reverse chronological)
- Each entry preview shows:
  - Mood indicator (emoji/icon)
  - Timestamp
  - Text snippet (first 2-3 lines)
  - Tracker summary (if trackers recorded)
  - Value chips (if values linked)
- Filter/sort options
- Floating action to create new entry

#### Behaviors

- Tapping entry expands inline or opens detail view
- Can create new entry via FAB
- Can delete entry via context action (long press or swipe)
- Can filter by date range, mood, values
- Can sort by date or mood

#### Constraints

- `[MUST]` Show entries in reverse chronological order
- `[MUST]` Group entries by date
- `[MUST]` Show mood indicator on each entry
- `[SHOULD]` Show tracker summary when trackers recorded
- `[SHOULD]` Show empty state when no entries exist
- `[MAY]` Allow grouping by week or month

---

### Journal Detail / Edit

**Purpose:** View or create/edit a journal entry

#### Shows

- **Mood selector** - 5-level scale:
  - Very Low 😢
  - Low 😕
  - Neutral 😐
  - Good 🙂
  - Excellent 😄
- **Reflection text** - rich text area for free-form journaling
- **Daily Check-ins section** - trackers with daily scope (once per day)
- **Trackers section** - trackers with per-entry scope (multiple per day)
- **Values selector** - link entry to values
- Timestamp (auto or manual)

#### Tracker Types

Custom trackers with configurable response types:

| Type | Description | Example |
|------|-------------|---------|
| **Choice** | Select from multiple options | "Energy: Low / Medium / High" |
| **Scale** | Rate on numeric range | "Sleep quality: 1-10" |
| **Yes/No** | Binary toggle | "Exercised today?" |

#### Tracker Scopes

| Scope | Behavior |
|-------|----------|
| **Daily** | Can only record once per day (appears in Daily Check-ins) |
| **Per-entry** | Can record multiple times per day (appears in Trackers section) |

#### Behaviors

- Tapping mood emoji selects that mood level
- Can edit reflection text with rich formatting
- Can respond to each tracker
- Can link to multiple values
- Save button commits entry
- Can delete entry

#### Constraints

- `[MUST]` Support 5-level mood selection
- `[MUST]` Support rich text for reflection
- `[MUST]` Separate daily vs per-entry trackers into sections
- `[MUST]` Support Choice, Scale, and Yes/No tracker types
- `[SHOULD]` Allow linking to multiple values
- `[SHOULD]` Auto-save drafts
- `[MAY]` Support adding photos or attachments

---

### Insights

**Purpose:** View statistics and insights about task completion, value balance, and wellbeing patterns

#### Shows

Single scrolling page with sections (no tabs):

1. **Global time range picker** at top (Today, Week, Month, Year, Custom)

2. **Value Balance Section**
   - Value balance visualization (pie chart or radar)
   - Current allocation vs target (based on value priorities)
   - Neglected values highlighted

3. **Task Completion Section**
   - Completion trends over selected time range
   - Tasks completed per day/week chart
   - Completion rate by value

4. **Wellbeing Patterns Section**
   - Mood trends from journal entries
   - Tracker summaries and trends
   - Correlation indicators (e.g., "Higher mood on days with Health tasks")

5. **Achievements Section**
   - Recent accomplishments (projects completed, streaks, milestones)
   - Positive reinforcement messages

#### Behaviors

- Changing time range picker updates all sections
- Tapping value in any chart opens value detail
- Tapping achievement shows details
- Sections scroll vertically as single page

#### Constraints

- `[MUST]` Single time range picker affects all sections
- `[MUST]` Highlight values that are neglected or imbalanced
- `[MUST]` Show positive reinforcement for achievements
- `[SHOULD]` Show mood/wellbeing trends from journal data
- `[SHOULD]` Correlate productivity with wellbeing indicators

---

### Settings

**Purpose:** Hub for all app configuration

#### Shows

- Links to settings subscreens:
  - Allocation Settings
  - Navigation Settings
  - Review Settings
  - Theme toggle (light/dark/system)
  - Account settings

#### Behaviors

- Tapping item navigates to subscreen
- Theme toggle changes immediately

#### Constraints

- `[MUST]` Theme toggle accessible from this screen
- `[MUST]` Provide access to review settings

---

### Allocation Settings

**Purpose:** Configure focus mode and allocation behavior

#### Shows

- Current focus mode selector (⊕FocusMode config context)
- Recovery mode toggle
- Daily task limit setting
- Link to exception rules

#### Behaviors

- Selecting focus mode changes allocation strategy
- Toggling recovery mode adjusts weights
- Can adjust custom weights if Custom mode selected

#### Constraints

- `[MUST]` Show all four focus modes: Intentional, Sustainable, Responsive, Personalized
- `[MUST]` Weight sliders only editable in Personalized mode
- `[SHOULD]` Show preview of how weights affect allocation

---

### Allocation Exception Rules

**Purpose:** Configure alert rules for tasks and projects that need attention

*Note: Rules are pre-defined by the system. Users can only toggle rules on/off and set severity level.*

#### Pre-defined Rules

| Rule | Default Severity | Condition |
|------|------------------|-----------|
| **Critical Overdue** | Critical | P1 tasks/projects overdue |
| **Deadline Imminent** | Critical | P1-P2 items with deadline within 24 hours |
| **Overdue Warning** | Warning | Any task/project overdue >3 days |
| **Approaching Deadline** | Warning | Items with deadline within 7 days |
| **Stale Items** | Notice | Tasks/projects not updated in >30 days |
| **Value Neglect** | Notice | Values with <10% of total task completion |

#### Shows

- List of pre-defined alert rules with:
  - Rule name and description
  - Current severity (Critical/Warning/Notice) - changeable
  - Enabled toggle

#### Behaviors

- Can toggle rules on/off
- Can change severity per rule (dropdown: Critical, Warning, Notice)
- Cannot add, remove, or modify rule conditions

#### Constraints

- `[MUST]` Show all pre-defined rules
- `[MUST]` Allow severity change per rule
- `[MUST]` Show current enabled state for each rule
- `[SHOULD]` Explain what each rule detects

---

### Navigation Settings

**Purpose:** Customize bottom navigation order

#### Shows

- List of navigation items in current order
- Available items: My Day, Projects, Values, Someday, Settings

#### Behaviors

- Can reorder items via drag
- All 5 items always present (no add/remove)

#### Constraints

- `[MUST]` Always show exactly 5 navigation items
- `[SHOULD]` Provide visual feedback during drag

---

### Review Settings

**Purpose:** Configure periodic review prompts

#### Shows

- List of review types (⊕Review settings context):
  - Values Alignment Review
  - Progress Review
  - Wellbeing Insights
  - Balance Review
  - Pinned Tasks Check

#### Behaviors

- Can toggle each review type on/off
- Can set frequency for each type

#### Constraints

- `[MUST]` Show enabled state and frequency for each type
- `[SHOULD]` Show when each review was last completed

---

### Review Run

**Purpose:** Execute a periodic review with guided steps

#### Shows

- Review type name and description
- Step-by-step guidance
- Relevant tasks or data for review
- Progress indicator

#### Behaviors

- Navigate through steps
- Can complete or skip steps
- Completing marks review as done

#### Constraints

- `[MUST]` Show contextual data relevant to review type
- `[MUST]` Mark review completed when finished
- `[SHOULD]` Allow skipping if user doesn't want to complete

---

### New/Edit Task (and Task Detail)

**Purpose:** Create, view, or modify a task. All three modes use the same screen with contextual differences.

#### Mode Differences

| Field/Element | Create | Edit | View |
|---------------|:------:|:----:|:----:|
| Name | ✅ editable, empty | ✅ editable, populated | ✅ read-only |
| Primary Value | ✅ required, pre-populated if context | ✅ editable | ✅ read-only |
| Secondary Values | ✅ optional | ✅ editable | ✅ read-only |
| Deadline | ✅ optional | ✅ editable | ✅ read-only |
| Start Date | ✅ optional | ✅ editable | ✅ read-only |
| Priority | ✅ default None | ✅ editable | ✅ read-only |
| Description | ✅ optional | ✅ editable | ✅ read-only |
| Project | ✅ picker, pre-populated if context | ✅ editable | ✅ read-only |
| Repeat Rule | ✅ picker | ✅ editable | ✅ read-only |
| Pinned toggle | ✅ default off | ✅ editable | ✅ read-only |
| Completed toggle | ❌ hidden | ✅ editable | ✅ read-only |
| Save button | ✅ "Create" | ✅ "Save" | ❌ hidden |
| Edit button | ❌ | ❌ | ✅ "Edit" |
| Delete action | ❌ | ✅ | ✅ |

#### Shows

- Task form (⊕Task edit context for create/edit, detail context for view)
- All fields per mode table above
- Component pickers: Value Picker, Priority Selector, Date Picker, Repeat Rule Picker

#### Behaviors

- **Create mode:** Empty form, "Create" saves new task
- **Edit mode:** Populated form, "Save" updates existing task
- **View mode:** Read-only display, "Edit" enters edit mode
- Validation before save (primary value required, deadline ≥ start date)

#### Pre-population Rules

| Context | Pre-populated Fields |
|---------|---------------------|
| Opened from Project Detail | Project field, primary/secondary values from project |
| Opened from Value Detail | Primary value set to that value |
| Opened from My Day | None (user selects) |
| Opened from Someday | None (user selects) |

#### Constraints

- `[MUST]` Primary value is required field
- `[MUST]` Secondary values are optional
- `[MUST]` Validate deadline ≥ start date
- `[MUST]` Use same screen layout for all three modes
- `[SHOULD]` Pre-fill fields from context (project, value)
- `[SHOULD]` Pre-fill values from project when project is selected (user can modify before saving)
- `[SHOULD]` Show view mode when navigating from list, edit mode when user taps edit

*Note: Tasks do NOT inherit values from projects at runtime. Value assignment is explicit and stored directly on each task. Pre-population is a UX convenience during creation, not automatic inheritance.*

---

### New/Edit Project

**Purpose:** Create or modify a project

#### Shows

- Project form (⊕Project edit context)
- All editable fields including values

#### Behaviors

- Can save or cancel
- Validation before save

#### Constraints

- `[MUST]` Name is required
- `[MUST]` Primary value is required (same as ⊕Task)
- `[MUST]` Secondary values are optional (same as ⊕Task)

*Note: Project values are used for the project's allocation scoring and as a template for new tasks. They are NOT automatically inherited by child tasks at runtime.*

---

### New/Edit Value

**Purpose:** Create or modify a value

#### Shows

- Value form (⊕Value edit context)
- Name, color picker, icon picker, priority selector

#### Behaviors

- Can save or cancel
- Validation before save

#### Constraints

- `[MUST]` Name is required
- `[MUST]` Color is required
- `[MUST]` Priority is required (default: Medium)

---

### Sign In

**Purpose:** User authentication

#### Shows

- Email input
- Password input
- Sign in button
- Links to: Forgot Password, Sign Up

#### Behaviors

- Validates credentials
- Navigates to My Day on success
- Shows error on failure

#### Constraints

- `[MUST]` Show clear error messages for invalid credentials
- `[SHOULD]` Support "remember me" option

---

### Sign Up

**Purpose:** New user registration

#### Shows

- Email input
- Password input
- Confirm password input
- Sign up button
- Link to: Sign In

#### Behaviors

- Validates inputs
- Creates account
- Navigates to onboarding on success

#### Constraints

- `[MUST]` Validate password confirmation matches
- `[MUST]` Show clear error messages for validation failures

---

### Forgot Password

**Purpose:** Password reset flow

#### Shows

- Email input
- Submit button
- Link back to Sign In

#### Behaviors

- Sends reset email
- Shows confirmation message

#### Constraints

- `[MUST]` Confirm email was sent (or show error)
- `[SHOULD]` Not reveal whether email exists in system

---

### Splash

**Purpose:** App launch and initialization

#### Shows

- App logo
- Loading indicator (if needed)

#### Behaviors

- Checks authentication state
- Navigates to My Day if authenticated
- Navigates to Sign In if not authenticated
- Navigates to Onboarding if first launch

#### Constraints

- `[MUST]` Auto-navigate after initialization
- `[SHOULD]` Show branding during load

---

### Onboarding

**Purpose:** First-run experience for new users

#### Shows

- Welcome message
- Focus mode selection wizard
- Optional value seeding suggestions

#### Behaviors

- Guide user through focus mode selection
- Optionally create starter values
- Navigate to My Day when complete

#### Constraints

- `[MUST]` Allow selecting initial focus mode
- `[SHOULD]` Explain what each focus mode does
- `[MAY]` Offer to create sample values to get started

---

## 5. Cross-Reference

### Screen-Entity Usage Matrix

| Screen | ⊕Task | ⊕Project | ⊕Value | ⊕FocusMode | ⊕Alert | ⊕Review | ⊕Journal | ⊕Tracker |
|--------|:-----:|:--------:|:------:|:----------:|:------:|:-------:|:--------:|:--------:|
| Welcome | — | — | — | — | — | — | — | — |
| Navigation Drawer | — | — | — | — | — | — | — | — |
| My Day | list | card | header | hero | banner | banner | — | — |
| Projects | — | card | — | — | — | — | — | — |
| Project Detail | list | detail | — | — | — | — | — | — |
| My Values | — | — | card | — | — | — | — | — |
| Value Detail | list | card | detail | — | — | — | — | — |
| Someday | list | card | header | — | — | — | — | — |
| Scheduled | list | card | — | — | — | — | — | — |
| Journal | — | — | — | — | — | — | list | summary |
| Journal Detail/Edit | — | — | picker | — | — | — | detail/edit | input |
| Insights | — | — | chart | — | — | — | — | chart |
| Settings | — | — | — | — | — | — | — | — |
| Allocation Settings | — | — | — | config | — | — | — | — |
| Exception Rules | — | — | — | — | config | — | — | — |
| Navigation Settings | — | — | — | — | — | — | — | — |
| Review Settings | — | — | — | — | — | settings | — | — |
| Review Run | list | — | — | — | — | run | — | — |
| New/Edit Task | edit | picker | picker | — | — | — | — | — |
| New/Edit Project | — | edit | picker | — | — | — | — | — |
| New/Edit Value | — | — | edit | — | — | — | — | — |
| Sign In | — | — | — | — | — | — | — | — |
| Sign Up | — | — | — | — | — | — | — | — |
| Forgot Password | — | — | — | — | — | — | — | — |
| Splash | — | — | — | — | — | — | — | — |
| Onboarding | — | — | picker | config | — | — | — | — |
| Focus Mode Wizard | — | — | — | config | config | — | — | — |

---

## 6. Navigation Structure

### Adaptive Navigation System

Taskly uses adaptive navigation that changes based on screen size:

#### Mobile (Small Screens)

**Bottom Navigation Bar** - 5 items:
1. My Day
2. Scheduled
3. Someday
4. Journal
5. **Browse** (opens Navigation Drawer)

**Navigation Drawer** - Full menu accessed via Browse:
1. My Day
2. Scheduled
3. Someday
4. Journal
5. Values
6. Projects
7. Insights
8. Settings

#### Desktop/Web (Large Screens)

**Navigation Rail** - Persistent side navigation with all 8 items:
1. My Day
2. Scheduled
3. Someday
4. Journal
5. Values
6. Projects
7. Insights
8. Settings

*No Browse item needed on desktop - all items visible in rail.*

### Adaptive Behavior Rules

- `[MUST]` Bottom nav on mobile, rail on desktop/tablet
- `[MUST]` Browse item only appears on mobile bottom nav
- `[MUST]` Navigation drawer slides in from left when Browse tapped
- `[SHOULD]` Rail shows icons and labels
- `[SHOULD]` Highlight current screen in nav

### Secondary Navigation

- From Settings: Allocation Settings, Navigation Settings, Review Settings
- From Allocation Settings: Exception Rules
- From any list: Detail views, Edit forms

### Modal/Sheet Navigation

- Task detail: Opens as bottom sheet from any task list
- New/Edit forms: Full screen or large sheet

### Wizard Flows

- Onboarding and Focus Mode Selection wizards hide global navigation to maintain focus
- Wizard screens show progress indicator and back/continue buttons only

---

## Appendix A: Focus Mode Definitions

| Mode | Icon | Tagline | Hero Description | Emphasis |
|------|:----:|---------|------------------|----------|
| **Intentional** | 🎯 | "Important over urgent" | You're being intentional today. Focus on work that truly aligns with your values — deadlines take a back seat to what matters most. | High importance, low urgency |
| **Sustainable** | 🌱 | "Growing all values" | You're being sustainable today. Nurture progress across all your values without burning out on any one. | Equal weights, synergy and balance boosted |
| **Responsive** | ⚡ | "Time-sensitive first" | You're being responsive today. Handle what's time-sensitive now, so you can be intentional again tomorrow. | High urgency, ignore synergy/balance |
| **Personalized** | 🎛️ | "Your own formula" | You've personalized your approach. Your own formula for what matters and how to prioritize it. | All weights adjustable |

### Recovery Mode

- Available as toggle on any focus mode
- When enabled: Boosts neglected values, reduces recently-worked values
- Visual indicator shows when active

---

## Appendix B: Review Type Definitions

| Type | Purpose | Frequency Default |
|------|---------|-------------------|
| **Values Alignment** | Reflect on whether tasks align with values | 14 days |
| **Progress** | Review completed tasks and achievements | 7 days |
| **Wellbeing Insights** | Check-in on energy and mood patterns | 7 days |
| **Balance** | Assess value distribution and neglect | 14 days |
| **Pinned Tasks Check** | Review and update pinned tasks | 7 days |
