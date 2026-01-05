
Taskly Design Integration Summary for AI Developer
1. General App Principles & Integration Notes

    CRITICAL Refer to  architecture summary document for overview of architecture before making any plans or changes.

    
    Platform: Mobile-first design, adaptable to larger screens (web/desktop via responsive Navigation Rail). The current mockups are for mobile.
    Theming: Crucial: The app MUST follow Material Design best practices for theming. The green theme in the mockups is for demonstration purposes only. The actual implementation should support user-selectable themes (Light/Dark mode) and potentially dynamic color (if the platform supports it and is desired). All components should inherit theme properties.
    Data Consistency: Ensure that data displayed on one screen (e.g., task metadata) is consistently formatted and presented when that same data appears on another screen.

    Ensure widgets and code generated are easy to maintain , prefer one widget per entity and context e.g. TaskListTile for everywhere
    tasks are shown in list with appropiate parameters for compact of variations

    Note Taskly Project uses a data driven screen approach for many screens - review the files for screen definitions. 

    Note for navigation - reuse existing navigation rail and menu bar pattern - search routine and navigation to find related files.
    There may also be navigationOnly types in screen definitios.

    Align changes to current architecture for backend



    Confirm all requirements for each screen are supported by backend (backend means all application layers that are not UI - it includes BLOCs) if they are not supported TELL USER THIS AND SEEK CONFIRMATION ON ANY REQUIRED UPDATES



2. Global Navigation Structure (REVISED)

Menu Item Order (Consistent across Mobile Drawer & Desktop Rail):

    My Day
    Scheduled
    Someday
    Journal
    Values
    Projects
    Statistics
    Settings

(Inbox is now consolidated within Someday and is no longer a top-level navigation item).

Adaptive Navigation Plan:

    Mobile (Small Screens):
        Bottom Navigation Bar: Persistent. Displays the first 4 menu items (My Day, Scheduled, Someday, Journal) plus a "Browse" item.
        Navigation Drawer: Accessible by tapping "Browse" in the bottom navigation. Displays all 8 menu items in the specified order.
            My Day
            Scheduled
            Someday
            Journal
            Projects
            Values
            Statistics
            Settings
    Desktop / Web (Large Screens):
        Navigation Rail (Side Navigation): Persistent. Displays all 8 menu items with icons and labels. No "Browse" needed.
            My Day
            Scheduled
            Someday
            Journal
            Projects
            Values
            Statistics
            Settings
    Wizard Flows (Onboarding/Setup): Screens that are part of a multi-step setup wizard (e.g., persona selection) omit the global navigation (bottom nav/rail) to maintain focus.


3. Persona Selection & My Safety Net Rules Workflow

Purpose: A crucial multi-step wizard to onboard new users or allow existing users to reconfigure their core prioritization strategy.

Launch Conditions:

    Initial Onboarding: If My Day is visited and no persona is saved, launch this workflow starting at "Choose Your Focus Style (Step 1 of X)".
    Reconfiguration: If the user taps the active persona banner on any My Day screen, launch this workflow starting at "Choose Your Focus Style (Step 1 of X)".

Dynamic Workflow Steps:

    Step 1: Choose Your Focus Style (screen_id: 8382360b960840c7bf90e91dd88c4337)
        Purpose: User selects their primary persona.
        UI Elements: Title ("Choose Your Focus Style (Step 1 of X)"), 5 persona cards (Idealist, Reflector, Realist-RECOMMENDED, Firefighter, Custom) with descriptions, "Continue" button.

        Navigation:
            Tapping "Continue" leads to:
                If static persona chosen: My Safety Net Rules (Step 2 of 2).
                If "Custom" chosen: Custom Persona Configuration (Step 2 of 3).
        Constraint: No global navigation.

    Step 2 (Conditional): Custom Persona Configuration (screen_id: 46ebcc86fbea4a4db0306dbe5e879a89)
        Purpose: Configure detailed parameters for the "Custom" persona.
        UI Elements: Title ("Custom Persona Configuration (Step 2 of 3)"), sections for "Current Weightings" and "Proposed Additional Weightings" with sliders, toggles, text inputs, info icons. "Continue" button.
        Navigation: Tapping "Continue" leads to My Safety Net Rules (Step 3 of 3).
        Constraint: Only displayed if "Custom" was selected in Step 1. Page number "2 of 3". No global navigation.

    Final Step: My Safety Net Rules (screen_id: 28da5c4cf5084692af6c803ee4815ef1)
        Purpose: Configure "safety net" rules for unallocated tasks.
        UI Elements: Title ("My Safety Net Rules (Step X of X)"), description text, "ACTIVE RULES" list, "SUGGESTIONS" list, "Add New Rule" button, "Save & Continue to My Day" button.
        Navigation: Tapping "Save & Continue to My Day" completes the workflow and navigates to the user's My Day screen.
        Constraint:  No global navigation.

5. Individual Screen Functionality & Backend Requirements

(Note: screen_ids are provided for reference to mockups)

    Welcome to Taskly (screen_id: 2e8263a0b0804c489e18ce780e0608fc)
        Purpose: Initial app introduction.
        UI Elements: Title, description, CTA ("Start Prioritizing"), "Already have an account?" link.
        Backend Needs: None directly; serves as a UI gateway.
    Navigation Drawer (screen_id: 6b13de8ed3424e728ae7540ec55b9927)
        Purpose: Provide access to all app sections on mobile.
        UI Elements: List of 8 menu items with icons and labels.
    
    My Day (Idealist/Reflector/Realist/Firefighter/Custom) (e.g., Idealist: f6721deba2fd4c7d97bc555196455613)
        Purpose: Personalized daily focus view.
        UI Elements: Persona banner (name + tagline), "Urgent Attention" and "Warning" banners (expandable), "My Focus" section (tasks/projects grouped by persona logic), message for excluded items, FAB.
        Constraint: Persona banner is clickable to launch the persona setup workflow.
    New Task - Select Project (screen_id: 085157a941aa4b69abb62c2524263b20)
        Purpose: Create a new task.
        UI Elements: Input fields (name, description), dropdown (project selection), date pickers (start/deadline), priority selector, labels input, value selector ("Connect to Purpose"), "Create Task" button.
        Backend Needs:
            GET /projects: Fetch list of user's projects for dropdown.
            GET /values: Fetch list of user's values.
            GET /labels: Fetch list of user's labels.
            POST /tasks: Create new task.
    New Project - Consistent Form (screen_id: 5ecc77fd840c4973a24a78fb47d799a2)
        Purpose: Create a new project.
        UI Elements: Input fields (name, description), priority selector, date picker (deadline), value selector ("Alignment"), "Create Project" button.
    My Values (screen_id: d97128291307494e88fa2e7207373335)
        Purpose: Overview and basic management of personal value tags.
        UI Elements: List of value cards (name, icon, color, priority, basic stats), "Create New Value" button.
    All Projects View (screen_id: 5d48317c92cb4e4e82ec76e02db33084)
        Purpose: Comprehensive list of all projects.
        UI Elements: Search bar, filter/sort options (Active, Completed, On Hold; by deadline, name, priority), list of project cards (name, values, progress, deadline).
    Project Detail View (screen_id: 9486adce8826498d9ea80c3a4100640b)
        Purpose: In-depth view of a specific project and its linked tasks.
        UI Elements: Project header (name, description, values, deadline, progress), sections for "Pending Tasks" and "Completed Tasks." Task cards with metadata.
    Scheduled - Timeline Focus 3/3 (screen_id: 228ec809cd884f2795ee6ec80a654388)
        Purpose: Chronological overview of upcoming commitments for capacity planning.
        UI Elements: Horizontal scrollable date picker, "Today" button, calendar icon. Semantic date groupings ("Today," "This Week") with specific date headers. Condensed item cards with "Starts," "In Progress," "Due" tags.
    Someday - Value Grouped 1/3 (screen_id: 97cf2b5ee32f43f9b39f02fb96301cbe)
        Purpose: Manage tasks/projects with no start date and no deadline.
        UI Elements: Grouped by value priority. Within value groups, tasks grouped by project, with an "Inbox" for value-assigned, project-less tasks. Standard item cards. Filter/sort bar. FAB.

    All Journal Entries (screen_id: 6e63cef0b2894dc89b5e9a44c535361e)
        Purpose: Timeline-based view of all past journal entries.
        UI Elements: Entries grouped by date. Each entry shows mood, timestamp, snippet, trackers. Expandable. Filter/sort.

    New Journal Entry - Clear Sections (screen_id: 623824bb4f3447f5b6fb46efcdd564bf)
        Purpose: Create a new journal entry.
        UI Elements: Mood selector, reflection text. Sections for "Daily Check-ins" (trackers with all-day scope) and "Trackers" (per-entry scope). "Save Entry" button.


This detailed summary should serve as a robust blueprint for the AI developer to implement Taskly.