# Phase 7B: Workflow Bloc Integration

## AI Implementation Instructions

- **build_runner**: Running in watch mode automatically. Do NOT run manually.
- If `.freezed.dart` or `.g.dart` files don't generate after ~30 seconds, assume syntax error in the source `.dart` file.
- **Validation**: Run `flutter analyze` after each phase/subphase. Fix ALL errors and warnings before proceeding.
- **Tests**: IGNORE tests during implementation. Do not run or update test files - do not fix errors for compilation of tests.
- **Forms**: Prefer `flutter_form_builder` fields and extensions where applicable.
- **Reuse**: Check existing patterns in codebase before creating new ones.

---

## Goal

Update `WorkflowRunBloc` to use `SectionDataService` for step content.

**Decisions Implemented**: DR-008 (WorkflowStep uses Section), DR-019 (WorkflowProgressBlock auto-added)

---

## Prerequisites

- Phase 7A complete (WorkflowStep updated)
- Phase 4A complete (SectionDataService exists)

---

## Task 1: Locate Existing WorkflowRunBloc

Search for the existing implementation:

```bash
# Find the file (for reference)
grep -r "WorkflowRunBloc\|WorkflowBloc" lib/
```

Expected location: `lib/presentation/features/workflow/bloc/workflow_run_bloc.dart` or similar.

---

## Task 2: Update WorkflowRunState

**File**: `lib/presentation/features/workflow/bloc/workflow_run_state.dart`

Update to include section data:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow_definition.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow_run.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow_step.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/screen_state.dart';

part 'workflow_run_state.freezed.dart';

/// State for workflow run bloc
@freezed
sealed class WorkflowRunState with _$WorkflowRunState {
  const factory WorkflowRunState.initial() = WorkflowRunInitialState;

  const factory WorkflowRunState.loading() = WorkflowRunLoadingState;

  const factory WorkflowRunState.active({
    required WorkflowDefinition definition,
    required WorkflowRun run,
    required WorkflowStep currentStep,
    /// Section data for current step (uses SectionData from ScreenBloc)
    required List<SectionData> stepSections,
    /// Support blocks for current step + global
    required List<SupportBlockData> supportBlocks,
    @Default(false) bool isTransitioning,
  }) = WorkflowRunActiveState;

  const factory WorkflowRunState.completed({
    required WorkflowDefinition definition,
    required WorkflowRun run,
  }) = WorkflowRunCompletedState;

  const factory WorkflowRunState.error({
    required String message,
    Object? error,
  }) = WorkflowRunErrorState;
}
```

---

## Task 3: Update WorkflowRunEvent

**File**: `lib/presentation/features/workflow/bloc/workflow_run_event.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'workflow_run_event.freezed.dart';

/// Events for workflow run bloc
@freezed
sealed class WorkflowRunEvent with _$WorkflowRunEvent {
  /// Start a new workflow run
  const factory WorkflowRunEvent.start({
    required String workflowDefinitionId,
    String? entityId,
    String? entityType,
  }) = WorkflowRunStartEvent;

  /// Resume an existing run
  const factory WorkflowRunEvent.resume({
    required String runId,
  }) = WorkflowRunResumeEvent;

  /// Complete current step and move to next
  const factory WorkflowRunEvent.completeStep() = WorkflowRunCompleteStepEvent;

  /// Go back to previous step
  const factory WorkflowRunEvent.previousStep() = WorkflowRunPreviousStepEvent;

  /// Skip current step (if allowed)
  const factory WorkflowRunEvent.skipStep() = WorkflowRunSkipStepEvent;

  /// Refresh current step data
  const factory WorkflowRunEvent.refreshStep() = WorkflowRunRefreshStepEvent;

  /// Pause workflow
  const factory WorkflowRunEvent.pause() = WorkflowRunPauseEvent;

  /// Cancel workflow
  const factory WorkflowRunEvent.cancel() = WorkflowRunCancelEvent;
}
```

---

## Task 4: Update WorkflowRunBloc

**File**: `lib/presentation/features/workflow/bloc/workflow_run_bloc.dart`

```dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow_definition.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow_run.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow_step.dart';
import 'package:taskly_bloc/domain/models/screens/support_block.dart';
import 'package:taskly_bloc/domain/repositories/workflow_repository.dart';
import 'package:taskly_bloc/domain/services/section_data_service.dart';
import 'package:taskly_bloc/domain/services/support_block_computer.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/screen_state.dart';
import 'package:taskly_bloc/presentation/features/workflow/bloc/workflow_run_event.dart';
import 'package:taskly_bloc/presentation/features/workflow/bloc/workflow_run_state.dart';

class WorkflowRunBloc extends Bloc<WorkflowRunEvent, WorkflowRunState> {
  final WorkflowRepository _workflowRepository;
  final SectionDataService _sectionDataService;
  final SupportBlockComputer _supportBlockComputer;

  WorkflowRunBloc({
    required WorkflowRepository workflowRepository,
    required SectionDataService sectionDataService,
    required SupportBlockComputer supportBlockComputer,
  })  : _workflowRepository = workflowRepository,
        _sectionDataService = sectionDataService,
        _supportBlockComputer = supportBlockComputer,
        super(const WorkflowRunState.initial()) {
    on<WorkflowRunStartEvent>(_onStart);
    on<WorkflowRunResumeEvent>(_onResume);
    on<WorkflowRunCompleteStepEvent>(_onCompleteStep);
    on<WorkflowRunPreviousStepEvent>(_onPreviousStep);
    on<WorkflowRunSkipStepEvent>(_onSkipStep);
    on<WorkflowRunRefreshStepEvent>(_onRefreshStep);
    on<WorkflowRunPauseEvent>(_onPause);
    on<WorkflowRunCancelEvent>(_onCancel);
  }

  Future<void> _onStart(
    WorkflowRunStartEvent event,
    Emitter<WorkflowRunState> emit,
  ) async {
    emit(const WorkflowRunState.loading());

    try {
      final definition = await _workflowRepository.getWorkflowDefinition(
        event.workflowDefinitionId,
      );
      if (definition == null) {
        emit(WorkflowRunState.error(
          message: 'Workflow not found: ${event.workflowDefinitionId}',
        ));
        return;
      }

      // Create new run
      final run = await _workflowRepository.createRun(
        workflowDefinitionId: definition.id,
        entityId: event.entityId,
        entityType: event.entityType,
      );

      await _loadStep(emit, definition, run, 0);
    } catch (e) {
      emit(WorkflowRunState.error(message: e.toString(), error: e));
    }
  }

  Future<void> _onResume(
    WorkflowRunResumeEvent event,
    Emitter<WorkflowRunState> emit,
  ) async {
    emit(const WorkflowRunState.loading());

    try {
      final run = await _workflowRepository.getRun(event.runId);
      if (run == null) {
        emit(WorkflowRunState.error(message: 'Run not found: ${event.runId}'));
        return;
      }

      final definition = await _workflowRepository.getWorkflowDefinition(
        run.workflowDefinitionId,
      );
      if (definition == null) {
        emit(const WorkflowRunState.error(message: 'Workflow definition not found'));
        return;
      }

      await _loadStep(emit, definition, run, run.currentStepIndex);
    } catch (e) {
      emit(WorkflowRunState.error(message: e.toString(), error: e));
    }
  }

  Future<void> _onCompleteStep(
    WorkflowRunCompleteStepEvent event,
    Emitter<WorkflowRunState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorkflowRunActiveState) return;

    emit(currentState.copyWith(isTransitioning: true));

    try {
      // Mark step as completed
      final updatedRun = await _workflowRepository.completeStep(
        currentState.run.id,
        currentState.currentStep.id,
      );

      // Check if workflow is complete
      if (updatedRun.currentStepIndex >= currentState.definition.totalSteps) {
        emit(WorkflowRunState.completed(
          definition: currentState.definition,
          run: updatedRun,
        ));
        return;
      }

      // Load next step
      await _loadStep(
        emit,
        currentState.definition,
        updatedRun,
        updatedRun.currentStepIndex,
      );
    } catch (e) {
      emit(WorkflowRunState.error(message: e.toString(), error: e));
    }
  }

  Future<void> _onPreviousStep(
    WorkflowRunPreviousStepEvent event,
    Emitter<WorkflowRunState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorkflowRunActiveState) return;
    if (currentState.run.currentStepIndex <= 0) return;

    emit(currentState.copyWith(isTransitioning: true));

    try {
      final updatedRun = await _workflowRepository.goToStep(
        currentState.run.id,
        currentState.run.currentStepIndex - 1,
      );

      await _loadStep(
        emit,
        currentState.definition,
        updatedRun,
        updatedRun.currentStepIndex,
      );
    } catch (e) {
      emit(WorkflowRunState.error(message: e.toString(), error: e));
    }
  }

  Future<void> _onSkipStep(
    WorkflowRunSkipStepEvent event,
    Emitter<WorkflowRunState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorkflowRunActiveState) return;
    if (currentState.currentStep.isRequired) return;

    emit(currentState.copyWith(isTransitioning: true));

    try {
      final updatedRun = await _workflowRepository.skipStep(
        currentState.run.id,
        currentState.currentStep.id,
      );

      if (updatedRun.currentStepIndex >= currentState.definition.totalSteps) {
        emit(WorkflowRunState.completed(
          definition: currentState.definition,
          run: updatedRun,
        ));
        return;
      }

      await _loadStep(
        emit,
        currentState.definition,
        updatedRun,
        updatedRun.currentStepIndex,
      );
    } catch (e) {
      emit(WorkflowRunState.error(message: e.toString(), error: e));
    }
  }

  Future<void> _onRefreshStep(
    WorkflowRunRefreshStepEvent event,
    Emitter<WorkflowRunState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorkflowRunActiveState) return;

    await _loadStep(
      emit,
      currentState.definition,
      currentState.run,
      currentState.run.currentStepIndex,
    );
  }

  Future<void> _onPause(
    WorkflowRunPauseEvent event,
    Emitter<WorkflowRunState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorkflowRunActiveState) return;

    await _workflowRepository.pauseRun(currentState.run.id);
  }

  Future<void> _onCancel(
    WorkflowRunCancelEvent event,
    Emitter<WorkflowRunState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorkflowRunActiveState) return;

    await _workflowRepository.cancelRun(currentState.run.id);
    emit(const WorkflowRunState.initial());
  }

  /// Load step data using SectionDataService
  Future<void> _loadStep(
    Emitter<WorkflowRunState> emit,
    WorkflowDefinition definition,
    WorkflowRun run,
    int stepIndex,
  ) async {
    final step = definition.getStep(stepIndex);
    if (step == null) {
      emit(const WorkflowRunState.error(message: 'Invalid step index'));
      return;
    }

    // Fetch section data for current step
    final sectionDataList = <SectionData>[];
    for (var i = 0; i < step.sections.length; i++) {
      final section = step.sections[i];
      final data = await _sectionDataService.fetchSectionData(section);
      sectionDataList.add(SectionData(
        index: i,
        title: section.title,
        data: data,
      ));
    }

    // Compute support blocks (step + global)
    final allTasks = sectionDataList.expand((s) => s.data.allTasks).toList();
    final allProjects = sectionDataList.expand((s) => s.data.allProjects).toList();

    // Auto-add WorkflowProgressBlock (DR-019)
    final supportBlocks = <SupportBlock>[
      const SupportBlock.workflowProgress(),
      ...definition.globalSupportBlocks.where((b) => b is! WorkflowProgressBlock),
      ...step.supportBlocks,
    ];

    final supportBlockDataList = <SupportBlockData>[];
    for (var i = 0; i < supportBlocks.length; i++) {
      final block = supportBlocks[i];
      final result = _supportBlockComputer.compute(
        block,
        tasks: allTasks,
        projects: allProjects,
        workflowRun: run,
      );
      supportBlockDataList.add(SupportBlockData(
        index: i,
        config: block,
        result: result,
      ));
    }

    emit(WorkflowRunState.active(
      definition: definition,
      run: run,
      currentStep: step,
      stepSections: sectionDataList,
      supportBlocks: supportBlockDataList,
    ));
  }
}
```

---

## Task 5: Update Workflow Bloc Barrel Export

**File**: `lib/presentation/features/workflow/bloc/bloc.dart`

```dart
export 'workflow_run_bloc.dart';
export 'workflow_run_event.dart';
export 'workflow_run_state.dart';
```

---

## Validation Checklist

- [ ] `flutter analyze` returns 0 errors, 0 warnings (ignore test file errors)
- [ ] `workflow_run_state.freezed.dart` generated
- [ ] `workflow_run_event.freezed.dart` generated
- [ ] `WorkflowRunBloc` uses `SectionDataService`
- [ ] `WorkflowProgressBlock` auto-added per DR-019
- [ ] All event handlers implemented

---

## Files Modified

| File | Change |
|------|--------|
| `lib/presentation/features/workflow/bloc/workflow_run_state.dart` | Include section data |
| `lib/presentation/features/workflow/bloc/workflow_run_event.dart` | Update events |
| `lib/presentation/features/workflow/bloc/workflow_run_bloc.dart` | Use SectionDataService |
| `lib/presentation/features/workflow/bloc/bloc.dart` | Update exports |

---

## Next Phase

Proceed to **Phase 8: System Screen Seeder** after validation passes.
