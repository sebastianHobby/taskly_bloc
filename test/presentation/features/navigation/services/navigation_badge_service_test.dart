import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/domain/screens/language/models/data_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/badge_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_chrome.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_spec.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/style_pack_v2.dart';
import 'package:taskly_bloc/domain/queries/project_query.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/presentation/features/navigation/services/navigation_badge_service.dart';

import '../../../../mocks/repository_mocks.dart';

ScreenSpec _makeScreen({
  required String id,
  required String name,
  ScreenChrome chrome = ScreenChrome.empty,
  SlottedModules modules = const SlottedModules(),
}) {
  return ScreenSpec(
    id: id,
    screenKey: 'test-$id',
    name: name,
    template: const ScreenTemplateSpec.standardScaffoldV1(),
    modules: modules,
    chrome: chrome,
  );
}

ListSectionParamsV2 _listParamsV2(DataConfig config) {
  return ListSectionParamsV2(
    config: config,
    pack: StylePackV2.standard,
    layout: const SectionLayoutSpecV2.flatList(),
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
        final screen = _makeScreen(
          id: 'settings-1',
          name: 'Settings',
          chrome: const ScreenChrome(badgeConfig: BadgeConfig.none()),
        );

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
          modules: SlottedModules(
            primary: [
              ScreenModuleSpec.taskListV2(
                params: _listParamsV2(DataConfig.task(query: taskQuery)),
                title: 'Tasks',
              ),
            ],
          ),
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
          modules: SlottedModules(
            primary: [
              ScreenModuleSpec.projectListV2(
                params: _listParamsV2(DataConfig.project(query: projectQuery)),
                title: 'Projects',
              ),
            ],
          ),
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
          modules: SlottedModules(
            primary: [
              ScreenModuleSpec.valueListV2(
                params: _listParamsV2(DataConfig.value()),
                title: 'Values',
              ),
            ],
          ),
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
          modules: SlottedModules(
            primary: [
              ScreenModuleSpec.taskListV2(
                params: _listParamsV2(DataConfig.task(query: taskQuery)),
                title: 'Tasks First',
              ),
              ScreenModuleSpec.projectListV2(
                params: _listParamsV2(
                  DataConfig.project(query: projectQuery),
                ),
                title: 'Projects Second',
              ),
            ],
          ),
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
        final screen = _makeScreen(
          id: 'settings-1',
          name: 'Settings',
          chrome: const ScreenChrome(badgeConfig: BadgeConfig.none()),
        );

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
          modules: SlottedModules(
            primary: [
              ScreenModuleSpec.taskListV2(
                params: _listParamsV2(DataConfig.task(query: taskQuery)),
                title: 'Tasks',
              ),
            ],
          ),
        );

        final query = badgeService.getTaskQueryForScreen(screen);

        expect(query, taskQuery);
      });

      test('returns null for project data section', () {
        final projectQuery = ProjectQuery.incomplete();
        final screen = _makeScreen(
          id: 'projects-1',
          name: 'Projects',
          modules: SlottedModules(
            primary: [
              ScreenModuleSpec.projectListV2(
                params: _listParamsV2(
                  DataConfig.project(query: projectQuery),
                ),
              ),
            ],
          ),
        );

        final query = badgeService.getTaskQueryForScreen(screen);

        expect(query, isNull);
      });
    });

    group('getProjectQueryForScreen', () {
      test('returns null for navigation-only screens', () {
        final screen = _makeScreen(
          id: 'settings-1',
          name: 'Settings',
          chrome: const ScreenChrome(badgeConfig: BadgeConfig.none()),
        );

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
          modules: SlottedModules(
            primary: [
              ScreenModuleSpec.projectListV2(
                params: _listParamsV2(
                  DataConfig.project(query: projectQuery),
                ),
                title: 'Projects',
              ),
            ],
          ),
        );

        final query = badgeService.getProjectQueryForScreen(screen);

        expect(query, projectQuery);
      });

      test('returns null for task data section', () {
        final screen = _makeScreen(
          id: 'tasks-1',
          name: 'Tasks',
          modules: SlottedModules(
            primary: [
              ScreenModuleSpec.taskListV2(
                params: _listParamsV2(
                  DataConfig.task(query: TaskQuery.all()),
                ),
                title: 'Tasks',
              ),
            ],
          ),
        );

        final query = badgeService.getProjectQueryForScreen(screen);

        expect(query, isNull);
      });
    });
  });
}
