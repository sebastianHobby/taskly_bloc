import 'package:bloc/bloc.dart';
import 'package:taskly_domain/core.dart';

import 'package:taskly_bloc/presentation/features/scope_context/model/anytime_scope.dart';
import 'package:taskly_bloc/presentation/features/anytime/model/anytime_sort.dart';

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

final class AnytimeSortOrderSet extends AnytimeScreenEvent {
  const AnytimeSortOrderSet(this.order);

  final AnytimeSortOrder order;
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
    required this.inboxCollapsed,
    required this.searchQuery,
    required this.sortOrder,
    this.effect,
  });

  final bool focusOnly;

  /// Whether the global Inbox section in Anytime is collapsed.
  final bool inboxCollapsed;

  /// Ephemeral search query for the current route/scope.
  final String searchQuery;
  final AnytimeSortOrder sortOrder;

  final AnytimeScreenEffect? effect;
}

final class AnytimeScreenReady extends AnytimeScreenState {
  const AnytimeScreenReady({
    required super.focusOnly,
    required super.inboxCollapsed,
    required super.searchQuery,
    required super.sortOrder,
    super.effect,
  });
}

class AnytimeScreenBloc extends Bloc<AnytimeScreenEvent, AnytimeScreenState> {
  AnytimeScreenBloc({AnytimeScope? scope})
    : _scope = scope,
      super(
        const AnytimeScreenReady(
          focusOnly: false,
          inboxCollapsed: false,
          searchQuery: '',
          sortOrder: AnytimeSortOrder.recentlyUpdated,
        ),
      ) {
    on<AnytimeFocusOnlyToggled>((event, emit) {
      emit(
        AnytimeScreenReady(
          focusOnly: !state.focusOnly,
          inboxCollapsed: state.inboxCollapsed,
          searchQuery: state.searchQuery,
          sortOrder: state.sortOrder,
        ),
      );
    });
    on<AnytimeFocusOnlySet>((event, emit) {
      emit(
        AnytimeScreenReady(
          focusOnly: event.enabled,
          inboxCollapsed: state.inboxCollapsed,
          searchQuery: state.searchQuery,
          sortOrder: state.sortOrder,
        ),
      );
    });

    on<AnytimeSearchQueryChanged>((event, emit) {
      emit(
        AnytimeScreenReady(
          focusOnly: state.focusOnly,
          inboxCollapsed: state.inboxCollapsed,
          searchQuery: event.query,
          sortOrder: state.sortOrder,
        ),
      );
    });

    on<AnytimeSortOrderSet>((event, emit) {
      emit(
        AnytimeScreenReady(
          focusOnly: state.focusOnly,
          inboxCollapsed: state.inboxCollapsed,
          searchQuery: state.searchQuery,
          sortOrder: event.order,
        ),
      );
    });

    on<AnytimeCreateTaskRequested>((event, emit) {
      final (defaultProjectId, defaultValueId) = _defaultsForScope(_scope);
      emit(
        AnytimeScreenReady(
          focusOnly: state.focusOnly,
          inboxCollapsed: state.inboxCollapsed,
          searchQuery: state.searchQuery,
          sortOrder: state.sortOrder,
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
          inboxCollapsed: state.inboxCollapsed,
          searchQuery: state.searchQuery,
          sortOrder: state.sortOrder,
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
          inboxCollapsed: state.inboxCollapsed,
          searchQuery: state.searchQuery,
          sortOrder: state.sortOrder,
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
              inboxCollapsed: !state.inboxCollapsed,
              searchQuery: state.searchQuery,
              sortOrder: state.sortOrder,
            ),
          );
        case ProjectProjectGroupingRef(:final projectId):
          final id = projectId.trim();
          if (id.isEmpty) return;
          emit(
            AnytimeScreenReady(
              focusOnly: state.focusOnly,
              inboxCollapsed: state.inboxCollapsed,
              searchQuery: state.searchQuery,
              sortOrder: state.sortOrder,
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
          inboxCollapsed: state.inboxCollapsed,
          searchQuery: state.searchQuery,
          sortOrder: state.sortOrder,
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
