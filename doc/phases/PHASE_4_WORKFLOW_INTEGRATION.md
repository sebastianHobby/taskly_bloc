# Phase 4: Workflow Integration

## AI Implementation Instructions

### Environment Setup
- **build_runner**: Running in watch mode automatically. Do NOT run manually.
- If `.freezed.dart` or `.g.dart` files don't generate after ~30 seconds, assume syntax error in the source `.dart` file.
- **Validation**: Run `flutter analyze` after each file creation. Fix ALL errors and warnings before proceeding.
- **Tests**: IGNORE tests during implementation. Do not run or update test files.
- **Forms**: Prefer `flutter_form_builder` fields and extensions where applicable.
- **Reuse**: Check existing patterns in codebase before creating new ones.

### Phase Goal
Achieve feature parity between workflows and screens. Workflows should use the same `List<Section>` model, rendered by the same widgets.

### Prerequisites
- Phase 0-3B complete (types, services, BLoC, UI)

---

## Background: Current Workflow Architecture

**Reference File**: `lib/presentation/features/workflow/bloc/workflow_run_bloc.dart` (~696 lines)

Current workflow model:
- `WorkflowDefinition` contains `List<WorkflowStep>`
- Each `WorkflowStep` has a `ViewDefinition` (the old model)
- `WorkflowRunBloc._loadItemsForStep()` extracts queries from ViewDefinition

**Goal**: Replace `ViewDefinition` in `WorkflowStep` with `List<Section>`, enabling:
- Same data fetching (SectionDataService)
- Same rendering (section renderers)
- Workflow-specific orchestration (step progression, actions)

---

## Task 1: Update WorkflowStep Model

**File**: `lib/domain/models/workflow/workflow_step.dart`

Update the model to use sections:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/screens/section.dart';

part 'workflow_step.freezed.dart';
part 'workflow_step.g.dart';

/// A single step in a workflow.
@freezed
class WorkflowStep with _$WorkflowStep {
  const factory WorkflowStep({
    required String id,
    required String name,
    
    /// The sections to display for this step.
    /// Uses the same Section model as screens.
    required List<Section> sections,
    
    /// Optional instruction text shown to user.
    String? instruction,
    
    /// Actions available in this step.
    @Default([]) List<WorkflowAction> actions,
    
    /// Whether this step requires user confirmation to proceed.
    @Default(false) bool requiresConfirmation,
    
    /// Minimum time (seconds) user must spend on this step.
    /// Useful for review steps.
    int? minimumDuration,
    
    /// Order of this step in the workflow.
    required int order,
  }) = _WorkflowStep;

  factory WorkflowStep.fromJson(Map<String, dynamic> json) =>
      _$WorkflowStepFromJson(json);
}

/// Actions available within a workflow step.
@freezed
class WorkflowAction with _$WorkflowAction {
  /// Complete selected tasks
  const factory WorkflowAction.completeTasks() = _CompleteTasksAction;
  
  /// Defer selected tasks to later
  const factory WorkflowAction.deferTasks({
    required Duration deferDuration,
  }) = _DeferTasksAction;
  
  /// Move to next step
  const factory WorkflowAction.nextStep() = _NextStepAction;
  
  /// Skip current step
  const factory WorkflowAction.skipStep() = _SkipStepAction;
  
  /// Custom action with callback
  const factory WorkflowAction.custom({
    required String id,
    required String label,
    String? icon,
  }) = _CustomAction;

  factory WorkflowAction.fromJson(Map<String, dynamic> json) =>
      _$WorkflowActionFromJson(json);
}
```

---

## Task 2: Create WorkflowStepBloc

**File**: `lib/presentation/features/workflow/bloc/workflow_step_bloc.dart`

A focused BLoC for a single workflow step (similar to SectionBloc):

```dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow_step.dart';
import 'package:taskly_bloc/domain/models/screens/section.dart';
import 'package:taskly_bloc/domain/models/screens/fetch_result.dart';
import 'package:taskly_bloc/domain/services/section_data_service.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/section_bloc.dart';

part 'workflow_step_bloc.freezed.dart';

@freezed
class WorkflowStepEvent with _$WorkflowStepEvent {
  /// Initialize step with sections
  const factory WorkflowStepEvent.started({
    required WorkflowStep step,
    String? parentEntityId,
  }) = _Started;

  /// Refresh step data
  const factory WorkflowStepEvent.refreshed() = _Refreshed;

  /// User selected/deselected an item
  const factory WorkflowStepEvent.itemSelectionToggled({
    required String itemId,
    required SelectableItemType itemType,
  }) = _ItemSelectionToggled;

  /// Execute a workflow action
  const factory WorkflowStepEvent.actionExecuted({
    required WorkflowAction action,
  }) = _ActionExecuted;

  /// Time spent on step updated
  const factory WorkflowStepEvent.timeUpdated({
    required Duration elapsed,
  }) = _TimeUpdated;
}

enum SelectableItemType { task, project }

@freezed
class WorkflowStepState with _$WorkflowStepState {
  const factory WorkflowStepState.initial() = _Initial;

  const factory WorkflowStepState.loading({
    required WorkflowStep step,
  }) = _Loading;

  const factory WorkflowStepState.loaded({
    required WorkflowStep step,
    required List<LoadedSection> sections,
    required Set<String> selectedTaskIds,
    required Set<String> selectedProjectIds,
    required Duration timeSpent,
    required bool canProceed,
  }) = _Loaded;

  const factory WorkflowStepState.actionInProgress({
    required WorkflowStep step,
    required List<LoadedSection> sections,
    required WorkflowAction action,
  }) = _ActionInProgress;

  const factory WorkflowStepState.error({
    required String message,
    Object? error,
  }) = _Error;
}

@injectable
class WorkflowStepBloc extends Bloc<WorkflowStepEvent, WorkflowStepState> {
  WorkflowStepBloc({
    required SectionDataService sectionDataService,
  })  : _sectionDataService = sectionDataService,
        super(const WorkflowStepState.initial()) {
    on<_Started>(_onStarted);
    on<_Refreshed>(_onRefreshed);
    on<_ItemSelectionToggled>(_onItemSelectionToggled);
    on<_ActionExecuted>(_onActionExecuted);
    on<_TimeUpdated>(_onTimeUpdated);
  }

  final SectionDataService _sectionDataService;
  
  WorkflowStep? _currentStep;
  String? _parentEntityId;

  Future<void> _onStarted(
    _Started event,
    Emitter<WorkflowStepState> emit,
  ) async {
    _currentStep = event.step;
    _parentEntityId = event.parentEntityId;

    emit(WorkflowStepState.loading(step: event.step));

    try {
      final sections = await _loadSections(event.step.sections);
      
      emit(WorkflowStepState.loaded(
        step: event.step,
        sections: sections,
        selectedTaskIds: {},
        selectedProjectIds: {},
        timeSpent: Duration.zero,
        canProceed: _canProceed(event.step, Duration.zero, {}),
      ));
    } catch (e) {
      emit(WorkflowStepState.error(
        message: 'Failed to load step data',
        error: e,
      ));
    }
  }

  Future<void> _onRefreshed(
    _Refreshed event,
    Emitter<WorkflowStepState> emit,
  ) async {
    final step = _currentStep;
    if (step == null) return;

    final currentState = state;
    Set<String> selectedTasks = {};
    Set<String> selectedProjects = {};
    Duration timeSpent = Duration.zero;

    if (currentState is _Loaded) {
      selectedTasks = currentState.selectedTaskIds;
      selectedProjects = currentState.selectedProjectIds;
      timeSpent = currentState.timeSpent;
    }

    try {
      final sections = await _loadSections(step.sections);
      
      emit(WorkflowStepState.loaded(
        step: step,
        sections: sections,
        selectedTaskIds: selectedTasks,
        selectedProjectIds: selectedProjects,
        timeSpent: timeSpent,
        canProceed: _canProceed(step, timeSpent, selectedTasks),
      ));
    } catch (e) {
      emit(WorkflowStepState.error(
        message: 'Failed to refresh step data',
        error: e,
      ));
    }
  }

  void _onItemSelectionToggled(
    _ItemSelectionToggled event,
    Emitter<WorkflowStepState> emit,
  ) {
    final currentState = state;
    if (currentState is! _Loaded) return;

    Set<String> selectedTasks = Set.from(currentState.selectedTaskIds);
    Set<String> selectedProjects = Set.from(currentState.selectedProjectIds);

    switch (event.itemType) {
      case SelectableItemType.task:
        if (selectedTasks.contains(event.itemId)) {
          selectedTasks.remove(event.itemId);
        } else {
          selectedTasks.add(event.itemId);
        }
      case SelectableItemType.project:
        if (selectedProjects.contains(event.itemId)) {
          selectedProjects.remove(event.itemId);
        } else {
          selectedProjects.add(event.itemId);
        }
    }

    emit(currentState.copyWith(
      selectedTaskIds: selectedTasks,
      selectedProjectIds: selectedProjects,
      canProceed: _canProceed(
        currentState.step,
        currentState.timeSpent,
        selectedTasks,
      ),
    ));
  }

  Future<void> _onActionExecuted(
    _ActionExecuted event,
    Emitter<WorkflowStepState> emit,
  ) async {
    final currentState = state;
    if (currentState is! _Loaded) return;

    emit(WorkflowStepState.actionInProgress(
      step: currentState.step,
      sections: currentState.sections,
      action: event.action,
    ));

    // Action execution is handled by parent WorkflowRunBloc
    // This just signals that action was triggered
  }

  void _onTimeUpdated(
    _TimeUpdated event,
    Emitter<WorkflowStepState> emit,
  ) {
    final currentState = state;
    if (currentState is! _Loaded) return;

    emit(currentState.copyWith(
      timeSpent: event.elapsed,
      canProceed: _canProceed(
        currentState.step,
        event.elapsed,
        currentState.selectedTaskIds,
      ),
    ));
  }

  Future<List<LoadedSection>> _loadSections(List<Section> sections) async {
    final results = <LoadedSection>[];

    for (final section in sections) {
      final data = await _sectionDataService.fetchSectionData(
        section: section,
        parentEntityId: _parentEntityId,
      );

      results.add(LoadedSection(
        section: section,
        data: data,
        displaySettings: const SectionDisplaySettings(), // Default for workflow
      ));
    }

    return results;
  }

  bool _canProceed(
    WorkflowStep step,
    Duration timeSpent,
    Set<String> selectedTasks,
  ) {
    // Check minimum duration requirement
    if (step.minimumDuration != null) {
      if (timeSpent.inSeconds < step.minimumDuration!) {
        return false;
      }
    }

    // Check confirmation requirement
    if (step.requiresConfirmation && selectedTasks.isEmpty) {
      return false;
    }

    return true;
  }
}
```

---

## Task 3: Update WorkflowRunBloc

**File**: `lib/presentation/features/workflow/bloc/workflow_run_bloc.dart`

Refactor to use WorkflowStepBloc for data loading. Key changes:

### Replace `_loadItemsForStep` with section-based loading

```dart
// BEFORE (example of pattern to replace):
Future<void> _loadItemsForStep(WorkflowStep step) async {
  final viewDefinition = step.viewDefinition;
  
  return switch (viewDefinition) {
    CollectionViewDefinition(:final query) => _loadCollection(query),
    AgendaViewDefinition(:final dateRange) => _loadAgenda(dateRange),
    // ... many more cases
  };
}

// AFTER:
Future<List<LoadedSection>> _loadItemsForStep(WorkflowStep step) async {
  final sections = step.sections;
  final results = <LoadedSection>[];
  
  for (final section in sections) {
    final data = await _sectionDataService.fetchSectionData(
      section: section,
      parentEntityId: _currentParentEntityId,
    );
    
    results.add(LoadedSection(
      section: section,
      data: data,
      displaySettings: const SectionDisplaySettings(),
    ));
  }
  
  return results;
}
```

### Update state to hold LoadedSection list

```dart
@freezed
class WorkflowRunState with _$WorkflowRunState {
  // ... existing variants, but update the step-related ones:
  
  const factory WorkflowRunState.stepActive({
    required WorkflowDefinition workflow,
    required int currentStepIndex,
    required WorkflowStep currentStep,
    required List<LoadedSection> sections, // NEW: replaces items list
    required Set<String> selectedTaskIds,
    required Set<String> selectedProjectIds,
    required Duration stepTimeSpent,
    required bool canProceed,
    Map<String, StepResult>? completedSteps,
  }) = _StepActive;
  
  // ... other variants
}
```

### Add SectionDataService dependency

```dart
@injectable
class WorkflowRunBloc extends Bloc<WorkflowRunEvent, WorkflowRunState> {
  WorkflowRunBloc({
    required WorkflowRepository workflowRepository,
    required TaskRepository taskRepository,
    required SectionDataService sectionDataService, // NEW
  })  : _workflowRepository = workflowRepository,
        _taskRepository = taskRepository,
        _sectionDataService = sectionDataService,
        super(const WorkflowRunState.initial());

  final SectionDataService _sectionDataService;
  // ...
}
```

---

## Task 4: Create WorkflowStepView

**File**: `lib/presentation/features/workflow/view/workflow_step_view.dart`

Renders a workflow step using section renderers:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow_step.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/section_bloc.dart';
import 'package:taskly_bloc/presentation/features/workflow/bloc/workflow_step_bloc.dart';
import 'package:taskly_bloc/presentation/widgets/sections/section_renderer.dart';

/// Renders a single workflow step with sections and actions.
class WorkflowStepView extends StatelessWidget {
  const WorkflowStepView({
    required this.step,
    required this.onActionExecuted,
    required this.onTaskSelected,
    this.parentEntityId,
    super.key,
  });

  final WorkflowStep step;
  final void Function(WorkflowAction action, Set<String> selectedTaskIds) onActionExecuted;
  final void Function(String taskId, bool selected) onTaskSelected;
  final String? parentEntityId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkflowStepBloc, WorkflowStepState>(
      builder: (context, state) {
        return state.when(
          initial: () => const SizedBox.shrink(),
          loading: (_) => const Center(child: CircularProgressIndicator()),
          loaded: (step, sections, selectedTasks, selectedProjects, timeSpent, canProceed) =>
              _buildContent(
                context,
                step,
                sections,
                selectedTasks,
                canProceed,
              ),
          actionInProgress: (step, sections, action) => Stack(
            children: [
              _buildContent(context, step, sections, {}, false),
              const Center(child: CircularProgressIndicator()),
            ],
          ),
          error: (message, _) => Center(child: Text('Error: $message')),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    WorkflowStep step,
    List<LoadedSection> sections,
    Set<String> selectedTaskIds,
    bool canProceed,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Step header with instruction
        if (step.instruction != null)
          _StepInstruction(instruction: step.instruction!),

        // Sections (main content)
        Expanded(
          child: _SelectableSectionsView(
            sections: sections,
            selectedTaskIds: selectedTaskIds,
            onTaskSelected: onTaskSelected,
          ),
        ),

        // Action bar
        if (step.actions.isNotEmpty)
          _ActionBar(
            actions: step.actions,
            canProceed: canProceed,
            selectedCount: selectedTaskIds.length,
            onActionExecuted: (action) => onActionExecuted(action, selectedTaskIds),
          ),
      ],
    );
  }
}

class _StepInstruction extends StatelessWidget {
  const _StepInstruction({required this.instruction});

  final String instruction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              instruction,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectableSectionsView extends StatelessWidget {
  const _SelectableSectionsView({
    required this.sections,
    required this.selectedTaskIds,
    required this.onTaskSelected,
  });

  final List<LoadedSection> sections;
  final Set<String> selectedTaskIds;
  final void Function(String taskId, bool selected) onTaskSelected;

  @override
  Widget build(BuildContext context) {
    // Use existing SectionsListView but with selection capability
    // For now, wrap with selection state
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sections.length,
      itemBuilder: (context, index) {
        final loadedSection = sections[index];
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < sections.length - 1 ? 16 : 0,
          ),
          child: _SelectableSectionRenderer(
            loadedSection: loadedSection,
            selectedTaskIds: selectedTaskIds,
            onTaskSelected: onTaskSelected,
          ),
        );
      },
    );
  }
}

class _SelectableSectionRenderer extends StatelessWidget {
  const _SelectableSectionRenderer({
    required this.loadedSection,
    required this.selectedTaskIds,
    required this.onTaskSelected,
  });

  final LoadedSection loadedSection;
  final Set<String> selectedTaskIds;
  final void Function(String taskId, bool selected) onTaskSelected;

  @override
  Widget build(BuildContext context) {
    // For workflow, we need selectable tasks
    // Wrap the standard renderer or create workflow-specific version
    return SectionRenderer(
      loadedSection: loadedSection,
      onTaskTap: (taskId) {
        final isSelected = selectedTaskIds.contains(taskId);
        onTaskSelected(taskId, !isSelected);
      },
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.actions,
    required this.canProceed,
    required this.selectedCount,
    required this.onActionExecuted,
  });

  final List<WorkflowAction> actions;
  final bool canProceed;
  final int selectedCount;
  final void Function(WorkflowAction action) onActionExecuted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (selectedCount > 0)
              Text(
                '$selectedCount selected',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            const Spacer(),
            ...actions.map((action) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _ActionButton(
                action: action,
                enabled: _isActionEnabled(action),
                onPressed: () => onActionExecuted(action),
              ),
            )),
          ],
        ),
      ),
    );
  }

  bool _isActionEnabled(WorkflowAction action) {
    return action.when(
      completeTasks: () => selectedCount > 0,
      deferTasks: (_) => selectedCount > 0,
      nextStep: () => canProceed,
      skipStep: () => true,
      custom: (_, __, ___) => true,
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.action,
    required this.enabled,
    required this.onPressed,
  });

  final WorkflowAction action;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final (label, icon, isPrimary) = action.when(
      completeTasks: () => ('Complete', Icons.check, true),
      deferTasks: (_) => ('Defer', Icons.schedule, false),
      nextStep: () => ('Next', Icons.arrow_forward, true),
      skipStep: () => ('Skip', Icons.skip_next, false),
      custom: (_, label, icon) => (label, _resolveIcon(icon), false),
    );

    if (isPrimary) {
      return FilledButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon),
        label: Text(label),
      );
    }

    return OutlinedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon),
      label: Text(label),
    );
  }

  IconData _resolveIcon(String? iconName) {
    if (iconName == null) return Icons.play_arrow;
    return switch (iconName) {
      'check' => Icons.check,
      'schedule' => Icons.schedule,
      'skip' => Icons.skip_next,
      'arrow_forward' => Icons.arrow_forward,
      _ => Icons.play_arrow,
    };
  }
}
```

---

## Task 5: Create ViewDefinition to Sections Migrator

**File**: `lib/domain/services/view_to_sections_migrator.dart`

For backwards compatibility during migration:

```dart
import 'package:taskly_bloc/domain/models/screens/section.dart';
import 'package:taskly_bloc/domain/models/screens/data_config.dart';
import 'package:taskly_bloc/domain/models/screens/view_definition.dart';

/// Converts legacy ViewDefinition to List<Section> for migration.
/// 
/// Use this to migrate existing workflow steps that use ViewDefinition
/// to the new section-based model.
class ViewToSectionsMigrator {
  /// Converts a ViewDefinition to equivalent sections.
  List<Section> migrate(ViewDefinition viewDefinition) {
    return switch (viewDefinition) {
      CollectionViewDefinition(:final query) => [
          DataSection(
            id: 'migrated_collection',
            dataConfig: _queryToDataConfig(query),
          ),
        ],
      AgendaViewDefinition(:final dateRange, :final query) => [
          DataSection(
            id: 'migrated_agenda',
            title: 'Agenda',
            dataConfig: TaskDataConfig(
              query: query ?? const TaskQuery(),
              dateFilter: DateFilter(
                field: DateFilterField.deadline,
                start: dateRange.start,
                end: dateRange.end,
              ),
            ),
          ),
        ],
      DetailViewDefinition(:final entityType, :final entityId) => [
          DataSection(
            id: 'migrated_detail',
            dataConfig: _entityTypeToDataConfig(entityType, entityId),
          ),
        ],
      AllocatedViewDefinition(:final maxItems) => [
          AllocationSection(
            id: 'migrated_allocation',
            maxTasks: maxItems,
          ),
        ],
      // Add other ViewDefinition variants as needed
      _ => <Section>[],
    };
  }

  DataConfig _queryToDataConfig(EntityQuery query) {
    return switch (query) {
      TaskQuery() => TaskDataConfig(query: query),
      ProjectQuery() => ProjectDataConfig(query: query),
      LabelQuery() => LabelDataConfig(query: query),
      ValueQuery() => ValueDataConfig(query: query),
      _ => TaskDataConfig(query: const TaskQuery()),
    };
  }

  DataConfig _entityTypeToDataConfig(EntityType type, String? entityId) {
    // For detail views, create a filter for specific entity
    return switch (type) {
      EntityType.task => TaskDataConfig(
          query: TaskQuery(ids: entityId != null ? [entityId] : null),
        ),
      EntityType.project => ProjectDataConfig(
          query: ProjectQuery(ids: entityId != null ? [entityId] : null),
        ),
      EntityType.label => LabelDataConfig(
          query: LabelQuery(ids: entityId != null ? [entityId] : null),
        ),
    };
  }
}
```

---

## Task 6: Update Workflow Drift Table (if needed)

If workflow steps are persisted, update the Drift table:

**File**: `lib/data/local/drift/tables/workflow_steps_table.dart`

```dart
import 'package:drift/drift.dart';

class WorkflowStepsTable extends Table {
  @override
  String get tableName => 'workflow_steps';

  TextColumn get id => text()();
  TextColumn get workflowId => text()();
  TextColumn get name => text()();
  
  /// JSON-encoded List<Section>
  TextColumn get sectionsJson => text()();
  
  TextColumn get instruction => text().nullable()();
  
  /// JSON-encoded List<WorkflowAction>
  TextColumn get actionsJson => text().withDefault(const Constant('[]'))();
  
  BoolColumn get requiresConfirmation => boolean().withDefault(const Constant(false))();
  IntColumn get minimumDuration => integer().nullable()();
  IntColumn get order => integer()();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

---

## Task 7: Register Dependencies

**File**: `lib/core/dependency_injection/injection.config.dart` or equivalent

Ensure new classes are registered:

```dart
// In your DI setup:
getIt.registerFactory<WorkflowStepBloc>(
  () => WorkflowStepBloc(
    sectionDataService: getIt<SectionDataService>(),
  ),
);

getIt.registerLazySingleton<ViewToSectionsMigrator>(
  () => ViewToSectionsMigrator(),
);
```

---

## Validation Checklist

After completing all tasks:

1. [ ] Run `flutter analyze` - expect 0 errors, 0 warnings
2. [ ] WorkflowStep model compiles with sections
3. [ ] WorkflowStepBloc loads sections correctly
4. [ ] WorkflowRunBloc updated to use SectionDataService
5. [ ] WorkflowStepView renders sections
6. [ ] Existing workflows still function (backwards compatible)
7. [ ] App launches without errors
8. [ ] Navigate to a workflow and verify steps render

---

## Files Created This Phase

| File | Purpose |
|------|---------|
| `lib/presentation/features/workflow/bloc/workflow_step_bloc.dart` | Per-step BLoC |
| `lib/presentation/features/workflow/view/workflow_step_view.dart` | Step UI with sections |
| `lib/domain/services/view_to_sections_migrator.dart` | Legacy migration |

## Files Modified This Phase

| File | Change |
|------|--------|
| `lib/domain/models/workflow/workflow_step.dart` | ViewDefinition → List<Section> |
| `lib/presentation/features/workflow/bloc/workflow_run_bloc.dart` | Use SectionDataService |
| `lib/data/local/drift/tables/workflow_steps_table.dart` | Schema update (if persisted) |
| DI configuration | Register new classes |

---

## Migration Strategy

For existing workflows in the database:

1. **Option A**: Run Drift migration that converts `view_definition_json` to `sections_json`
2. **Option B**: Handle both formats in repository (check which field is populated)
3. **Option C**: Use ViewToSectionsMigrator at runtime when loading legacy steps

Recommended: **Option B** for gradual migration, then **Option A** once stable.

---

## Integration Notes

### Selection in Workflows
Workflows often need task selection (e.g., "select tasks to complete"). The section renderers from Phase 3B need to support:
- Checkbox per task
- Multi-select mode
- Selection state passed up to WorkflowStepBloc

Consider adding a `selectable: bool` parameter to TaskListRenderer.

### Action Execution
WorkflowAction execution happens in WorkflowRunBloc, not WorkflowStepBloc:
- WorkflowStepBloc emits `actionInProgress` state
- WorkflowRunBloc listens and performs actual action
- On completion, WorkflowStepBloc is refreshed

---

## Next Phase
Proceed to **Phase 5: User Settings & Preferences** after all validation passes.
