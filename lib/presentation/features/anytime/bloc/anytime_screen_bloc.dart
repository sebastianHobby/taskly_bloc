import 'package:bloc/bloc.dart';
import 'package:taskly_domain/core.dart';

import 'package:taskly_bloc/presentation/features/scope_context/model/anytime_scope.dart';

sealed class AnytimeScreenEffect {
  const AnytimeScreenEffect();
}

final class AnytimeNavigateToInbox extends AnytimeScreenEffect {
  const AnytimeNavigateToInbox();
}

final class AnytimeNavigateToProjectAnytime extends AnytimeScreenEffect {
  const AnytimeNavigateToProjectAnytime({required this.projectId});

  final String projectId;
}

final class AnytimeNavigateToTaskEdit extends AnytimeScreenEffect {
  const AnytimeNavigateToTaskEdit({required this.taskId});

  final String taskId;
}

final class AnytimeNavigateToTaskNew extends AnytimeScreenEffect {
  const AnytimeNavigateToTaskNew({this.defaultProjectId, this.defaultValueId});

  final String? defaultProjectId;
  final String? defaultValueId;
}

final class AnytimeOpenProjectNew extends AnytimeScreenEffect {
  const AnytimeOpenProjectNew({required this.openToValues});

  final bool openToValues;
}

sealed class AnytimeScreenEvent {
  const AnytimeScreenEvent();
}

final class AnytimeFocusOnlyToggled extends AnytimeScreenEvent {
  const AnytimeFocusOnlyToggled();
}

final class AnytimeFocusOnlySet extends AnytimeScreenEvent {
  const AnytimeFocusOnlySet(this.enabled);

  final bool enabled;
}

final class AnytimeCreateTaskRequested extends AnytimeScreenEvent {
  const AnytimeCreateTaskRequested();
}

final class AnytimeCreateProjectRequested extends AnytimeScreenEvent {
  const AnytimeCreateProjectRequested();
}

final class AnytimeTaskTapped extends AnytimeScreenEvent {
  const AnytimeTaskTapped({required this.taskId});

  final String taskId;
}

final class AnytimeProjectHeaderTapped extends AnytimeScreenEvent {
  const AnytimeProjectHeaderTapped({required this.projectRef});

  final ProjectGroupingRef projectRef;
}

final class AnytimeEffectHandled extends AnytimeScreenEvent {
  const AnytimeEffectHandled();
}

sealed class AnytimeScreenState {
  const AnytimeScreenState({required this.focusOnly, this.effect});

  final bool focusOnly;

  final AnytimeScreenEffect? effect;
}

final class AnytimeScreenReady extends AnytimeScreenState {
  const AnytimeScreenReady({required super.focusOnly, super.effect});
}

class AnytimeScreenBloc extends Bloc<AnytimeScreenEvent, AnytimeScreenState> {
  AnytimeScreenBloc({AnytimeScope? scope})
    : _scope = scope,
      super(const AnytimeScreenReady(focusOnly: false)) {
    on<AnytimeFocusOnlyToggled>((event, emit) {
      emit(AnytimeScreenReady(focusOnly: !state.focusOnly));
    });
    on<AnytimeFocusOnlySet>((event, emit) {
      emit(AnytimeScreenReady(focusOnly: event.enabled));
    });

    on<AnytimeCreateTaskRequested>((event, emit) {
      final (defaultProjectId, defaultValueId) = _defaultsForScope(_scope);
      emit(
        AnytimeScreenReady(
          focusOnly: state.focusOnly,
          effect: AnytimeNavigateToTaskNew(
            defaultProjectId: defaultProjectId,
            defaultValueId: defaultValueId,
          ),
        ),
      );
    });

    on<AnytimeCreateProjectRequested>((event, emit) {
      emit(
        AnytimeScreenReady(
          focusOnly: state.focusOnly,
          effect: AnytimeOpenProjectNew(
            openToValues: _scope is AnytimeValueScope,
          ),
        ),
      );
    });

    on<AnytimeTaskTapped>((event, emit) {
      final id = event.taskId.trim();
      if (id.isEmpty) return;
      emit(
        AnytimeScreenReady(
          focusOnly: state.focusOnly,
          effect: AnytimeNavigateToTaskEdit(taskId: id),
        ),
      );
    });

    on<AnytimeProjectHeaderTapped>((event, emit) {
      switch (event.projectRef) {
        case InboxProjectGroupingRef():
          emit(
            AnytimeScreenReady(
              focusOnly: state.focusOnly,
              effect: const AnytimeNavigateToInbox(),
            ),
          );
        case ProjectProjectGroupingRef(:final projectId):
          final id = projectId.trim();
          if (id.isEmpty) return;
          emit(
            AnytimeScreenReady(
              focusOnly: state.focusOnly,
              effect: AnytimeNavigateToProjectAnytime(projectId: id),
            ),
          );
      }
    });

    on<AnytimeEffectHandled>((event, emit) {
      if (state.effect == null) return;
      emit(AnytimeScreenReady(focusOnly: state.focusOnly));
    });
  }

  final AnytimeScope? _scope;

  (String?, String?) _defaultsForScope(AnytimeScope? scope) {
    if (scope == null) return (null, null);

    return switch (scope) {
      AnytimeProjectScope(:final projectId) => (projectId, null),
      AnytimeValueScope(:final valueId) => (null, valueId),
    };
  }
}
