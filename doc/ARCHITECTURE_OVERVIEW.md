# Taskly Architecture

> Comprehensive architecture documentation for Taskly.
> This document reflects the current implemented state of the application.
> 
> **Last Updated:** 7 January 2026

---

## Table of Contents

1. [High-Level Architecture](#high-level-architecture)
2. [Domain Model](#domain-model)
3. [Scoring & Allocation System](#scoring--allocation-system)
4. [Review System](#review-system)
5. [Alert System](#alert-system)
6. [Data-Driven Screen System](#data-driven-screen-system)
7. [Navigation & Routing](#navigation--routing)
8. [Data Layer](#data-layer)
9. [Dependency Injection](#dependency-injection)
10. [Implementation Status](#implementation-status)

---

## High-Level Architecture

### Layer Overview

Taskly follows a clean architecture pattern with four main layers:

```
┌─────────────────────────────────────────────────────────────┐
│  PRESENTATION LAYER (lib/presentation/)                     │
│  - Widgets, Pages, Renderers                                │
│  - BLoCs (state management)                                 │
│  - Navigation & Routing                                     │
├─────────────────────────────────────────────────────────────┤
│  DOMAIN LAYER (lib/domain/)                                 │
│  - Business logic & Services                                │
│  - Models (entities, value objects)                         │
│  - Queries & Predicates                                     │
│  - Repository Contracts (interfaces)                        │
├─────────────────────────────────────────────────────────────┤
│  DATA LAYER (lib/data/)                                     │
│  - Repository Implementations                               │
│  - Database (Drift/PowerSync)                               │
│  - Mappers & API connectors                                 │
├─────────────────────────────────────────────────────────────┤
│  CORE LAYER (lib/core/)                                     │
│  - Dependency Injection (GetIt)                             │
│  - Routing configuration                                    │
│  - Theme & L10n                                             │
│  - Utilities & Environment                                  │
└─────────────────────────────────────────────────────────────┘
```

### Key Design Principles

1. **Dependency Inversion**: Domain defines interfaces (contracts), Data implements them
2. **Repository Pattern**: All data access through repository contracts
3. **BLoC Pattern**: State management via flutter_bloc
4. **Data-Driven UI**: Screen definitions drive rendering
5. **Unified Queries**: Type-safe query objects with database-level filtering
6. **Values-First Scoring**: All task prioritization flows through the Unified Scoring Service

---

## Domain Model

### Core Entities

#### Task

The central work item with value alignment and scheduling.

```dart
class Task {
  final String id;
  final String name;
  final String? description;
  final bool completed;
  final DateTime? startDate;
  final DateTime? deadlineDate;
  final Priority priority;           // P1, P2, P3, P4
  final bool isPinned;
  final String? projectId;
  final RepeatRule? repeatRule;
  
  // Value relationships (via junction table)
  final List<TaskValue> values;      // Includes isPrimary flag
  
  // Computed properties
  String? get primaryValueId;
  List<Value> get secondaryValues;
}
```

**Key Changes**:
- Values have `isPrimary` flag via junction table
- **No value inheritance**: Tasks store their own values directly; they do NOT inherit from parent project at runtime

| Value Type | Weight | Purpose |
|------------|--------|---------|
| **Primary Value** | 100% | Main driver, determines task's primary account |
| **Secondary Values** | 30% | Additional benefits, powers Synergy scoring |

*Note: When creating a task within a project, the UI pre-populates the project's values as a convenience. The user can modify before saving. Once saved, task values are independent of the project.*

#### Project

Container for related tasks with shared context.

```dart
class Project {
  final String id;
  final String name;
  final String? description;
  final DateTime? startDate;
  final DateTime? deadlineDate;
  final Priority priority;
  final bool completed;              // Simple boolean (aligned with Task)
  final bool isPinned;
  final RepeatRule? repeatRule;
  
  // Value relationships (same pattern as Task)
  final List<ProjectValue> values;   // Includes isPrimary flag
  
  // Computed properties (same as Task for feature parity)
  String? get primaryValueId;
  List<Value> get secondaryValues;
  
  // Task aggregates
  int get taskCount;
  int get completedCount;
  double get progressPercentage;
}
```

**Key Point**: Projects have the same primary/secondary value structure as Tasks for feature parity.

| Value Type | Weight | Purpose |
|------------|--------|--------|
| **Primary Value** | 100% | Main driver, determines project's primary grouping |
| **Secondary Values** | 30% | Additional context, powers Synergy scoring |

*Note: Projects use `bool completed` (not a status enum) to align with Task model. "On Hold" functionality is not supported. Projects are either active (completed=false) or completed (completed=true).*

#### Value

Personal value or life area for task categorization.

```dart
class Value {
  final String id;
  final String name;
  final String color;                // Hex color
  final String icon;                 // Icon identifier
  final ValuePriority priority;      // high, medium, low
  final DateTime? lastReviewedAt;
  
  // Computed (via enrichment)
  int get taskCount;
  double get completionRate;
  bool get isStale;                  // >30 days without review
}
```

#### FocusMode (formerly AllocationPersona)

Allocation strategy preset determining task prioritization weights.

```dart
enum FocusMode {
  intentional,    // Important over urgent
  sustainable,    // Growing all values
  responsive,     // Time-sensitive first
  personalized,   // User-defined weights
}
```

| Mode | 💎 Importance | 🔥 Urgency | ⚡ Synergy | ⚖️ Balance | Best For |
|------|:-------------:|:----------:|:----------:|:----------:|----------|
| **Intentional** | 2.0 | 0.5 | 1.0 | 1.0 | Deep work on what matters most |
| **Sustainable** | 1.0 | 1.0 | 1.5 | 1.5 | Balanced daily productivity |
| **Responsive** | 0.5 | 3.0 | 0.0 | 0.0 | Handling urgent deadlines |
| **Personalized** | Custom | Custom | Custom | Custom | Advanced customization |

#### Review

Periodic reflection prompt for wellbeing and progress.

```dart
enum ReviewType {
  valuesAlignment,
  progress,
  wellbeingInsights,
  balance,
  pinnedTasksCheck,
}

class ReviewTypeConfig {
  final bool enabled;
  final int frequencyDays;
  final DateTime? lastCompletedAt;
}

class ReviewSettings {
  final Map<ReviewType, ReviewTypeConfig> types;
  
  bool isDue(ReviewType type);
}
```

#### Alert

System notification requiring user attention.

```dart
enum AlertSeverity { critical, warning, notice }

class Alert {
  final AlertSeverity severity;
  final String title;
  final String message;
  final List<Task> affectedTasks;
  final List<AlertAction> actions;
}
```

#### Journal

Reflection entry linked to values and wellbeing.

```dart
class Journal {
  final String id;
  final DateTime date;
  final String content;
  final int mood;                    // 1-5 scale
  final List<Value> values;
  final List<TrackerResponse> trackerResponses;
}
```

#### Tracker

Custom tracking item for habits and metrics.

```dart
enum TrackerType { choice, scale, yesNo }
enum TrackerScope { daily, perEntry }

class Tracker {
  final String id;
  final String name;
  final TrackerType type;
  final TrackerScope scope;
  final List<String>? options;       // For choice type
  final int? minValue;               // For scale type
  final int? maxValue;               // For scale type
}
```

---

## Scoring & Allocation System

### Overview

The Unified Scoring Service is the heart of task prioritization, calculating scores based on four factors weighted by the active Focus Mode.

```
┌─────────────────────────────────────────────────────────────┐
│                  AllocationOrchestrator                      │
│  • Coordinates allocation flow                              │
│  • Handles pinned tasks                                     │
│  • Produces AllocationResult with reasoning                 │
├─────────────────────────────────────────────────────────────┤
│                  TaskScoringService                          │
│  • Unified scoring: Score = Σ(Weight × Factor)              │
│  • Focus Mode determines weights                            │
│  • Recovery Mode applies balance boost                      │
├─────────────────────────────────────────────────────────────┤
│                  Factor Calculators                          │
│  • ImportanceCalculator: Value Priority × Task Priority     │
│  • UrgencyCalculator: Smooth decay curve                    │
│  • SynergyCalculator: Secondary value overlap               │
│  • BalanceCalculator: Neglect score from accumulator        │
└─────────────────────────────────────────────────────────────┘
```

### Scoring Formula

```
Score = (W_I × Importance) + (W_U × Urgency) + (W_S × Synergy) + (W_B × Balance)
```

### Factor Calculations

#### Importance (💎)

Contextual priority combining Value Priority and Task Priority:

```dart
double _calculateImportance(Task task, ScoringContext context) {
  final valuePriority = task.primaryValue?.priority ?? ValuePriority.medium;
  final taskPriority = task.priority;
  
  // Value Priority: high=1.0, medium=0.6, low=0.3
  // Task Priority: P1=1.0, P2=0.7, P3=0.4, P4=0.1
  return valuePriority.weight * taskPriority.weight;
}
```

#### Urgency (🔥)

Smooth decay curve based on deadline proximity:

```dart
double _calculateUrgency(Task task, ScoringContext context) {
  if (task.deadlineDate == null) return 0;
  
  final daysUntilDeadline = task.deadlineDate!.difference(context.now).inDays;
  
  if (daysUntilDeadline < 0) return 1.0;  // Overdue
  
  // Smooth decay: Day 0 = 1.0, Day 7 = 0.5, Day 14 = 0.33
  return 1.0 / (1.0 + daysUntilDeadline / 7.0);
}
```

#### Synergy (⚡)

Bonus for tasks whose secondary values overlap with other allocated tasks:

```dart
double _calculateSynergy(Task task, ScoringContext context) {
  if (task.secondaryValues.isEmpty) return 0;
  
  final activeValueIds = context.allocatedTasks
      .expand((t) => [t.primaryValueId, ...t.secondaryValueIds])
      .whereNotNull()
      .toSet();
  
  final overlap = task.secondaryValueIds
      .where((id) => activeValueIds.contains(id))
      .length;
  
  return (overlap / task.secondaryValues.length).clamp(0.0, 1.0);
}
```

#### Balance (⚖️)

Neglect score from AccumulatorService:

```dart
double _calculateBalance(Task task, ScoringContext context) {
  final valueId = task.primaryValueId;
  if (valueId == null) return 0;
  
  // Accumulator tracks days since value was worked
  final neglectScore = context.accumulatorService.getNeglectScore(valueId);
  
  // Normalize to 0-1 range (30 days = max neglect)
  return (neglectScore / 30.0).clamp(0.0, 1.0);
}
```

### Recovery Mode

A toggle available on any Focus Mode that boosts tasks from neglected values:

```dart
ScoringWeights _getWeights(FocusMode mode, bool recoveryEnabled) {
  var weights = _baseWeights[mode]!;
  
  if (recoveryEnabled) {
    // Boost balance factor by +5.0
    weights = weights.copyWith(
      balance: weights.balance + 5.0,
    );
  }
  
  return weights;
}
```

Visual indicator shows when Recovery Mode is active.

### Allocation Result

```dart
class AllocationResult {
  final List<AllocatedItem> allocatedTasks;
  final List<AllocatedItem> allocatedProjects;
  final List<AllocatedItem> pinnedTasks;
  final Map<String, AllocationValueGroup> itemsByValue;
  final AllocationReasoning? reasoning;
}

class AllocatedItem {
  final dynamic item;          // Task or Project
  final ItemType type;         // task or project
  final ReasonBadge badge;     // Vital, Crisis, Smart, CatchUp
  final double score;
}

enum ItemType { task, project }

enum ReasonBadge {
  vital,     // High importance + value priority
  crisis,    // High urgency (deadline-driven)
  smart,     // High synergy (efficient)
  catchUp,   // High balance (neglected value)
}
```

*Note: Tasks and projects are scored separately using the same weighting formula. Both can appear on My Day based on their individual scores, not because they're linked to each other.*

---

## Review System

### Overview

Reviews are periodic reflection prompts that help users maintain alignment with their values and catch problems early.

```
┌─────────────────────────────────────────────────────────────┐
│                  ReviewSettings                              │
│  • Per-type enable/disable                                  │
│  • Frequency configuration                                  │
│  • Last completed tracking                                  │
├─────────────────────────────────────────────────────────────┤
│                  ReviewService                               │
│  • Checks which reviews are due                             │
│  • Generates review steps                                   │
│  • Records completion                                       │
├─────────────────────────────────────────────────────────────┤
│                  ReviewBanner                                │
│  • Displayed on My Day when review due                      │
│  • Same prominence as warning alerts                        │
│  • Tapping navigates to review run screen                   │
└─────────────────────────────────────────────────────────────┘
```

### Review Types

| Review | Purpose | Default Frequency |
|--------|---------|-------------------|
| **Values Alignment** | Reflect on whether tasks align with values | 14 days |
| **Progress** | Review completed tasks and achievements | 7 days |
| **Wellbeing Insights** | Check-in on energy and mood patterns | 7 days |
| **Balance** | Assess value distribution and neglect | 14 days |
| **Pinned Tasks Check** | Review and update pinned tasks | 7 days |

### Data Model

```dart
class ReviewSettings {
  final Map<ReviewType, ReviewTypeConfig> types;
  
  const ReviewSettings({required this.types});
  
  factory ReviewSettings.defaults() => ReviewSettings(
    types: {
      ReviewType.valuesAlignment: ReviewTypeConfig(frequencyDays: 14),
      ReviewType.progress: ReviewTypeConfig(frequencyDays: 7),
      ReviewType.wellbeingInsights: ReviewTypeConfig(frequencyDays: 7),
      ReviewType.balance: ReviewTypeConfig(frequencyDays: 14),
      ReviewType.pinnedTasksCheck: ReviewTypeConfig(frequencyDays: 7),
    },
  );
  
  bool isDue(ReviewType type) {
    final config = types[type];
    if (config == null || !config.enabled) return false;
    if (config.lastCompletedAt == null) return true;
    
    final daysSince = DateTime.now().difference(config.lastCompletedAt!).inDays;
    return daysSince >= config.frequencyDays;
  }
}
```

### Storage

Review settings stored as JSON in `UserProfileTable.review_settings`.

---

## Alert System

### Overview

The Alert System acts as a safety net, catching critical tasks that the current Focus Mode might otherwise filter out.

```
┌─────────────────────────────────────────────────────────────┐
│                  ProblemDetectorService                      │
│  • Runs in parallel with allocation                         │
│  • Identifies exceptions to Focus Mode logic                │
│  • Produces Alert objects with affected tasks               │
├─────────────────────────────────────────────────────────────┤
│                  AlertBanner                                 │
│  • Displayed at top of My Day                               │
│  • Color reflects severity                                  │
│  • Collapsed: title + task count                            │
│  • Expanded: full message + task list + actions             │
└─────────────────────────────────────────────────────────────┘
```

### Alert Severity

| Severity | Color | When Triggered |
|----------|-------|----------------|
| **Critical** | Error color | P1 tasks overdue, deadlines within 24 hours |
| **Warning** | Warning color | Tasks overdue >3 days, approaching deadlines |
| **Notice** | Info color | Stale tasks (>30 days untouched), value neglect |

### Alert Rules

```dart
class AlertRule {
  final String id;
  final AlertSeverity severity;
  final String title;
  final String messageTemplate;
  final TaskPredicate predicate;
  final bool enabled;
}
```

### Stale Threshold

Configurable via `SoftGatesSettings.staleAfterDaysWithoutUpdates` (default: 30 days).

All stale calculations reference this single setting for consistency.

---

## Data-Driven Screen System

### Overview

Screens are defined declaratively and rendered by a unified rendering pipeline.

```
┌──────────────────────────────────────────────────────────────────┐
│                    SCREEN DEFINITION                              │
│  (ScreenDefinition → DataDrivenScreenDefinition)                 │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │ Sections: [DataSection, AllocationSection, AgendaSection] │    │
│  │ SupportBlocks: [AlertBanner, ReviewBanner, Stats...]     │    │
│  │ FAB Operations, AppBar Actions, Trigger Config           │    │
│  └──────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│                   DATA INTERPRETATION                             │
│              (ScreenDataInterpreter + SectionDataService)         │
│                                                                   │
│  • Fetches data for each section via repositories                │
│  • Computes enrichments (value stats, etc.)                      │
│  • Evaluates support blocks (alerts, reviews)                    │
│  • Produces ScreenData with SectionDataResults                   │
└──────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│                     UI RENDERING                                  │
│          (UnifiedScreenPage → SectionWidget → Renderers)          │
│                                                                   │
│  • ScreenBloc manages state                                      │
│  • SectionWidget dispatches to appropriate renderer              │
│  • TaskListRenderer, AllocationSectionRenderer, etc.             │
└──────────────────────────────────────────────────────────────────┘
```

### Screen Definition Types

```dart
sealed class ScreenDefinition {
  // Data-driven screen with sections - rendered by UnifiedScreenPage
  factory ScreenDefinition.dataDriven({...}) = DataDrivenScreenDefinition;
  
  // Navigation-only screen - has custom widget
  factory ScreenDefinition.navigationOnly({...}) = NavigationOnlyScreenDefinition;
}
```

### Section Types

| Section Type | Purpose | Key Configuration |
|--------------|---------|-------------------|
| **DataSection** | Generic entity list | `DataConfig`, `RelatedDataConfig`, `DisplayConfig`, `EnrichmentConfig` |
| **AllocationSection** | My Day / Focus view | `sourceFilter`, `maxTasks`, `displayMode`, `showExcludedSection` |
| **AgendaSection** | Date-grouped timeline | `nearTermDays`, `emptyDayHandling`, `dateTagDisplay`, `semanticGrouping` |

#### AgendaSection Configuration

```dart
class AgendaSectionConfig {
  final int nearTermDays;           // Days to show empty placeholders (default: 7)
  final EmptyDayHandling emptyDayHandling; // hybrid (default), showAll, skipAll
  final bool showOverdueSection;    // Show overdue items at top (default: true)
  final bool bidirectionalSync;     // Picker syncs with scroll (default: true)
  final DateTagDisplay dateTagDisplay; // How to show Starts/InProgress/Due tags
}

enum EmptyDayHandling {
  hybrid,   // Show empty near-term, skip distant (Option D)
  showAll,  // Always show empty days with placeholder
  skipAll,  // Never show empty days
}

enum DateTagDisplay {
  badge,      // Colored tag badge
  icon,       // Icon indicator
  background, // Subtle background color
}
```

### Support Blocks (Updated)

| Block Type | Purpose | Location |
|------------|---------|----------|
| `alertBanner` | Critical/Warning/Notice alerts | Top of My Day |
| `reviewBanner` | Due review prompts | Below alerts on My Day |
| `focusModeHero` | Focus Mode indicator with stats | My Day header |
| `quickActions` | Action buttons | Various screens |
| `contextSummary` | Project/entity info | Detail pages |
| `stats` | Statistics display | Value/Project cards |
| `problemSummary` | Problem detection summary | Support section |
| `emptyState` | Custom empty state | When no items |
| `entityHeader` | Detail page header | Detail pages |

### System Screens

| Screen | Type | Sections |
|--------|------|----------|
| **My Day** | DataDriven | AllocationSection + AlertBanner + ReviewBanner + FocusModeHero |
| **Scheduled** | DataDriven | AgendaSection |
| **Someday** | DataDriven | DataSection (tasks and projects without dates) |
| **Projects** | DataDriven | DataSection (project list) |
| **Values** | DataDriven | DataSection (value list with stats) |
| **Journal** | NavigationOnly | Custom widget |
| **Insights** | NavigationOnly | Custom widget (scrolling sections) |
| **Settings** | NavigationOnly | Custom widget |

---

## Navigation & Routing

### Adaptive Navigation

Navigation adapts based on screen size:

**Mobile (Bottom Navigation - 5 items):**
1. My Day
2. Scheduled
3. Someday
4. Journal
5. Browse → Navigation Drawer (Values, Projects, Insights, Settings)

**Desktop/Web (Navigation Rail - 8 items):**
All items visible: My Day, Scheduled, Someday, Journal, Values, Projects, Insights, Settings

### Routing Patterns

Two route patterns only:

1. **Screens**: `/:screenKey` → `Routing.buildScreen(screenKey)`
2. **Entities**: `/:entityType/:id` → `Routing.buildEntityDetail(type, id)`

```dart
// Convention: screenKey uses underscores, URL uses hyphens
'my_day' → '/my-day'
'focus_mode_settings' → '/focus-mode-settings'
```

### Entity Navigation

```dart
extension TaskNavigation on Task {
  void navigateTo(BuildContext context);
  VoidCallback onTap(BuildContext context);
}
// Similar for Project, Value, Journal
```

---

## Data Layer

### Database Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      PowerSync                               │
│  • Offline-first sync with Supabase                         │
│  • Handles conflict resolution                              │
│  • Schema defined in powersync_schema.dart                  │
├─────────────────────────────────────────────────────────────┤
│                        Drift                                 │
│  • Local SQLite database                                    │
│  • Type-safe queries                                        │
│  • Schema defined in database.dart                          │
├─────────────────────────────────────────────────────────────┤
│                      Supabase                                │
│  • Authentication                                           │
│  • Remote database (source of truth)                        │
│  • Real-time subscriptions                                  │
└─────────────────────────────────────────────────────────────┘
```

### Junction Tables

#### task_values

```sql
CREATE TABLE task_values (
  id UUID PRIMARY KEY,
  task_id UUID REFERENCES tasks(id),
  value_id UUID REFERENCES values(id),
  is_primary BOOLEAN DEFAULT false,  -- NEW: Primary value flag
  created_at TIMESTAMP
);

-- Constraint: Only one primary value per task
CREATE UNIQUE INDEX task_values_primary_unique 
  ON task_values(task_id) 
  WHERE is_primary = true;
```

#### project_values

```sql
CREATE TABLE project_values (
  id UUID PRIMARY KEY,
  project_id UUID REFERENCES projects(id),
  value_id UUID REFERENCES values(id),
  is_primary BOOLEAN DEFAULT false,
  created_at TIMESTAMP
);

-- Constraint: Only one primary value per project (same as task_values)
CREATE UNIQUE INDEX project_values_primary_unique 
  ON project_values(project_id) 
  WHERE is_primary = true;
```

### Settings Storage

User settings stored as JSON in `user_profiles` table:

| Column | Purpose |
|--------|---------|
| `allocation_settings` | FocusMode, recovery toggle, weights, daily limit |
| `review_settings` | ReviewTypeConfig per ReviewType |
| `alert_settings` | Alert rule enable/disable, severity overrides |
| `display_settings` | Theme, date format, locale |

### Repository Pattern

Domain defines contracts, Data implements:

```dart
// Contract
abstract class TaskRepositoryContract {
  Stream<List<Task>> watchAll([TaskQuery? query]);
  Future<Task?> getById(String id);
  Future<void> create({...});
  Future<void> setPrimaryValue(String taskId, String valueId);
}

// Implementation
class TaskRepository implements TaskRepositoryContract {
  // Uses Drift + PowerSync
}
```

---

## Dependency Injection

Using GetIt for service location:

```dart
final GetIt getIt = GetIt.instance;

// Registration Order in setupDependencies():
// 1. Database (PowerSync, Drift)
// 2. Core services (IdGenerator, Supabase)
// 3. Repositories (Task, Project, Value, Settings)
// 4. Scoring services (TaskScoringService, AccumulatorService)
// 5. Domain services (AllocationOrchestrator, ReviewService, AlertService)
// 6. Screen services (ScreenDataInterpreter, SectionDataService)
```

---

## Implementation Status

### Backend/Domain Layer — ✅ Complete

| Component | Status | Location |
|-----------|--------|----------|
| FocusMode enum (was AllocationPersona) | ✅ Done | `domain/models/allocation/focus_mode.dart` |
| Primary/Secondary values (junction table) | ✅ Done | `task_values`, `project_values` tables |
| Unified Scoring Service | ✅ Done | `domain/services/scoring/` |
| Smooth urgency curve | ✅ Done | Scoring service |
| ReviewSettings model | ✅ Done | `domain/models/settings/review_settings.dart` |
| AllocationAlertRule model | ✅ Done | `domain/models/settings/allocation_alert_rule.dart` |
| ProblemDetectorService | ✅ Done | `domain/services/workflow/problem_detector_service.dart` |
| AgendaSectionDataService | ✅ Done | `domain/services/screens/agenda_section_data_service.dart` |
| Value inheritance removed | ✅ Done | Tasks store values directly |

### Presentation Layer — Partial

| Component | Status | Notes |
|-----------|--------|-------|
| Settings Hub | ✅ Done | Theme, language, navigation order |
| Allocation Settings | ✅ Done | Focus mode, value rankings |
| Navigation Settings | ✅ Done | Reorder nav items |
| **Review Settings UI** | ❌ Missing | Configure review types + frequency |
| **Alert Rules Settings UI** | ❌ Missing | Configure which alerts are enabled |
| **Review Run Screen** | ❌ Missing | Execute reviews when due |
| **Review Banner** | ❌ Missing | Shows on My Day when reviews due |

### Key Architecture Decisions Implemented

| Decision | Description |
|----------|-------------|
| **No value inheritance** | Tasks store their own values; project values pre-populate form only |
| **FocusMode naming** | Intentional, Sustainable, Responsive, Personalized |
| **Recovery Mode** | Toggle on any Focus Mode to boost neglected values |
| **Alert = Exception = Safety Net** | Same concept - rules triggering banners on My Day |
| **Reviews** | 4 types: Progress, Wellbeing, Balance, Pinned Tasks (Values Alignment merged into Balance) |

---

## Summary

Taskly's architecture maintains clean architecture principles with a data-driven screen system:

1. **Values-First Scoring**: Unified scoring service with Focus Mode weights
2. **Recovery Mode**: Toggle for catching up on neglected values
3. **Primary/Secondary Values**: Clear distinction for scoring and display
4. **Review System**: Configurable periodic reflection prompts (UI pending)
5. **Alert Safety Net**: Smart problem detection independent of Focus Mode

The architecture remains extensible and testable, with clear separation of concerns and type-safe data flow from screen definitions through to UI rendering.
