@Tags(['unit', 'projects'])
library;

import '../../../../helpers/test_imports.dart';
import 'package:taskly_bloc/presentation/features/projects/bloc/projects_screen_bloc.dart';
import 'package:taskly_bloc/presentation/features/projects/model/projects_sort.dart';
import 'package:taskly_bloc/presentation/features/scope_context/model/projects_scope.dart';
import 'package:taskly_domain/core.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  testSafe('initial state defaults are stable', () async {
    final bloc = ProjectsScreenBloc();
    addTearDown(bloc.close);
    expect(
      bloc.state,
      isA<ProjectsScreenReady>()
          .having((s) => s.focusOnly, 'focusOnly', false)
          .having((s) => s.inboxCollapsed, 'inboxCollapsed', false)
          .having((s) => s.searchQuery, 'searchQuery', '')
          .having(
            (s) => s.sortOrder,
            'sortOrder',
            ProjectsSortOrder.recentlyUpdated,
          ),
    );
  });

  blocTestSafe<ProjectsScreenBloc, ProjectsScreenState>(
    'toggles focus-only and updates search query',
    build: ProjectsScreenBloc.new,
    act: (bloc) {
      bloc.add(const ProjectsFocusOnlyToggled());
      bloc.add(const ProjectsSearchQueryChanged('alpha'));
    },
    expect: () => [
      isA<ProjectsScreenReady>().having((s) => s.focusOnly, 'focusOnly', true),
      isA<ProjectsScreenReady>().having(
        (s) => s.searchQuery,
        'searchQuery',
        'alpha',
      ),
    ],
  );

  blocTestSafe<ProjectsScreenBloc, ProjectsScreenState>(
    'emits create task effect with scope defaults',
    build: () => ProjectsScreenBloc(
      scope: const ProjectsProjectScope(projectId: 'project-1'),
    ),
    act: (bloc) => bloc.add(const ProjectsCreateTaskRequested()),
    expect: () => [
      isA<ProjectsScreenReady>().having(
        (s) => s.effect,
        'effect',
        isA<ProjectsNavigateToTaskNew>().having(
          (e) => e.defaultProjectId,
          'defaultProjectId',
          'project-1',
        ),
      ),
    ],
  );

  blocTestSafe<ProjectsScreenBloc, ProjectsScreenState>(
    'clears effect when handled',
    build: ProjectsScreenBloc.new,
    act: (bloc) {
      bloc.add(const ProjectsCreateProjectRequested());
      bloc.add(const ProjectsEffectHandled());
    },
    expect: () => [
      isA<ProjectsScreenReady>().having(
        (s) => s.effect,
        'effect',
        isA<ProjectsOpenProjectNew>(),
      ),
      isA<ProjectsScreenReady>().having((s) => s.effect, 'effect', isNull),
    ],
  );
}
