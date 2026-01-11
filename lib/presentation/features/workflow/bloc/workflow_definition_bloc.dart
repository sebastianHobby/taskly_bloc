import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/core/logging/talker_service.dart';
import 'package:taskly_bloc/domain/interfaces/workflow_repository_contract.dart';
import 'package:taskly_bloc/domain/workflow/model/workflow.dart';
import 'package:taskly_bloc/domain/workflow/model/workflow_definition.dart';

part 'workflow_definition_bloc.freezed.dart';

// =============================================================================
// Events
// =============================================================================

@freezed
sealed class WorkflowDefinitionEvent with _$WorkflowDefinitionEvent {
  /// Start watching workflow definitions for the user
  const factory WorkflowDefinitionEvent.subscriptionRequested() =
      WorkflowDefinitionSubscriptionRequested;

  /// Create a new workflow definition
  const factory WorkflowDefinitionEvent.definitionCreated({
    required WorkflowDefinition definition,
  }) = WorkflowDefinitionCreated;

  /// Update an existing workflow definition
  const factory WorkflowDefinitionEvent.definitionUpdated({
    required WorkflowDefinition definition,
  }) = WorkflowDefinitionUpdated;

  /// Delete a workflow definition
  const factory WorkflowDefinitionEvent.definitionDeleted({
    required String definitionId,
  }) = WorkflowDefinitionDeleted;

  /// Toggle active status of a workflow definition
  const factory WorkflowDefinitionEvent.activeToggled({
    required WorkflowDefinition definition,
  }) = WorkflowDefinitionActiveToggled;
}

// =============================================================================
// States
// =============================================================================

@freezed
sealed class WorkflowDefinitionState with _$WorkflowDefinitionState {
  const factory WorkflowDefinitionState.initial() = WorkflowDefinitionInitial;
  const factory WorkflowDefinitionState.loading() = WorkflowDefinitionLoading;

  const factory WorkflowDefinitionState.loaded({
    required List<WorkflowDefinition> definitions,
    required List<Workflow> activeWorkflows,
  }) = WorkflowDefinitionLoaded;

  const factory WorkflowDefinitionState.error({
    required Object error,
    required StackTrace stackTrace,
  }) = WorkflowDefinitionError;
}

// =============================================================================
// BLoC
// =============================================================================

/// BLoC for managing workflow definitions.
///
/// Provides listing of workflow definitions and active workflow instances.
/// Uses WorkflowRepositoryContract for data operations.
class WorkflowDefinitionBloc
    extends Bloc<WorkflowDefinitionEvent, WorkflowDefinitionState> {
  WorkflowDefinitionBloc({
    required WorkflowRepositoryContract workflowRepository,
  }) : _workflowRepository = workflowRepository,
       super(const WorkflowDefinitionState.initial()) {
    on<WorkflowDefinitionSubscriptionRequested>(
      _onSubscriptionRequested,
      transformer: restartable(),
    );
    on<WorkflowDefinitionCreated>(
      _onDefinitionCreated,
      transformer: droppable(),
    );
    on<WorkflowDefinitionUpdated>(
      _onDefinitionUpdated,
      transformer: droppable(),
    );
    on<WorkflowDefinitionDeleted>(
      _onDefinitionDeleted,
      transformer: droppable(),
    );
    on<WorkflowDefinitionActiveToggled>(
      _onActiveToggled,
      transformer: restartable(),
    );
  }

  final WorkflowRepositoryContract _workflowRepository;

  Future<void> _onSubscriptionRequested(
    WorkflowDefinitionSubscriptionRequested event,
    Emitter<WorkflowDefinitionState> emit,
  ) async {
    emit(const WorkflowDefinitionState.loading());

    try {
      // Combine streams for definitions and active workflows
      await emit.forEach<(List<WorkflowDefinition>, List<Workflow>)>(
        _combinedStream(),
        onData: (data) {
          final (definitions, activeWorkflows) = data;
          return WorkflowDefinitionState.loaded(
            definitions: definitions,
            activeWorkflows: activeWorkflows,
          );
        },
        onError: (error, stackTrace) {
          talker.handle(
            error,
            stackTrace,
            '[WorkflowDefinitionBloc] Stream error',
          );
          return WorkflowDefinitionState.error(
            error: error,
            stackTrace: stackTrace,
          );
        },
      );
    } catch (e, st) {
      talker.handle(e, st, '[WorkflowDefinitionBloc] Error in subscription');
      emit(WorkflowDefinitionState.error(error: e, stackTrace: st));
    }
  }

  Stream<(List<WorkflowDefinition>, List<Workflow>)> _combinedStream() {
    // Watch both definitions and active workflows
    final definitionsStream = _workflowRepository.watchWorkflowDefinitions();
    final activeWorkflowsStream = _workflowRepository.watchActiveWorkflows();

    // Combine using latest-snapshot semantics.
    return Rx.combineLatest2(
      definitionsStream,
      activeWorkflowsStream,
      (definitions, workflows) => (definitions, workflows),
    );
  }

  Future<void> _onDefinitionCreated(
    WorkflowDefinitionCreated event,
    Emitter<WorkflowDefinitionState> emit,
  ) async {
    try {
      await _workflowRepository.createWorkflowDefinition(event.definition);
      talker.blocLog(
        'WorkflowDefinitionBloc',
        'Created workflow definition: ${event.definition.name}',
      );
      // Stream will update state automatically
    } catch (e, st) {
      talker.handle(
        e,
        st,
        '[WorkflowDefinitionBloc] Error creating definition',
      );
      emit(WorkflowDefinitionState.error(error: e, stackTrace: st));
    }
  }

  Future<void> _onDefinitionUpdated(
    WorkflowDefinitionUpdated event,
    Emitter<WorkflowDefinitionState> emit,
  ) async {
    try {
      await _workflowRepository.updateWorkflowDefinition(event.definition);
      talker.blocLog(
        'WorkflowDefinitionBloc',
        'Updated workflow definition: ${event.definition.name}',
      );
      // Stream will update state automatically
    } catch (e, st) {
      talker.handle(
        e,
        st,
        '[WorkflowDefinitionBloc] Error updating definition',
      );
      emit(WorkflowDefinitionState.error(error: e, stackTrace: st));
    }
  }

  Future<void> _onDefinitionDeleted(
    WorkflowDefinitionDeleted event,
    Emitter<WorkflowDefinitionState> emit,
  ) async {
    try {
      await _workflowRepository.deleteWorkflowDefinition(event.definitionId);
      talker.blocLog(
        'WorkflowDefinitionBloc',
        'Deleted workflow definition: ${event.definitionId}',
      );
      // Stream will update state automatically
    } catch (e, st) {
      talker.handle(
        e,
        st,
        '[WorkflowDefinitionBloc] Error deleting definition',
      );
      emit(WorkflowDefinitionState.error(error: e, stackTrace: st));
    }
  }

  Future<void> _onActiveToggled(
    WorkflowDefinitionActiveToggled event,
    Emitter<WorkflowDefinitionState> emit,
  ) async {
    try {
      final updated = event.definition.copyWith(
        isActive: !event.definition.isActive,
        updatedAt: DateTime.now(),
      );
      await _workflowRepository.updateWorkflowDefinition(updated);
      talker.blocLog(
        'WorkflowDefinitionBloc',
        'Toggled active status for: ${event.definition.name} -> ${updated.isActive}',
      );
      // Stream will update state automatically
    } catch (e, st) {
      talker.handle(
        e,
        st,
        '[WorkflowDefinitionBloc] Error toggling active status',
      );
      emit(WorkflowDefinitionState.error(error: e, stackTrace: st));
    }
  }
}
