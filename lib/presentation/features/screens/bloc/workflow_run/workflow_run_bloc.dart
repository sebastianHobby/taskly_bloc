import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/core/utils/app_logger.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/screens/entity_selector.dart';
import 'package:taskly_bloc/domain/models/screens/workflow_item.dart';
import 'package:taskly_bloc/domain/models/screens/workflow_progress.dart';
import 'package:taskly_bloc/domain/models/settings.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/models/workflow/problem_acknowledgment.dart';
import 'package:taskly_bloc/domain/contracts/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';
import 'package:taskly_bloc/domain/repositories/problem_acknowledgments_repository.dart';
import 'package:taskly_bloc/domain/services/screens/screen_query_builder.dart';
import 'package:taskly_bloc/domain/services/screens/support_block_computer.dart';
import 'package:taskly_bloc/domain/services/workflow/problem_detector.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';

part 'workflow_run_event.dart';
part 'workflow_run_state.dart';
part 'workflow_run_bloc.freezed.dart';

/// BLoC for managing workflow execution with progress tracking
class WorkflowRunBloc extends Bloc<WorkflowRunEvent, WorkflowRunState<Task>> {
  WorkflowRunBloc({
    required WorkflowScreen screen,
    required TaskRepositoryContract taskRepository,
    required SettingsRepositoryContract settingsRepository,
    required ProblemAcknowledgmentsRepository problemAcknowledgmentsRepository,
    required ProblemDetector problemDetector,
    required ScreenQueryBuilder queryBuilder,
    required SupportBlockComputer supportBlockComputer,
  }) : _screen = screen,
       _taskRepository = taskRepository,
       _settingsRepository = settingsRepository,
       _problemAcknowledgmentsRepository = problemAcknowledgmentsRepository,
       _problemDetector = problemDetector,
       _queryBuilder = queryBuilder,
       _supportBlockComputer = supportBlockComputer,
       super(const WorkflowRunState()) {
    on<_Started>(_onStarted);
    on<_ItemMarkedReviewed>(_onItemMarkedReviewed);
    on<_ItemSkipped>(_onItemSkipped);
    on<_NextItemRequested>(_onNextItemRequested);
    on<_PreviousItemRequested>(_onPreviousItemRequested);
    on<_ItemJumpedTo>(_onItemJumpedTo);
    on<_WorkflowCompleted>(_onWorkflowCompleted);
    on<_ProblemAcknowledged>(_onProblemAcknowledged);
    on<_ProblemSnoozed>(_onProblemSnoozed);
    on<_ProblemDismissed>(_onProblemDismissed);
  }

  final WorkflowScreen _screen;
  final TaskRepositoryContract _taskRepository;
  final SettingsRepositoryContract _settingsRepository;
  final ProblemAcknowledgmentsRepository _problemAcknowledgmentsRepository;
  final ProblemDetector _problemDetector;
  final ScreenQueryBuilder _queryBuilder;
  final SupportBlockComputer _supportBlockComputer;
  final _logger = AppLogger.forBloc('WorkflowRun');

  static const _defaultSnoozeDays = 7;

  Future<void> _onStarted(
    _Started event,
    Emitter<WorkflowRunState<Task>> emit,
  ) async {
    emit(state.copyWith(status: WorkflowRunStatus.loading));

    try {
      final now = DateTime.now();

      // Build query from screen definition
      final query = _queryBuilder.buildTaskQuery(
        selector: _screen.selector,
        display: _screen.display,
        now: now,
      );

      // Fetch tasks using watchAll and take first emission
      final tasks = await _taskRepository.watchAll(query).first;

      final softGatesSettings = await _settingsRepository
          .loadSoftGatesSettings();

      final urgentTasksAllOpen = await _loadUrgentTasksAllOpen(
        now: now,
        settings: softGatesSettings,
      );

      // Wrap tasks in WorkflowItem with proper type annotation
      final items = tasks
          .map<WorkflowItem<Task>>(
            (Task task) => WorkflowItem<Task>(
              entity: task,
              entityId: task.id,
            ),
          )
          .toList();

      // Calculate initial progress with explicit type parameter
      final progress = _supportBlockComputer.computeWorkflowProgress<Task>(
        items,
      );

      final detectedProblems = _problemDetector.detectForWorkflowRun(
        workflowTasks: tasks,
        urgentTasksAllOpen: urgentTasksAllOpen,
        settings: softGatesSettings,
        now: now,
      );

      final problems = await _filterAcknowledgedProblems(
        detectedProblems,
        now: now,
      );

      emit(
        state.copyWith(
          status: WorkflowRunStatus.running,
          items: items,
          currentIndex: 0,
          progress: progress,
          problems: problems,
        ),
      );
    } catch (e, st) {
      _logger.error('Failed to start workflow', e, st);
      emit(
        state.copyWith(
          status: WorkflowRunStatus.error,
          error: e,
          stackTrace: st,
        ),
      );
    }
  }

  Future<List<Task>> _loadUrgentTasksAllOpen({
    required DateTime now,
    required SoftGatesSettings settings,
  }) async {
    final latestUrgent = now.add(
      Duration(days: settings.urgentDeadlineWithinDays),
    );

    final urgentQuery = TaskQuery(
      filter: QueryFilter<TaskPredicate>(
        shared: [
          const TaskBoolPredicate(
            field: TaskBoolField.completed,
            operator: BoolOperator.isFalse,
          ),
          const TaskDatePredicate(
            field: TaskDateField.deadlineDate,
            operator: DateOperator.isNotNull,
          ),
          TaskDatePredicate(
            field: TaskDateField.deadlineDate,
            operator: DateOperator.onOrBefore,
            date: latestUrgent,
          ),
        ],
      ),
    );

    return _taskRepository.watchAll(urgentQuery).first;
  }

  Future<List<DetectedProblem>> _filterAcknowledgedProblems(
    List<DetectedProblem> problems, {
    required DateTime now,
  }) async {
    final results = <DetectedProblem>[];

    for (final problem in problems) {
      final acks = await _problemAcknowledgmentsRepository
          .watchAcknowledgmentsForEntity(
            entityType: problem.entityType,
            entityId: problem.entityId,
          )
          .first;

      ProblemAcknowledgment? matching;
      for (final ack in acks) {
        if (ack.problemType == problem.type) {
          matching = ack;
          break;
        }
      }

      if (matching == null) {
        results.add(problem);
        continue;
      }

      final snoozeUntil = matching.snoozeUntil;
      if (snoozeUntil != null && snoozeUntil.isAfter(now)) {
        continue;
      }

      // Any explicit acknowledgment suppresses the problem until it is no
      // longer detected (or until a future change adds re-show rules).
    }

    return results;
  }

  Future<void> _onProblemAcknowledged(
    _ProblemAcknowledged event,
    Emitter<WorkflowRunState<Task>> emit,
  ) async {
    await _problemAcknowledgmentsRepository.acknowledge(
      problemType: event.problemType,
      entityType: event.entityType,
      entityId: event.entityId,
      acknowledgedAt: DateTime.now(),
    );

    await _recomputeProblems(emit);
  }

  Future<void> _onProblemSnoozed(
    _ProblemSnoozed event,
    Emitter<WorkflowRunState<Task>> emit,
  ) async {
    final now = DateTime.now();
    await _problemAcknowledgmentsRepository.acknowledge(
      problemType: event.problemType,
      entityType: event.entityType,
      entityId: event.entityId,
      resolutionAction: ResolutionAction.snoozed,
      snoozeUntil: now.add(const Duration(days: _defaultSnoozeDays)),
      acknowledgedAt: now,
    );

    await _recomputeProblems(emit);
  }

  Future<void> _onProblemDismissed(
    _ProblemDismissed event,
    Emitter<WorkflowRunState<Task>> emit,
  ) async {
    await _problemAcknowledgmentsRepository.acknowledge(
      problemType: event.problemType,
      entityType: event.entityType,
      entityId: event.entityId,
      resolutionAction: ResolutionAction.dismissed,
      acknowledgedAt: DateTime.now(),
    );

    await _recomputeProblems(emit);
  }

  Future<void> _recomputeProblems(
    Emitter<WorkflowRunState<Task>> emit,
  ) async {
    if (state.status != WorkflowRunStatus.running) return;
    if (state.items.isEmpty) {
      emit(state.copyWith(problems: const <DetectedProblem>[]));
      return;
    }

    final now = DateTime.now();
    final softGatesSettings = await _settingsRepository.loadSoftGatesSettings();
    final workflowTasks = state.items
        .map((i) => i.entity)
        .toList(growable: false);
    final urgentTasksAllOpen = await _loadUrgentTasksAllOpen(
      now: now,
      settings: softGatesSettings,
    );
    final detectedProblems = _problemDetector.detectForWorkflowRun(
      workflowTasks: workflowTasks,
      urgentTasksAllOpen: urgentTasksAllOpen,
      settings: softGatesSettings,
      now: now,
    );
    final problems = await _filterAcknowledgedProblems(
      detectedProblems,
      now: now,
    );
    emit(state.copyWith(problems: problems));
  }

  Future<void> _onItemMarkedReviewed(
    _ItemMarkedReviewed event,
    Emitter<WorkflowRunState<Task>> emit,
  ) async {
    final updatedItems = state.items.map((item) {
      if (item.entityId == event.entityId) {
        return item.copyWith(
          status: WorkflowItemStatus.completed,
          lastReviewedAt: DateTime.now(),
          notes: event.notes,
        );
      }
      return item;
    }).toList();

    final progress = _supportBlockComputer.computeWorkflowProgress(
      updatedItems,
    );

    emit(
      state.copyWith(
        items: updatedItems,
        progress: progress,
      ),
    );
  }

  Future<void> _onItemSkipped(
    _ItemSkipped event,
    Emitter<WorkflowRunState<Task>> emit,
  ) async {
    final updatedItems = state.items.map((item) {
      if (item.entityId == event.entityId) {
        return item.copyWith(
          status: WorkflowItemStatus.skipped,
          notes: event.reason,
        );
      }
      return item;
    }).toList();

    final progress = _supportBlockComputer.computeWorkflowProgress(
      updatedItems,
    );

    emit(
      state.copyWith(
        items: updatedItems,
        progress: progress,
      ),
    );
  }

  Future<void> _onNextItemRequested(
    _NextItemRequested event,
    Emitter<WorkflowRunState<Task>> emit,
  ) async {
    if (state.hasNext) {
      emit(state.copyWith(currentIndex: state.currentIndex + 1));
    }
  }

  Future<void> _onPreviousItemRequested(
    _PreviousItemRequested event,
    Emitter<WorkflowRunState<Task>> emit,
  ) async {
    if (state.hasPrevious) {
      emit(state.copyWith(currentIndex: state.currentIndex - 1));
    }
  }

  Future<void> _onItemJumpedTo(
    _ItemJumpedTo event,
    Emitter<WorkflowRunState<Task>> emit,
  ) async {
    if (event.index >= 0 && event.index < state.items.length) {
      emit(state.copyWith(currentIndex: event.index));
    }
  }

  Future<void> _onWorkflowCompleted(
    _WorkflowCompleted event,
    Emitter<WorkflowRunState<Task>> emit,
  ) async {
    emit(state.copyWith(status: WorkflowRunStatus.completed));
  }
}
