import 'package:bloc/bloc.dart';
import 'package:taskly_domain/core.dart';

import 'package:taskly_bloc/presentation/features/scope_context/model/projects_scope.dart';
import 'package:taskly_bloc/presentation/features/projects/model/projects_sort.dart';

sealed class ProjectsScreenEffect {
  const ProjectsScreenEffect();
}

final class ProjectsNavigateToProjectDetail extends ProjectsScreenEffect {
  const ProjectsNavigateToProjectDetail({required this.projectId});

  final String projectId;
}

final class ProjectsNavigateToTaskEdit extends ProjectsScreenEffect {
  const ProjectsNavigateToTaskEdit({required this.taskId});

  final String taskId;
}

final class ProjectsNavigateToTaskNew extends ProjectsScreenEffect {
  const ProjectsNavigateToTaskNew({
    this.defaultProjectId,
    this.defaultValueId,
  });

  final String? defaultProjectId;
  final String? defaultValueId;
}

final class ProjectsOpenProjectNew extends ProjectsScreenEffect {
  const ProjectsOpenProjectNew({required this.openToValues});

  final bool openToValues;
}

sealed class ProjectsScreenEvent {
  const ProjectsScreenEvent();
}

final class ProjectsFocusOnlyToggled extends ProjectsScreenEvent {
  const ProjectsFocusOnlyToggled();
}

final class ProjectsFocusOnlySet extends ProjectsScreenEvent {
  const ProjectsFocusOnlySet(this.enabled);

  final bool enabled;
}

final class ProjectsSortOrderSet extends ProjectsScreenEvent {
  const ProjectsSortOrderSet(this.order);

  final ProjectsSortOrder order;
}

final class ProjectsSearchQueryChanged extends ProjectsScreenEvent {
  const ProjectsSearchQueryChanged(this.query);

  final String query;
}

final class ProjectsCreateTaskRequested extends ProjectsScreenEvent {
  const ProjectsCreateTaskRequested();
}

final class ProjectsCreateProjectRequested extends ProjectsScreenEvent {
  const ProjectsCreateProjectRequested();
}

final class ProjectsTaskTapped extends ProjectsScreenEvent {
  const ProjectsTaskTapped({required this.taskId});

  final String taskId;
}

final class ProjectsProjectHeaderTapped extends ProjectsScreenEvent {
  const ProjectsProjectHeaderTapped({required this.projectRef});

  final ProjectGroupingRef projectRef;
}

final class ProjectsEffectHandled extends ProjectsScreenEvent {
  const ProjectsEffectHandled();
}

sealed class ProjectsScreenState {
  const ProjectsScreenState({
    required this.focusOnly,
    required this.inboxCollapsed,
    required this.searchQuery,
    required this.sortOrder,
    this.effect,
  });

  final bool focusOnly;

  /// Whether the global Inbox section in Projects is collapsed.
  final bool inboxCollapsed;

  /// Ephemeral search query for the current route/scope.
  final String searchQuery;
  final ProjectsSortOrder sortOrder;

  final ProjectsScreenEffect? effect;
}

final class ProjectsScreenReady extends ProjectsScreenState {
  const ProjectsScreenReady({
    required super.focusOnly,
    required super.inboxCollapsed,
    required super.searchQuery,
    required super.sortOrder,
    super.effect,
  });
}

class ProjectsScreenBloc
    extends Bloc<ProjectsScreenEvent, ProjectsScreenState> {
  ProjectsScreenBloc({ProjectsScope? scope})
    : _scope = scope,
      super(
        const ProjectsScreenReady(
          focusOnly: false,
          inboxCollapsed: false,
          searchQuery: '',
          sortOrder: ProjectsSortOrder.recentlyUpdated,
        ),
      ) {
    on<ProjectsFocusOnlyToggled>((event, emit) {
      emit(
        ProjectsScreenReady(
          focusOnly: !state.focusOnly,
          inboxCollapsed: state.inboxCollapsed,
          searchQuery: state.searchQuery,
          sortOrder: state.sortOrder,
        ),
      );
    });
    on<ProjectsFocusOnlySet>((event, emit) {
      emit(
        ProjectsScreenReady(
          focusOnly: event.enabled,
          inboxCollapsed: state.inboxCollapsed,
          searchQuery: state.searchQuery,
          sortOrder: state.sortOrder,
        ),
      );
    });

    on<ProjectsSearchQueryChanged>((event, emit) {
      emit(
        ProjectsScreenReady(
          focusOnly: state.focusOnly,
          inboxCollapsed: state.inboxCollapsed,
          searchQuery: event.query,
          sortOrder: state.sortOrder,
        ),
      );
    });

    on<ProjectsSortOrderSet>((event, emit) {
      emit(
        ProjectsScreenReady(
          focusOnly: state.focusOnly,
          inboxCollapsed: state.inboxCollapsed,
          searchQuery: state.searchQuery,
          sortOrder: event.order,
        ),
      );
    });

    on<ProjectsCreateTaskRequested>((event, emit) {
      final (defaultProjectId, defaultValueId) = _defaultsForScope(_scope);
      emit(
        ProjectsScreenReady(
          focusOnly: state.focusOnly,
          inboxCollapsed: state.inboxCollapsed,
          searchQuery: state.searchQuery,
          sortOrder: state.sortOrder,
          effect: ProjectsNavigateToTaskNew(
            defaultProjectId: defaultProjectId,
            defaultValueId: defaultValueId,
          ),
        ),
      );
    });

    on<ProjectsCreateProjectRequested>((event, emit) {
      emit(
        ProjectsScreenReady(
          focusOnly: state.focusOnly,
          inboxCollapsed: state.inboxCollapsed,
          searchQuery: state.searchQuery,
          sortOrder: state.sortOrder,
          effect: ProjectsOpenProjectNew(
            openToValues: _scope is ProjectsValueScope,
          ),
        ),
      );
    });

    on<ProjectsTaskTapped>((event, emit) {
      final id = event.taskId.trim();
      if (id.isEmpty) return;
      emit(
        ProjectsScreenReady(
          focusOnly: state.focusOnly,
          inboxCollapsed: state.inboxCollapsed,
          searchQuery: state.searchQuery,
          sortOrder: state.sortOrder,
          effect: ProjectsNavigateToTaskEdit(taskId: id),
        ),
      );
    });

    on<ProjectsProjectHeaderTapped>((event, emit) {
      switch (event.projectRef) {
        case InboxProjectGroupingRef():
          emit(
            ProjectsScreenReady(
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
            ProjectsScreenReady(
              focusOnly: state.focusOnly,
              inboxCollapsed: state.inboxCollapsed,
              searchQuery: state.searchQuery,
              sortOrder: state.sortOrder,
              effect: ProjectsNavigateToProjectDetail(projectId: id),
            ),
          );
      }
    });

    on<ProjectsEffectHandled>((event, emit) {
      if (state.effect == null) return;
      emit(
        ProjectsScreenReady(
          focusOnly: state.focusOnly,
          inboxCollapsed: state.inboxCollapsed,
          searchQuery: state.searchQuery,
          sortOrder: state.sortOrder,
        ),
      );
    });
  }

  final ProjectsScope? _scope;

  (String?, String?) _defaultsForScope(ProjectsScope? scope) {
    if (scope == null) return (null, null);

    return switch (scope) {
      ProjectsProjectScope(:final projectId) => (projectId, null),
      ProjectsValueScope(:final valueId) => (null, valueId),
    };
  }
}
