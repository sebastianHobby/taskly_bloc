# Taskly UI Behavior Specification

> **Purpose:** Interaction patterns and behavioral requirements for all UI screens.  
> **Scope:** User actions, navigation flows, gestures, validation, state management.  
> **Companion:** See `screen_ui_elements.md` for visual specifications.

---

## 1. Global Interaction Patterns

### 1.1 Gesture Actions

| Gesture | Context | Action | Visual Feedback |
|---------|---------|--------|-----------------|
| **Swipe Left** | All list items | Delete | Red background + Trash icon reveal |
| **Swipe Right** | Tasks only | Toggle complete/incomplete | Green background + Check icon reveal |
| **Tap** | Task checkbox | Toggle completion | Checkbox animation |
| **Tap** | Task row | Open task detail | Navigation |
| **Tap** | Project card | Open project detail | Navigation |
| **Tap** | Value group header | Open value detail | Navigation |
| **Long Press** | List items | Context menu (delete, edit) | Elevation + menu |
| **Pull Down** | Lists | Refresh content | Refresh indicator |

**Swipe Behavior Rules:**
- `[MUST]` Left swipe reveals delete with visual feedback
- `[MUST]` Right swipe on tasks toggles completion with undo snackbar
- `[MUST]` Projects do NOT support right-swipe completion
- `[MUST]` Delete action shows undo snackbar (immediate delete + undo)

### 1.2 Floating Action Button (FAB)

| Screen | FAB Action |
|--------|------------|
| My Day | Create Task |
| Someday | Create Task |
| Scheduled | Create Task |
| Projects | Create Project |
| Project Detail | Create Task (in project) |
| My Values | Create Value |
| Value Detail | Create Task (with value) |
| Journal | Create Journal Entry |
| Insights | No FAB |
| Settings | No FAB |

**FAB Behavior:**
- `[MUST]` Single tap creates (no expand menu)
- `[MUST]` Pre-populate context fields (project, value) when opened from context
- `[SHOULD]` Hide on scroll down, reappear on scroll up (mobile)
- `[MAY]` Extended FAB with label on larger screens

### 1.3 Delete Behavior

**UX Pattern:** Immediate deletion with undo snackbar

| Step | Action |
|------|--------|
| 1 | User swipes left or selects delete from context menu |
| 2 | Item immediately removed from view |
| 3 | Snackbar appears: "[Item] deleted" + "Undo" action |
| 4 | Undo restores item; Snackbar dismissal finalizes delete |

### 1.4 Completed Items Policy

| Screen | Completed Items Behavior |
|--------|-------------------------|
| My Day | Removed entirely |
| Scheduled | Removed entirely |
| Someday | Removed entirely |
| Projects | "Completed" tab to view |
| My Values | "Completed" tab to view |
| Project Detail | Collapsed "Completed" section at bottom |
| Value Detail | "Completed" tab to view |

**Rules:**
- `[MUST]` Retain completed items indefinitely (never auto-delete)
- `[MUST]` Default to "Active" filter on screens with tabs
- `[MUST]` Remove completed items from day-based views (My Day, Scheduled, Someday)

### 1.5 Form Discard Behavior

When dismissing a form with unsaved changes:

1. Show "Discard Changes?" dialog
2. Options: "Discard" / "Keep Editing"
3. If "Discard": close form without saving
4. If "Keep Editing": return to form

---

## 2. Sorting & Grouping Rules

### 2.1 Value Grouping

**Applies to:** My Day, Someday, Value Detail

| Sort Level | Criteria | Order |
|------------|----------|-------|
| 1. Group | Value Priority | High → Medium → Low |
| 2. Within Priority | Value Name | Alphabetical A → Z |
| 3. Within Value | Item Priority | P1 → P2 → P3 → P4 → None |
| 4. Tie-breaker | Item Name | Alphabetical A → Z |

**Group Header:** Value icon + Name + Priority badge + Color indicator

### 2.2 Value Picker Sorting

**Sort Order:** By value priority (High → Medium → Low), then alphabetically within priority level.

### 2.3 Project List Sorting

**User-selectable options:**
- By deadline (soonest first)
- By name (alphabetical)
- By priority (P1 → P4)
- By recently updated

**Default:** Remember last used sort option

---

## 3. Screen Behaviors

### 3.1 My Day

#### Focus Mode Banner
- **Tap:** Launches Focus Mode Selection Wizard
- **Collapse:** Collapses to AppBar on scroll down

#### Alert Banner
- **Tap (collapsed):** Expands inline to show details and actions
- **Actions when expanded:**
  - "Reschedule All": Opens date picker → applies selected date to all overdue items
  - "Dismiss": Collapses banner (alerts remain)

#### Review Banner
- **Tap:** Opens Review Run screen as modal/sheet

#### Pinned Section
- **Default:** Collapsed (shows "📌 X pinned items")
- **Tap header:** Expands to show full list
- **Contents:** Both pinned tasks AND pinned projects
- **Internal sort:** Priority (P1→P4), then alphabetical

#### Task/Project Items
- **Tap checkbox (task):** Toggle completion
- **Tap row (task):** Open task detail
- **Tap card (project):** Open project detail
- **Swipe right (task):** Toggle completion with undo
- **Swipe left:** Delete with undo

### 3.2 Scheduled

#### Date Picker (Horizontal Strip)
- **Tap date:** Scrolls main list to that date section
- **Scroll main list:** Updates picker to show earliest visible date (bidirectional sync)
- **Does NOT filter:** Always shows full agenda, just navigates

#### Today Button
- **Tap:** Scrolls to current date section

#### Calendar Modal (via icon)
- **Open:** Full month view for rapid navigation
- **Select date:** Scrolls main list to that date, closes modal

#### Overdue Section
- **Default:** Collapsed if >2 items, showing top 2 + "+N more"
- **Tap header:** Expands to show all overdue items
- **Collapse at:** 3+ items triggers collapsible behavior

#### Date Tags
| Tag | When Shown |
|-----|------------|
| "Starts" | Item's start date |
| "In Progress" | Days between start and deadline (condensed display) |
| "Due" | Item's deadline date |

#### In Progress Items (Condensed)
- Task: Name + blue dot (no checkbox, no metadata)
- Project: Name + mini progress ring + blue dot
- Purpose: Reduce clutter on consecutive days

#### Repeating Items
| Type | Display |
|------|---------|
| Fixed Interval (`repeatFromCompletion = false`) | Show ALL instances within loaded horizon |
| After Completion (`repeatFromCompletion = true`) | Show NEXT instance only with 🔁 icon |

#### Empty Day Handling
| Date Range | Behavior |
|------------|----------|
| Today → +7 days | Show date header + "No tasks scheduled" placeholder |
| Beyond 7 days | Skip empty days entirely |

#### Data Loading
- Initial load: Today + 1 month
- On scroll/jump: Load additional months as needed

### 3.3 Someday

- **Filter Tabs:** Active | Completed (default: Active)
- **Content:** Only items with NO deadline AND NO start date
- **Grouping:** By primary value (same rules as My Day)
- **Completed items:** Removed from view (visible via Completed tab)

### 3.4 Projects

#### Search Bar
- **Typing:** Filters projects by name in real-time
- **Clear:** X button clears search

#### Filter Tabs
- **Active** (default): Shows incomplete projects
- **Completed:** Shows completed projects

#### Sort Options
- By deadline, name, priority, recently updated
- **Remember:** Persist last used sort option

### 3.5 Project Detail

#### Header Area
- **Tap:** Opens edit mode

#### Complete Project Button
- **Location:** Header area, below progress bar
- **Visibility:** When project has tasks and is not completed
- **Behavior:** Marks project complete regardless of pending tasks
- **With pending tasks:** Show confirmation dialog

#### Last Task Completion Prompt
- **Trigger:** When user completes the final task in project
- **Prompt:** "All tasks done! Complete project?" with Yes/No

#### Completed Tasks Section
- **Default:** Collapsed
- **Tap header:** Expands to show completed tasks

#### New Task (via FAB)
- **Pre-populate:** Project field + project's values
- **User can modify:** Values before saving

### 3.6 My Values

- **Tap card:** Opens value detail
- **Long press/drag:** NOT supported for reordering (algorithmic sort only)
- **Grid layout:** 2 columns (mobile), 3-5 columns (desktop/masonry)
- **Stale indicator:** Warning icon if >30 days since review

### 3.7 Value Detail

#### Sections
1. **Primary Focus:** Items where this value is Primary (full saturation)
2. **Synergy:** Items where this value is Secondary (faded)

#### Filter Tabs
- All | Active | Completed

#### Sort
- Primary associations before secondary
- Within each: by deadline, then priority

### 3.8 Journal

- **Sort:** Reverse chronological (newest first)
- **Grouping:** By date
- **Filter options:** Date range, mood, values
- **Tap entry:** Expands inline or opens detail view

### 3.9 Journal Detail / Edit

#### Mood Selector
- 5-level emoji row: 😢 😕 😐 🙂 😄
- Tap to select

#### Reflection Text
- Plain text (rich text/markdown deferred to v2)

#### Trackers
- **Daily scope:** Appears in "Daily Check-ins" section (once per day)
- **Per-entry scope:** Appears in "Trackers" section (multiple per day)

#### Values
- Multi-select (no primary/secondary distinction for journal entries)

### 3.10 Insights

- **Time range picker:** Global filter affecting all sections
- **Options:** Today, Week, Month, Year, Custom
- **Sections:** Scroll vertically as single page

#### Value Balance Section
- **Chart:** Radar chart (assuming <8 values typical)
- **Tap value:** Opens value detail

### 3.11 Review Run

#### Layout
- Single scrollable page with 4 stacked sections
- Each section expandable/collapsible

#### Review Types (4 total)
1. **Progress** - Completed tasks summary
2. **Wellbeing Insights** - Mood trend + reflection text field
3. **Balance** - Radar chart + neglect warnings + boost toggle
4. **Pinned Tasks Check** - List with quick unpin buttons

*Note: Values Alignment merged into Balance section.*

#### Section Actions
- **"Mark Complete" button** per section
- **"Complete Review" button** at bottom (completes all)

#### Access Pattern
- Review banner on My Day when any review is due
- Tap banner → Opens Review screen as modal/sheet

### 3.12 Settings

#### Settings Hub Structure
1. **Appearance:** Theme toggle (Light/Dark/System)
2. **Strategy:** Allocation Settings, Exception Rules
3. **Workflow:** Navigation Order, Review Preferences
4. **Account:** Profile, Export Data, Sign Out

*Note: Density toggle deferred to v2. Calendar Sync deferred to v2.*

### 3.13 Allocation Settings

- **Focus Mode Selector:** 4 modes (Intentional, Sustainable, Responsive, Personalized)
- **Recovery Toggle:** Boosts neglected values
- **Custom Weights:** Visible only when Personalized mode selected

### 3.14 Allocation Exception Rules

**Pre-defined rules (user can toggle on/off and set severity):**

| Rule | Default Severity |
|------|------------------|
| Critical Overdue | Critical |
| Deadline Imminent | Critical |
| Overdue Warning | Warning |
| Approaching Deadline | Warning |
| Stale Items | Notice |
| Value Neglect | Notice |

- **Cannot:** Add, remove, or modify rule conditions
- **Can:** Toggle enabled, change severity (Critical/Warning/Notice)

### 3.15 Review Settings

| Review Type | Default Frequency |
|-------------|-------------------|
| Progress | 7 days |
| Wellbeing Insights | 7 days |
| Balance | 14 days |
| Pinned Tasks Check | 7 days |

- **Toggle:** Enable/disable each type
- **Frequency:** Configurable (7, 14, 21, 30 days)

### 3.16 Navigation Settings

- **Items:** My Day, Scheduled, Someday, Journal, Browse
- **Reorder:** Drag handles to customize bottom nav order
- **Always 5 items:** Cannot add or remove

---

## 4. Focus Mode Selection Wizard

**Trigger:** Tap Focus Mode Banner on My Day

**Global Navigation:** Hidden during wizard flow

### Step 1: Choose Your Focus Style
- **Display:** 4 selectable mode cards
- **Card content:** Icon, Name, Tagline, Description, "~X Tasks" estimate
- **Selection:** Tap card to select, enables Continue button

| Mode | Icon | Tagline |
|------|------|---------|
| Intentional | 🎯 | "Important over urgent" |
| Sustainable | 🌱 | "Growing all values" (Recommended) |
| Responsive | ⚡ | "Time-sensitive first" |
| Personalized | 🎛️ | "Your own formula" |

### Step 2: Custom Configuration (Personalized only)
- **Weight sliders:** Importance, Urgency, Synergy, Balance
- **Recovery toggle**
- **Preview:** Top 3-5 items that would be allocated

### Step 3: Safety Net Rules
- **List:** Alert rules with Enable toggle + Severity dropdown
- **Action:** "Save & Continue to My Day"

**Navigation:** Step indicator at top, Back/Continue buttons

---

## 5. Task/Project Form Behavior

### 5.1 Mode Differences

| Mode | Fields | Save Button |
|------|--------|-------------|
| Create | Empty, editable | "Create" |
| Edit | Populated, editable | "Save" |
| View | Populated, read-only | "Edit" button |

### 5.2 Pre-population Rules

| Context | Pre-populated Fields |
|---------|---------------------|
| From Project Detail | Project + project's values |
| From Value Detail | Primary value set |
| From My Day | None |
| From Someday | None |

### 5.3 Validation

- `[MUST]` Primary value required
- `[MUST]` Name required
- `[MUST]` Deadline ≥ Start date (if both set)

### 5.4 Project Value Pre-population

When user selects a project in task form:
1. Task form pre-fills with project's values
2. User can modify values before saving
3. Values saved on task are independent (no runtime inheritance)

### 5.5 Duplicate Task Action

- **Access:** From task detail view (context menu or action button)
- **Creates:** Copy of task with same values, dates, priority, project
- **Opens:** New task in edit mode for modification before save

---

## 6. Value Deletion Behavior

When deleting a value that is primary on tasks/projects:

| Scenario | Behavior |
|----------|----------|
| Has secondary values | Highest-priority secondary → new primary |
| Same priority secondaries | Alphabetically first → new primary |
| No secondary values | Task/project has no primary (orphaned) |

**Rules:**
- `[MUST]` Warn user about affected items before deletion
- `[MUST]` Show count of affected items in confirmation dialog

---

## 7. Allocation Refresh Triggers

| Trigger | Behavior |
|---------|----------|
| Midnight | Automatic refresh when date changes |
| App open (stale) | Refresh if last allocation was before today |
| Manual refresh | Pull-to-refresh on My Day |
| Settings change | Refresh when focus mode or weights changed |

---

## 8. Authentication Flow

### Sign In
- Validates credentials
- Success → My Day
- Failure → Error message

### Sign Up
- Validates inputs (password confirmation)
- Creates account
- Success → Onboarding

### Forgot Password
- Sends reset email
- Shows confirmation (does not reveal if email exists)

### Splash Screen
- Checks auth state
- Authenticated → My Day
- Not authenticated → Sign In
- First launch → Onboarding

### Onboarding
1. Welcome message
2. Focus mode selection wizard
3. Optional value seeding (suggested starter values)
4. → My Day

---

## 9. Accessibility Requirements

- `[MUST]` Semantic labels for all interactive elements
- `[MUST]` Keyboard/screen-reader accessible
- `[SHOULD]` Test with TalkBack and VoiceOver
- `[SHOULD]` Support dynamic text scaling
- `[MUST]` Contrast ratios meet WCAG 2.1 AA (4.5:1 minimum)

---

## 10. Constraint Summary

### MUST (Required)

- Primary value required on all tasks and projects
- Checkbox always visible on tasks
- Projects show progress ring, never checkbox
- Delete provides undo snackbar
- Completed items removed from My Day, Scheduled, Someday
- Review banner same prominence as warning alerts
- Fixed interval repeating items show all instances
- After-completion repeating items show only next instance with 🔁

### SHOULD (Recommended)

- FAB hides on scroll down, reappears on scroll up
- Remember last used sort option
- Pinned section collapsed by default
- Completed section collapsed in Project Detail
- Show empty states with contextual guidance

### MAY (Optional)

- Extended FAB with label on larger screens
- Quick shortcuts in date picker
- Support adding photos to journal
