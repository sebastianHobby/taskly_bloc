import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/core/logging/talker_service.dart';
import 'package:taskly_bloc/presentation/shared/telemetry/operation_context_factory.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_bloc/domain/screens/runtime/entity_action_service.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_actions_state.dart';
import 'package:taskly_domain/taskly_domain.dart';
import 'package:taskly_domain/telemetry.dart';

sealed class ScreenActionsEvent {
  const ScreenActionsEvent();
}

final class ScreenActionsTaskCompletionChanged extends ScreenActionsEvent {
  const ScreenActionsTaskCompletionChanged({
    required this.taskId,
    required this.completed,
    this.occurrenceDate,
    this.originalOccurrenceDate,
    this.completer,
  });

  final String taskId;
  final bool completed;
  final DateTime? occurrenceDate;
  final DateTime? originalOccurrenceDate;
  final Completer<void>? completer;
}

final class ScreenActionsProjectCompletionChanged extends ScreenActionsEvent {
  const ScreenActionsProjectCompletionChanged({
    required this.projectId,
    required this.completed,
    this.occurrenceDate,
    this.originalOccurrenceDate,
    this.completer,
  });

  final String projectId;
  final bool completed;
  final DateTime? occurrenceDate;
  final DateTime? originalOccurrenceDate;
  final Completer<void>? completer;
}

final class ScreenActionsTaskSeriesCompleted extends ScreenActionsEvent {
  const ScreenActionsTaskSeriesCompleted({
    required this.taskId,
    this.completer,
  });

  final String taskId;
  final Completer<void>? completer;
}

final class ScreenActionsProjectSeriesCompleted extends ScreenActionsEvent {
  const ScreenActionsProjectSeriesCompleted({
    required this.projectId,
    this.completer,
  });

  final String projectId;
  final Completer<void>? completer;
}

final class ScreenActionsTaskPinnedChanged extends ScreenActionsEvent {
  const ScreenActionsTaskPinnedChanged({
    required this.taskId,
    required this.pinned,
    this.completer,
  });

  final String taskId;
  final bool pinned;
  final Completer<void>? completer;
}

final class ScreenActionsProjectPinnedChanged extends ScreenActionsEvent {
  const ScreenActionsProjectPinnedChanged({
    required this.projectId,
    required this.pinned,
    this.completer,
  });

  final String projectId;
  final bool pinned;
  final Completer<void>? completer;
}

final class ScreenActionsDeleteEntity extends ScreenActionsEvent {
  const ScreenActionsDeleteEntity({
    required this.entityType,
    required this.entityId,
    this.completer,
  });

  final EntityType entityType;
  final String entityId;
  final Completer<void>? completer;
}

final class ScreenActionsMoveTaskToProject extends ScreenActionsEvent {
  const ScreenActionsMoveTaskToProject({
    required this.taskId,
    required this.targetProjectId,
    this.completer,
  });

  final String taskId;

  /// Empty string means "no project".
  final String targetProjectId;
  final Completer<void>? completer;
}

/// Allows emit-only failure surfacing (e.g. input validation failures).
final class ScreenActionsFailureEvent extends ScreenActionsEvent {
  const ScreenActionsFailureEvent({
    required this.failureKind,
    required this.fallbackMessage,
    this.entityType,
    this.entityId,
    this.error,
  });

  final ScreenActionsFailureKind failureKind;
  final String fallbackMessage;
  final EntityType? entityType;
  final String? entityId;
  final Object? error;
}

class ScreenActionsBloc extends Bloc<ScreenActionsEvent, ScreenActionsState> {
  ScreenActionsBloc({
    required EntityActionService entityActionService,
    required AppErrorReporter errorReporter,
  }) : _entityActionService = entityActionService,
       _errorReporter = errorReporter,
       super(const ScreenActionsIdleState()) {
    on<ScreenActionsTaskCompletionChanged>(
      _onTaskCompletionChanged,
      transformer: sequential(),
    );
    on<ScreenActionsProjectCompletionChanged>(
      _onProjectCompletionChanged,
      transformer: sequential(),
    );
    on<ScreenActionsTaskSeriesCompleted>(
      _onTaskSeriesCompleted,
      transformer: sequential(),
    );
    on<ScreenActionsProjectSeriesCompleted>(
      _onProjectSeriesCompleted,
      transformer: sequential(),
    );
    on<ScreenActionsTaskPinnedChanged>(
      _onTaskPinnedChanged,
      transformer: sequential(),
    );
    on<ScreenActionsProjectPinnedChanged>(
      _onProjectPinnedChanged,
      transformer: sequential(),
    );
    on<ScreenActionsDeleteEntity>(
      _onDeleteEntity,
      transformer: sequential(),
    );
    on<ScreenActionsMoveTaskToProject>(
      _onMoveTaskToProject,
      transformer: sequential(),
    );
    on<ScreenActionsFailureEvent>(
      _onFailureEvent,
      transformer: sequential(),
    );
  }

  final EntityActionService _entityActionService;
  final AppErrorReporter _errorReporter;
  final OperationContextFactory _contextFactory =
      const OperationContextFactory();

  bool _isUnexpectedOrUnmapped(Object error) {
    if (error is AppFailure) {
      return error.reportAsUnexpected;
    }
    return true;
  }

  void _reportIfUnexpectedOrUnmapped(
    Object error,
    StackTrace stackTrace, {
    required OperationContext context,
    required String message,
  }) {
    if (!_isUnexpectedOrUnmapped(error)) return;

    _errorReporter.reportUnexpected(
      error,
      stackTrace,
      context: context,
      message: message,
    );
  }

  OperationContext _newContext({
    required String intent,
    required String operation,
    required EntityType entityType,
    required String entityId,
    Map<String, Object?> extraFields = const <String, Object?>{},
  }) {
    return _contextFactory.create(
      feature: 'usm',
      screen: 'screen_actions',
      intent: intent,
      operation: operation,
      entityType: entityType.name,
      entityId: entityId,
      extraFields: extraFields,
    );
  }

  Future<void> _onTaskCompletionChanged(
    ScreenActionsTaskCompletionChanged event,
    Emitter<ScreenActionsState> emit,
  ) async {
    final context = _newContext(
      intent: 'task_completion_changed',
      operation: event.completed
          ? 'complete_occurrence'
          : 'uncomplete_occurrence',
      entityType: EntityType.task,
      entityId: event.taskId,
      extraFields: <String, Object?>{
        'occurrenceDate': event.occurrenceDate?.toIso8601String(),
        'originalOccurrenceDate': event.originalOccurrenceDate
            ?.toIso8601String(),
      },
    );

    try {
      if (event.completed) {
        await _entityActionService.completeTask(
          event.taskId,
          occurrenceDate: event.occurrenceDate,
          originalOccurrenceDate: event.originalOccurrenceDate,
          context: context,
        );
      } else {
        await _entityActionService.uncompleteTask(
          event.taskId,
          occurrenceDate: event.occurrenceDate,
          context: context,
        );
      }
      event.completer?.complete();
    } catch (e, st) {
      _reportIfUnexpectedOrUnmapped(
        e,
        st,
        context: context,
        message: 'Task completion change failed',
      );

      talker.handle(e, st, '[ScreenActionsBloc] task completion failed');

      final shouldShowSnackBar = !_isUnexpectedOrUnmapped(e);
      emit(
        ScreenActionsFailureState(
          failureKind: ScreenActionsFailureKind.completionFailed,
          fallbackMessage: 'Task update failed',
          shouldShowSnackBar: shouldShowSnackBar,
          entityType: EntityType.task,
          entityId: event.taskId,
          error: e,
        ),
      );
      event.completer?.completeError(e, st);
      emit(const ScreenActionsIdleState());
    }
  }

  Future<void> _onProjectCompletionChanged(
    ScreenActionsProjectCompletionChanged event,
    Emitter<ScreenActionsState> emit,
  ) async {
    final context = _newContext(
      intent: 'project_completion_changed',
      operation: event.completed
          ? 'complete_occurrence'
          : 'uncomplete_occurrence',
      entityType: EntityType.project,
      entityId: event.projectId,
      extraFields: <String, Object?>{
        'occurrenceDate': event.occurrenceDate?.toIso8601String(),
        'originalOccurrenceDate': event.originalOccurrenceDate
            ?.toIso8601String(),
      },
    );

    try {
      if (event.completed) {
        await _entityActionService.completeProject(
          event.projectId,
          occurrenceDate: event.occurrenceDate,
          originalOccurrenceDate: event.originalOccurrenceDate,
          context: context,
        );
      } else {
        await _entityActionService.uncompleteProject(
          event.projectId,
          occurrenceDate: event.occurrenceDate,
          context: context,
        );
      }
      event.completer?.complete();
    } catch (e, st) {
      _reportIfUnexpectedOrUnmapped(
        e,
        st,
        context: context,
        message: 'Project completion change failed',
      );

      talker.handle(e, st, '[ScreenActionsBloc] project completion failed');

      final shouldShowSnackBar = !_isUnexpectedOrUnmapped(e);
      emit(
        ScreenActionsFailureState(
          failureKind: ScreenActionsFailureKind.completionFailed,
          fallbackMessage: 'Project update failed',
          shouldShowSnackBar: shouldShowSnackBar,
          entityType: EntityType.project,
          entityId: event.projectId,
          error: e,
        ),
      );
      event.completer?.completeError(e, st);
      emit(const ScreenActionsIdleState());
    }
  }

  Future<void> _onTaskSeriesCompleted(
    ScreenActionsTaskSeriesCompleted event,
    Emitter<ScreenActionsState> emit,
  ) async {
    final context = _newContext(
      intent: 'task_complete_series',
      operation: 'complete_series',
      entityType: EntityType.task,
      entityId: event.taskId,
    );

    try {
      await _entityActionService.completeTaskSeries(
        event.taskId,
        context: context,
      );
      event.completer?.complete();
    } catch (e, st) {
      _reportIfUnexpectedOrUnmapped(
        e,
        st,
        context: context,
        message: 'Task series completion failed',
      );

      talker.handle(e, st, '[ScreenActionsBloc] task series complete failed');

      final shouldShowSnackBar = !_isUnexpectedOrUnmapped(e);
      emit(
        ScreenActionsFailureState(
          failureKind: ScreenActionsFailureKind.completionFailed,
          fallbackMessage: 'Series completion failed',
          shouldShowSnackBar: shouldShowSnackBar,
          entityType: EntityType.task,
          entityId: event.taskId,
          error: e,
        ),
      );
      event.completer?.completeError(e, st);
      emit(const ScreenActionsIdleState());
    }
  }

  Future<void> _onProjectSeriesCompleted(
    ScreenActionsProjectSeriesCompleted event,
    Emitter<ScreenActionsState> emit,
  ) async {
    final context = _newContext(
      intent: 'project_complete_series',
      operation: 'complete_series',
      entityType: EntityType.project,
      entityId: event.projectId,
    );

    try {
      await _entityActionService.completeProjectSeries(
        event.projectId,
        context: context,
      );
      event.completer?.complete();
    } catch (e, st) {
      _reportIfUnexpectedOrUnmapped(
        e,
        st,
        context: context,
        message: 'Project series completion failed',
      );

      talker.handle(
        e,
        st,
        '[ScreenActionsBloc] project series complete failed',
      );

      final shouldShowSnackBar = !_isUnexpectedOrUnmapped(e);
      emit(
        ScreenActionsFailureState(
          failureKind: ScreenActionsFailureKind.completionFailed,
          fallbackMessage: 'Series completion failed',
          shouldShowSnackBar: shouldShowSnackBar,
          entityType: EntityType.project,
          entityId: event.projectId,
          error: e,
        ),
      );
      event.completer?.completeError(e, st);
      emit(const ScreenActionsIdleState());
    }
  }

  Future<void> _onTaskPinnedChanged(
    ScreenActionsTaskPinnedChanged event,
    Emitter<ScreenActionsState> emit,
  ) async {
    final context = _newContext(
      intent: 'task_pinned_changed',
      operation: event.pinned ? 'pin' : 'unpin',
      entityType: EntityType.task,
      entityId: event.taskId,
      extraFields: <String, Object?>{'pinned': event.pinned},
    );

    try {
      if (event.pinned) {
        await _entityActionService.pinTask(event.taskId, context: context);
      } else {
        await _entityActionService.unpinTask(event.taskId, context: context);
      }
      event.completer?.complete();
    } catch (e, st) {
      _reportIfUnexpectedOrUnmapped(
        e,
        st,
        context: context,
        message: 'Task pin change failed',
      );

      talker.handle(e, st, '[ScreenActionsBloc] task pin failed');

      final shouldShowSnackBar = !_isUnexpectedOrUnmapped(e);
      emit(
        ScreenActionsFailureState(
          failureKind: ScreenActionsFailureKind.pinFailed,
          fallbackMessage: 'Task pin failed',
          shouldShowSnackBar: shouldShowSnackBar,
          entityType: EntityType.task,
          entityId: event.taskId,
          error: e,
        ),
      );
      event.completer?.completeError(e, st);
      emit(const ScreenActionsIdleState());
    }
  }

  Future<void> _onProjectPinnedChanged(
    ScreenActionsProjectPinnedChanged event,
    Emitter<ScreenActionsState> emit,
  ) async {
    final context = _newContext(
      intent: 'project_pinned_changed',
      operation: event.pinned ? 'pin' : 'unpin',
      entityType: EntityType.project,
      entityId: event.projectId,
      extraFields: <String, Object?>{'pinned': event.pinned},
    );

    try {
      if (event.pinned) {
        await _entityActionService.pinProject(
          event.projectId,
          context: context,
        );
      } else {
        await _entityActionService.unpinProject(
          event.projectId,
          context: context,
        );
      }
      event.completer?.complete();
    } catch (e, st) {
      _reportIfUnexpectedOrUnmapped(
        e,
        st,
        context: context,
        message: 'Project pin change failed',
      );

      talker.handle(e, st, '[ScreenActionsBloc] project pin failed');

      final shouldShowSnackBar = !_isUnexpectedOrUnmapped(e);
      emit(
        ScreenActionsFailureState(
          failureKind: ScreenActionsFailureKind.pinFailed,
          fallbackMessage: 'Project pin failed',
          shouldShowSnackBar: shouldShowSnackBar,
          entityType: EntityType.project,
          entityId: event.projectId,
          error: e,
        ),
      );
      event.completer?.completeError(e, st);
      emit(const ScreenActionsIdleState());
    }
  }

  Future<void> _onDeleteEntity(
    ScreenActionsDeleteEntity event,
    Emitter<ScreenActionsState> emit,
  ) async {
    final context = _contextFactory.create(
      feature: 'usm',
      screen: 'screen_actions',
      intent: 'delete_entity',
      operation: 'delete',
      entityType: event.entityType.name,
      entityId: event.entityId,
    );

    try {
      await _entityActionService.performAction(
        entityId: event.entityId,
        entityType: event.entityType,
        action: EntityActionType.delete,
        context: context,
      );
      event.completer?.complete();
    } catch (e, st) {
      _reportIfUnexpectedOrUnmapped(
        e,
        st,
        context: context,
        message: 'Delete entity failed',
      );

      talker.handle(e, st, '[ScreenActionsBloc] delete failed');

      final shouldShowSnackBar = !_isUnexpectedOrUnmapped(e);
      emit(
        ScreenActionsFailureState(
          failureKind: ScreenActionsFailureKind.deleteFailed,
          fallbackMessage: 'Delete failed',
          shouldShowSnackBar: shouldShowSnackBar,
          entityType: event.entityType,
          entityId: event.entityId,
          error: e,
        ),
      );
      event.completer?.completeError(e, st);
      emit(const ScreenActionsIdleState());
    }
  }

  Future<void> _onMoveTaskToProject(
    ScreenActionsMoveTaskToProject event,
    Emitter<ScreenActionsState> emit,
  ) async {
    final targetProjectId = event.targetProjectId.isEmpty
        ? null
        : event.targetProjectId;
    final context = _newContext(
      intent: 'move_task_to_project',
      operation: 'move',
      entityType: EntityType.task,
      entityId: event.taskId,
      extraFields: <String, Object?>{'targetProjectId': targetProjectId},
    );

    try {
      await _entityActionService.moveTask(
        event.taskId,
        targetProjectId,
        context: context,
      );
      event.completer?.complete();
    } catch (e, st) {
      _reportIfUnexpectedOrUnmapped(
        e,
        st,
        context: context,
        message: 'Move task failed',
      );

      talker.handle(e, st, '[ScreenActionsBloc] move failed');

      final shouldShowSnackBar = !_isUnexpectedOrUnmapped(e);
      emit(
        ScreenActionsFailureState(
          failureKind: ScreenActionsFailureKind.moveFailed,
          fallbackMessage: 'Move failed',
          shouldShowSnackBar: shouldShowSnackBar,
          entityType: EntityType.task,
          entityId: event.taskId,
          error: e,
        ),
      );
      event.completer?.completeError(e, st);
      emit(const ScreenActionsIdleState());
    }
  }

  Future<void> _onFailureEvent(
    ScreenActionsFailureEvent event,
    Emitter<ScreenActionsState> emit,
  ) async {
    emit(
      ScreenActionsFailureState(
        failureKind: event.failureKind,
        fallbackMessage: event.fallbackMessage,
        shouldShowSnackBar: true,
        entityType: event.entityType,
        entityId: event.entityId,
        error: event.error,
      ),
    );

    // Reset so the next failure is delivered.
    emit(const ScreenActionsIdleState());
  }
}
