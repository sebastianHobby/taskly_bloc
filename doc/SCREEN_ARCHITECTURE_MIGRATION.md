# Screen Architecture Migration Plan

> **Status:** 🔄 In Progress
> **Started:** 2026-01-01
> **Last Updated:** 2026-01-01

## Overview

Migrate from per-screen widget architecture to a unified view/workflow system where:
- **ViewDefinition** (sealed class) defines view types: `collection`, `agenda`, `detail`, `allocated`
- **ScreenDefinition** (flat class) wraps ViewDefinition with navigation metadata
- **WorkflowDefinition** orchestrates multi-step review flows using ViewDefinitions
- **ProblemDetection** provides opt-in soft gates per view with global threshold config

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        ViewDefinition                           │
│                     (sealed class - core)                       │
├─────────────┬─────────────┬─────────────┬─────────────────────┤
│ .collection │   .agenda   │   .detail   │     .allocated      │
│  (lists)    │(date-based) │(single item)│ (value-weighted)    │
└──────┬──────┴──────┬──────┴──────┬──────┴──────────┬──────────┘
       │             │             │                 │
       ▼             ▼             ▼                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                      ScreenDefinition                           │
│            (flat class - navigation metadata)                   │
│  id, screenKey, name, iconName, isSystem, isActive, sortOrder  │
│                    + view: ViewDefinition                       │
└─────────────────────────────────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────────────────────────┐
│                    WorkflowDefinition                           │
│              (orchestration - multi-step flows)                 │
│    steps: List<WorkflowStep>  (each step has ViewDefinition)   │
│    triggerConfig: TriggerConfig (RRULE for scheduling)         │
│    lastCompletedAt: DateTime                                    │
└─────────────────────────────────────────────────────────────────┘
```

## BLoC & Service Architecture

**Principle:** No BLoC-to-BLoC dependencies. BLoCs use Domain Services.

```
┌─────────────────────────────────────────────────────────────────┐
│                    Presentation Layer (BLoCs)                   │
├─────────────┬─────────────┬─────────────┬─────────────────────┤
│  ViewBloc   │ WorkflowBloc│  TaskBloc   │  ProjectBloc, etc.  │
│  (generic)  │             │             │                     │
└──────┬──────┴──────┬──────┴──────┬──────┴──────────┬──────────┘
       │             │             │                 │
       ▼             ▼             ▼                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Domain Layer (Services)                     │
├─────────────┬─────────────┬─────────────┬─────────────────────┤
│ ViewService │WorkflowSvc  │ProblemDet.  │AllocationOrch.      │
└──────┬──────┴──────┬──────┴──────┬──────┴──────────┬──────────┘
       │             │             │                 │
       ▼             ▼             ▼                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Data Layer (Repositories)                    │
│  TaskRepo, ProjectRepo, LabelRepo, WorkflowRepo, ScreenRepo    │
└─────────────────────────────────────────────────────────────────┘
```

### Key Components

**ViewBloc** (Generic)
- Uses: `ViewService`, `ProblemDetectorService`
- Handles: All view types via ViewDefinition
- No dependencies on other BLoCs

**WorkflowBloc**
- Uses: `WorkflowService`, `ViewService`
- Handles: Multi-step workflow orchestration
- No dependencies on other BLoCs

**Entity BLoCs** (Task/Project/Label)
- Uses: Repositories directly
- Handles: CRUD operations
- No dependencies on other BLoCs

**Domain Services**
- `ViewService`: Fetches/filters entities based on ViewDefinition
- `WorkflowService`: Orchestrates workflow steps and state
- `ProblemDetectorService`: Detects problems using view's opt-in list + global settings
- `AllocationOrchestrator`: Existing allocation logic (unchanged)

## Key Decisions

### Architecture
- ✅ `ViewDefinition` sealed class with 4 variants (collection, agenda, detail, allocated)
- ✅ `ScreenDefinition` flat class wrapping ViewDefinition (not sealed)
- ✅ `WorkflowDefinition` separate from screens - orchestration layer
- ✅ `WorkflowStep` uses ViewDefinition directly (inline, not by reference)
- ✅ Multi-step workflows supported (e.g., "Review Projects" → "Review Values")

### Data & State
- ✅ UUID5 deterministic IDs for system screens
- ✅ Database as single source of truth (no template merge layer)
- ✅ Breaking changes OK - no backwards compatibility, replace and delete legacy code
- ✅ Wipe and resync PowerSync after migration

### Priority System (NEW)
- ✅ `priority` field on Task and Project (P1=highest, P4=lowest, null=none)
- ✅ No default priority on creation

### Review Tracking
- ✅ `lastReviewedAt` on entities (Task, Project, Label/Value) - entity-level tracking
- ✅ `lastCompletedAt` on WorkflowDefinition - workflow-level tracking
- ✅ Both levels for maximum query flexibility

### Problem Detection (Soft Gates)
- ✅ Views opt-in to problem types via `DisplayConfig.problemsToDetect`
- ✅ Global `SoftGatesSettings` defines HOW problems are detected (thresholds)
- ✅ Empty list = no problems checked; specific list = only those checked
- ✅ Remove per-instance acknowledgment (no snooze/dismiss per problem)

### Allocation
- ✅ Global allocation settings (unchanged)
- ✅ `ViewDefinition.allocated` uses selector filter to subset tasks/values
- ✅ NextActionsPage migrates to ViewDefinition.allocated

### Cleanup
- ✅ Remove `CompletionCriteria` (not implemented)
- ✅ Remove `ResolutionAction` enum
- ✅ Remove `ProblemAcknowledgment` model
- ✅ Remove `workflow_sessions`, `workflow_item_reviews`, `problem_acknowledgments` tables
- ✅ Remove legacy workflow code (replace, don't refactor)

## Post-Migration Reminders

⚠️ **REMIND USER:**
- [ ] Delete all screen_definitions data from local database
- [ ] Wipe PowerSync local data and resync
- [ ] Delete any test data in Supabase

---

## 🤖 AI Agent Implementation Guidelines

**Critical reminders for AI agents continuing this migration:**

1. **Build Runner**: ❌ **DO NOT run build_runner manually** - it runs in background in watch mode. Freezed/JSON serializable code generates automatically.
   - ⚠️ **If generated code is not updating**, assume a **syntax error in non-generated code** first. Check the source file against working examples in the codebase before investigating other causes.

2. **Freezed Syntax**: Always verify freezed classes use correct syntax:
   - Use `sealed class` for sealed hierarchies (e.g., `ViewDefinition`)
   - Use `class` (NOT `abstract class`) for regular freezed classes
   - Pattern: `@freezed class MyClass with _$MyClass { const factory MyClass(...) = _MyClass; }`

3. **Code Quality**: Run `flutter analyze` regularly and keep code compiling. Fix warnings where practical.

4. **Testing Requirements**:
   - Update tests alongside code changes
   - Ensure all tests pass before marking phases complete
   - Maintain excellent test architecture and consistent patterns
   - Target robust test coverage for new code

5. **Final Deliverable**: At migration end, provide summary of:
   - All completed actions
   - Test coverage status
   - Any remaining warnings/issues

---

## Phase 1: UUID5 + Database as Source of Truth ✅ COMPLETE

**Goal:** Remove template-first architecture, use deterministic IDs, seed to database.

### Tasks

- [x] 1.1 Create `SystemScreenFactory` with UUID5 ID generation ✅
- [x] 1.2 Create `SystemScreenSeeder` service ✅
- [x] 1.3 Add SQLite unique constraint `(user_id, screen_key)` to Drift ✅
- [x] 1.4 Add `seedSystemScreens()` to repository contract and implementations ✅
- [x] 1.5 Update `UserDataSeeder` to include screen seeding ✅
- [x] 1.6 Wire seeding into auth flow (AuthBloc passes userId) ✅
- [x] 1.7 Update tests ✅
- [x] 1.8 Simplify `ScreenDefinitionsRepository` wrapper (remove template merge) ✅
- [x] 1.9 Delete `SystemScreenTemplates` ✅

### Files Created
- `lib/data/features/screens/system_screen_factory.dart` ✅
- `lib/data/services/system_screen_seeder.dart` ✅

### Files Deleted
- `lib/domain/models/screens/system_screen_templates.dart` ✅

---

## Phase 2: Supabase Schema Migration ✅ COMPLETE

**Goal:** Update Supabase schema for new architecture.

### Tasks

- [x] 2.1 Add `priority` column to `tasks` (INTEGER, nullable, CHECK 1-4) ✅
- [x] 2.2 Add `priority` column to `projects` (INTEGER, nullable, CHECK 1-4) ✅
- [x] 2.3 Add `last_reviewed_at` column to `labels` ✅
- [x] 2.4 Add `view_type` column to `screen_definitions` ✅
- [x] 2.5 Create `workflow_definitions` table ✅
- [x] 2.6 Create `workflows` table (runtime state with JSON step_states) ✅
- [x] 2.7 Enable RLS on new tables with user_id policies ✅
- [x] 2.8 Create indexes for new tables/columns ✅
- [x] 2.9 Drop `completion_criteria` column from `screen_definitions` ✅
- [x] 2.10 Drop `workflow_sessions` table ✅
- [x] 2.11 Drop `workflow_item_reviews` table ✅
- [x] 2.12 Drop `problem_acknowledgments` table ✅

### Schema Changes Summary

**Added Columns:**
| Table | Column | Type | Notes |
|-------|--------|------|-------|
| `tasks` | `priority` | INTEGER | P1-P4, nullable, CHECK constraint |
| `projects` | `priority` | INTEGER | P1-P4, nullable, CHECK constraint |
| `labels` | `last_reviewed_at` | TIMESTAMPTZ | For value review tracking |
| `screen_definitions` | `view_type` | TEXT | collection/agenda/detail/allocated |

**New Tables:**
| Table | Purpose |
|-------|---------|
| `workflow_definitions` | Workflow templates with steps (JSON), trigger config, lastCompletedAt |
| `workflows` | Runtime instances with step_states (JSON), status, progress |

**Dropped Tables:**
- `workflow_sessions` → replaced by `workflows`
- `workflow_item_reviews` → replaced by JSON arrays in `workflows.step_states`
- `problem_acknowledgments` → removed (no per-instance tracking)

- `screen_definitions.completion_criteria` → not implemented

---

## Phase 3: Domain Model Updates ✅ COMPLETE

**Goal:** Create new domain models and update existing ones.

### Tasks

- [x] 3.1 Create `ViewDefinition` sealed class ✅
- [x] 3.2 Refactor `ScreenDefinition` from sealed to flat class ✅
- [x] 3.3 Add `priority` field to `Task` model ✅
- [x] 3.4 Add `priority` field to `Project` model ✅
- [x] 3.5 Add `lastReviewedAt` field to `Label` model (for values) ✅
- [x] 3.6 Create `WorkflowDefinition` model ✅
- [x] 3.7 Create `WorkflowStep` model ✅
- [x] 3.8 Create `Workflow` model (runtime state) ✅
- [x] 3.9 Create `WorkflowStepState` model ✅
- [x] 3.10 Update `DisplayConfig` to ensure `problemsToDetect` is opt-in list ✅
- [x] 3.11 Remove `CompletionCriteria` model ✅ (never existed)
- [ ] 3.12 Remove `ResolutionAction` enum → DEFERRED to Phase 5 (still in use)
- [ ] 3.13 Remove `ProblemAcknowledgment` model → DEFERRED to Phase 5 (still in use)
- [x] 3.14 Update tests ✅

**Note:** ProblemType enum extracted to separate file (`problem_type.dart`) to decouple from ProblemAcknowledgment. ResolutionAction and ProblemAcknowledgment removal deferred to Phase 5 when old workflow system is replaced.

### Files Created
```
lib/domain/models/screens/view_definition.dart
lib/domain/models/workflow/workflow_definition.dart
lib/domain/models/workflow/workflow_step.dart
lib/domain/models/workflow/workflow.dart
lib/domain/models/workflow/workflow_step_state.dart
```

### Files to Modify
```
lib/domain/models/screens/screen_definition.dart
lib/domain/models/task.dart
lib/domain/models/project.dart
lib/domain/models/label.dart
lib/domain/models/screens/display_config.dart
```

### Files to Delete
```
lib/domain/models/screens/completion_criteria.dart
lib/domain/models/workflow/problem_acknowledgment.dart (ResolutionAction, ProblemAcknowledgment)
```

### ViewDefinition Design

```dart
@freezed
sealed class ViewDefinition with _$ViewDefinition {
  /// Simple list view (Inbox, Projects list, Labels list)
  const factory ViewDefinition.collection({
    required EntitySelector selector,
    required DisplayConfig display,
    List<SupportBlock>? supportBlocks,
  }) = CollectionView;

  /// Date-grouped view (Today, Upcoming)
  const factory ViewDefinition.agenda({
    required EntitySelector selector,
    required DisplayConfig display,
    required AgendaConfig agendaConfig,
    List<SupportBlock>? supportBlocks,
  }) = AgendaView;

  /// Single entity detail view (Project detail, Value detail)
  const factory ViewDefinition.detail({
    required DetailParentType parentType,
    ViewDefinition? childView,
    List<SupportBlock>? supportBlocks,
  }) = DetailView;

  /// Allocation-based view (Next Actions)
  const factory ViewDefinition.allocated({
    required EntitySelector selector,
    required DisplayConfig display,
    List<SupportBlock>? supportBlocks,
  }) = AllocatedView;
}
```

### ScreenDefinition Design (Flat)

```dart
@freezed
class ScreenDefinition with _$ScreenDefinition {
  const factory ScreenDefinition({
    required String id,
    required String userId,
    required String screenKey,
    required String name,
    required ViewDefinition view,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? iconName,
    @Default(false) bool isSystem,
    @Default(true) bool isActive,
    @Default(0) int sortOrder,
    @Default(ScreenCategory.workspace) ScreenCategory category,
  }) = _ScreenDefinition;
}
```

---

## Phase 4: Services Layer ✅ COMPLETE

**Goal:** Create domain services to eliminate BLoC-to-BLoC dependencies.

### Tasks

- [x] 4.1 Create `ViewService` (fetch/filter entities) ✅
- [x] 4.2 Create `WorkflowService` (orchestrate workflows) ✅
- [x] 4.3 Create `ProblemDetectorService` (detect problems) ✅
- [x] 4.4 Refactor existing services to match new pattern ✅
- [x] 4.5 Update tests ✅

### Files Created
```
lib/domain/services/screens/view_service.dart          ✅
lib/domain/services/workflow/workflow_service.dart     ✅
lib/domain/services/workflow/problem_detector_service.dart ✅
test/domain/services/screens/view_service_test.dart    ✅ (5 tests)
```

---

## Phase 5: Problem System Overhaul

**Goal:** Replace acknowledgment-based system with opt-in detection + bulk actions.

### Tasks

- [x] 5.1 Create `ProblemDefinition` model ✅
- [x] 5.2 Create `ProblemAction` sealed class (9 variants) ✅
- [x] 5.3 Create `ProblemActionEvaluator` service ✅
- [x] 5.4 Create `ProblemCard` widget ✅
- [x] 5.5 Create `ProblemActionButton` widget ✅
- [x] 5.6 Create `TaskPreviewList` widget ✅
- [x] 5.7 Update `ProblemDetectorService` to use view's problemsToDetect list ✅ (already implemented)
- [ ] 5.8 Deprecate/remove `ExcludedUrgentBanner` → DEFERRED to Phase 6 (coupled with old workflow)
- [ ] 5.9 Refactor `_SoftGatesPanel` to use `ProblemCard` → DEFERRED to Phase 6
- [ ] 5.10 Remove problem acknowledgment repository and interfaces → DEFERRED to Phase 6
- [x] 5.11 Update tests ✅ (42 new tests)

### Files Created
```
lib/domain/models/workflow/problem_action.dart           ✅
lib/domain/models/workflow/problem_definition.dart       ✅
lib/domain/services/workflow/problem_action_evaluator.dart ✅
lib/presentation/widgets/problem/problem_card.dart       ✅
lib/presentation/widgets/problem/problem_action_button.dart ✅
lib/presentation/widgets/problem/task_preview_list.dart  ✅
lib/presentation/widgets/problem/problem.dart            ✅ (barrel export)
test/domain/models/workflow/problem_action_test.dart     ✅ (13 tests)
test/domain/models/workflow/problem_definition_test.dart ✅ (12 tests)
test/domain/services/workflow/problem_action_evaluator_test.dart ✅ (17 tests)
```

### ProblemAction Design (9 actions)

```dart
@freezed
sealed class ProblemAction with _$ProblemAction {
  // Date actions (urgent/overdue tasks)
  const factory ProblemAction.rescheduleToday() = RescheduleToday;
  const factory ProblemAction.rescheduleTomorrow() = RescheduleTomorrow;
  const factory ProblemAction.rescheduleInDays(int days) = RescheduleInDays;
  const factory ProblemAction.pickDate() = PickDate;
  const factory ProblemAction.clearDeadline() = ClearDeadline;
  
  // Value actions (unassigned tasks)
  const factory ProblemAction.assignValue({
    required String valueId,
    required String valueName,
  }) = AssignValue;
  const factory ProblemAction.pickValue() = PickValue;
  
  // Priority actions (high-priority overdue)
  const factory ProblemAction.lowerPriority() = LowerPriority;
  const factory ProblemAction.removePriority() = RemovePriority;
}
```

### Problem Detection Flow

```dart
// Views opt-in via DisplayConfig
DisplayConfig(
  problemsToDetect: [ProblemType.excludedUrgentTask, ProblemType.staleTasks],
)
```

---

## Phase 6: Workflow System Overhaul

**Goal:** Replace old workflow system with new multi-step architecture.

### Tasks

- [x] 6.1 Create workflow definition repository contract ✅ (already existed: workflow_repository_contract.dart)
- [x] 6.2 Create workflow definition repository implementation ✅
- [x] 6.3 Create workflow (runtime) repository contract ✅ (combined in workflow_repository_contract.dart)
- [x] 6.4 Create workflow (runtime) repository implementation ✅
- [x] 6.5 Create `WorkflowRunBloc` (new version) ✅
- [x] 6.6 Create `WorkflowRunPage` (new version) ✅
- [ ] 6.7 Create `WorkflowProgressWidget` (dynamic from step_states)
- [ ] 6.8 Wire workflow completion to update entity.lastReviewedAt
- [x] 6.9 Wire workflow completion to update definition.lastCompletedAt ✅
- [ ] 6.10 Delete old workflow session/item review code
- [x] 6.11 Update Drift schema (local) ✅
- [ ] 6.12 Update PowerSync schema
- [ ] 6.13 Update tests

### Files Created
```
lib/data/drift/features/workflow_tables.drift.dart
lib/data/features/workflow/repositories/workflow_repository_impl.dart
lib/presentation/features/workflow/bloc/workflow_run_bloc.dart
lib/presentation/features/workflow/view/workflow_run_page.dart
```

### Workflow Progress Display

```dart
// Progress calculated from workflow state
class WorkflowState {
  final List<String> reviewedEntityIds;
  final List<String> skippedEntityIds;
  final List<String> pendingEntityIds;
  final int currentIndex;
  
  int get totalItems => reviewedEntityIds.length + skippedEntityIds.length + pendingEntityIds.length;
  int get completedItems => reviewedEntityIds.length + skippedEntityIds.length;
}

// Display: "4 of 7" with progress bar
// Display: "Item 5 of 7" for current position
```

### Files to Create
```
lib/domain/interfaces/workflow_definitions_repository_contract.dart
lib/domain/interfaces/workflows_repository_contract.dart
lib/data/features/workflow/repositories/workflow_definitions_repository_impl.dart
lib/data/features/workflow/repositories/workflows_repository_impl.dart
lib/presentation/features/workflow/bloc/workflow_run_bloc.dart (new)
lib/presentation/features/workflow/view/workflow_run_page.dart (new)
lib/presentation/features/workflow/widgets/workflow_progress_widget.dart
```

### Files to Delete
```
lib/domain/interfaces/workflow_sessions_repository_contract.dart
lib/domain/interfaces/workflow_item_reviews_repository_contract.dart
lib/data/features/screens/repositories/workflow_sessions_repository_impl.dart
lib/data/features/screens/repositories/workflow_item_reviews_repository_impl.dart
lib/domain/models/workflow/workflow_session.dart
lib/presentation/features/screens/bloc/workflow_run_bloc.dart (old)
lib/presentation/features/screens/bloc/workflow_run/ (old folder)
lib/presentation/features/screens/view/workflow_run_page.dart (old)
lib/presentation/features/screens/view/workflow_screen_page.dart (old)
```

---

## Phase 7: Data Layer Updates

**Goal:** Update Drift schema, PowerSync schema, and repository implementations.

### Tasks

- [ ] 7.1 Update Drift task table (add priority)
- [ ] 7.2 Update Drift project table (add priority)
- [ ] 7.3 Update Drift label table (add lastReviewedAt)
- [ ] 7.4 Update Drift screen_definitions table (add view_type, remove completion_criteria)
- [ ] 7.5 Create Drift workflow_definitions table
- [ ] 7.6 Create Drift workflows table
- [ ] 7.7 Remove Drift workflow_sessions table
- [ ] 7.8 Remove Drift workflow_item_reviews table
- [ ] 7.9 Remove Drift problem_acknowledgments table
- [ ] 7.10 Update PowerSync schema to match
- [ ] 7.11 Update TaskRepository for priority field
- [ ] 7.12 Update ProjectRepository for priority field
- [ ] 7.13 Update LabelRepository for lastReviewedAt field
- [ ] 7.14 Update ScreenDefinitionsRepository for new model
- [ ] 7.15 Run build_runner for generated code
- [ ] 7.16 Update tests

---

## Phase 8: BLoC Layer

**Goal:** Create ViewBloc, WorkflowBloc using services (no BLoC-to-BLoC deps).

### Tasks

- [ ] 8.1 Create `ViewBloc` (generic, uses ViewService + ProblemDetectorService)
- [ ] 8.2 Create `WorkflowBloc` (uses WorkflowService + ViewService)
- [ ] 8.3 Update existing entity BLoCs if needed
- [ ] 8.4 Update tests

---

## Phase 9: Migrate System Screens to ViewDefinition

**Goal:** Update SystemScreenFactory and screen rendering to use ViewDefinition.

### Tasks

- [ ] 9.1 Update `SystemScreenFactory` to create ScreenDefinitions with ViewDefinition
- [ ] 9.2 Refactor `ScreenHostPage` to use ViewBloc and route by ViewDefinition type
- [ ] 9.3 Migrate Inbox → ViewDefinition.collection
- [ ] 9.4 Migrate Today → ViewDefinition.agenda
- [ ] 9.5 Migrate Upcoming → ViewDefinition.agenda
- [ ] 9.6 Migrate Projects list → ViewDefinition.collection
- [ ] 9.7 Migrate Labels list → ViewDefinition.collection
- [ ] 9.8 Migrate Values list → ViewDefinition.collection
- [ ] 9.9 Migrate Next Actions → ViewDefinition.allocated
- [ ] 9.10 Migrate Project detail → ViewDefinition.detail
- [ ] 9.11 Migrate Label/Value detail → ViewDefinition.detail
- [ ] 9.12 Delete old view implementations
- [ ] 9.13 Update tests

---

## Phase 10: Screen Creator UI

**Goal:** Allow users to create custom filtered screens.

### Tasks

- [ ] 10.1 Design screen creator flow
- [ ] 10.2 Create `ScreenCreatorDialog` widget
- [ ] 10.3 Create filter builder UI (preset filters to start)
- [ ] 10.4 Create icon picker
- [ ] 10.5 Create view type selector (collection/agenda/allocated)
- [ ] 10.6 Create problem types selector
- [ ] 11.1 Remove empty feature folders
- [ ] 11.2 Update barrel exports
- [ ] 11.3 Remove unused imports throughout codebase
- [ ] 11.4 Run `dart fix --apply`
- [ ] 11.5 Run `flutter pub outdated` and update dependencies
- [ ] 11.6 Update README if needed
- [ ] 11.7 Final test run - all 1060+ tests passing
- [ ] 11e 11: Cleanup & Documentation

**Goal:** Remove all legacy code, update documentation.

### Tasks

- [ ] 9.1 Remove empty feature folders
- [ ] 9.2 Update barrel exports
- [ ] 9.3 Remove unused imports throughout codebase
- [ ] 9.4 Run `dart fix --apply`
- [ ] 9.5 Run `flutter pub outdated` and update dependencies
- [ ] 9.6 Update README if needed
- [ ] 9.7 Final test run - all 1060+ tests passing
- [ ] 9.8 **REMIND USER: Wipe local PowerSync data and resync**

---

## Progress Log

| Date | Phase | Task | Status | Notes |
|------|-------|------|--------|-------|
| 2026-01-01 | - | Plan created | ✅ | |
| 2026-01-01 | 1 | Phase 1 complete | ✅ | UUID5 + DB source of truth |
| 2026-01-01 | 2 | Phase 2 complete | ✅ | Supabase schema migration |
| 2026-01-01 | 3 | Phase 3 complete | ✅ | Domain models (3.12/3.13 deferred to Phase 5) |
| 2026-01-01 | 4 | Phase 4 complete | ✅ | Services layer (ViewService, WorkflowService, ProblemDetectorService) |

---

## Final Folder Structure

```
lib/domain/models/
├── screens/
│   ├── view_definition.dart       ← NEW: sealed class
│   ├── screen_definition.dart     ← MODIFIED: flat class
│   ├── display_config.dart
│   ├── entity_selector.dart
│   ├── support_block.dart
│   └── trigger_config.dart
├── workflow/
│   ├── problem_type.dart          ← NEW: extracted enum
│   ├── workflow_definition.dart   ← NEW
│   ├── workflow_step.dart         ← NEW
│   ├── workflow.dart              ← NEW (runtime)
│   └── workflow_step_state.dart   ← NEW
├── problem/
│   ├── problem_definition.dart    ← NEW (Phase 5)
│   └── problem_action.dart        ← NEW (Phase 5)
├── task.dart                      ← MODIFIED (priority)
├── project.dart                   ← MODIFIED (priority)
└── label.dart                     ← MODIFIED (lastReviewedAt)

lib/presentation/
├── widgets/
│   └── problem/
│       ├── problem_card.dart      ← NEW (Phase 5)
│       ├── problem_action_button.dart ← NEW (Phase 5)
│       └── task_preview_list.dart ← NEW
├── features/
│   └── workflow/                  ← NEW (replaces screens/workflow_run)
│       ├── bloc/
│       ├── view/
│       └── widgets/
└── ...
```

---

## Supabase Migration Script Reference

Migration completed. Script stored in chat history for reference.

**Tables Created:**
- `workflow_definitions`
- `workflows`

**Columns Added:**
- `tasks.priority`
- `projects.priority`
- `labels.last_reviewed_at`
- `screen_definitions.view_type`

**Tables/Columns Removed:**
- `workflow_sessions` (table)
- `workflow_item_reviews` (table)
- `problem_acknowledgments` (table)
- `screen_definitions.completion_criteria` (column)

---

## 🔔 Important Reminder for Final Phase Completion

**Integration Test Issue (NOT BLOCKING - Investigate Later):**

The integration tests are still skipped (7 tests) due to pump/async issues that need further investigation. The working pattern was discovered in `auth_diagnostic_test.dart` (runAsync + multiple pump() calls, NOT pump(Duration)), but full integration tests still hang after 10 minutes despite using this pattern. 

This is a **separate issue** to investigate when you have time - it is NOT blocking the migration progress. All 1065 unit tests pass successfully.

**Test Status:**
- ✅ Unit Tests: 1065 passing
- ⏸️ Integration Tests: 7 skipped (hanging issue)
- 📍 Working Pattern: See `test/integration/auth_diagnostic_test.dart` for reference

---
