import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/logging/talker_service.dart';
import 'package:taskly_bloc/domain/analytics/model/entity_type.dart';
import 'package:taskly_bloc/domain/screens/runtime/entity_action_service.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_actions_state.dart';

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
  }) : _entityActionService = entityActionService,
       super(const ScreenActionsIdleState()) {
    on<ScreenActionsTaskCompletionChanged>(
      _onTaskCompletionChanged,
      transformer: sequential(),
    );
    on<ScreenActionsProjectCompletionChanged>(
      _onProjectCompletionChanged,
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

  Future<void> _onTaskCompletionChanged(
    ScreenActionsTaskCompletionChanged event,
    Emitter<ScreenActionsState> emit,
  ) async {
    try {
      if (event.completed) {
        await _entityActionService.completeTask(
          event.taskId,
          occurrenceDate: event.occurrenceDate,
          originalOccurrenceDate: event.originalOccurrenceDate,
        );
      } else {
        await _entityActionService.uncompleteTask(
          event.taskId,
          occurrenceDate: event.occurrenceDate,
        );
      }
      event.completer?.complete();
    } catch (e, st) {
      talker.handle(e, st, '[ScreenActionsBloc] task completion failed');
      emit(
        ScreenActionsFailureState(
          failureKind: ScreenActionsFailureKind.completionFailed,
          fallbackMessage: 'Task update failed',
          entityType: EntityType.task.name,
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
    try {
      if (event.completed) {
        await _entityActionService.completeProject(
          event.projectId,
          occurrenceDate: event.occurrenceDate,
          originalOccurrenceDate: event.originalOccurrenceDate,
        );
      } else {
        await _entityActionService.uncompleteProject(
          event.projectId,
          occurrenceDate: event.occurrenceDate,
        );
      }
      event.completer?.complete();
    } catch (e, st) {
      talker.handle(e, st, '[ScreenActionsBloc] project completion failed');
      emit(
        ScreenActionsFailureState(
          failureKind: ScreenActionsFailureKind.completionFailed,
          fallbackMessage: 'Project update failed',
          entityType: EntityType.project.name,
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
    try {
      if (event.pinned) {
        await _entityActionService.pinTask(event.taskId);
      } else {
        await _entityActionService.unpinTask(event.taskId);
      }
      event.completer?.complete();
    } catch (e, st) {
      talker.handle(e, st, '[ScreenActionsBloc] task pin failed');
      emit(
        ScreenActionsFailureState(
          failureKind: ScreenActionsFailureKind.pinFailed,
          fallbackMessage: 'Task pin failed',
          entityType: EntityType.task.name,
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
    try {
      if (event.pinned) {
        await _entityActionService.pinProject(event.projectId);
      } else {
        await _entityActionService.unpinProject(event.projectId);
      }
      event.completer?.complete();
    } catch (e, st) {
      talker.handle(e, st, '[ScreenActionsBloc] project pin failed');
      emit(
        ScreenActionsFailureState(
          failureKind: ScreenActionsFailureKind.pinFailed,
          fallbackMessage: 'Project pin failed',
          entityType: EntityType.project.name,
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
    try {
      await _entityActionService.performAction(
        entityId: event.entityId,
        entityType: event.entityType,
        action: EntityActionType.delete,
      );
      event.completer?.complete();
    } catch (e, st) {
      talker.handle(e, st, '[ScreenActionsBloc] delete failed');
      emit(
        ScreenActionsFailureState(
          failureKind: ScreenActionsFailureKind.deleteFailed,
          fallbackMessage: 'Delete failed',
          entityType: event.entityType.name,
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
    try {
      await _entityActionService.moveTask(
        event.taskId,
        event.targetProjectId.isEmpty ? null : event.targetProjectId,
      );
      event.completer?.complete();
    } catch (e, st) {
      talker.handle(e, st, '[ScreenActionsBloc] move failed');
      emit(
        ScreenActionsFailureState(
          failureKind: ScreenActionsFailureKind.moveFailed,
          fallbackMessage: 'Move failed',
          entityType: EntityType.task.name,
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
        entityType: event.entityType?.name,
        entityId: event.entityId,
        error: event.error,
      ),
    );

    // Reset so the next failure is delivered.
    emit(const ScreenActionsIdleState());
  }
}
