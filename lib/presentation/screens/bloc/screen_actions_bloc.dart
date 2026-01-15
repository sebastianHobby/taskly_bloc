import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/logging/talker_service.dart';
import 'package:taskly_bloc/domain/screens/runtime/entity_action_service.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_actions_state.dart';

sealed class ScreenActionsEvent {
  const ScreenActionsEvent();
}

final class ScreenActionsTaskCompletionChanged extends ScreenActionsEvent {
  const ScreenActionsTaskCompletionChanged({
    required this.taskId,
    required this.completed,
    this.completer,
  });

  final String taskId;
  final bool completed;
  final Completer<void>? completer;
}

final class ScreenActionsProjectCompletionChanged extends ScreenActionsEvent {
  const ScreenActionsProjectCompletionChanged({
    required this.projectId,
    required this.completed,
    this.completer,
  });

  final String projectId;
  final bool completed;
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

final class ScreenActionsDeleteEntity extends ScreenActionsEvent {
  const ScreenActionsDeleteEntity({
    required this.entityType,
    required this.entityId,
    this.completer,
  });

  final String entityType;
  final String entityId;
  final Completer<void>? completer;
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
    on<ScreenActionsDeleteEntity>(
      _onDeleteEntity,
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
        await _entityActionService.completeTask(event.taskId);
      } else {
        await _entityActionService.uncompleteTask(event.taskId);
      }
      event.completer?.complete();
    } catch (e, st) {
      talker.handle(e, st, '[ScreenActionsBloc] task completion failed');
      emit(
        ScreenActionsFailureState(
          message: 'Task update failed',
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
        await _entityActionService.completeProject(event.projectId);
      } else {
        await _entityActionService.uncompleteProject(event.projectId);
      }
      event.completer?.complete();
    } catch (e, st) {
      talker.handle(e, st, '[ScreenActionsBloc] project completion failed');
      emit(
        ScreenActionsFailureState(
          message: 'Project update failed',
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
          message: 'Task pin failed',
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
          message: 'Delete failed',
          error: e,
        ),
      );
      event.completer?.completeError(e, st);
      emit(const ScreenActionsIdleState());
    }
  }
}
