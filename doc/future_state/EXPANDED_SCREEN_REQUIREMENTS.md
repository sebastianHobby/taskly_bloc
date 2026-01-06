# Taskly Visual Design Specification

> **Purpose:** This document serves as the single source of truth for the visual design of the Taskly application. It is intended to guide AI agents and developers in generating high-fidelity mockups and implementing UI widgets.
> **Scope:** Includes global styling rules, component definitions, and screen layout specifications that have been explicitly agreed upon.
> **Philosophy:** Visuals should reinforce the "Values-Aligned" mission—calm, clarity, and intentionality over busyness.

---

## 1. Design System Foundation

### 1.1 Theming
*   **System:** Material Design 3 (Material You).
*   **Color Source:** Generated dynamically from a single User Seed Color.
*   **Modes:** Light and Dark mode support required.
*   **Surface Tones:** Use surface tints to distinguish between "Allocated" (System) and "Manual" (User) content.

### 1.2 Typography
*   **Hierarchy:** Follow Material 3 Type Scale.
*   **Readability:** Primary text (Task Names) must use high-emphasis colors. Secondary text (Values, Projects) must use medium-emphasis colors.

### 1.3 Global Interaction Visuals
*   **Loading States:**
    *   **Lists/Grids:** Shimmer/Skeleton rows matching the content layout.
    *   **Dashboards/Charts:** Centered Spinner or localized skeleton blocks.
*   **Swipe Gestures:**
    *   **Swipe Left (All items):** Red background + Trash Icon (Delete).
    *   **Feedback:** Visual reveal of background color and icon. SnackBar with Undo action after delete.
*   **Reordering:**
    *   **Manual Reordering:** Not allowed. Lists are sorted algorithmically or by fixed criteria (Tasks by Priority/Deadline).
*   **Floating Action Button (FAB):**
    *   **Placement:** Standard bottom-right (mobile) or Top of Rail (desktop).
    *   **Context:** Action matches current screen (e.g., "Create Value" on Values screen).
    *   **Behavior:** Auto-hide on scroll down, reappear on scroll up (mobile).
*   **Empty States:**
    *   **Structure:** Centered thematic Illustration + Title + Guiding Text + Single Call-to-Action button.
    *   **Context:** Specific message explaining what the screen will show (e.g., "No scheduled tasks yet. Plan ahead!").

### 1.4 Priority Color System
*   **P1 (Critical):** Red (Error Container).
*   **P2 (High):** Orange (Tertiary Container).
*   **P3 (Medium):** Yellow (Secondary Container).
*   **P4 (Low):** Blue (Primary Container).

### 1.5 AI Mockup Generation Guidelines
*When generating UI mockups from these specifications:*

| Guideline | Description |
|-----------|-------------|
| **Mix of Entities** | Show representative mix of tasks AND projects on screens that display both |
| **Data Combinations** | Include examples of all data states: with/without deadlines, all priority levels (P1-P4, None), pinned items, repeating items |
| **Tasks vs Projects** | Tasks show checkboxes; Projects show progress rings (no checkbox) |
| **Completed Styling** | Tasks: strikethrough + faded (50% opacity). Projects: "Completed ✓" badge, progress ring hidden |
| **Filter Tab States** | Show filter tabs in both active and inactive visual states |
| **Value Colors** | Include multiple value color variations to demonstrate value grouping |
| **Empty & Populated** | Show both empty states (with illustration + CTA) and populated states |
| **Overdue Styling** | Overdue items use Error color (red) for deadline text and tags |

---

## 2. Shared Component Specifications
*Visual definition of core data entities.*
*   **General Truncation:**
    *   **Headers/Titles:** Max 2 lines with ellipsis.
    *   **Value Chips/Tags:** Max 1 line with ellipsis (no wrapping).
    *   **Descriptions:** Collapsed to 3 lines by default with "More" expansion.

### 2.1 Task List Tile
**Context:** Used in My Day, Project Details, Someday, and Lists.
**Visual Structure:** Standard List Tile.
*   **Leading:**
    *   **Checkbox:** Circular Material 3 checkbox.
    *   **State:**
        *   *Unchecked:* Outlined, accent color.
        *   *Checked:* Filled, accent color, strikethrough text, lowered opacity (50%).
*   **Body (Content):**
    *   **Line 1 (Title):** Task Name. Max 2 lines. textOverflow: ellipsis.
    *   **Line 2 (Metadata Row):**
        *   *Priority Badge:* (If present) Small colored dot or abbreviated tag (P1/P2).
        *   *Deadline:* Relative text (e.g., "Tomorrow") in small caption font. Color: Error if overdue.
        *   *Project:* (If applicable) Small folder icon + Project Name.
*   **Visual Indicators:**
    *   **Primary Value:** Represented by a vertical color bar (4dp wide) on the far left edge OR a colored background tint on the leading container. Must be full saturation.
    *   **Secondary Values:** Small colored dots or faded text chips (30% opacity) in the Metadata Row.
    *   **Pinned:** Small "Thumbtack" icon visible near the trailing edge if strictly pinned.

### 2.2 Project Card
**Context:** Used in Project lists, Summaries, and grouped lists.
**Visual Structure:** Elevated or Outlined Card (Not a tile).
*   **Header:**
    *   **Icon:** Project folder/category icon.
    *   **Title:** Project Name (Headline style).
    *   **Badge:** "Pinned" icon if applicable.
    *   **Deadline Badge:** (If within 7 days) "Due in X days" prominent badge.
*   **Body:**
    *   **Progress:** Circular Progress Indicator (Ring).
        *   *Position:* Takes the place of the Leading Checkbox to distinguish from Tasks.
        *   *Value:* Computed from `completedTasks / totalTasks`.
        *   *Visual:* Uses Project's Primary Value color. Resides in header area or prominent lead.
    *   **Stats:** Text line: "X/Y Tasks".
*   **Footer/Tags:**
    *   **Values:** Row of Value chips (Primary = Solid, Secondary = Outlined/Faded).
*   **Completion State:**
    *   **NO Checkbox.** Projects cannot be checked off from the card.
    *   **Completed Visual:** If 100% complete, show "Completed ✓" badge overlaid or in corner. Progress bar hidden.

### 2.3 Value Card
**Context:** Used in "My Values" grid.
**Visual Structure:** Highly visual "Identity" card.
*   **Background:** Subtle tint of the Value's assigned color.
*   **Content:**
    *   **Icon:** Large, central or top-left icon representing the life area (e.g., Heart for Health, Briefcase for Career).
    *   **Label:** Value Name in bold.
    *   **Priority:** Badge indicating High/Medium/Low priority (affects algorithm weight).
    *   **Metrics Display:**
        *   **Progress Bar:** Mini horizontal bar showing completion rate (% of associated tasks completed).
        *   **Task Count:** Text below name (e.g., "12 tasks · 75%").
        *   **Position:** Below the Value Name, above the bottom edge.
    *   **Stale Indicator:** Warning icon (⚠️) overlay if `lastReviewedAt` > 30 days ago.
    *   **Visual Weight:** These elements are the "Why" of the app and should feel permanent and substantial.

### 2.4 Alert Banner
**Context:** My Day header for system warnings.
**Visual Structure:**
*   **Collapsed:** Thin colored strip (Red/Orange/Blue based on severity) with count (e.g., "3 Overdue").
*   **Expanded:** List of items + Actions ("Reschedule All", "Dismiss").
*   **Severity Colors:** Critical = Error Color, Warning = Tertiary/Orange, Notice = Primary/Blue.

### 2.5 Complex Component Definitions

#### Value Picker
**Context:** Creating/Editing Tasks and Projects.
**Visual Structure:**
*   **List:** Scrollable list of Value items.
*   **Item:** Icon + Name + Priority Badge.
*   **Selection States:**
    *   *Primary:* Full Color, "Primary" badge, Border highlight.
    *   *Secondary:* Faded (30%), "Secondary" badge.
    *   *Unselected:* Default styling.
*   **Behavior:** Tap unselected -> becomes Primary (if none) or Secondary. Tap Primary -> Deselect (promote first secondary). Tap Secondary -> Deselect.

#### Priority Selector
**Context:** Creating/Editing Tasks.
**Visual Structure:** Segmented Button or Chip Group.
*   **Options:** P1 (Red), P2 (Orange), P3 (Yellow), P4 (Blue), None (Gray).
*   **State:** Selected option is filled with its color. Unselected are outlined.
*   **Default:** "None" is selected by default for new items.

#### Repeat Rule Picker
**Context:** Scheduling Tasks/Projects.
**Visual Structure:** Form Section.
*   **Frequency:** Segmented Button (None | Daily | Weekly | Monthly | Yearly).
*   **Interval:** Numeric Input (e.g., "Every [ 2 ] Weeks").
*   **Weekdays:** Multi-select Toggle Buttons (Mon, Tue, Wed...) visible only if Weekly.
*   **Completion Toggle:** Switch "Repeat after completion" (vs fixed schedule).
*   **End Condition:** Dropdown (Never, After X times, On Date).
*   **Preview:** Human-readable text summary at bottom (e.g., "Every 2 weeks on Mon, Wed").

#### Date Picker
**Context:** Scheduling.
**Visual Structure:**
*   **Input:** Date items only (No time picker).
*   **Granularity:** Date-only. Specific times (e.g., 2:00 PM) are NOT supported in this version.
*   **Validation:** Start Date <= Deadline.
*   **Clear:** Independent clear buttons for Start and Deadline.

---

## 3. Screen Layout Specifications (Tier 1)
*Critical workflows user encounters immediately.*

### 3.0 Entry & Authentication
**Goal:** Smooth entry and secure authentication.

*   **Splash Screen:** Centered Brand Logo. Minimalist.
*   **Welcome Screen:**
    *   **Visual:** Centered Layout.
    *   **Content:**
        *   **Hero Illustration:** Thematic (Values/Focus).
        *   **Headline:** "Welcome to Taskly" (Display style).
        *   **Subtext:** Brief value proposition (e.g., "Productivity with purpose").
    *   **Actions:**
        *   **Primary:** "Start Prioritizing" Button (Go to Sign Up).
        *   **Secondary:** "Sign In" Text Link.
*   **Auth Screens (Sign In / Sign Up):**
    *   **Form:** Standard vertical layout.
    *   **Fields:** Email, Password, (Confirm Password for Sign Up).
    *   **Actions:** Primary Button, "Forgot Password?" Link (Sign In only).
    *   **Feedback:** Inline red text for errors.
*   **Forgot Password:**
    *   **Form:** Email Input only.
    *   **Action:** "Send Reset Link" Button.

### 3.1 Focus Mode Wizard (Daily Launch / Onboarding)
**Goal:** Help user select the right focus mode for the day (Step 1 of allocation).
**Layout Type:** **Vertical List (Option C)**.

**Visual Layout:**
*   **Header:**
    *   Greeting: "Good Morning."
    *   Prompt: "How should we shape your day?"
*   **List Area (Scrollable):**
    *   Vertical stack of expansive Cards.
*   **Card Design:**
    *   **Left:** Large Illustration/Icon of the mode (e.g., Target for Intentional, Leaf for Sustainable).
    *   **Center:**
        *   **Title:** Mode Name (Intentional, Sustainable, Responsive, Personalized).
        *   **Description:** 1-line benefit (e.g., "Deep work on primary values").
        *   **Tagline:** (e.g., "Important over urgent").
    *   **Right/Action:**
        *   **Hero Metric:** "~X Tasks" (Estimated count based on mode settings).
        *   **State:** Selected card expands slightly or highlights with a border.
*   **Personalized Step (If Personalized selected):** Shows Sliders for weights + Recovery Toggle + Preview List.
*   **Onboarding Only - Seed Values Step:**
    *   *Visual:* Grid of common Value suggestions (Health, Career, Family, Growth).
    *   *Interaction:* Multi-select chips to quick-create initial values.
*   **Interaction:** Tapping a card selects it and enables the "Start Day" FAB/Button.

### 3.2 My Day Screen (Home)
**Goal:** Execution and focus.
**Layout Type:** **Hero Banner + Split View**.

**Header Region (Hero Banner - Option A):**
*   **Height:** ~25-30% of screen height.
*   **Background:** Dynamic gradient or solid color based on the selected Focus Mode.
*   **Content:**
    *   **Mindset Label:** Large text stating the mode (e.g., "INTENTIONAL MODE").
    *   **Focus Summary:** "Prioritizing [Primary Value] today."
    *   **Progress:** Circular indicator or "X Tasks Remaining" text.
    *   **Edit Action:** Small icon button to re-run the Wizard (change mode).
*   **Visual Effect:** Collapses to a standard AppBar upon scrolling down.

**Pinned Section (4B.1):**
*   **Position:** Below Alert/Review banners, above the value-grouped "Allocated" list.
*   **Default State:** Collapsed — shows only header with count (e.g., "📌 3 pinned items").
*   **Expanded State:** Tapping header reveals full list of pinned items.
*   **Contents:** Both pinned Tasks AND pinned Projects (mixed).
*   **Internal Sort:** By priority (P1 → P2 → P3 → P4 → None), then alphabetical by name.
*   **Visual Treatment:** Same Task Tiles and Project Cards as main list, with subtle pin icon (📌) overlay on each item.
*   **Style:** Subtle surface variant background or left border to distinguish from allocated section.

**Body Region (Split List - Option A):**
*   **Structure:** Two distinct sections (Slivers).
*   **Section 1: The Plan (Allocated)**
    *   **Heading:** "Recommended Plan" or "Allocated for You".
    *   **Content:** Algorithmically chosen Tasks and Projects interspersed.
    *   **Grouping:** Grouped by **Primary Value**.
        *   *Group Header:* Value Icon + Name + Priority Badge + Color.
    *   **Style:** Standard background.
*   **Section 2: The Extras (Reference/Pinned)**
    *   **Heading:** "Your Pins & Additions" (Shows count e.g., "📌 3 Items").
    *   **Content:** Manually pinned tasks/projects or tasks added after the plan was generated.
    *   **State:** **Collapsed by default** (Expandable).
    *   **Sort:** P1 -> P4.
    *   **Style:** Subtle background tint (surface variant) or distinctive left border to signify "Manual Override".
*   **Footer:** "All Done!" illustration when list is empty.

**Focus Mode Selection Wizard (4B.2):**
*Launched when user taps the Focus Mode Banner. Multi-step flow with hidden global navigation.*

| Step | Name | Content | Visibility |
|------|------|---------|------------|
| 1 | Choose Your Focus | 4 selectable mode cards: Intentional (🎯), Sustainable (🌱), Responsive (⚡), Personalized (🎛️). Each shows: Icon, Name, Tagline, Description, "~X Tasks" estimate. | Always |
| 2 | Custom Configuration | Weight sliders: Importance, Urgency, Synergy, Balance. Recovery mode toggle. Preview list of top 3-5 items with current weights. | Personalized mode only |
| 3 | Safety Net Rules | List of alert rules with Enable toggle + Severity dropdown (Critical/Warning/Notice). | Always |

*   **Navigation:** Step indicator at top (e.g., "Step 1 of 3"). Back/Continue buttons.
*   **Completion:** "Save & Continue to My Day" on final step.
*   **Global Nav:** Hidden during wizard flow.

### Tier 2: Core Task Management

#### 3.3 Global Navigation Structure
> **Goal:** Access core screens (My Day, Values, Projects) from anywhere.
> **Layout Strategy:** **Option A: Adaptive Navigation**.

**Visual Layout:**
*   **Mobile (< 600dp):** **Bottom Navigation Bar** (5 Items).
    1.  **My Day** (Home).
    2.  **Scheduled** (Calendar).
    3.  **Someday** (Backlog).
    4.  **Journal** (Feed).
    5.  **Browse** (Menu) -> Opens **Navigation Drawer** containing Projects, Values, Insights, Settings.
*   **Tablet/Desktop (> 600dp):** **Navigation Rail** (Left Edge - 8 Items).
    *   Items: My Day, Scheduled, Someday, Journal, Values, Projects, Insights, Settings.
    *   Position: Fixed to left edge.
    *   Fab: Primary "Add" FAB docks to the top of the rail.

#### 3.4 New / Edit Task
> **Goal:** Rapid entry of tasks without losing context.
> **Layout Strategy:** **Option A: Adaptive Sheet**.

**Visual Layout:**
*   **Mobile:** **Modal Bottom Sheet**.
    *   Height: Dynamic (auto-height for simple, expands to 90% for details).
    *   Handle: Visible drag handle at top.
*   **Desktop:** **Side Sheet** (Right Edge).
    *   Width: Fixed (~400dp).
    *   Behavior: Slides in from right, overlaying or pushing content.
*   **Content Internal:**
    *   **Top:** Task Name (Large text field).
    *   **Middle:** Row of "Quick Toggles" (Date, Priority P1-P4, Pin).
    *   **Bottom:**
        *   "Value Picker" (Dropdown or horizontally scrolling chips).
        *   "More Details" expands to show Descriptions/Subtasks, Repeat Rule Picker.
    *   **Action:** Floating or Fixed "Save" button.
    *   **Discard Behavior:** If sheet/modal is dismissed with unsaved changes, show "Discard Changes?" dialog (Confirm/Cancel) to prevent data loss.

#### 3.5 My Values Screen
> **Goal:** Visualize "Life Areas" as identity pillars, not just data buckets.
> **Layout Strategy:** **Option A: Adaptive Identity Grid**.

**Visual Layout:**
*   **Mobile:** **2-Column Vertical Grid**.
*   **Desktop:** **Responsive Masonry Grid** (3-5 columns based on width).
*   **Card Content (Identity Card):**
    *   **Height:** Aspect ratio ~3:4 (Portrait/Tall) to emphasize "Pillars".
    *   **Visuals:** Large central Icon, tinted background (Value Color).
    *   **Data:**
        *   Name (Bold, bottom anchored).
        *   Priority Badge (Top right).
        *   "Strength/Health" indicator (Small bar or dot below name).
*   **Interactions:**
    *   **Tap:** Open Value Detail screen.
    *   **Long Press / Drag:** Reorder items to adjust manual priority rank (visualizes the "Hierarchy of Needs").
    *   **FAB:** "Create Value".
        *   **Stale Indicator:** Warning icon if last reviewed > 30 days.
*   **Actions:** FAB to "Create Value" (opens Adaptive Sheet).

### Tier 3: Organization & Planning

#### 3.6 Projects Screen
> **Goal:** High-level view of long-term commitments.
> **Layout Strategy:** **Active/Completed Toggle**.

**Visual Layout:**
*   **Header Controls:**
    *   **Segmented Button:** `[ Active (Default) | Completed ]`.
    *   **Search/Filter:** Icon button for finding specific projects (by name).
    *   **Sort:** Deadline, Name, Priority, Recent.
*   **Body Content (Active Tab):**
    *   **Mobile:** Vertical List of Project Cards (See 2.2).
    *   **Desktop:** **Responsive Grid** (Masonry, 3+ columns) of Project Cards.
    *   **Empty State:** "No Active Projects" illustration + "Create Project" button.
*   **Body Content (Completed Tab):**
    *   Similar layout but with "Completed" styles (Desaturated, Badge visible).
*   **Note:** No "On Hold" status columns. Binary Active/Done state.

#### 3.7 Scheduled Screen (Calendar)
> **Goal:** Time-based planning and deadline visibility.
> **Layout Strategy:** **Option A: Infinite Agenda (Split on Desktop)**.

**Visual Layout:**
*   **Mobile Layout:**
    *   **Top Bar:** Horizontal Date Strip (~7 days, e.g., "Mon 6"). Bidirectional sync with scroll.
        *   "Today" Button: Jump to current date.
        *   Calendar Icon: Open **Full Month Modal** for rapid jumps.
    *   **Body:** Continuous vertical list of tasks/projects grouped by day.
*   **Desktop Layout:**
    *   **Split View:** Two-pane or sidebar layout.
    *   **Left Pane (Fixed):** Large Month Calendar for rapid navigation.
    *   **Right Pane (Scroll):** Infinite Agenda List.
*   **List Item Styling:**
    *   **Overdue Section:** At top, collapsible, high visibility (Red).
    *   **Sticky Headers:** Semantic groupings ("Today", "Tomorrow", "This Week", "Next Week", "Later").
    *   **Date Headers:** Specific date ("Mon, Jan 7").
    *   **Items:** Standard Task Tiles and Project Cards.

**Date Tag Logic (4A.1):**

| Day Type | Tag | Color | Visual Priority | Card Display |
|----------|-----|-------|-----------------|---------------|
| Start Date | "Starts" | Green (Success) | High | Full card with all metadata |
| In-Between | "In Progress" | Blue (Primary) | Low | Condensed row (see below) |
| Deadline | "Due" | Red (Error) | High | Full card with all metadata |

*Items with only a deadline show on that date with "Due" tag. Items with only a start date show on that date with "Starts" tag.*

**In Progress Condensed Display (4A.3):**
*To avoid clutter on consecutive days, multi-day items display differently on intermediate days:*

| Entity | Condensed Visual | Distinguishing Element |
|--------|------------------|------------------------|
| **Task** | Single line: Task Name + Blue "In Progress" dot | No checkbox, no metadata |
| **Project** | Single line: Project Name + Mini progress ring (16dp) + Blue "In Progress" dot | Mini ring shows completion %, distinguishes from tasks |

*Both use same row height (~48dp). Project's mini ring visually differentiates it from a task row.*

**Repeating Items Display (4A.2):**

| Repeat Type | Backend Flag | Display Behavior | Visual Indicator |
|-------------|--------------|------------------|------------------|
| **Fixed Interval** | `repeatFromCompletion = false` | Show **ALL instances** within loaded date horizon | No special icon |
| **After Completion** | `repeatFromCompletion = true` | Show **NEXT instance only** | 🔁 Loop icon on item |

*Fixed Interval Example:* "Weekly standup" (every Monday) shows on Jan 6, 13, 20, 27...
*After Completion Example:* "Haircut" (6 weeks after done) shows only next due date with 🔁.

**Empty Day Handling (4A.4):**

| Date Range | If Empty | Visual |
|------------|----------|--------|
| **Near-term (Today → +7 days)** | Show date header + placeholder | "No tasks scheduled" in muted text |
| **Beyond 7 days** | Skip entirely | Date header not rendered |

#### 3.8 Someday Screen (Unscheduled)
> **Goal:** Browse unscheduled tasks and projects.
> **Layout Strategy:** **Option A: The Value-Grouped Expansion**.

**Visual Layout:**
*   **Header:** Simple Illustration/Banner explaining "Ideas for later".
*   **Filter Tabs:** Active | Completed. (Completed removed from view by default).
*   **Body:**
    *   **Grouped List:** Items grouped by **Primary Value**.
    *   **Headers:** Value Icon + Name + Priority Badge. Sorted by Value Priority (High -> Low).
    *   **Items:** Mixed Task Tiles and Project Cards.
    *   **Content:** Only items with *No Deadline* and *No Start Date*.

#### 3.9 Project Detail Screen
> **Goal:** Execution context for a specific goal.
> **Layout Strategy:** **Option A: The "Progress Wrapper"**.

**Visual Layout:**
*   **Layout:** SliverAppBar + Pinned Header.
*   **Header (Collapsible):**
    *   **Top:** Large Project Name + Deadlines (Badge if urgent).
    *   **Hero:** Prominent **Circular Progress Indicator** next to a "Complete Project" button (visible if Active, Manual trigger).
    *   **Metadata:** Value Chips (Primary fully colored, Secondaries faded), Description.
*   **Body:**
    *   **Pending Tasks:** Standard list (sorted by Task Priority P1->P4).
    *   **Completed Tasks:** Distinct "History" expansion tile at bottom (default collapsed).
*   **Actions:** FAB to "Add Task" (Pre-populates Project field and Values).

#### 3.10 Value Detail Screen
> **Goal:** View "Life Area" health and association.
> **Layout Strategy:** **Option A: The "Primary Focus" List**.

**Visual Layout:**
*   **Header:** "Identity Card" style (Icon, Color, Priority Badge) + Health Metric (e.g., "Last reviewed X days ago").
*   **Filter Tabs:** All | Active | Completed.
*   **Body (Active Tab):**
    *   **Section 1: "Primary Focus"**: Items (Tasks/Projects) where this Value is **Primary** (Full visual saturation). Sorted by Deadline/Priority.
    *   **Section 2: "Synergy"**: Items where this Value is **Secondary** (Faded/Outlined visuals).
*   **Actions:** FAB to "Add Task" (Pre-populates Primary Value).

#### 3.11 New / Edit Project (Flow)
> **Layout Strategy:** **Option A: Adaptive Sheet** (Matches Task).

**Visual Layout:**
*   **Fields:** Name (Required), Primary Value (Required, Picker), Secondary Values, Description, Dates (Start/Dead), Priority, Pinned Toggle, Repeat Rule.
*   **Validation:** Name/Primary Value required.
*   **Discard Behavior:** Standard "Discard Changes?" confirmation on dismissal with dirty state.

#### 3.12 New / Edit Value (Flow)
> **Layout Strategy:** **Option A: Adaptive Sheet** (Matches Task).

**Visual Layout:**
*   **Fields:** Name (Required), Color Picker (Required), Icon Picker, Priority Selector (Default: Medium).

---

### Tier 4: Reflection & Connect

#### 3.13 Journal Screen (Log)
> **Goal:** Encouraging reflection via a chronological "Life Feed".
> **Layout Strategy:** **Option A: Social Feed (Timeline)**.

**Visual Layout:**
*   **Header Section:**
    *   **Search & Filter:** Text search, Date Range Picker.
    *   **Quick Actions:** "Quick Mood/Note" button (or FAB).
    *   **Filter Chips:** "All", "Entries", "Tasks", "Moods".
*   **Feed Body:** Reverse chronological vertical list.
*   **Item Types:**
    *   **1. User Entry (Note):** Standard "Card".
        *   **Header:** Date + Large Mood Emoji (e.g. "Fri, Oct 12 · 😃").
        *   **Body:** Text snippet (max 3 lines).
        *   **Footer (Tracker Stamps):** Small icon+value pills (e.g., "💤 8/10").
        *   **Values:** Chip row of linked values.
    *   **3. Mood Log (Standalone):**
        *   *Visual:* Minimal row. Time + Emoji + Rating.
*   **Desktop Layout:** Masonry Grid layout for efficient use of space.

#### 3.14 Journal Detail / Edit Screen
> **Goal:** Create/Edit Entry.

**Visual Layout:**
*   **Header:** Date (Editable).
*   **Mood Selector:** 5-level Emoji Row (😢 😕 😐 🙂 😄).
*   **Output:** Rich Text Editor area.
    *   **Toolbar:** Basic formatting only: Bold, Italic, Bullet List, Numbered List.
*   **Trackers Section:**
    *   **Daily Check-ins:** Trackers scoped "Daily".
    *   **Entry Trackers:** Trackers scoped "Per-entry".
    *   *Inputs:* Slider (Scale), Choice Chips (Choice), Toggle (Yes/No).
*   **Values Section:** Value Picker (Multi-select).

#### 3.15 Insights Screen (Dashboard)
> **Goal:** Visualizing "Balance" and "Alignment" (The 'Why').
> **Layout Strategy:** **Option A: Radar "Flower" Chart**.

**Visual Layout:**
*   **Scrollable Page:** Single vertical scroll.
*   **Header:**
    *   **Time Range:** Global Picker (Today, Week, Month, Year).
    *   **Gamification Stats:**
        *   **Streak Counter:** "🔥 X Day Streak" (Prominent).
        *   **Level/XP:** Progress bar (Optional, if implemented).
*   **Section 1: Value Balance (The Flower):**
    *   **Visual:** Radar / Spider Chart. Axis = Value. Data = Balance Score.
    *   **Metaphor:** Balanced shape = Balanced life.
*   **Section 2: Task Completion:**
    *   **Velocity:** Bar chart (Tasks completed per day/week).
    *   **Focus Distribution:** Pie chart (Time spent per Value type).
*   **Section 3: Wellbeing:**
    *   **Mood Trend:** Sparkline graph overlaying Energy levels.
*   **Section 4: Achievements:** List of recent milestones or "Level Ups".

#### 3.16 Review Run (Single Page)
> **Goal:** Validating system health and user alignment in one efficient flow.
> **Layout Strategy:** **Option B: Consolidated Scroll (Single Page)**.

**Visual Layout:**
*   **Structure:** Single vertical scrollable page containing all pending review sections as distinct cards/groups.
*   **Header:** Title "Review" + Subtitle (e.g., "Weekly Check-in").
*   **Body (Review Sections):**
    *   **1. Values Alignment:**
        *   List of User's Values.
        *   Input: Simple 5-star rating or "Aligned?" toggle per value.
    *   **2. Progress Check:**
        *   Summary count: "You completed X tasks".
        *   List: Top 3-5 completed achievements.
    *   **3. Wellbeing Insights:**
        *   Visual: Mood trend sparkline from Journal.
        *   Input: Short reflection text field ("One thing I learned...").
    *   **4. Balance Check:**
        *   Visual: Mini Radar Chart showing this week's distribution.
        *   Input: Toggle to "Boost" neglected values next week.
    *   **5. Pinned Item Scrub:**
        *   List: All currently pinned tasks/projects.
        *   Action: Quick "Unpin" button on each row to clear clutter.
*   **Footer:** Large "Complete Review" button (Floating or fixed at bottom).

---

### Tier 5: Configuration & Settings

#### 3.17 Settings Hub
**Goal:** Central configuration and preference management.
**Layout Strategy:** **Grouped List**.

**Visual Layout:**
*   **Header:** Simple AppBar "Settings".
*   **Body:** Grouped List items with dividers.
*   **Groups:**
    *   **Appearance:**
        *   Theme Toggle (Segmented Button: Light/Dark/System).
        *   **Density:** Compact vs Comfortable Layout toggle.
    *   **Strategy (The Core):**
        *   "Allocation Settings" (Focus Mode config).
        *   "Exception Rules" (Alert thresholds).
    *   **Integrations:**
        *   **Calendar Sync:** "Permissions" status + "Sync Now" button.
    *   **Workflow:**
        *   "Navigation Order" (Customize tabs).
        *   "Review Preferences" (Frequency/Type).
    *   **Account:** Profile, Export Data (JSON/CSV), Sign Out.

#### 3.18 Allocation Settings
**Goal:** Tuning the "Engine" of the app.
**Visual Layout:**
*   **Focus Mode Selector:** Horizontal Carousel or Grid of cards (Same as Wizard).
*   **Recovery Toggle:** Large Switch tile with description ("Boost neglected values").
*   **Custom Weights (Conditional):**
    *   *Visible:* Only when "Personalized" mode is active.
    *   *UI:* List of Sliders for each Value (0-100%).
    *   *Feedback:* Dynamic "Total Weight" indicator.

#### 3.19 Exception Rules
**Goal:** Define what triggers an "Alert" in My Day.
**Visual Layout:**
*   **List:** Vertical list of Rule Cards.
*   **Rule Item:**
    *   **Left:** Toggle Switch (Enable/Disable).
    *   **Body:** Rule Name (e.g., "Critical Overdue") + Description.
    *   **Right/Action:** Dropdown Chip for Severity (Critical/Warning/Notice).
    *   *Color:* Dropdown Chip changes color based on severity (Red/Orange/Blue).

#### 3.20 Review Settings (5.1)
> **Goal:** Configure periodic review prompts and frequencies.
> **Layout Strategy:** **Expandable List**.

**Visual Layout:**
*   **Header:** AppBar "Review Preferences".
*   **Body:** Vertical list of Review Type rows.

**Review Types:**

| Review Type | Default Frequency | Description |
|-------------|-------------------|-------------|
| Values Alignment | 14 days | Reflect on whether tasks align with values |
| Progress | 7 days | Review completed tasks and achievements |
| Wellbeing Insights | 7 days | Check-in on energy and mood patterns |
| Balance | 14 days | Assess value distribution and neglect |
| Pinned Tasks Check | 7 days | Review and update pinned tasks |

**Row Visual (Collapsed):**
*   **Left:** Review Type Name (Title style).
*   **Right:** Toggle Switch (Enable/Disable).
*   **Subtitle:** "Every X days · Last completed [date]" or "Never completed".

**Row Visual (Expanded on Tap):**
*   **Frequency Picker:** Dropdown or stepper (7, 14, 21, 30 days).
*   **Last Completed:** Read-only date display.
*   **Description:** Brief explanation of what this review covers.

#### 3.21 Navigation Settings (5.2)
> **Goal:** Customize bottom navigation order on mobile.
> **Layout Strategy:** **Reorderable List with Drag Handles**.

**Visual Layout:**
*   **Header:** AppBar "Navigation Order".
*   **Subheader:** Instructional text: "Drag to reorder your bottom navigation tabs."
*   **Body:** Vertical list of 5 navigation items.

**List Item Visual:**
*   **Leading:** Drag handle icon (≡ or ⋮⋮).
*   **Icon:** Navigation item icon (e.g., Home for My Day).
*   **Label:** Navigation item name.
*   **Position Number:** Subtle badge showing current position (1-5).



**Interaction:**
*   **Drag:** Long-press and drag to reorder.
*   **Visual Feedback:** Lifted item has elevation shadow; drop zone highlighted.
*   **Save:** Changes apply immediately (no explicit save button).

