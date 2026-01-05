1. General Design Principles & Constraints

    Platform: Mobile (iOS focus, but principles apply broadly to mobile native/web).
    Theming: Consistent Dark Mode Material Theming. This includes:
        A primary dark background.
        Vibrant accent colors (e.g., bright green, purple/pink) for interactive elements, highlights, and status indicators.
        Consistent rounded corners for cards, buttons, and input fields.
        Unified typography across all screens (titles, body text, metadata).
    Consistency:
        Task/Project Cards: A standardized, condensed card/tile design is used for displaying individual tasks and projects across all "My Day," "Scheduled," and "Someday" views.
        Metadata Display: Essential metadata (start date, deadline, priority, labels, associated project/Inbox, values) is shown concisely using small icons and secondary text, designed to enhance rather than clutter the main item.
        Project vs. Task Distinction: Projects are visually distinct from tasks (e.g., different card background, larger header, project-specific icons).
        Value Priority Labels: "HIGH PRIORITY VALUE," "MEDIUM PRIORITY VALUE," "LOW PRIORITY VALUE" are used consistently for value groups, visually distinct from individual task/project priorities (P1-P4, Low/Medium/High).
        Mobile Navigation: A consistent bottom navigation bar is present on most content screens (e.g., My Day/Home, Values, Plus, Plan/Scheduled, Profile/Settings). Screens like onboarding and persona selection intentionally omit this for focused user flows.
    Persona-Driven Experience: The core of Taskly's design revolves around dynamically adapting content and grouping based on the user's selected persona, while maintaining visual consistency for individual items.
    Progressive Disclosure: Complex configurations (like Custom Persona settings) and detailed explanations (like allocation transparency) utilize progressive disclosure to avoid overwhelming the user at first glance.

2. My Day Screens (Persona-Specific)

Purpose: The central, personalized focus view, showing tasks and projects the user should work on today, based on their chosen persona's prioritization logic.

Core Functionality (Consistent Across Personas):

    Persona Banner: A prominent banner at the top displaying the active persona's name and a first-person tagline.
    Allocation Exceptions: Consistent "Urgent Attention" and "Warning" banners appear directly below the persona banner.
        Urgent Attention: Highly prominent, typically for critical, unallocated items.
        Warning: Expandable banner showing a count of items needing review.
    "My Focus" Section: Displays allocated tasks and projects using the consistent card design.
        Metadata: Start date, deadline, priority (P1-P4, Low/Medium/High), labels, and associated project/Inbox are consistently shown.
        Internal Ordering: Within any grouping, tasks/projects are ordered by individual priority (highest first) and then by urgency (soonest deadline first).
    Excluded Items Message: A clear, persona-aligned message at the bottom indicating tasks/projects that were not allocated by the current persona's rules, offering transparency.
    Quick Actions: Checkbox for completion, tap for detail screen.
    New Item FAB: A floating action button (FAB) for quickly adding new tasks/projects.

Behavior & Grouping (Persona-Specific):

    My Day (Idealist) - Final Refined (screen_id: 09151e6a98454b4b9d5f71c7bd2a0a66):
        Tagline: "Show me what matters most, not what's most urgent."
        Grouping: Primarily grouped by Value Priority ("HIGH PRIORITY VALUE: Strategic Vision," "MEDIUM PRIORITY VALUE: Creative Exploration," etc.), ordered from highest to lowest value priority.
        Constraint: Does not include overall stats at the top to maintain focus on value-aligned tasks.
    My Day (Reflector) - Final Refined (screen_id: d52d20d59de84c13a89981abac4946b1):
        Tagline: "Show me values I've been neglecting."
        Grouping: Primarily grouped by Value, explicitly ordered by most neglected values first. Each value group includes a clear visual indicator of its neglect status.
        Constraint: Includes a "Value Balance Summary" graph (e.g., a pie chart or similar visualization) above the first value group to highlight areas of neglect and guide the user's attention.
    My Day (Realist) - New Mockup (screen_id: 1d161495dc5443f9a222de5ed91cff01):
        Tagline: "Show me what matters most, but warn me about urgent tasks."
        Grouping: Primarily grouped by Value Priority ("HIGH PRIORITY VALUE," etc.), ordered from highest to lowest value priority.
        Constraint: Designed to be a balanced view, similar in structure to Idealist but with the Realist's specific tagline.
    My Day (Firefighter) - Final Refined (screen_id: 023f0613e7a14851a3b1cc2ae881c3ed):
        Tagline: "Show me what's urgent right now."
        Grouping: Strictly by Urgency/Deadline ("OVERDUE," "DUE TODAY," "UPCOMING (Next 7 Days)," "HIGH PRIORITY, NO DEADLINE").
        Constraint: The "My Focus" section prioritizes critical and time-sensitive items. The excluded items message is tailored: "X tasks and projects that are not urgent have been deprioritized to help you focus on critical items."
    My Day (Custom Persona) - New (screen_id: d3aa09202db741ae9d55dfc4930e86c9):
        Tagline: "Let me decide what you show me."
        Grouping: Adaptable, demonstrating a blend, e.g., "Weighted by: Value Priority & Urgency" to reflect custom settings.
        Constraint: The grouping and ordering logic is fully user-configurable, offering maximum flexibility. The excluded message: "X tasks excluded by your custom focus settings, but are in your backlog."

3. Support & Setup Screens

    Welcome to Taskly (screen_id: 8a4261d37c234bf1b7ae15cad8483f4f):
        Purpose: Introduce new users to Taskly's core mission and value-driven approach.
        Functionality: Compelling headline, brief explanation, clear "Start Prioritizing" call to action. Link for existing accounts.
        Constraint: No mobile navigation bar to maintain focus on onboarding.
    Select Persona - Hero View (screen_id: 31803be3aacc4564b8dc3e121899fb41):
        Purpose: Allow users to choose their primary workflow persona.
        Functionality: All five personas displayed simultaneously as visually distinct "hero" cards with names, descriptions, and unique branding. "The Realist" is "Recommended." "Custom" includes an "Configure" option.
        Constraint: Single-page view, no scrolling. No mobile navigation bar for focused selection.
    Custom Persona Configuration (screen_id: 46ebcc86fbea4a4db0306dbe5e879a89):
        Purpose: Allow users to fine-tune prioritization parameters for the "Custom" persona.
        Functionality: Clean UI with progressive disclosure. "Current Weightings" (Value Priority, Urgency Boost, Thresholds, Neglect Influence, Urgent Task Behavior) are shown with editable inputs. "Proposed Additional Weightings" (Task Priority Level Boost, Recency Penalty, Start Date Proximity Bonus, Overdue Emergency Multiplier) are available for advanced configuration. "Save Custom Persona" button.
        Constraint: No mobile navigation bar during configuration.
    Allocation Exception Rules (screen_id: 1e4cdb4905f445148e67e77b9e544b8f):
        Purpose: Define "safety net" rules for unallocated tasks to prevent them from falling through the cracks.
        Functionality: Lists active rules (e.g., "Immediate Deadline," "High Value Health"). Allows adding new custom rules with criteria (e.g., "if deadline < X days AND value is Y") and severity (Warning/Urgent). Suggests common rules.
        Constraint: No mobile navigation bar during rule creation/editing.

4. Core Content Management Screens

    New Task - Select Project (screen_id: 061bc0c99df764c43a6eda08f864b0f4e):
        Purpose: Create a new task with comprehensive metadata.
        Functionality: Fields for name, description, "Connect to Purpose" (link to values), start date, due date, priority (Low/Medium/High), project selection (dropdown), labels.
        Constraint: "Link to Values / Alignment" section consistently after description.
    New Project - Consistent Form (screen_id: 0b77c24eb0ad4618815796a588b343ec):
        Purpose: Create a new project with comprehensive metadata.
        Functionality: Fields for project name, description, "Alignment" (link to values), due date, priority.
        Constraint: Mirrors the "New Task" flow, with "Link to Values / Alignment" consistently after description, and no project selection (as projects can't be nested).
    My Values (screen_id: 41e7fffd52104b2ba5f0cd4a70e2b793):
        Purpose: Overview, creation, and basic management of personal value tags.
        Functionality: Lists custom value tags with their color, icon, and priority level. Shows initial stats (e.g., "12 tasks completed this week," "45% of total focus time," "5 active projects"). "Create New Value" call to action. Filter options (All Priorities, High Priority, Most Active).
        Constraint: Serves as a primary entry point for value management.
    All Projects View (screen_id: 39559a3a4109444191c980f8a845aa09):
        Purpose: Comprehensive list of all projects, with filtering and sorting.
        Functionality: Lists projects with name, associated values, progress (e.g., "75% Complete"), task count, and deadline. Search bar, filters (Active, Completed, On Hold), and sort options.
    Project Detail View (screen_id: 013742bc2f1347b9b0a27b77ab78fec3):
        Purpose: In-depth view of a specific project and its linked tasks.
        Functionality: Project details (name, description, values, deadline, progress) at the top. Below, a list of "Pending Tasks" (sortable) and "Completed Tasks." Each task shows its metadata (priority, energy, due day).
    Inbox View (screen_id: b9639aff46d54adc91d830ae4a578b58, not in selected screen context list, but referenced in chat):
        Purpose: Dedicated view for tasks without any assigned project or value.
        Functionality: Lists unassigned tasks, allowing quick review, editing, or assignment.
    Scheduled - Timeline Focus 3/3 (screen_id: 9968a3071ace40f3898edfa7ba3ee09c):
        Purpose: Overview of upcoming scheduled tasks and projects for capacity planning.
        Functionality: Top horizontal, scrollable date picker (with "Today" button and calendar icon). Semantic date groupings ("Today," "This Week," etc.) with specific date headers.
        Constraint (Start/Deadline Logic): Items with both start and deadline dates are displayed:
            On their start date with a "Starts" tag.
            On subsequent days as "In Progress" (subtle visual).
            On their deadline date with a prominent "Due" tag.
        Detail Level: Condensed card view, visually distinguishing tasks/projects, compactly showing values and essential metadata.
        Constraint: "In Progress" items are subtly grouped under their primary start/project header to show ongoing work across days without repeating full cards.
    Someday - Value Grouped 1/3 (screen_id: 926efeb92bf44f5e8b43258680a3ef57):
        Purpose: A home for tasks and projects with no start date AND no deadline, for future consideration.
        Functionality: Primarily grouped by Value Priority (e.g., "HIGH PRIORITY VALUE: Career"). Within each value group, tasks are further grouped by their Project. An "Inbox" sub-heading exists for tasks assigned to that value but not a project.
        Detail Level: Standard task/project cards, visually distinct.
        Interactions: Prominent FAB for adding new "Someday" items. Context-sensitive quick actions (e.g., "Schedule," "Assign"). Global filter/sort bar at the top applies within value groups.
    All Journal Entries (screen_id: 6b8adec16e164f0dafb758dac4eb06c3):
        Purpose: Timeline-based view of all past journal entries.
        Functionality: Entries grouped by date ("Today," "Yesterday"). Each entry shows mood, timestamp, text snippet, and associated trackers. Expandable for full details. Filter/sort options for mood, tags, favorites.
    New Journal Entry - Clear Sections (screen_id: 8f13dc37eeaa429f8e692050c428e08e):
        Purpose: Create a new journal entry for mood, reflection, and tracking.
        Functionality: Mood selection (5-level scale). Clearly divided into "Daily Check-ins" (all-day scope trackers like "Sleep Quality," "Focus Area") and "Trackers" (per-entry scope like "Current Activity" [Choice], "Water Intake" [Scale], "Achieved Main Goal?" [Yes/No]). Reflection text field.
