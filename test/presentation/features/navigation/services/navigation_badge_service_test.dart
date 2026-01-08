import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/domain/models/screens/data_config.dart';
import 'package:taskly_bloc/domain/models/screens/screen_chrome.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/screens/section_ref.dart';
import 'package:taskly_bloc/domain/models/screens/section_template_id.dart';
import 'package:taskly_bloc/domain/models/screens/templates/data_list_section_params.dart';
import 'package:taskly_bloc/domain/models/screens/templates/screen_item_tile_variants.dart';
import 'package:taskly_bloc/domain/queries/project_query.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/presentation/features/navigation/services/navigation_badge_service.dart';

import '../../../../mocks/repository_mocks.dart';

ScreenDefinition _makeScreen({
  required String id,
  required String name,
  List<SectionRef> sections = const [],
  ScreenChrome chrome = ScreenChrome.empty,
}) {
  final now = DateTime.now();
  return ScreenDefinition(
    id: id,
    screenKey: 'test-$id',
    name: name,
    createdAt: now,
    updatedAt: now,
    sections: sections,
    chrome: chrome,
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
      test('returns null for navigation-only screens', () {
        final screen = _makeScreen(id: 'settings-1', name: 'Settings');

        final stream = badgeService.badgeStreamFor(screen);

        expect(stream, isNull);
      });

      test('returns null when no data sections', () {
        final screen = _makeScreen(
          id: 'empty-1',
          name: 'Empty',
        );

        final stream = badgeService.badgeStreamFor(screen);

        expect(stream, isNull);
      });

      test('returns task count stream for task data section', () {
        final taskQuery = TaskQuery.incomplete();
        final screen = _makeScreen(
          id: 'inbox-1',
          name: 'Inbox',
          sections: [
            SectionRef(
              templateId: SectionTemplateId.taskList,
              params: DataListSectionParams(
                config: DataConfig.task(query: taskQuery),
                taskTileVariant: TaskTileVariant.listTile,
                projectTileVariant: ProjectTileVariant.listTile,
                valueTileVariant: ValueTileVariant.compactCard,
              ).toJson(),
              overrides: const SectionOverrides(title: 'Tasks'),
            ),
          ],
        );

        when(
          () => taskRepo.watchAllCount(taskQuery),
        ).thenAnswer((_) => Stream.value(5));

        final stream = badgeService.badgeStreamFor(screen);

        expect(stream, isNotNull);
        verify(() => taskRepo.watchAllCount(taskQuery)).called(1);
      });

      test('returns project count stream for project data section', () {
        final projectQuery = ProjectQuery.incomplete();
        final screen = _makeScreen(
          id: 'projects-1',
          name: 'Projects',
          sections: [
            SectionRef(
              templateId: SectionTemplateId.projectList,
              params: DataListSectionParams(
                config: DataConfig.project(query: projectQuery),
                taskTileVariant: TaskTileVariant.listTile,
                projectTileVariant: ProjectTileVariant.listTile,
                valueTileVariant: ValueTileVariant.compactCard,
              ).toJson(),
              overrides: const SectionOverrides(title: 'Projects'),
            ),
          ],
        );

        when(
          () => projectRepo.watchAllCount(projectQuery),
        ).thenAnswer((_) => Stream.value(3));

        final stream = badgeService.badgeStreamFor(screen);

        expect(stream, isNotNull);
        verify(() => projectRepo.watchAllCount(projectQuery)).called(1);
      });

      test('returns null for value data section', () {
        final screen = _makeScreen(
          id: 'values-1',
          name: 'Values',
          sections: [
            SectionRef(
              templateId: SectionTemplateId.valueList,
              params: DataListSectionParams(
                config: DataConfig.value(),
                taskTileVariant: TaskTileVariant.listTile,
                projectTileVariant: ProjectTileVariant.listTile,
                valueTileVariant: ValueTileVariant.compactCard,
              ).toJson(),
              overrides: const SectionOverrides(title: 'Values'),
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
          sections: [
            SectionRef(
              templateId: SectionTemplateId.taskList,
              params: DataListSectionParams(
                config: DataConfig.task(query: taskQuery),
                taskTileVariant: TaskTileVariant.listTile,
                projectTileVariant: ProjectTileVariant.listTile,
                valueTileVariant: ValueTileVariant.compactCard,
              ).toJson(),
              overrides: const SectionOverrides(title: 'Tasks First'),
            ),
            SectionRef(
              templateId: SectionTemplateId.projectList,
              params: DataListSectionParams(
                config: DataConfig.project(query: projectQuery),
                taskTileVariant: TaskTileVariant.listTile,
                projectTileVariant: ProjectTileVariant.listTile,
                valueTileVariant: ValueTileVariant.compactCard,
              ).toJson(),
              overrides: const SectionOverrides(title: 'Projects Second'),
            ),
          ],
        );

        when(
          () => taskRepo.watchAllCount(taskQuery),
        ).thenAnswer((_) => Stream.value(10));

        badgeService.badgeStreamFor(screen);

        verify(() => taskRepo.watchAllCount(taskQuery)).called(1);
        verifyNever(() => projectRepo.watchAllCount(any()));
      });
    });

    group('getTaskQueryForScreen', () {
      test('returns null for navigation-only screens', () {
        final screen = _makeScreen(id: 'settings-1', name: 'Settings');

        final query = badgeService.getTaskQueryForScreen(screen);

        expect(query, isNull);
      });

      test('returns null when no data sections', () {
        final screen = _makeScreen(
          id: 'empty-1',
          name: 'Empty',
        );

        final query = badgeService.getTaskQueryForScreen(screen);

        expect(query, isNull);
      });

      test('returns task query from task data section', () {
        final taskQuery = TaskQuery.inbox();
        final screen = _makeScreen(
          id: 'inbox-1',
          name: 'Inbox',
          sections: [
            SectionRef(
              templateId: SectionTemplateId.taskList,
              params: DataListSectionParams(
                config: DataConfig.task(query: taskQuery),
                taskTileVariant: TaskTileVariant.listTile,
                projectTileVariant: ProjectTileVariant.listTile,
                valueTileVariant: ValueTileVariant.compactCard,
              ).toJson(),
              overrides: const SectionOverrides(title: 'Tasks'),
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
          sections: [
            SectionRef(
              templateId: SectionTemplateId.projectList,
              params: DataListSectionParams(
                config: DataConfig.project(query: ProjectQuery.all()),
                taskTileVariant: TaskTileVariant.listTile,
                projectTileVariant: ProjectTileVariant.listTile,
                valueTileVariant: ValueTileVariant.compactCard,
              ).toJson(),
              overrides: const SectionOverrides(title: 'Projects'),
            ),
          ],
        );

        final query = badgeService.getTaskQueryForScreen(screen);

        expect(query, isNull);
      });
    });

    group('getProjectQueryForScreen', () {
      test('returns null for navigation-only screens', () {
        final screen = _makeScreen(id: 'settings-1', name: 'Settings');

        final query = badgeService.getProjectQueryForScreen(screen);

        expect(query, isNull);
      });

      test('returns null when no data sections', () {
        final screen = _makeScreen(
          id: 'empty-1',
          name: 'Empty',
        );

        final query = badgeService.getProjectQueryForScreen(screen);

        expect(query, isNull);
      });

      test('returns project query from project data section', () {
        final projectQuery = ProjectQuery.incomplete();
        final screen = _makeScreen(
          id: 'projects-1',
          name: 'Projects',
          sections: [
            SectionRef(
              templateId: SectionTemplateId.projectList,
              params: DataListSectionParams(
                config: DataConfig.project(query: projectQuery),
                taskTileVariant: TaskTileVariant.listTile,
                projectTileVariant: ProjectTileVariant.listTile,
                valueTileVariant: ValueTileVariant.compactCard,
              ).toJson(),
              overrides: const SectionOverrides(title: 'Projects'),
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
          sections: [
            SectionRef(
              templateId: SectionTemplateId.taskList,
              params: DataListSectionParams(
                config: DataConfig.task(query: TaskQuery.all()),
                taskTileVariant: TaskTileVariant.listTile,
                projectTileVariant: ProjectTileVariant.listTile,
                valueTileVariant: ValueTileVariant.compactCard,
              ).toJson(),
              overrides: const SectionOverrides(title: 'Tasks'),
            ),
          ],
        );

        final query = badgeService.getProjectQueryForScreen(screen);

        expect(query, isNull);
      });
    });
  });
}
