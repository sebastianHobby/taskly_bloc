# Taskly UI Elements Specification

> **Purpose:** Visual design specification for all UI elements in Taskly.  
> **Scope:** Component definitions, visual styling, layout specifications.  
> **Philosophy:** Calm, clarity, and intentionality over busyness.

---

## 1. Design System Foundation

### 1.1 Theming

| Aspect | Specification |
|--------|---------------|
| **Design System** | Material Design 3 (Material You) |
| **Color Source** | Dynamic, generated from User Seed Color |
| **Theme Modes** | Light, Dark, System (user selectable) |
| **Surface Tints** | Differentiate "Allocated" (system) vs "Manual" (user) content |

### 1.2 Typography

| Element | Treatment |
|---------|-----------|
| **Hierarchy** | Material 3 Type Scale |
| **Primary Text** | High-emphasis colors (task names) |
| **Secondary Text** | Medium-emphasis colors (values, projects, metadata) |
| **Truncation - Titles** | Max 2 lines with ellipsis |
| **Truncation - Chips** | Max 1 line with ellipsis (no wrapping) |
| **Truncation - Descriptions** | 3 lines collapsed, "More" to expand |

### 1.3 Priority Color System

| Priority | Label | Color Role |
|----------|-------|------------|
| P1 | Critical | Red (Error Container) |
| P2 | High | Orange (Tertiary Container) |
| P3 | Medium | Yellow (Secondary Container) |
| P4 | Low | Blue (Primary Container) |
| None | No Priority | Gray (Surface Variant) |

### 1.4 Spacing & Touch Targets

- Consistent spacing scale throughout app
- Minimum touch target: 48×48 dp
- Responsive layouts for different screen sizes

---

## 2. Shared Components

### 2.1 Task List Tile

**Context:** My Day, Project Details, Someday, Scheduled, Value Detail

**Structure:**

```
┌─────────────────────────────────────────────────────────────┐
│ ▌ ○ Task Name (max 2 lines with ellipsis)              📌   │
│ ▌   [P1] Tomorrow • 📁 Project Name                         │
│ ▌   ● ● ●  (secondary value dots, 30% opacity)              │
└─────────────────────────────────────────────────────────────┘
 ↑
 Primary value color bar (4dp wide, full saturation)
```

| Element | Specification |
|---------|---------------|
| **Leading** | Circular Material 3 checkbox |
| **Primary Value** | 4dp vertical color bar on far left edge, full saturation |
| **Secondary Values** | Small colored dots (30% opacity) in metadata row |
| **Title** | Task name, max 2 lines, ellipsis overflow |
| **Metadata Row** | Priority badge + Deadline (relative) + Project icon/name |
| **Pin Indicator** | Thumbtack icon (📌) near trailing edge, only when pinned |
| **Repeat Indicator** | 🔁 icon when repeating (after-completion type) |

**Visual States:**

| State | Visual Treatment |
|-------|------------------|
| Unchecked | Checkbox outlined, accent color |
| Completed | Checkbox filled, strikethrough text, 50% opacity |
| Overdue | Deadline text in Error color (red) |

### 2.2 Project Card

**Context:** Project lists, My Day, Someday, Value Detail

**Structure:**

```
┌─────────────────────────────────────────────────────────────┐
│  📁 Project Name                              📌  [Due 3d]  │
│  ┌───┐                                                      │
│  │ ◐ │  X/Y Tasks                                          │
│  └───┘                                                      │
│  [Value1] [Value2 (faded)]                                  │
└─────────────────────────────────────────────────────────────┘
```

| Element | Specification |
|---------|---------------|
| **Style** | Elevated or Outlined Card (NOT a tile) |
| **Header** | Project name (Headline style) + Pin icon (if pinned) |
| **Progress Ring** | Circular indicator in place of checkbox |
| **Progress Color** | Uses project's primary value color |
| **Stats** | "X/Y Tasks" text |
| **Deadline Badge** | "Due in X days" (prominent if within 7 days) |
| **Values** | Primary = solid chip, Secondary = faded/outlined (30% opacity) |

**Visual States:**

| State | Visual Treatment |
|-------|------------------|
| Active | Progress ring visible, stats shown |
| Completed | "Completed ✓" badge overlay, progress ring hidden |
| No Checkbox | Projects NEVER show checkbox |

### 2.3 Value Card

**Context:** My Values grid

**Structure:**

```
┌─────────────────────┐
│                [H]  │  ← Priority badge
│       🎯            │  ← Large icon (centered)
│                     │
│  ═══════════ 75%    │  ← Mini progress bar
│  Career             │  ← Value name (bold)
│  12 tasks • 75%     │  ← Task count + completion rate
└─────────────────────┘
 ↑
 Background: subtle tint of value color
```

| Element | Specification |
|---------|---------------|
| **Background** | Subtle tint of assigned value color |
| **Icon** | Large, central or top-left, represents life area |
| **Name** | Bold, bottom-anchored |
| **Priority Badge** | High/Medium/Low indicator (top right) |
| **Progress Bar** | Mini horizontal bar showing completion rate |
| **Metrics** | Task count + completion percentage below name |
| **Stale Indicator** | Warning icon (⚠️) overlay if >30 days since review |
| **Aspect Ratio** | ~3:4 (portrait/tall) to emphasize "pillars" |

**Metrics Displayed:**

- Task count (tasks where this value is primary)
- Completion rate (% completed)
- Neglect indicator (days since last task completion for this value)

### 2.4 Alert Banner

**Context:** My Day header

**States:**

| State | Visual |
|-------|--------|
| Collapsed | Thin colored strip + count (e.g., "3 Overdue") |
| Expanded | List of items + Action buttons |

**Severity Colors:**

| Severity | Color Role | Example |
|----------|------------|---------|
| Critical | Error (Red) | Overdue P1 items |
| Warning | Tertiary (Orange) | Approaching deadlines |
| Notice | Primary (Blue) | Stale items |

### 2.5 Review Banner

**Context:** My Day header (below alerts)

| Element | Specification |
|---------|---------------|
| **Prominence** | Same visual weight as Warning alert |
| **Indicator** | Ring icon + "Review Due" text |
| **Content** | Review type name, due indicator |
| **State** | Shows "Due" badge when overdue |

### 2.6 Focus Mode Banner

**Context:** My Day header (hero area)

**Structure:**

```
┌─────────────────────────────────────────────────────────────┐
│                    INTENTIONAL MODE                    ⚙️   │
│                                                             │
│     ┌───┐                                                   │
│     │ ◐ │   Prioritizing Career today                      │
│     └───┘   12 Tasks Remaining                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

| Element | Specification |
|---------|---------------|
| **Height** | ~25-30% of screen height |
| **Background** | Dynamic gradient/solid based on focus mode |
| **Progress** | Ring indicator + "X Tasks Remaining" text |
| **Mode Label** | Large text stating mode (e.g., "INTENTIONAL MODE") |
| **Focus Summary** | "Prioritizing [Primary Value] today" |
| **Edit Action** | Small icon button to re-run wizard |
| **Collapse Behavior** | Collapses to standard AppBar on scroll down |

---

## 3. Input Components

### 3.1 Value Picker

**Context:** Creating/editing tasks and projects

| Element | Specification |
|---------|---------------|
| **Layout** | Scrollable list, sorted by value priority (High→Medium→Low) |
| **Item Display** | Icon + Name + Priority Badge |
| **Selection States** | Primary (full color + badge), Secondary (30% faded + badge), Unselected |

**Selection Behavior:**

| Action | Result |
|--------|--------|
| Tap unselected (no primary) | Becomes Primary |
| Tap unselected (has primary) | Becomes Secondary |
| Tap Primary | Deselects (promotes first secondary) |
| Tap Secondary | Deselects |

### 3.2 Priority Selector

**Context:** Creating/editing tasks

| Element | Specification |
|---------|---------------|
| **Style** | Segmented Button or Chip Group |
| **Options** | P1 (Red), P2 (Orange), P3 (Yellow), P4 (Blue), None (Gray) |
| **States** | Selected = filled with color, Unselected = outlined |
| **Default** | "None" selected for new items |

### 3.3 Date Picker

**Context:** Scheduling tasks/projects

| Element | Specification |
|---------|---------------|
| **Input Type** | Date only (no time component) |
| **Shortcuts** | Today, Tomorrow, Weekend, Monday, +1 Week |
| **Validation** | Start Date ≤ Deadline |
| **Clear** | Independent clear buttons for Start and Deadline |

### 3.4 Repeat Rule Picker

**Context:** Scheduling tasks/projects

| Element | Specification |
|---------|---------------|
| **Frequency** | Segmented: None | Daily | Weekly | Monthly | Yearly |
| **Interval** | Numeric input (e.g., "Every [ 2 ] Weeks") |
| **Weekdays** | Multi-select toggles (Mon-Sun), visible only for Weekly |
| **Completion Toggle** | "Repeat after completion" switch |
| **End Condition** | Dropdown: Never, After X times, On Date |
| **Preview** | Human-readable summary (e.g., "Every 2 weeks on Mon, Wed") |

### 3.5 Color Picker

**Context:** Creating/editing values

| Element | Specification |
|---------|---------------|
| **Style** | Preset palette grid (no custom input) |
| **Options** | Curated set of ~12-16 colors from Material palette |
| **Selection** | Single select with checkmark overlay |

### 3.6 Icon Picker

**Context:** Creating/editing values

| Element | Specification |
|---------|---------------|
| **Style** | Scrollable grid of icons |
| **Options** | ~200 curated Material icons (life areas, activities, objects) |
| **Categories** | Grouped by category (Health, Work, Home, Hobbies, etc.) |
| **Selection** | Single select with highlight border |

### 3.7 Project Picker

**Context:** Creating/editing tasks

| Element | Specification |
|---------|---------------|
| **Style** | Dropdown with project list |
| **Item Display** | Project name + primary value color indicator |
| **Optional** | "No Project" option at top |
| **Behavior** | Pre-populates task values when project selected |

---

## 4. Empty States

**Structure:**

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│                    [Thematic Icon]                          │
│                                                             │
│                  Title Text Here                            │
│             Guiding descriptive text                        │
│                                                             │
│                 [ Primary Action ]                          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

| Element | Specification |
|---------|---------------|
| **Structure** | Centered: Icon + Title + Description + Single CTA |
| **Icon** | Thematic illustration matching screen context |
| **Text** | Contextual message explaining what will appear |

**Examples:**

| Screen | Message |
|--------|---------|
| My Day | "Your day is clear! Select a focus mode to get started." |
| Someday | "No ideas saved for later. Add tasks without dates here." |
| Projects | "No projects yet. Create one to organize related tasks." |
| Journal | "No reflections yet. Start journaling to track your wellbeing." |

---

## 5. Loading States

| Context | Visual |
|---------|--------|
| **Lists/Grids** | Shimmer/skeleton rows matching content layout |
| **Dashboards/Charts** | Centered spinner or localized skeleton blocks |

---

## 6. Screen Layouts

### 6.1 Mobile Navigation

**Bottom Navigation Bar (5 items):**
1. My Day (Home icon)
2. Scheduled (Calendar icon)
3. Someday (Inbox icon)
4. Journal (Book icon)
5. Browse (Menu icon) → Opens Navigation Drawer

**Navigation Drawer (from Browse):**
Full menu: My Day, Scheduled, Someday, Journal, Values, Projects, Insights, Settings

### 6.2 Desktop Navigation

**Navigation Rail (Left Edge, 8 items):**
1. My Day
2. Scheduled
3. Someday
4. Journal
5. Values
6. Projects
7. Insights
8. Settings

**FAB Placement:** Docks to top of rail

### 6.3 My Day Layout

```
┌─────────────────────────────────────────────────────────────┐
│ [Focus Mode Hero Banner - Collapsible]                      │
├─────────────────────────────────────────────────────────────┤
│ [Alert Banner - if alerts pending]                          │
├─────────────────────────────────────────────────────────────┤
│ [Review Banner - if reviews due]                            │
├─────────────────────────────────────────────────────────────┤
│ 📌 Pinned Section (collapsed by default)                    │
│    3 pinned items                                           │
├─────────────────────────────────────────────────────────────┤
│ ═══════ Career (High) ═══════                               │
│ □ Task 1...                                                 │
│ ◐ Project Card...                                           │
├─────────────────────────────────────────────────────────────┤
│ ═══════ Health (Medium) ═══════                             │
│ □ Task 2...                                                 │
└─────────────────────────────────────────────────────────────┘
                                                         [+]
                                                         FAB
```

### 6.4 Scheduled Layout

**Mobile:**
```
┌─────────────────────────────────────────────────────────────┐
│ [Mon 6] [Tue 7] [Wed 8] [Thu 9] ...  📅 [Today]            │
├─────────────────────────────────────────────────────────────┤
│ ▼ OVERDUE (3+ items collapsed)                              │
│   □ Overdue task 1                                          │
│   □ Overdue task 2                                          │
│   +2 more                                                   │
├─────────────────────────────────────────────────────────────┤
│ ═══════ Today ═══════                                       │
│ □ Task with [Due] tag                                       │
├─────────────────────────────────────────────────────────────┤
│ ═══════ Tomorrow - Tue, Jan 7 ═══════                       │
│ □ Task with [Starts] tag                                    │
└─────────────────────────────────────────────────────────────┘
```

**Desktop:** Split view with Month Calendar (left) + Agenda (right)

**Date Tags:**

| Tag | Color | When Shown |
|-----|-------|------------|
| Starts | Green (Success) | Item's start date |
| In Progress | Blue (Primary) | Between start and deadline (condensed display) |
| Due | Red (Error) | Item's deadline date |

**In Progress Condensed Display:**
- Task: Single line with name + blue "In Progress" dot (no checkbox, no metadata)
- Project: Single line with name + mini progress ring (16dp) + blue dot

### 6.5 Review Run Layout (Single Page)

```
┌─────────────────────────────────────────────────────────────┐
│ Review                                          [X] Close   │
│ Weekly Check-in                                             │
├─────────────────────────────────────────────────────────────┤
│ ▼ Progress Check                        [Mark Complete]     │
│   You completed 12 tasks this week!                         │
│   • Completed Project Alpha                                 │
│   • Finished Q4 Report                                      │
├─────────────────────────────────────────────────────────────┤
│ ▼ Wellbeing Insights                    [Mark Complete]     │
│   [Mood sparkline chart]                                    │
│   "One thing I learned..." [text field]                     │
├─────────────────────────────────────────────────────────────┤
│ ▼ Balance Check                         [Mark Complete]     │
│   [Mini Radar Chart]                                        │
│   ⚠️ Health is neglected this week                          │
│   [ ] Boost neglected values next week                      │
├─────────────────────────────────────────────────────────────┤
│ ▼ Pinned Tasks Check                    [Mark Complete]     │
│   □ Pinned task 1                              [Unpin]      │
│   □ Pinned task 2                              [Unpin]      │
└─────────────────────────────────────────────────────────────┘
│                    [ Complete Review ]                      │
└─────────────────────────────────────────────────────────────┘
```

**4 Review Types (stacked sections):**
1. Progress - Completed tasks summary
2. Wellbeing Insights - Mood trend + reflection
3. Balance - Radar chart + neglect warnings
4. Pinned Tasks Check - List with unpin actions

### 6.6 Insights Layout

**Single scrolling page with sections:**

1. **Header:** Global time range picker (Today, Week, Month, Year)

2. **Value Balance Section:**
   - Radar chart (assuming <8 values typical)
   - Axis = Value, Data = Balance Score
   - Balanced shape = balanced life

3. **Task Completion Section:**
   - Completion trends chart
   - Tasks per value breakdown

4. **Wellbeing Patterns Section:**
   - Mood trend sparkline from journal
   - Tracker summaries

*Note: Gamification elements (streaks, achievements, XP) are removed from scope.*

### 6.7 Task/Project Form Layout

**Mobile:** Modal Bottom Sheet (dynamic height, expands to 90% for details)  
**Desktop:** Side Sheet (right edge, ~400dp fixed width)

```
┌─────────────────────────────────────────────────────────────┐
│ ═══════════════════════════════════════════                 │
│                                                             │
│ Task Name                                                   │
│ ___________________________________________________         │
│                                                             │
│ [📅 Date] [P1 P2 P3 P4 -] [📌 Pin]                         │
│                                                             │
│ Primary Value: [Value Picker Dropdown]                      │
│ Secondary Values: [+ Add]                                   │
│                                                             │
│ ▼ More Details                                              │
│   Description: ________________________________              │
│   Project: [Dropdown]                                       │
│   Repeat: [Picker]                                          │
│                                                             │
│                                            [ Create ]       │
└─────────────────────────────────────────────────────────────┘
```

**Unified editing:** View and edit modes use same screen layout. Inline editing for all fields.

---

## 7. Adaptive Breakpoints

| Breakpoint | Navigation | Layout Adjustments |
|------------|------------|-------------------|
| < 600dp | Bottom Nav + Drawer | Single column, bottom sheets |
| 600-840dp | Rail (icons only) | 2-column grids, side sheets |
| > 840dp | Rail (icons + labels) | Multi-column, split views |

---

## 8. Mockup Generation Guidelines

When generating UI mockups:

| Guideline | Description |
|-----------|-------------|
| **Mix of Entities** | Show tasks AND projects on screens that display both |
| **Data Variations** | Include: with/without deadlines, all priority levels (P1-P4, None), pinned items, repeating items |
| **Tasks vs Projects** | Tasks = checkboxes; Projects = progress rings (never checkboxes) |
| **Completed Styling** | Tasks: strikethrough + 50% opacity. Projects: "Completed ✓" badge |
| **Filter Tab States** | Show both active and inactive states |
| **Value Colors** | Include multiple value color variations |
| **Empty & Populated** | Show both empty states and populated states |
| **Overdue Styling** | Error color (red) for deadline text and tags |
