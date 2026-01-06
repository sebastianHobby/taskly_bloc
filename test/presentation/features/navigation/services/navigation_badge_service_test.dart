import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/domain/models/screens/data_config.dart';
import 'package:taskly_bloc/domain/models/screens/screen_category.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/screens/section.dart';
import 'package:taskly_bloc/domain/queries/project_query.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/presentation/features/navigation/services/navigation_badge_service.dart';

import '../../../../mocks/repository_mocks.dart';

/// Helper to create a test DataDrivenScreenDefinition with required fields.
DataDrivenScreenDefinition _makeScreen({
  required String id,
  required String name,
  ScreenCategory category = ScreenCategory.workspace,
  List<Section> sections = const [],
}) {
  final now = DateTime.now();
  return DataDrivenScreenDefinition(
    id: id,
    screenKey: 'test-$id',
    name: name,
    screenType: ScreenType.list,
    createdAt: now,
    updatedAt: now,
    category: category,
    sections: sections,
  );
}

void main() {
  late NavigationBadgeService badgeService;
  late MockTaskRepositoryContract taskRepo;
  late MockProjectRepositoryContract projectRepo;

  setUp(() {
    taskRepo = MockTaskRepositoryContract();
    projectRepo = MockProjectRepositoryContract();
    badgeService = NavigationBadgeService(
      taskRepository: taskRepo,
      projectRepository: projectRepo,
    );
  });

  group('NavigationBadgeService', () {
    group('badgeStreamFor', () {
      test('returns null for non-workspace category', () {
        final screen = _makeScreen(
          id: 'wellbeing-1',
          name: 'Wellbeing',
          category: ScreenCategory.wellbeing,
          sections: [
            DataSection(
              config: DataConfig.task(query: TaskQuery.all()),
              title: 'Tasks',
            ),
          ],
        );

        final stream = badgeService.badgeStreamFor(screen);

        expect(stream, isNull);
      });

      test('returns null when no data sections', () {
        final screen = _makeScreen(
          id: 'empty-1',
          name: 'Empty',
          category: ScreenCategory.workspace,
        );

        final stream = badgeService.badgeStreamFor(screen);

        expect(stream, isNull);
      });

      test('returns task count stream for task data section', () {
        final taskQuery = TaskQuery.incomplete();
        final screen = _makeScreen(
          id: 'inbox-1',
          name: 'Inbox',
          category: ScreenCategory.workspace,
          sections: [
            DataSection(
              config: DataConfig.task(query: taskQuery),
              title: 'Tasks',
            ),
          ],
        );

        when(
          () => taskRepo.watchCount(taskQuery),
        ).thenAnswer((_) => Stream.value(5));

        final stream = badgeService.badgeStreamFor(screen);

        expect(stream, isNotNull);
        verify(() => taskRepo.watchCount(taskQuery)).called(1);
      });

      test('returns project count stream for project data section', () {
        final projectQuery = ProjectQuery.incomplete();
        final screen = _makeScreen(
          id: 'projects-1',
          name: 'Projects',
          category: ScreenCategory.workspace,
          sections: [
            DataSection(
              config: DataConfig.project(query: projectQuery),
              title: 'Projects',
            ),
          ],
        );

        when(
          () => projectRepo.watchCount(projectQuery),
        ).thenAnswer((_) => Stream.value(3));

        final stream = badgeService.badgeStreamFor(screen);

        expect(stream, isNotNull);
        verify(() => projectRepo.watchCount(projectQuery)).called(1);
      });

      test('returns null for value data section', () {
        final screen = _makeScreen(
          id: 'values-1',
          name: 'Values',
          category: ScreenCategory.workspace,
          sections: [
            DataSection(
              config: DataConfig.value(),
              title: 'Values',
            ),
          ],
        );

        final stream = badgeService.badgeStreamFor(screen);

        expect(stream, isNull);
      });

      test('returns null for value data section', () {
        final screen = _makeScreen(
          id: 'values-1',
          name: 'Values',
          category: ScreenCategory.workspace,
          sections: [
            DataSection(
              config: DataConfig.value(),
              title: 'Values',
            ),
          ],
        );

        final stream = badgeService.badgeStreamFor(screen);

        expect(stream, isNull);
      });

      test('uses first data section when multiple sections exist', () {
        final taskQuery = TaskQuery.incomplete();
        final projectQuery = ProjectQuery.all();
        final screen = _makeScreen(
          id: 'mixed-1',
          name: 'Mixed',
          category: ScreenCategory.workspace,
          sections: [
            DataSection(
              config: DataConfig.task(query: taskQuery),
              title: 'Tasks First',
            ),
            DataSection(
              config: DataConfig.project(query: projectQuery),
              title: 'Projects Second',
            ),
          ],
        );

        when(
          () => taskRepo.watchCount(taskQuery),
        ).thenAnswer((_) => Stream.value(10));

        badgeService.badgeStreamFor(screen);

        verify(() => taskRepo.watchCount(taskQuery)).called(1);
        verifyNever(() => projectRepo.watchCount(any()));
      });
    });

    group('getTaskQueryForScreen', () {
      test('returns null for non-workspace category', () {
        final screen = _makeScreen(
          id: 'settings-1',
          name: 'Settings',
          category: ScreenCategory.settings,
          sections: [
            DataSection(
              config: DataConfig.task(query: TaskQuery.all()),
              title: 'Tasks',
            ),
          ],
        );

        final query = badgeService.getTaskQueryForScreen(screen);

        expect(query, isNull);
      });

      test('returns null when no data sections', () {
        final screen = _makeScreen(
          id: 'empty-1',
          name: 'Empty',
          category: ScreenCategory.workspace,
        );

        final query = badgeService.getTaskQueryForScreen(screen);

        expect(query, isNull);
      });

      test('returns task query from task data section', () {
        final taskQuery = TaskQuery.inbox();
        final screen = _makeScreen(
          id: 'inbox-1',
          name: 'Inbox',
          category: ScreenCategory.workspace,
          sections: [
            DataSection(
              config: DataConfig.task(query: taskQuery),
              title: 'Tasks',
            ),
          ],
        );

        final query = badgeService.getTaskQueryForScreen(screen);

        expect(query, taskQuery);
      });

      test('returns null for project data section', () {
        final screen = _makeScreen(
          id: 'projects-1',
          name: 'Projects',
          category: ScreenCategory.workspace,
          sections: [
            DataSection(
              config: DataConfig.project(query: ProjectQuery.all()),
              title: 'Projects',
            ),
          ],
        );

        final query = badgeService.getTaskQueryForScreen(screen);

        expect(query, isNull);
      });
    });

    group('getProjectQueryForScreen', () {
      test('returns null for non-workspace category', () {
        final screen = _makeScreen(
          id: 'wellbeing-1',
          name: 'Wellbeing',
          category: ScreenCategory.wellbeing,
          sections: [
            DataSection(
              config: DataConfig.project(query: ProjectQuery.all()),
              title: 'Projects',
            ),
          ],
        );

        final query = badgeService.getProjectQueryForScreen(screen);

        expect(query, isNull);
      });

      test('returns null when no data sections', () {
        final screen = _makeScreen(
          id: 'empty-1',
          name: 'Empty',
          category: ScreenCategory.workspace,
        );

        final query = badgeService.getProjectQueryForScreen(screen);

        expect(query, isNull);
      });

      test('returns project query from project data section', () {
        final projectQuery = ProjectQuery.incomplete();
        final screen = _makeScreen(
          id: 'projects-1',
          name: 'Projects',
          category: ScreenCategory.workspace,
          sections: [
            DataSection(
              config: DataConfig.project(query: projectQuery),
              title: 'Projects',
            ),
          ],
        );

        final query = badgeService.getProjectQueryForScreen(screen);

        expect(query, projectQuery);
      });

      test('returns null for task data section', () {
        final screen = _makeScreen(
          id: 'tasks-1',
          name: 'Tasks',
          category: ScreenCategory.workspace,
          sections: [
            DataSection(
              config: DataConfig.task(query: TaskQuery.all()),
              title: 'Tasks',
            ),
          ],
        );

        final query = badgeService.getProjectQueryForScreen(screen);

        expect(query, isNull);
      });
    });
  });
}
