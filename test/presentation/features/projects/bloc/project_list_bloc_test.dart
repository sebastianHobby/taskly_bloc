import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/presentation/features/projects/bloc/project_list_bloc.dart';

class MockProjectRepositoryContract extends Mock
    implements ProjectRepositoryContract {}

class MockSettingsRepositoryContract extends Mock
    implements SettingsRepositoryContract {}

void main() {
  group('ProjectOverviewBloc', () {
    late MockProjectRepositoryContract mockProjectRepository;
    late MockSettingsRepositoryContract mockSettingsRepository;
    late StreamController<List<Project>> projectsController;

    setUpAll(() {
      initializeTalkerForTest();
      registerFallbackValue(const SortPreferences(criteria: []));
      registerFallbackValue(PageKey.projectOverview);
      registerFallbackValue(const PageDisplaySettings());
    });

    setUp(() {
      mockProjectRepository = MockProjectRepositoryContract();
      mockSettingsRepository = MockSettingsRepositoryContract();
      projectsController = StreamController<List<Project>>.broadcast();

      when(
        () => mockProjectRepository.watchAll(
          withRelated: any(named: 'withRelated'),
        ),
      ).thenAnswer((_) => projectsController.stream);
      when(
        () => mockSettingsRepository.loadPageSort(any()),
      ).thenAnswer((_) async => null);
      when(
        () => mockSettingsRepository.savePageSort(any(), any()),
      ).thenAnswer((_) async {});
      when(
        () => mockSettingsRepository.loadPageDisplaySettings(any()),
      ).thenAnswer((_) async => const PageDisplaySettings());
      when(
        () => mockSettingsRepository.savePageDisplaySettings(any(), any()),
      ).thenAnswer((_) async {});
      when(() => mockProjectRepository.delete(any())).thenAnswer((_) async {});
      when(
        () => mockProjectRepository.update(
          id: any(named: 'id'),
          name: any(named: 'name'),
          completed: any(named: 'completed'),
          description: any(named: 'description'),
          startDate: any(named: 'startDate'),
          deadlineDate: any(named: 'deadlineDate'),
          repeatIcalRrule: any(named: 'repeatIcalRrule'),
          repeatFromCompletion: any(named: 'repeatFromCompletion'),
          labelIds: any(named: 'labelIds'),
          priority: any(named: 'priority'),
        ),
      ).thenAnswer((_) async {});
    });

    tearDown(() async {
      await projectsController.close();
    });

    Project createProject({
      required String id,
      required String name,
      bool completed = false,
    }) {
      final now = DateTime.now();
      return Project(
        id: id,
        name: name,
        completed: completed,
        createdAt: now,
        updatedAt: now,
      );
    }

    group('initial state', () {
      test('is ProjectOverviewInitial', () {
        final bloc = ProjectOverviewBloc(
          projectRepository: mockProjectRepository,
        );

        expect(bloc.state, isA<ProjectOverviewInitial>());
      });
    });

    group('ProjectOverviewSubscriptionRequested', () {
      test('calls watchAll when subscription is requested', () async {
        final bloc = ProjectOverviewBloc(
          projectRepository: mockProjectRepository,
        );

        bloc.add(const ProjectOverviewSubscriptionRequested());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        verify(() => mockProjectRepository.watchAll()).called(1);
        await bloc.close();
      });

      test('calls watchAll with relations when withRelated is true', () async {
        final bloc = ProjectOverviewBloc(
          projectRepository: mockProjectRepository,
          withRelated: true,
        );

        bloc.add(const ProjectOverviewSubscriptionRequested());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        verify(
          () => mockProjectRepository.watchAll(withRelated: true),
        ).called(1);
        await bloc.close();
      });

      test('emits loaded state when projects are received', () async {
        final bloc = ProjectOverviewBloc(
          projectRepository: mockProjectRepository,
        );

        bloc.add(const ProjectOverviewSubscriptionRequested());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        projectsController.add([
          createProject(id: '1', name: 'Project A'),
          createProject(id: '2', name: 'Project B'),
        ]);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(bloc.state, isA<ProjectOverviewLoaded>());
        final loadedState = bloc.state as ProjectOverviewLoaded;
        expect(loadedState.projects.length, 2);
        await bloc.close();
      });

      test('emits error state when stream errors', () async {
        final bloc = ProjectOverviewBloc(
          projectRepository: mockProjectRepository,
        );

        bloc.add(const ProjectOverviewSubscriptionRequested());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        projectsController.addError(Exception('Database error'));
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(bloc.state, isA<ProjectOverviewError>());
        await bloc.close();
      });
    });

    group('ProjectOverviewSortChanged', () {
      test('re-sorts projects with new preferences', () async {
        final bloc = ProjectOverviewBloc(
          projectRepository: mockProjectRepository,
        );

        bloc.add(const ProjectOverviewSubscriptionRequested());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        projectsController.add([
          createProject(id: '1', name: 'Zebra'),
          createProject(id: '2', name: 'Apple'),
        ]);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Default sort is ascending by name
        var loadedState = bloc.state as ProjectOverviewLoaded;
        expect(loadedState.projects.first.name, 'Apple');

        // Change sort to descending
        bloc.add(
          const ProjectOverviewSortChanged(
            preferences: SortPreferences(
              criteria: [
                SortCriterion(
                  field: SortField.name,
                  direction: SortDirection.descending,
                ),
              ],
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        loadedState = bloc.state as ProjectOverviewLoaded;
        expect(loadedState.projects.first.name, 'Zebra');
        await bloc.close();
      });

      test('persists sort preferences to settings', () async {
        final bloc = ProjectOverviewBloc(
          projectRepository: mockProjectRepository,
          settingsRepository: mockSettingsRepository,
          pageKey: PageKey.projectOverview,
        );

        bloc.add(const ProjectOverviewSubscriptionRequested());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        projectsController.add([createProject(id: '1', name: 'Test')]);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        const newSort = SortPreferences(
          criteria: [
            SortCriterion(
              field: SortField.name,
              direction: SortDirection.descending,
            ),
          ],
        );
        bloc.add(const ProjectOverviewSortChanged(preferences: newSort));
        await Future<void>.delayed(const Duration(milliseconds: 50));

        verify(
          () => mockSettingsRepository.savePageSort(
            PageKey.projectOverview,
            newSort,
          ),
        ).called(1);
        await bloc.close();
      });
    });

    group('ProjectOverviewToggleProjectCompletion', () {
      test('calls update on repository to toggle completion', () async {
        final bloc = ProjectOverviewBloc(
          projectRepository: mockProjectRepository,
        );

        bloc.add(const ProjectOverviewSubscriptionRequested());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final project = createProject(
          id: '1',
          name: 'Test',
        );
        projectsController.add([project]);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        bloc.add(ProjectOverviewToggleProjectCompletion(project: project));
        await Future<void>.delayed(const Duration(milliseconds: 50));

        verify(
          () => mockProjectRepository.update(
            id: '1',
            name: 'Test',
            completed: true,
            description: any(named: 'description'),
            startDate: any(named: 'startDate'),
            deadlineDate: any(named: 'deadlineDate'),
            repeatIcalRrule: any(named: 'repeatIcalRrule'),
            repeatFromCompletion: any(named: 'repeatFromCompletion'),
            labelIds: any(named: 'labelIds'),
            priority: any(named: 'priority'),
          ),
        ).called(1);
        await bloc.close();
      });
    });

    group('ProjectOverviewDeleteProject', () {
      test('calls delete on repository', () async {
        final bloc = ProjectOverviewBloc(
          projectRepository: mockProjectRepository,
        );

        bloc.add(const ProjectOverviewSubscriptionRequested());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        projectsController.add([createProject(id: '1', name: 'Test')]);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final project = createProject(id: '1', name: 'Test');
        bloc.add(ProjectOverviewDeleteProject(project: project));
        await Future<void>.delayed(const Duration(milliseconds: 50));

        verify(() => mockProjectRepository.delete('1')).called(1);
        await bloc.close();
      });
    });

    group('ProjectOverviewTaskCountsUpdated', () {
      test('updates task counts in state', () async {
        final bloc = ProjectOverviewBloc(
          projectRepository: mockProjectRepository,
        );

        bloc.add(const ProjectOverviewSubscriptionRequested());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        projectsController.add([createProject(id: '1', name: 'Test')]);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final counts = {
          '1': const ProjectTaskCounts(
            projectId: '1',
            totalCount: 10,
            completedCount: 5,
          ),
        };
        bloc.add(ProjectOverviewTaskCountsUpdated(taskCounts: counts));
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final loadedState = bloc.state as ProjectOverviewLoaded;
        expect(loadedState.taskCounts['1']?.totalCount, 10);
        expect(loadedState.taskCounts['1']?.completedCount, 5);
        await bloc.close();
      });
    });

    group('loadDisplaySettings', () {
      test('returns default settings when no settings repository', () async {
        final bloc = ProjectOverviewBloc(
          projectRepository: mockProjectRepository,
        );

        final settings = await bloc.loadDisplaySettings();
        expect(settings, const PageDisplaySettings());
        await bloc.close();
      });

      test('loads settings from repository when available', () async {
        when(
          () => mockSettingsRepository.loadPageDisplaySettings(
            PageKey.projectOverview,
          ),
        ).thenAnswer(
          (_) async => const PageDisplaySettings(hideCompleted: false),
        );

        final bloc = ProjectOverviewBloc(
          projectRepository: mockProjectRepository,
          settingsRepository: mockSettingsRepository,
          pageKey: PageKey.projectOverview,
        );

        final settings = await bloc.loadDisplaySettings();
        expect(settings.hideCompleted, false);
        await bloc.close();
      });
    });

    group('lifecycle', () {
      test('closes cleanly', () async {
        final bloc = ProjectOverviewBloc(
          projectRepository: mockProjectRepository,
        );

        bloc.add(const ProjectOverviewSubscriptionRequested());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        await bloc.close();
        // No assertion needed - just verify no exceptions
      });
    });
  });
}
