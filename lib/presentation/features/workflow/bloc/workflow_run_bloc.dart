import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/workflow_repository_contract.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow_definition.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow_step.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow_step_state.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_ref.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/screens/templates/params/agenda_section_params.dart';
import 'package:taskly_bloc/domain/screens/templates/params/allocation_section_params.dart';
import 'package:taskly_bloc/domain/screens/templates/params/data_list_section_params.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_service.dart';

part 'workflow_run_bloc.freezed.dart';

/// Events for [WorkflowRunBloc]
@freezed
sealed class WorkflowRunEvent with _$WorkflowRunEvent {
  /// Start the workflow with a definition
  const factory WorkflowRunEvent.started({
    required WorkflowDefinition definition,
  }) = WorkflowStarted;

  /// Resume an existing workflow
  const factory WorkflowRunEvent.resumed({
    required Workflow workflow,
    required WorkflowDefinition definition,
  }) = WorkflowResumed;

  /// Mark the current item as reviewed
  const factory WorkflowRunEvent.itemReviewed({
    required String entityId,
  }) = ItemReviewed;

  /// Skip the current item
  const factory WorkflowRunEvent.itemSkipped({
    required String entityId,
  }) = ItemSkipped;

  /// Move to next item in current step
  const factory WorkflowRunEvent.nextItem() = NextItemRequested;

  /// Move to previous item in current step
  const factory WorkflowRunEvent.previousItem() = PreviousItemRequested;

  /// Jump to specific item index
  const factory WorkflowRunEvent.jumpToItem({
    required int index,
  }) = JumpToItemRequested;

  /// Advance to the next step
  const factory WorkflowRunEvent.nextStep() = NextStepRequested;

  /// Go back to previous step
  const factory WorkflowRunEvent.previousStep() = PreviousStepRequested;

  /// Complete the entire workflow
  const factory WorkflowRunEvent.completed() = WorkflowCompleteRequested;

  /// Abandon the workflow
  const factory WorkflowRunEvent.abandoned() = WorkflowAbandonRequested;
}

/// State for [WorkflowRunBloc]
@freezed
sealed class WorkflowRunState with _$WorkflowRunState {
  const factory WorkflowRunState.initial() = WorkflowInitial;

  const factory WorkflowRunState.loading() = WorkflowLoading;

  const factory WorkflowRunState.running({
    required WorkflowDefinition definition,
    required Workflow workflow,
    required int currentStepIndex,
    required List<Task> currentStepItems,
    required int currentItemIndex,
    required WorkflowProgress progress,

    /// Section data results for the current step (used for display)
    @Default([]) List<SectionDataResult> sectionDataResults,
  }) = WorkflowRunning;

  const factory WorkflowRunState.stepComplete({
    required WorkflowDefinition definition,
    required Workflow workflow,
    required int completedStepIndex,
    required WorkflowProgress progress,
  }) = WorkflowStepComplete;

  const factory WorkflowRunState.completed({
    required WorkflowDefinition definition,
    required Workflow workflow,
    required WorkflowProgress progress,
  }) = WorkflowCompleted;

  const factory WorkflowRunState.abandoned({
    required WorkflowDefinition definition,
    required Workflow workflow,
  }) = WorkflowAbandoned;

  const factory WorkflowRunState.error({
    required Object error,
    StackTrace? stackTrace,
  }) = WorkflowError;
}

/// Progress tracking for a workflow
@freezed
abstract class WorkflowProgress with _$WorkflowProgress {
  const factory WorkflowProgress({
    required int totalSteps,
    required int completedSteps,
    required int currentStepIndex,
    required StepProgress currentStepProgress,
  }) = _WorkflowProgress;

  const WorkflowProgress._();

  double get overallPercentage {
    if (totalSteps == 0) return 0;
    final stepWeight = 1.0 / totalSteps;
    final completedWeight = completedSteps * stepWeight;
    final currentWeight = currentStepProgress.percentage * stepWeight;
    return completedWeight + currentWeight;
  }
}

/// Progress tracking for a single step
@freezed
abstract class StepProgress with _$StepProgress {
  const factory StepProgress({
    required int totalItems,
    required int reviewedItems,
    required int skippedItems,
    required int currentItemIndex,
  }) = _StepProgress;

  const StepProgress._();

  int get completedItems => reviewedItems + skippedItems;
  int get pendingItems => totalItems - completedItems;
  double get percentage => totalItems == 0 ? 0 : completedItems / totalItems;
}

/// BLoC for managing new multi-step workflow execution
class WorkflowRunBloc extends Bloc<WorkflowRunEvent, WorkflowRunState> {
  WorkflowRunBloc({
    required WorkflowRepositoryContract workflowRepository,
    required TaskRepositoryContract taskRepository,
    required SectionDataService sectionDataService,
  }) : _workflowRepository = workflowRepository,
       _taskRepository = taskRepository,
       _sectionDataService = sectionDataService,
       super(const WorkflowRunState.initial()) {
    on<WorkflowStarted>(_onStarted, transformer: sequential());
    on<WorkflowResumed>(_onResumed, transformer: sequential());
    on<ItemReviewed>(_onItemReviewed, transformer: sequential());
    on<ItemSkipped>(_onItemSkipped, transformer: sequential());
    on<NextItemRequested>(_onNextItem, transformer: sequential());
    on<PreviousItemRequested>(_onPreviousItem, transformer: sequential());
    on<JumpToItemRequested>(_onJumpToItem, transformer: sequential());
    on<NextStepRequested>(_onNextStep, transformer: sequential());
    on<PreviousStepRequested>(_onPreviousStep, transformer: sequential());
    on<WorkflowCompleteRequested>(_onCompleted, transformer: sequential());
    on<WorkflowAbandonRequested>(_onAbandoned, transformer: sequential());
  }

  final WorkflowRepositoryContract _workflowRepository;
  final TaskRepositoryContract _taskRepository;
  final SectionDataService _sectionDataService;

  Future<void> _onStarted(
    WorkflowStarted event,
    Emitter<WorkflowRunState> emit,
  ) async {
    emit(const WorkflowRunState.loading());

    try {
      final definition = event.definition;
      final now = DateTime.now();

      // Initialize step states for all steps
      final stepStates = <WorkflowStepState>[];
      for (var i = 0; i < definition.steps.length; i++) {
        final step = definition.steps[i];
        final items = await _loadItemsForStep(step, now);

        stepStates.add(
          WorkflowStepState(
            stepIndex: i,
            pendingEntityIds: items.map((t) => t.id).toList(),
          ),
        );
      }

      // Create new workflow instance
      final workflow = await _workflowRepository.createWorkflow(
        Workflow(
          id: '', // Repository generates v4 ID
          workflowDefinitionId: definition.id,
          status: WorkflowStatus.inProgress,
          stepStates: stepStates,
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Load items for first step using SectionDataService
      final (firstStepItems, firstStepSectionData) = await _loadStepData(
        definition.steps.first,
      );

      final progress = _calculateProgress(definition, workflow, firstStepItems);

      emit(
        WorkflowRunState.running(
          definition: definition,
          workflow: workflow,
          currentStepIndex: 0,
          currentStepItems: firstStepItems,
          currentItemIndex: 0,
          progress: progress,
          sectionDataResults: firstStepSectionData,
        ),
      );
    } catch (e, st) {
      talker.handle(e, st, 'WorkflowRunBloc failed to start workflow');
      emit(WorkflowRunState.error(error: e, stackTrace: st));
    }
  }

  Future<void> _onResumed(
    WorkflowResumed event,
    Emitter<WorkflowRunState> emit,
  ) async {
    emit(const WorkflowRunState.loading());

    try {
      final definition = event.definition;
      final workflow = event.workflow;

      final currentStep = definition.steps[workflow.currentStepIndex];
      final (items, sectionData) = await _loadStepData(currentStep);
      final progress = _calculateProgress(definition, workflow, items);

      emit(
        WorkflowRunState.running(
          definition: definition,
          workflow: workflow,
          currentStepIndex: workflow.currentStepIndex,
          currentStepItems: items,
          currentItemIndex: 0,
          progress: progress,
          sectionDataResults: sectionData,
        ),
      );
    } catch (e, st) {
      talker.handle(e, st, 'WorkflowRunBloc failed to resume workflow');
      emit(WorkflowRunState.error(error: e, stackTrace: st));
    }
  }

  Future<void> _onItemReviewed(
    ItemReviewed event,
    Emitter<WorkflowRunState> emit,
  ) async {
    final current = state;
    if (current is! WorkflowRunning) return;

    try {
      final stepIndex = current.currentStepIndex;
      final stepState = current.workflow.stepStates[stepIndex];

      // Update entity's lastReviewedAt timestamp
      await _taskRepository.updateLastReviewedAt(
        id: event.entityId,
        reviewedAt: DateTime.now(),
      );

      // Move from pending to reviewed
      final newPending = stepState.pendingEntityIds
          .where((id) => id != event.entityId)
          .toList();
      final newReviewed = [...stepState.reviewedEntityIds, event.entityId];

      final newStepState = stepState.copyWith(
        reviewedEntityIds: newReviewed,
        pendingEntityIds: newPending,
      );

      final newStepStates = [...current.workflow.stepStates];
      newStepStates[stepIndex] = newStepState;

      final updatedWorkflow = current.workflow.copyWith(
        stepStates: newStepStates,
        updatedAt: DateTime.now(),
      );

      await _workflowRepository.updateWorkflow(updatedWorkflow);

      final progress = _calculateProgress(
        current.definition,
        updatedWorkflow,
        current.currentStepItems,
      );

      emit(
        current.copyWith(
          workflow: updatedWorkflow,
          progress: progress,
        ),
      );
    } catch (e, st) {
      talker.handle(e, st, 'WorkflowRunBloc failed to mark item as reviewed');
      emit(WorkflowRunState.error(error: e, stackTrace: st));
    }
  }

  Future<void> _onItemSkipped(
    ItemSkipped event,
    Emitter<WorkflowRunState> emit,
  ) async {
    final current = state;
    if (current is! WorkflowRunning) return;

    try {
      final stepIndex = current.currentStepIndex;
      final stepState = current.workflow.stepStates[stepIndex];

      // Move from pending to skipped
      final newPending = stepState.pendingEntityIds
          .where((id) => id != event.entityId)
          .toList();
      final newSkipped = [...stepState.skippedEntityIds, event.entityId];

      final newStepState = stepState.copyWith(
        skippedEntityIds: newSkipped,
        pendingEntityIds: newPending,
      );

      final newStepStates = [...current.workflow.stepStates];
      newStepStates[stepIndex] = newStepState;

      final updatedWorkflow = current.workflow.copyWith(
        stepStates: newStepStates,
        updatedAt: DateTime.now(),
      );

      await _workflowRepository.updateWorkflow(updatedWorkflow);

      final progress = _calculateProgress(
        current.definition,
        updatedWorkflow,
        current.currentStepItems,
      );

      emit(
        current.copyWith(
          workflow: updatedWorkflow,
          progress: progress,
        ),
      );
    } catch (e, st) {
      talker.handle(e, st, 'WorkflowRunBloc failed to skip item');
      emit(WorkflowRunState.error(error: e, stackTrace: st));
    }
  }

  Future<void> _onNextItem(
    NextItemRequested event,
    Emitter<WorkflowRunState> emit,
  ) async {
    final current = state;
    if (current is! WorkflowRunning) return;

    final nextIndex = current.currentItemIndex + 1;
    if (nextIndex < current.currentStepItems.length) {
      emit(current.copyWith(currentItemIndex: nextIndex));
    }
  }

  Future<void> _onPreviousItem(
    PreviousItemRequested event,
    Emitter<WorkflowRunState> emit,
  ) async {
    final current = state;
    if (current is! WorkflowRunning) return;

    final prevIndex = current.currentItemIndex - 1;
    if (prevIndex >= 0) {
      emit(current.copyWith(currentItemIndex: prevIndex));
    }
  }

  Future<void> _onJumpToItem(
    JumpToItemRequested event,
    Emitter<WorkflowRunState> emit,
  ) async {
    final current = state;
    if (current is! WorkflowRunning) return;

    if (event.index >= 0 && event.index < current.currentStepItems.length) {
      emit(current.copyWith(currentItemIndex: event.index));
    }
  }

  Future<void> _onNextStep(
    NextStepRequested event,
    Emitter<WorkflowRunState> emit,
  ) async {
    final current = state;
    late final WorkflowDefinition definition;
    late final Workflow workflow;
    late final int currentStepIndex;

    if (current is WorkflowRunning) {
      definition = current.definition;
      workflow = current.workflow;
      currentStepIndex = current.currentStepIndex;
    } else if (current is WorkflowStepComplete) {
      definition = current.definition;
      workflow = current.workflow;
      currentStepIndex = current.completedStepIndex;
    } else {
      return;
    }

    final nextStepIndex = currentStepIndex + 1;

    if (nextStepIndex >= definition.steps.length) {
      // All steps completed
      add(const WorkflowRunEvent.completed());
      return;
    }

    try {
      emit(const WorkflowRunState.loading());

      final now = DateTime.now();
      final nextStep = definition.steps[nextStepIndex];
      final (items, sectionData) = await _loadStepData(nextStep);

      final updatedWorkflow = workflow.copyWith(
        currentStepIndex: nextStepIndex,
        updatedAt: now,
      );

      await _workflowRepository.updateWorkflow(updatedWorkflow);

      final newProgress = _calculateProgress(
        definition,
        updatedWorkflow,
        items,
      );

      emit(
        WorkflowRunState.running(
          definition: definition,
          workflow: updatedWorkflow,
          currentStepIndex: nextStepIndex,
          currentStepItems: items,
          currentItemIndex: 0,
          progress: newProgress,
          sectionDataResults: sectionData,
        ),
      );
    } catch (e, st) {
      talker.handle(e, st, 'WorkflowRunBloc failed to advance to next step');
      emit(WorkflowRunState.error(error: e, stackTrace: st));
    }
  }

  Future<void> _onPreviousStep(
    PreviousStepRequested event,
    Emitter<WorkflowRunState> emit,
  ) async {
    final current = state;
    if (current is! WorkflowRunning) return;

    final prevStepIndex = current.currentStepIndex - 1;
    if (prevStepIndex < 0) return;

    try {
      emit(const WorkflowRunState.loading());

      final now = DateTime.now();
      final prevStep = current.definition.steps[prevStepIndex];
      final (items, sectionData) = await _loadStepData(prevStep);

      final updatedWorkflow = current.workflow.copyWith(
        currentStepIndex: prevStepIndex,
        updatedAt: now,
      );

      await _workflowRepository.updateWorkflow(updatedWorkflow);

      final progress = _calculateProgress(
        current.definition,
        updatedWorkflow,
        items,
      );

      emit(
        WorkflowRunState.running(
          definition: current.definition,
          workflow: updatedWorkflow,
          currentStepIndex: prevStepIndex,
          currentStepItems: items,
          currentItemIndex: 0,
          progress: progress,
          sectionDataResults: sectionData,
        ),
      );
    } catch (e, st) {
      talker.handle(e, st, 'WorkflowRunBloc failed to go to previous step');
      emit(WorkflowRunState.error(error: e, stackTrace: st));
    }
  }

  Future<void> _onCompleted(
    WorkflowCompleteRequested event,
    Emitter<WorkflowRunState> emit,
  ) async {
    final current = state;
    late final WorkflowDefinition definition;
    late final Workflow workflow;

    if (current is WorkflowRunning) {
      definition = current.definition;
      workflow = current.workflow;
    } else if (current is WorkflowStepComplete) {
      definition = current.definition;
      workflow = current.workflow;
    } else {
      return;
    }

    try {
      final now = DateTime.now();

      final completedWorkflow = workflow.copyWith(
        status: WorkflowStatus.completed,
        completedAt: now,
        updatedAt: now,
      );

      await _workflowRepository.updateWorkflow(completedWorkflow);

      // Update definition's lastCompletedAt
      await _workflowRepository.updateWorkflowDefinition(
        definition.copyWith(lastCompletedAt: now),
      );

      final progress = _calculateProgressFromWorkflow(
        definition,
        completedWorkflow,
      );

      emit(
        WorkflowRunState.completed(
          definition: definition,
          workflow: completedWorkflow,
          progress: progress,
        ),
      );
    } catch (e, st) {
      talker.handle(e, st, 'WorkflowRunBloc failed to complete workflow');
      emit(WorkflowRunState.error(error: e, stackTrace: st));
    }
  }

  Future<void> _onAbandoned(
    WorkflowAbandonRequested event,
    Emitter<WorkflowRunState> emit,
  ) async {
    final current = state;
    if (current is! WorkflowRunning) return;

    try {
      final now = DateTime.now();

      final abandonedWorkflow = current.workflow.copyWith(
        status: WorkflowStatus.abandoned,
        updatedAt: now,
      );

      await _workflowRepository.updateWorkflow(abandonedWorkflow);

      emit(
        WorkflowRunState.abandoned(
          definition: current.definition,
          workflow: abandonedWorkflow,
        ),
      );
    } catch (e, st) {
      talker.handle(e, st, 'WorkflowRunBloc failed to abandon workflow');
      emit(WorkflowRunState.error(error: e, stackTrace: st));
    }
  }

  /// Load data for a workflow step using SectionDataService
  /// Returns a tuple of (tasks, sectionDataResults) for the step
  Future<(List<Task>, List<SectionDataResult>)> _loadStepData(
    WorkflowStep step,
  ) async {
    final sectionResults = <SectionDataResult>[];
    final allTasks = <Task>[];

    // Load data for all sections in this step
    for (final section in step.sections) {
      final result = await _fetchSectionData(section);
      if (result == null) continue;
      sectionResults.add(result);

      // Collect tasks from the result
      allTasks.addAll(result.allTasks);
    }

    return (allTasks, sectionResults);
  }

  Future<SectionDataResult?> _fetchSectionData(SectionRef section) {
    return switch (section.templateId) {
      SectionTemplateId.taskList ||
      SectionTemplateId.projectList ||
      SectionTemplateId.valueList => _sectionDataService.fetchDataList(
        DataListSectionParams.fromJson(section.params),
      ),
      SectionTemplateId.allocation => _sectionDataService.fetchAllocation(
        AllocationSectionParams.fromJson(section.params),
      ),
      SectionTemplateId.agenda => _sectionDataService.fetchAgenda(
        AgendaSectionParams.fromJson(section.params),
      ),
      _ => Future.value(null),
    };
  }

  /// Loads task items for a workflow step.
  ///
  /// Used during workflow initialization to populate step states with entity IDs.
  /// Delegates to [_loadStepData] which uses SectionDataService.
  Future<List<Task>> _loadItemsForStep(
    WorkflowStep step,
    DateTime now,
  ) async {
    final (tasks, _) = await _loadStepData(step);
    return tasks;
  }

  WorkflowProgress _calculateProgress(
    WorkflowDefinition definition,
    Workflow workflow,
    List<Task> currentItems,
  ) {
    final currentStepState = workflow.stepStates[workflow.currentStepIndex];

    final stepProgress = StepProgress(
      totalItems: currentItems.length,
      reviewedItems: currentStepState.reviewedEntityIds.length,
      skippedItems: currentStepState.skippedEntityIds.length,
      currentItemIndex: 0,
    );

    var completedSteps = 0;
    for (var i = 0; i < workflow.currentStepIndex; i++) {
      final state = workflow.stepStates[i];
      final total =
          state.reviewedEntityIds.length +
          state.skippedEntityIds.length +
          state.pendingEntityIds.length;
      final completed =
          state.reviewedEntityIds.length + state.skippedEntityIds.length;
      if (completed == total && total > 0) {
        completedSteps++;
      }
    }

    return WorkflowProgress(
      totalSteps: definition.steps.length,
      completedSteps: completedSteps,
      currentStepIndex: workflow.currentStepIndex,
      currentStepProgress: stepProgress,
    );
  }

  WorkflowProgress _calculateProgressFromWorkflow(
    WorkflowDefinition definition,
    Workflow workflow,
  ) {
    final lastStepState = workflow.stepStates.isNotEmpty
        ? workflow.stepStates.last
        : const WorkflowStepState(stepIndex: 0);

    final stepProgress = StepProgress(
      totalItems:
          lastStepState.reviewedEntityIds.length +
          lastStepState.skippedEntityIds.length +
          lastStepState.pendingEntityIds.length,
      reviewedItems: lastStepState.reviewedEntityIds.length,
      skippedItems: lastStepState.skippedEntityIds.length,
      currentItemIndex: 0,
    );

    return WorkflowProgress(
      totalSteps: definition.steps.length,
      completedSteps: definition.steps.length,
      currentStepIndex: definition.steps.length - 1,
      currentStepProgress: stepProgress,
    );
  }
}
