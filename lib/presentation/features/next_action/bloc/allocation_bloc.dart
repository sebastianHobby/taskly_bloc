import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/core/utils/friendly_error_message.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/extensions/task_value_inheritance.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/models/priority/allocation_result.dart';
import 'package:taskly_bloc/domain/services/allocation/allocation_orchestrator.dart';

part 'allocation_event.dart';
part 'allocation_state.dart';
part 'allocation_bloc.freezed.dart';

/// Bloc for managing task allocation and focus list
class AllocationBloc extends Bloc<AllocationEvent, AllocationState> {
  AllocationBloc({
    required AllocationOrchestrator orchestrator,
  }) : _orchestrator = orchestrator,
       super(const AllocationState()) {
    on<AllocationSubscriptionRequested>(_onSubscriptionRequested);
    on<AllocationTaskPinned>(_onTaskPinned);
    on<AllocationTaskUnpinned>(_onTaskUnpinned);
    on<AllocationRefreshRequested>(_onRefreshRequested);
    on<AllocationExcludedDismissed>(_onExcludedDismissed);
    on<AllocationBulkTasksPinned>(_onBulkTasksPinned);
    on<AllocationTaskCompletionToggled>(_onTaskCompletionToggled);
  }

  final AllocationOrchestrator _orchestrator;

  Future<void> _onSubscriptionRequested(
    AllocationSubscriptionRequested event,
    Emitter<AllocationState> emit,
  ) async {
    emit(state.copyWith(status: AllocationStatus.loading));

    await emit.forEach<AllocationResult>(
      _orchestrator.watchAllocation(),
      onData: _mapResultToState,
      onError: (error, stackTrace) {
        talker.handle(error, stackTrace, 'AllocationBloc subscription error');
        return state.copyWith(
          status: AllocationStatus.failure,
          errorMessage: friendlyErrorMessage(error),
        );
      },
    );
  }

  AllocationState _mapResultToState(AllocationResult result) {
    // Separate pinned from regular tasks by checking the systemLabelType
    // This is more reliable than checking by ID since label IDs are UUIDs
    final pinned = result.allocatedTasks
        .where(
          (t) => t.task.labels.any(
            (l) => l.systemLabelType == SystemLabelType.pinned,
          ),
        )
        .toList();

    final regular = result.allocatedTasks
        .where(
          (t) => !t.task.labels.any(
            (l) => l.systemLabelType == SystemLabelType.pinned,
          ),
        )
        .toList();

    // Group regular tasks by value
    final groupedByValue = <String, List<AllocatedTask>>{};
    for (final task in regular) {
      groupedByValue.putIfAbsent(task.qualifyingValueId, () => []).add(task);
    }

    // Create allocation groups with metadata
    final groups = <String, AllocationGroup>{};
    for (final entry in groupedByValue.entries) {
      final valueId = entry.key;
      final tasks = entry.value;
      final categoryWeight = result.reasoning.categoryWeights[valueId] ?? 0.0;
      final categoryQuota = result.reasoning.categoryAllocations[valueId] ?? 0;

      // Get value name from first task
      final valueName = tasks.first.task
          .getEffectiveValues()
          .firstWhere(
            (v) => v.id == valueId,
            orElse: () => throw StateError('Value not found'),
          )
          .name;

      groups[valueId] = AllocationGroup(
        valueId: valueId,
        valueName: valueName,
        tasks: tasks,
        weight: categoryWeight,
        quota: categoryQuota,
      );
    }

    // Extract excluded urgent tasks
    final excludedUrgent = result.excludedTasks.where((et) {
      if (et.task.deadlineDate == null) return false;
      final daysUntilDeadline = et.task.deadlineDate!
          .difference(DateTime.now())
          .inDays;
      // Default to 3 days if preferences not loaded yet
      return daysUntilDeadline <= 3;
    }).toList();

    // Check if we should show excluded warning
    final showWarning = result.warnings.any(
      (w) => w.type == WarningType.excludedUrgentTask,
    );

    return state.copyWith(
      status: AllocationStatus.success,
      pinnedTasks: pinned,
      tasksByValue: groups,
      excludedCount: result.excludedTasks.length,
      excludedUrgent: excludedUrgent,
      reasoning: result.reasoning,
      lastRefreshed: DateTime.now(),
      showExcludedWarning: showWarning,
      errorMessage: null,
    );
  }

  Future<void> _onTaskPinned(
    AllocationTaskPinned event,
    Emitter<AllocationState> emit,
  ) async {
    try {
      await _orchestrator.pinTask(event.taskId);
    } catch (e, stackTrace) {
      talker.handle(e, stackTrace, 'AllocationBloc failed to pin task');
      emit(
        state.copyWith(
          status: AllocationStatus.failure,
          errorMessage: friendlyErrorMessage(e),
        ),
      );
    }
  }

  Future<void> _onTaskUnpinned(
    AllocationTaskUnpinned event,
    Emitter<AllocationState> emit,
  ) async {
    try {
      await _orchestrator.unpinTask(event.taskId);
    } catch (e, stackTrace) {
      talker.handle(e, stackTrace, 'AllocationBloc failed to unpin task');
      emit(
        state.copyWith(
          status: AllocationStatus.failure,
          errorMessage: friendlyErrorMessage(e),
        ),
      );
    }
  }

  Future<void> _onRefreshRequested(
    AllocationRefreshRequested event,
    Emitter<AllocationState> emit,
  ) async {
    // Refresh is handled by stream reactivity
    // This is a no-op but kept for future manual refresh logic
  }

  Future<void> _onExcludedDismissed(
    AllocationExcludedDismissed event,
    Emitter<AllocationState> emit,
  ) async {
    emit(state.copyWith(showExcludedWarning: false));
  }

  Future<void> _onBulkTasksPinned(
    AllocationBulkTasksPinned event,
    Emitter<AllocationState> emit,
  ) async {
    try {
      for (final taskId in event.taskIds) {
        await _orchestrator.pinTask(taskId);
      }
    } catch (e, stackTrace) {
      talker.handle(e, stackTrace, 'AllocationBloc failed to pin tasks');
      emit(
        state.copyWith(
          status: AllocationStatus.failure,
          errorMessage: friendlyErrorMessage(e),
        ),
      );
    }
  }

  Future<void> _onTaskCompletionToggled(
    AllocationTaskCompletionToggled event,
    Emitter<AllocationState> emit,
  ) async {
    try {
      await _orchestrator.toggleTaskCompletion(event.taskId);
    } catch (e, stackTrace) {
      talker.handle(
        e,
        stackTrace,
        'AllocationBloc failed to toggle completion',
      );
      emit(
        state.copyWith(
          status: AllocationStatus.failure,
          errorMessage: friendlyErrorMessage(e),
        ),
      );
    }
  }
}
