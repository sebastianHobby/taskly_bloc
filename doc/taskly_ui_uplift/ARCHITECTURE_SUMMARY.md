# Taskly Architecture Summary

This document provides a comprehensive overview of the Taskly codebase architecture for developers who need to maintain, extend, or understand the system.

---

## Table of Contents

1. [High-Level Architecture](#high-level-architecture)
2. [Data-Driven Screen System](#data-driven-screen-system)
3. [Navigation & Routing](#navigation--routing)
4. [Other Architectural Patterns](#other-architectural-patterns)
5. [Detailed Component Breakdown](#detailed-component-breakdown)

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

### Layer Responsibilities

| Layer | Location | Responsibility |
|-------|----------|----------------|
| **Presentation** | `lib/presentation/` | UI widgets, BLoCs, navigation, renderers |
| **Domain** | `lib/domain/` | Business logic, models, service interfaces, queries |
| **Data** | `lib/data/` | Persistence, API integration, repository implementations |
| **Core** | `lib/core/` | Cross-cutting concerns: DI, routing, theming, utilities |

### Key Design Principles

1. **Dependency Inversion**: Domain defines interfaces (contracts), Data implements them
2. **Repository Pattern**: All data access through repository contracts
3. **BLoC Pattern**: State management via flutter_bloc
4. **Data-Driven UI**: Screen definitions drive rendering (see next section)
5. **Unified Queries**: Type-safe query objects with database-level filtering

---

## Data-Driven Screen System

The heart of Taskly's architecture is a **data-driven screen system** where screens are defined declaratively and rendered by a unified rendering pipeline.

### System Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                    SCREEN DEFINITION                              │
│  (ScreenDefinition → DataDrivenScreenDefinition)                 │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │ Sections: [DataSection, AllocationSection, AgendaSection] │    │
│  │ SupportBlocks: [ProblemSummary, QuickActions, Stats...]  │    │
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
│  • Evaluates support blocks                                      │
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

Located in `lib/domain/models/screens/screen_definition.dart`:

```dart
sealed class ScreenDefinition {
  // Data-driven screen with sections - rendered by UnifiedScreenPage
  factory ScreenDefinition.dataDriven({...}) = DataDrivenScreenDefinition;
  
  // Navigation-only screen - has custom widget, not rendered by unified system
  factory ScreenDefinition.navigationOnly({...}) = NavigationOnlyScreenDefinition;
}
```

**DataDrivenScreenDefinition** - Used for: Inbox, My Day, Planned, Projects, Labels, Values
- Contains `sections` (what data to show)
- Contains `supportBlocks` (auxiliary UI elements)
- Rendered by `UnifiedScreenPage`

**NavigationOnlyScreenDefinition** - Used for: Settings, Journal, Wellbeing Dashboard
- Only provides navigation metadata (icon, name, category)
- Has custom widget implementation registered in `Routing`

### Screen Types (ScreenType enum)

```dart
enum ScreenType {
  list,      // Entity list with DataSection/AgendaSection
  focus,     // Allocation-focused (uses AllocationSection) 
  workflow,  // Multi-step workflow execution
}
```

### Section Types

Located in `lib/domain/models/screens/section.dart`:

| Section Type | Purpose | Key Configuration |
|--------------|---------|-------------------|
| **DataSection** | Generic entity list | `DataConfig`, `RelatedDataConfig`, `DisplayConfig`, `EnrichmentConfig` |
| **AllocationSection** | Focus/My Day view | `sourceFilter`, `maxTasks`, `displayMode`, `showExcludedSection` |
| **AgendaSection** | Date-grouped tasks | `dateField`, `grouping`, `additionalFilter` |

#### DataSection Configuration

```dart
Section.data(
  config: DataConfig.task(query: TaskQuery.inbox()),  // What to fetch
  relatedData: [RelatedDataConfig.projects()],        // Related entities
  display: DisplayConfig(groupBy: GroupByField.project), // How to display
  enrichment: EnrichmentConfig.valueStats(),          // Computed stats
  title: 'Tasks',
)
```

#### DataConfig Variants

Located in `lib/domain/models/screens/data_config.dart`:

```dart
sealed class DataConfig {
  factory DataConfig.task({required TaskQuery query});
  factory DataConfig.project({required ProjectQuery query});
  factory DataConfig.label({LabelQuery? query});
  factory DataConfig.value({LabelQuery? query});
  factory DataConfig.journal({JournalQuery? query});
}
```

### Query System

Queries are pure data objects that define filtering without coupling to repositories (DR-007).

Located in `lib/domain/queries/`:

**TaskQuery** - Main query for tasks
```dart
TaskQuery(
  filter: QueryFilter<TaskPredicate>(
    shared: [TaskBoolPredicate(field: completed, operator: isFalse)],
    orGroups: [[...], [...]]  // Optional OR groups
  ),
  sortCriteria: [SortCriterion(field: deadlineDate, direction: asc)],
  occurrenceExpansion: OccurrenceExpansion(...),  // For repeating tasks
)
```

**QueryFilter** - Normalized filter supporting AND + OR:
- `shared`: Predicates that always apply (AND)
- `orGroups`: Groups where each group is AND, groups are OR'd together

**Predicate Types**:
- `TaskBoolPredicate` - completed, etc.
- `TaskDatePredicate` - deadlineDate, startDate with operators
- `TaskProjectPredicate` - project filtering
- `TaskLabelPredicate` - label/value filtering with inheritance support

**Convenience Factories**:
```dart
TaskQuery.inbox()           // Tasks without project
TaskQuery.today(now: ...)   // Due today or earlier
TaskQuery.forProject(projectId: ...)
TaskQuery.forValue(valueId: ..., includeInherited: true)
```

### Related Data Configuration

Located in `lib/domain/models/screens/related_data_config.dart`:

```dart
sealed class RelatedDataConfig {
  factory RelatedDataConfig.tasks({TaskQuery? additionalFilter});
  factory RelatedDataConfig.projects({ProjectQuery? additionalFilter});
  factory RelatedDataConfig.valueHierarchy({...});  // Value → Project → Task
}
```

### Display Configuration

Located in `lib/domain/models/screens/display_config.dart`:

```dart
DisplayConfig(
  groupBy: GroupByField.project,    // none, project, value, label, date, priority
  sorting: [SortCriterion(...)],
  problemsToDetect: [ProblemType.overdue],
  showCompleted: true,
  groupByCompletion: true,
  completedCollapsed: true,
  enableSwipeToDelete: false,
)
```

### Enrichment Configuration

Located in `lib/domain/models/screens/enrichment_config.dart`:

For computing additional statistics alongside section data:

```dart
EnrichmentConfig.valueStats(
  sparklineWeeks: 4,      // Trend data duration
  gapWarningThreshold: 15, // % gap that triggers warning
)
```

### Support Blocks

Located in `lib/domain/models/screens/support_block.dart`:

Auxiliary UI elements rendered in support sections:

| Block Type | Purpose | System-Only |
|------------|---------|-------------|
| `workflowProgress` | Workflow step progress | Yes (DR-019) |
| `quickActions` | Action buttons | No |
| `contextSummary` | Project/entity info | No |
| `relatedEntities` | Related entity links | No |
| `stats` | Statistics display | No |
| `problemSummary` | Problem detection (DR-018) | No |
| `emptyState` | Custom empty state | No |
| `entityHeader` | Detail page header | No |

### System Screen Definitions

Located in `lib/domain/models/screens/system_screen_definitions.dart`:

Built-in screens defined in code (not database):

```dart
SystemScreenDefinitions.inbox       // Tasks without project
SystemScreenDefinitions.myDay       // Focus/allocation view
SystemScreenDefinitions.planned     // Future tasks agenda
SystemScreenDefinitions.logbook     // Completed tasks
SystemScreenDefinitions.projects    // Project list
SystemScreenDefinitions.labels      // Label list
SystemScreenDefinitions.values      // Value list with stats
SystemScreenDefinitions.settings    // NavigationOnly
SystemScreenDefinitions.journal     // NavigationOnly
```

### Section Data Flow

```
Section → SectionDataService → SectionDataResult
```

**SectionDataService** (`lib/domain/services/screens/section_data_service.dart`):
- Handles all section types
- Uses repositories for data fetching
- Calls `AllocationOrchestrator` for allocation sections
- Computes enrichments

**SectionDataResult** (`lib/domain/services/screens/section_data_result.dart`):

```dart
sealed class SectionDataResult {
  // Generic entity list
  factory SectionDataResult.data({
    required List<dynamic> primaryEntities,
    required String primaryEntityType,
    Map<String, List<dynamic>> relatedEntities,
    EnrichmentResult? enrichment,
  });
  
  // Allocation result with grouping
  factory SectionDataResult.allocation({
    required List<Task> allocatedTasks,
    List<AllocatedTask> pinnedTasks,
    Map<String, AllocationValueGroup> tasksByValue,
    AllocationReasoning? reasoning,
    ...
  });
  
  // Date-grouped tasks
  factory SectionDataResult.agenda({
    required Map<String, List<Task>> groupedTasks,
    required List<String> groupOrder,
  });
}
```

### Rendering Pipeline

```
UnifiedScreenPage
  └── ScreenBloc (state management)
        └── ScreenDataInterpreter (data coordination)
              └── SectionDataService (per-section data)
                    └── Repositories (actual data)
```

**UnifiedScreenPage** (`lib/presentation/features/screens/view/unified_screen_page.dart`):
- Entry point for data-driven screens
- Creates `ScreenBloc` with definition
- Delegates to `_UnifiedScreenView` for rendering

**SectionWidget** (`lib/presentation/widgets/section_widget.dart`):
- Dispatches to appropriate renderer based on `SectionDataResult` type
- `AllocationSectionResult` → `AllocationSectionRenderer`
- `DataSectionResult` (task) → `TaskListRenderer`

**Renderers** (`lib/presentation/features/screens/renderers/`):
- `TaskListRenderer` - Simple task list
- `AllocationSectionRenderer` - Focus view with persona-based grouping

---

## Navigation & Routing

### Routing Architecture

Located in `lib/core/routing/`:

**Two Route Patterns Only**:
1. **Screens**: `/:screenKey` → `Routing.buildScreen(screenKey)`
2. **Entities**: `/:entityType/:id` → `Routing.buildEntityDetail(type, id)`

```dart
// Convention: screenKey uses underscores, URL uses hyphens
'orphan_tasks' → '/orphan-tasks'
```

### Routing Class

`lib/core/routing/routing.dart` - Single source of truth for navigation:

```dart
abstract final class Routing {
  // Path utilities
  static String screenPath(String screenKey);
  static String parseScreenKey(String segment);
  
  // Screen navigation (replaces current view)
  static void toScreen(BuildContext context, ScreenDefinition screen);
  static void toScreenKey(BuildContext context, String screenKey);
  
  // Entity navigation (pushes onto stack)
  static void toTask(BuildContext context, Task task);
  static void toProject(BuildContext context, Project project);
  static void toEntity(BuildContext context, EntityType type, String id);
  
  // Builder registration (called at bootstrap)
  static void registerScreenBuilders(Map<String, Widget Function()> builders);
  static void registerEntityBuilders({...});
  
  // Build widgets
  static Widget buildScreen(String screenKey);
  static Widget buildEntityDetail(String entityType, String id);
}
```

### Screen Resolution Order

`Routing.buildScreen(screenKey)`:
1. Check `_screenBuilders` for custom builder (screens with specific BLoCs)
2. Check `SystemScreenDefinitions.getByKey()` for system screens
3. Fall back to `UnifiedScreenPageById` for user-defined screens

### NavigationOnly Screen Registration

In `lib/bootstrap.dart`, custom screens are registered:

```dart
Routing.registerScreenBuilders({
  SystemScreenDefinitions.journal.screenKey: () => BlocProvider(
    create: (_) => JournalEntryBloc(wellbeingRepo),
    child: const JournalScreen(),
  ),
  SystemScreenDefinitions.settings.screenKey: () => const SettingsScreen(),
  // ... other custom screens
});
```

### Navigation State Management

**NavigationBloc** (`lib/presentation/features/navigation/bloc/navigation_bloc.dart`):
- Watches `ScreenDefinitionsRepository` for screen changes
- Maps screens to `NavigationDestinationVm` view models
- Provides badge streams for navigation items
- Handles sort order and icons

### Navigation Extensions

`lib/presentation/navigation/navigation_extensions.dart`:

```dart
extension TaskNavigation on Task {
  void navigateTo(BuildContext context);
  VoidCallback onTap(BuildContext context);
}
// Similar for Project, Label
```

---

## Other Architectural Patterns

### Allocation System - Also known as My Focus - Uses personas

The allocation system selects which tasks to show in "My Day" based on user values and preferences.

**AllocationOrchestrator** (`lib/domain/services/allocation/allocation_orchestrator.dart`):
- Coordinates allocation strategies
- Handles pinned tasks
- Produces `AllocationResult` with reasoning

**Allocation Personas** (`lib/domain/models/settings/allocation_config.dart`):

| Persona | Behavior |
|---------|----------|
| `idealist` | Pure value alignment, no urgency |
| `reflector` | Prioritizes neglected values |
| `realist` | Balanced with urgency warnings |
| `firefighter` | Urgency-first |
| `custom` | User-defined |

**Strategies** (`lib/domain/services/allocation/`):
- `ProportionalAllocator` - Weight-based allocation
- `UrgencyWeightedAllocator` - Combines urgency with values
- `NeglectBasedAllocator` - Boosts neglected values

### Workflow System

Multi-step review workflows for periodic task review.

**WorkflowDefinition** (`lib/domain/models/workflow/workflow_definition.dart`):
```dart
WorkflowDefinition(
  id: 'weekly_review',
  name: 'Weekly Review',
  steps: [WorkflowStep(...)],
  globalSupportBlocks: [SupportBlock.workflowProgress()],
  triggerConfig: TriggerConfig.schedule(rrule: 'FREQ=WEEKLY'),
)
```

**WorkflowService** (`lib/domain/services/workflow/workflow_service.dart`):
- Manages workflow lifecycle
- Tracks step progression
- Marks entities as reviewed

### Problem Detection

**ProblemDetectorService** (`lib/domain/services/workflow/problem_detector_service.dart`):
- Detects problems like overdue, urgent, stale tasks
- Integrates with `SupportBlock.problemSummary()`
- Provides inline indicators + summary banners

### Dependency Injection

Using GetIt (`lib/core/dependency_injection/dependency_injection.dart`):

```dart
final GetIt getIt = GetIt.instance;

// Registration pattern:
getIt.registerLazySingleton<TaskRepositoryContract>(
  () => TaskRepository(...),
);

// Usage:
final taskRepo = getIt<TaskRepositoryContract>();
```

**Registration Order** (in `setupDependencies()`):
1. Database (PowerSync, Drift)
2. Core services (IdGenerator, Supabase)
3. Repositories (Task, Project, Label, Settings)
4. Domain services (AllocationOrchestrator, SectionDataService)
5. Screen services (ScreenDataInterpreter)

### BLoC Pattern

Each feature has a BLoC for state management:

```
lib/presentation/features/<feature>/
  ├── bloc/
  │   ├── feature_bloc.dart
  │   ├── feature_event.dart
  │   └── feature_state.dart
  ├── view/
  │   └── feature_page.dart
  └── widgets/
      └── feature_specific_widget.dart
```

**ScreenBloc** (`lib/presentation/features/screens/bloc/screen_bloc.dart`):
- Thin state holder
- Delegates to `ScreenDataInterpreter`
- Handles load, refresh, reset events

### Repository Pattern

Domain defines contracts, Data implements:

```dart
// lib/domain/interfaces/task_repository_contract.dart
abstract class TaskRepositoryContract {
  Stream<List<Task>> watchAll([TaskQuery? query]);
  Future<Task?> getById(String id);
  Future<void> create({...});
  // ...
}

// lib/data/repositories/task_repository.dart
class TaskRepository implements TaskRepositoryContract {
  // Implementation using Drift/PowerSync
}
```

### Freezed Models

Domain models use `freezed` for immutability and union types:

```dart
@freezed
sealed class Section with _$Section {
  const factory Section.data({...}) = DataSection;
  const factory Section.allocation({...}) = AllocationSection;
  const factory Section.agenda({...}) = AgendaSection;
}
```

---

## Detailed Component Breakdown

### Key Files by Purpose

| Purpose | Key Files |
|---------|-----------|
| Screen Definition | `lib/domain/models/screens/screen_definition.dart` |
| System Screens | `lib/domain/models/screens/system_screen_definitions.dart` |
| Section Types | `lib/domain/models/screens/section.dart` |
| Data Config | `lib/domain/models/screens/data_config.dart` |
| Display Config | `lib/domain/models/screens/display_config.dart` |
| Query System | `lib/domain/queries/task_query.dart`, `query_filter.dart` |
| Screen Rendering | `lib/presentation/features/screens/view/unified_screen_page.dart` |
| Section Rendering | `lib/presentation/widgets/section_widget.dart` |
| Data Interpretation | `lib/domain/services/screens/screen_data_interpreter.dart` |
| Section Data | `lib/domain/services/screens/section_data_service.dart` |
| Routing | `lib/core/routing/routing.dart`, `router.dart` |
| Navigation | `lib/presentation/features/navigation/bloc/navigation_bloc.dart` |
| Allocation | `lib/domain/services/allocation/allocation_orchestrator.dart` |
| DI Setup | `lib/core/dependency_injection/dependency_injection.dart` |
| Bootstrap | `lib/bootstrap.dart` |



### Testing Strategy

```
test/
├── domain/           # Unit tests for domain logic
├── data/             # Repository/mapper tests
├── presentation/     # Widget/BLoC tests
├── integration/      # Cross-layer tests
├── fixtures/         # Test data factories
├── mocks/            # Mock implementations
└── helpers/          # Test utilities
```

---

## Summary

Taskly's architecture centers on:

1. **Data-Driven Screens**: Screen definitions → interpretation → unified rendering
2. **Clean Layer Separation**: Presentation → Domain → Data → Core
3. **Type-Safe Queries**: Composable predicates with database-level filtering
4. **Convention-Based Routing**: Two patterns (screens + entities) with builder registration
5. **Flexible Allocation**: Persona-based task prioritization
6. **Extensible Sections**: DataSection, AllocationSection, AgendaSection with enrichment

The unified screen model (DR-017) is the architectural cornerstone - understanding how `ScreenDefinition` flows through `ScreenDataInterpreter` to `UnifiedScreenPage` is key to working effectively with this codebase.
