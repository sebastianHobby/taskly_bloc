import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/presentation/features/tasks/bloc/task_list_bloc.dart';

import '../../../../fixtures/test_data.dart';
import '../../../../helpers/fallback_values.dart';
import '../../../../mocks/repository_mocks.dart';

void main() {
  setUpAll(registerAllFallbackValues);

  late MockTaskRepositoryContract taskRepo;
  late MockSettingsRepositoryContract settingsRepo;

  setUp(() {
    taskRepo = MockTaskRepositoryContract();
    settingsRepo = MockSettingsRepositoryContract();
  });

  group('TaskOverviewBloc', () {
    const defaultQuery = TaskQuery();
    const testPageKey = PageKey.taskOverview;

    TaskOverviewBloc buildBloc({
      TaskQuery? query,
      bool useSettingsRepo = false,
      PageKey? pageKey,
    }) {
      return TaskOverviewBloc(
        taskRepository: taskRepo,
        query: query ?? defaultQuery,
        settingsRepository: useSettingsRepo ? settingsRepo : null,
        pageKey: pageKey,
      );
    }

    group('initial state', () {
      test('is TaskOverviewInitial', () {
        when(() => taskRepo.watchAll(any())).thenAnswer(
          (_) => const Stream.empty(),
        );

        final bloc = buildBloc();

        expect(bloc.state, const TaskOverviewState.initial());
        bloc.close();
      });
    });

    group('subscriptionRequested', () {
      blocTest<TaskOverviewBloc, TaskOverviewState>(
        'emits [loading, loaded] when repository returns tasks',
        setUp: () {
          when(() => taskRepo.watchAll(any())).thenAnswer(
            (_) => Stream.value([TestData.task(id: '1')]),
          );
        },
        build: buildBloc,
        act: (bloc) =>
            bloc.add(const TaskOverviewEvent.subscriptionRequested()),
        expect: () => [
          const TaskOverviewState.loading(),
          isA<TaskOverviewLoaded>().having(
            (s) => s.tasks.length,
            'tasks count',
            1,
          ),
        ],
      );

      blocTest<TaskOverviewBloc, TaskOverviewState>(
        'emits [loading, loaded] with empty list when no tasks',
        setUp: () {
          when(() => taskRepo.watchAll(any())).thenAnswer(
            (_) => Stream.value([]),
          );
        },
        build: buildBloc,
        act: (bloc) =>
            bloc.add(const TaskOverviewEvent.subscriptionRequested()),
        expect: () => [
          const TaskOverviewState.loading(),
          isA<TaskOverviewLoaded>().having(
            (s) => s.tasks,
            'tasks',
            isEmpty,
          ),
        ],
      );

      blocTest<TaskOverviewBloc, TaskOverviewState>(
        'emits [loading, error] when repository throws',
        setUp: () {
          when(() => taskRepo.watchAll(any())).thenAnswer(
            (_) => Stream.error(Exception('Database error')),
          );
        },
        build: buildBloc,
        act: (bloc) =>
            bloc.add(const TaskOverviewEvent.subscriptionRequested()),
        expect: () => [
          const TaskOverviewState.loading(),
          isA<TaskOverviewError>(),
        ],
      );

      blocTest<TaskOverviewBloc, TaskOverviewState>(
        'uses provided query when watching tasks',
        setUp: () {
          when(() => taskRepo.watchAll(any())).thenAnswer(
            (_) => Stream.value([]),
          );
        },
        build: () => buildBloc(query: const TaskQuery()),
        act: (bloc) =>
            bloc.add(const TaskOverviewEvent.subscriptionRequested()),
        verify: (_) {
          verify(
            () => taskRepo.watchAll(any(that: isA<TaskQuery>())),
          ).called(1);
        },
      );
    });

    group('toggleTaskCompletion', () {
      blocTest<TaskOverviewBloc, TaskOverviewState>(
        'calls repository update with toggled completion',
        setUp: () {
          when(() => taskRepo.watchAll(any())).thenAnswer(
            (_) => Stream.value([TestData.task(id: '1')]),
          );
          when(
            () => taskRepo.update(
              id: any(named: 'id'),
              name: any(named: 'name'),
              completed: any(named: 'completed'),
              description: any(named: 'description'),
              startDate: any(named: 'startDate'),
              deadlineDate: any(named: 'deadlineDate'),
              projectId: any(named: 'projectId'),
              repeatIcalRrule: any(named: 'repeatIcalRrule'),
            ),
          ).thenAnswer((_) async {});
        },
        build: buildBloc,
        seed: () => TaskOverviewLoaded(
          tasks: [TestData.task(id: '1')],
          query: defaultQuery,
        ),
        act: (bloc) => bloc.add(
          TaskOverviewEvent.toggleTaskCompletion(
            task: TestData.task(id: '1'),
          ),
        ),
        verify: (_) {
          verify(
            () => taskRepo.update(
              id: '1',
              name: any(named: 'name'),
              completed: true,
              description: any(named: 'description'),
              startDate: any(named: 'startDate'),
              deadlineDate: any(named: 'deadlineDate'),
              projectId: any(named: 'projectId'),
              repeatIcalRrule: any(named: 'repeatIcalRrule'),
            ),
          ).called(1);
        },
      );

      blocTest<TaskOverviewBloc, TaskOverviewState>(
        'emits error state when repository throws',
        setUp: () {
          when(() => taskRepo.watchAll(any())).thenAnswer(
            (_) => Stream.value([]),
          );
          when(
            () => taskRepo.update(
              id: any(named: 'id'),
              name: any(named: 'name'),
              completed: any(named: 'completed'),
              description: any(named: 'description'),
              startDate: any(named: 'startDate'),
              deadlineDate: any(named: 'deadlineDate'),
              projectId: any(named: 'projectId'),
              repeatIcalRrule: any(named: 'repeatIcalRrule'),
            ),
          ).thenThrow(Exception('Update failed'));
        },
        build: buildBloc,
        seed: () => TaskOverviewLoaded(
          tasks: [TestData.task(id: '1')],
          query: defaultQuery,
        ),
        act: (bloc) => bloc.add(
          TaskOverviewEvent.toggleTaskCompletion(task: TestData.task(id: '1')),
        ),
        expect: () => [isA<TaskOverviewError>()],
      );
    });

    group('deleteTask', () {
      blocTest<TaskOverviewBloc, TaskOverviewState>(
        'calls repository delete',
        setUp: () {
          when(() => taskRepo.watchAll(any())).thenAnswer(
            (_) => Stream.value([]),
          );
          when(() => taskRepo.delete(any())).thenAnswer((_) async {});
        },
        build: buildBloc,
        seed: () => TaskOverviewLoaded(
          tasks: [TestData.task(id: '1')],
          query: defaultQuery,
        ),
        act: (bloc) => bloc.add(
          TaskOverviewEvent.deleteTask(task: TestData.task(id: '1')),
        ),
        verify: (_) {
          verify(() => taskRepo.delete('1')).called(1);
        },
      );

      blocTest<TaskOverviewBloc, TaskOverviewState>(
        'emits error state when repository throws',
        setUp: () {
          when(() => taskRepo.watchAll(any())).thenAnswer(
            (_) => Stream.value([]),
          );
          when(
            () => taskRepo.delete(any()),
          ).thenThrow(Exception('Delete failed'));
        },
        build: buildBloc,
        seed: () => TaskOverviewLoaded(
          tasks: [TestData.task(id: '1')],
          query: defaultQuery,
        ),
        act: (bloc) => bloc.add(
          TaskOverviewEvent.deleteTask(task: TestData.task(id: '1')),
        ),
        expect: () => [isA<TaskOverviewError>()],
      );
    });

    group('sortChanged', () {
      blocTest<TaskOverviewBloc, TaskOverviewState>(
        'persists sort to settings repository when available',
        setUp: () {
          when(() => taskRepo.watchAll(any())).thenAnswer(
            (_) => Stream.value([]),
          );
          when(
            () => settingsRepo.savePageSort(any(), any()),
          ).thenAnswer((_) async {});
        },
        build: () => buildBloc(useSettingsRepo: true, pageKey: testPageKey),
        act: (bloc) => bloc.add(
          const TaskOverviewEvent.sortChanged(
            preferences: SortPreferences(),
          ),
        ),
        verify: (_) {
          verify(
            () => settingsRepo.savePageSort(any(), any()),
          ).called(1);
        },
      );
    });

    group('displaySettingsChanged', () {
      blocTest<TaskOverviewBloc, TaskOverviewState>(
        'persists display settings to repository when available',
        setUp: () {
          when(() => taskRepo.watchAll(any())).thenAnswer(
            (_) => Stream.value([]),
          );
          when(
            () => settingsRepo.savePageDisplaySettings(any(), any()),
          ).thenAnswer((_) async {});
        },
        build: () => buildBloc(useSettingsRepo: true, pageKey: testPageKey),
        act: (bloc) => bloc.add(
          const TaskOverviewEvent.displaySettingsChanged(
            settings: PageDisplaySettings(),
          ),
        ),
        verify: (_) {
          verify(
            () => settingsRepo.savePageDisplaySettings(any(), any()),
          ).called(1);
        },
      );
    });
  });
}
