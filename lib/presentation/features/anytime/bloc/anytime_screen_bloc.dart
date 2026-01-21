import 'package:bloc/bloc.dart';
import 'package:taskly_domain/core.dart';

import 'package:taskly_bloc/presentation/features/scope_context/model/anytime_scope.dart';

sealed class AnytimeScreenEffect {
  const AnytimeScreenEffect();
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

final class AnytimeShowStartLaterSet extends AnytimeScreenEvent {
  const AnytimeShowStartLaterSet(this.enabled);

  /// When true, items with a future planned day (start date) are included.
  final bool enabled;
}

final class AnytimeSearchQueryChanged extends AnytimeScreenEvent {
  const AnytimeSearchQueryChanged(this.query);

  final String query;
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
  const AnytimeScreenState({
    required this.focusOnly,
    required this.showStartLaterItems,
    required this.inboxCollapsed,
    required this.searchQuery,
    this.effect,
  });

  final bool focusOnly;

  /// When true, items with a future planned day (start date) are included.
  final bool showStartLaterItems;

  /// Whether the global Inbox section in Anytime is collapsed.
  final bool inboxCollapsed;

  /// Ephemeral search query for the current route/scope.
  final String searchQuery;

  final AnytimeScreenEffect? effect;
}

final class AnytimeScreenReady extends AnytimeScreenState {
  const AnytimeScreenReady({
    required super.focusOnly,
    required super.showStartLaterItems,
    required super.inboxCollapsed,
    required super.searchQuery,
    super.effect,
  });
}

class AnytimeScreenBloc extends Bloc<AnytimeScreenEvent, AnytimeScreenState> {
  AnytimeScreenBloc({AnytimeScope? scope})
    : _scope = scope,
      super(
        const AnytimeScreenReady(
          focusOnly: false,
          showStartLaterItems: false,
          inboxCollapsed: false,
          searchQuery: '',
        ),
      ) {
    on<AnytimeFocusOnlyToggled>((event, emit) {
      emit(
        AnytimeScreenReady(
          focusOnly: !state.focusOnly,
          showStartLaterItems: state.showStartLaterItems,
          inboxCollapsed: state.inboxCollapsed,
          searchQuery: state.searchQuery,
        ),
      );
    });
    on<AnytimeFocusOnlySet>((event, emit) {
      emit(
        AnytimeScreenReady(
          focusOnly: event.enabled,
          showStartLaterItems: state.showStartLaterItems,
          inboxCollapsed: state.inboxCollapsed,
          searchQuery: state.searchQuery,
        ),
      );
    });

    on<AnytimeShowStartLaterSet>((event, emit) {
      emit(
        AnytimeScreenReady(
          focusOnly: state.focusOnly,
          showStartLaterItems: event.enabled,
          inboxCollapsed: state.inboxCollapsed,
          searchQuery: state.searchQuery,
        ),
      );
    });

    on<AnytimeSearchQueryChanged>((event, emit) {
      emit(
        AnytimeScreenReady(
          focusOnly: state.focusOnly,
          showStartLaterItems: state.showStartLaterItems,
          inboxCollapsed: state.inboxCollapsed,
          searchQuery: event.query,
        ),
      );
    });

    on<AnytimeCreateTaskRequested>((event, emit) {
      final (defaultProjectId, defaultValueId) = _defaultsForScope(_scope);
      emit(
        AnytimeScreenReady(
          focusOnly: state.focusOnly,
          showStartLaterItems: state.showStartLaterItems,
          inboxCollapsed: state.inboxCollapsed,
          searchQuery: state.searchQuery,
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
          showStartLaterItems: state.showStartLaterItems,
          inboxCollapsed: state.inboxCollapsed,
          searchQuery: state.searchQuery,
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
          showStartLaterItems: state.showStartLaterItems,
          inboxCollapsed: state.inboxCollapsed,
          searchQuery: state.searchQuery,
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
              showStartLaterItems: state.showStartLaterItems,
              inboxCollapsed: !state.inboxCollapsed,
              searchQuery: state.searchQuery,
            ),
          );
        case ProjectProjectGroupingRef(:final projectId):
          final id = projectId.trim();
          if (id.isEmpty) return;
          emit(
            AnytimeScreenReady(
              focusOnly: state.focusOnly,
              showStartLaterItems: state.showStartLaterItems,
              inboxCollapsed: state.inboxCollapsed,
              searchQuery: state.searchQuery,
              effect: AnytimeNavigateToProjectAnytime(projectId: id),
            ),
          );
      }
    });

    on<AnytimeEffectHandled>((event, emit) {
      if (state.effect == null) return;
      emit(
        AnytimeScreenReady(
          focusOnly: state.focusOnly,
          showStartLaterItems: state.showStartLaterItems,
          inboxCollapsed: state.inboxCollapsed,
          searchQuery: state.searchQuery,
        ),
      );
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
