@Tags(['unit', 'anytime'])
library;

import '../../../../helpers/test_imports.dart';
import 'package:taskly_bloc/presentation/features/anytime/bloc/anytime_screen_bloc.dart';
import 'package:taskly_bloc/presentation/features/anytime/model/anytime_sort.dart';
import 'package:taskly_bloc/presentation/features/scope_context/model/anytime_scope.dart';
import 'package:taskly_domain/core.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  testSafe('initial state defaults are stable', () async {
    final bloc = AnytimeScreenBloc();
    addTearDown(bloc.close);
    expect(
      bloc.state,
      isA<AnytimeScreenReady>()
          .having((s) => s.focusOnly, 'focusOnly', false)
          .having((s) => s.inboxCollapsed, 'inboxCollapsed', false)
          .having((s) => s.searchQuery, 'searchQuery', '')
          .having(
            (s) => s.sortOrder,
            'sortOrder',
            AnytimeSortOrder.dueSoonest,
          ),
    );
  });

  blocTestSafe<AnytimeScreenBloc, AnytimeScreenState>(
    'toggles focus-only and updates search query',
    build: AnytimeScreenBloc.new,
    act: (bloc) {
      bloc.add(const AnytimeFocusOnlyToggled());
      bloc.add(const AnytimeSearchQueryChanged('alpha'));
    },
    expect: () => [
      isA<AnytimeScreenReady>().having((s) => s.focusOnly, 'focusOnly', true),
      isA<AnytimeScreenReady>().having(
        (s) => s.searchQuery,
        'searchQuery',
        'alpha',
      ),
    ],
  );

  blocTestSafe<AnytimeScreenBloc, AnytimeScreenState>(
    'emits create task effect with scope defaults',
    build: () => AnytimeScreenBloc(
      scope: const AnytimeProjectScope(projectId: 'project-1'),
    ),
    act: (bloc) => bloc.add(const AnytimeCreateTaskRequested()),
    expect: () => [
      isA<AnytimeScreenReady>().having(
        (s) => s.effect,
        'effect',
        isA<AnytimeNavigateToTaskNew>()
            .having((e) => e.defaultProjectId, 'defaultProjectId', 'project-1'),
      ),
    ],
  );

  blocTestSafe<AnytimeScreenBloc, AnytimeScreenState>(
    'clears effect when handled',
    build: AnytimeScreenBloc.new,
    act: (bloc) {
      bloc.add(const AnytimeCreateProjectRequested());
      bloc.add(const AnytimeEffectHandled());
    },
    expect: () => [
      isA<AnytimeScreenReady>().having(
        (s) => s.effect,
        'effect',
        isA<AnytimeOpenProjectNew>(),
      ),
      isA<AnytimeScreenReady>().having((s) => s.effect, 'effect', isNull),
    ],
  );
}

