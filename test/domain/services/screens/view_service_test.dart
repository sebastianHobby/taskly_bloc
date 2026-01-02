import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/screens/view_definition.dart';
import 'package:taskly_bloc/domain/models/screens/entity_selector.dart';
import 'package:taskly_bloc/domain/models/screens/display_config.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/services/screens/view_service.dart';
import 'package:taskly_bloc/domain/services/screens/screen_query_builder.dart';

import '../../../fixtures/test_data.dart';
import '../../../helpers/fallback_values.dart';
import '../../../helpers/test_helpers.dart';
import '../../../mocks/fake_repositories.dart';

void main() {
  setUpAll(registerAllFallbackValues);

  late ViewService viewService;
  late FakeTaskRepository taskRepo;
  late FakeProjectRepository projectRepo;
  late FakeLabelRepository labelRepo;
  late ScreenQueryBuilder queryBuilder;

  setUp(() {
    taskRepo = FakeTaskRepository();
    projectRepo = FakeProjectRepository();
    labelRepo = FakeLabelRepository();
    queryBuilder = ScreenQueryBuilder();
    viewService = ViewService(
      taskRepository: taskRepo,
      projectRepository: projectRepo,
      labelRepository: labelRepo,
      queryBuilder: queryBuilder,
    );
  });

  group('ViewService', () {
    group('watchCollectionView', () {
      test('emits tasks when entityType is task', () async {
        taskRepo.pushTasks([TestData.task(id: '1'), TestData.task(id: '2')]);
        const selector = EntitySelector(entityType: EntityType.task);
        const display = DisplayConfig();

        final result = await viewService
            .watchCollectionView(selector: selector, display: display)
            .first
            .timeout(kDefaultStreamTimeout);

        expect(result, hasLength(2));
      });

      test('emits projects when entityType is project', () async {
        projectRepo.pushProjects([TestData.project(id: '1')]);
        const selector = EntitySelector(entityType: EntityType.project);
        const display = DisplayConfig();

        final result = await viewService
            .watchCollectionView(selector: selector, display: display)
            .first
            .timeout(kDefaultStreamTimeout);

        expect(result, hasLength(1));
      });

      test('emits labels when entityType is label', () async {
        labelRepo.pushLabels([
          TestData.label(id: '1'),
          TestData.label(id: '2', type: LabelType.value),
        ]);
        const selector = EntitySelector(entityType: EntityType.label);
        const display = DisplayConfig();

        final result = await viewService
            .watchCollectionView(selector: selector, display: display)
            .first
            .timeout(kDefaultStreamTimeout);

        expect(result, hasLength(2));
      });

      test('emits only value labels when entityType is goal', () async {
        labelRepo.pushLabels([
          TestData.label(id: '1'),
          TestData.label(id: '2', type: LabelType.value),
          TestData.label(id: '3', type: LabelType.value),
        ]);
        const selector = EntitySelector(entityType: EntityType.goal);
        const display = DisplayConfig();

        final result = await viewService
            .watchCollectionView(selector: selector, display: display)
            .first
            .timeout(kDefaultStreamTimeout);

        expect(result, hasLength(2));
        for (final item in result) {
          expect((item as Label).type, LabelType.value);
        }
      });

      test('emits empty list when no tasks exist', () async {
        taskRepo.pushTasks([]);
        const selector = EntitySelector(entityType: EntityType.task);
        const display = DisplayConfig();

        final result = await viewService
            .watchCollectionView(selector: selector, display: display)
            .first
            .timeout(kDefaultStreamTimeout);

        expect(result, isEmpty);
      });
    });

    group('watchAgendaView', () {
      test('throws when entityType is not task', () {
        const selector = EntitySelector(entityType: EntityType.project);
        const display = DisplayConfig();
        const agendaConfig = AgendaConfig(
          dateField: DateField.deadlineDate,
          groupingStrategy: AgendaGrouping.today,
        );

        expect(
          () => viewService.watchAgendaView(
            selector: selector,
            display: display,
            agendaConfig: agendaConfig,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('emits tasks with deadline dates', () async {
        taskRepo.pushTasks([
          TestData.task(id: '1', deadlineDate: DateTime(2025, 1, 15)),
          TestData.task(id: '2', deadlineDate: DateTime(2025, 1, 16)),
          TestData.task(id: '3'), // No deadline
        ]);
        const selector = EntitySelector(entityType: EntityType.task);
        const display = DisplayConfig();
        const agendaConfig = AgendaConfig(
          dateField: DateField.deadlineDate,
          groupingStrategy: AgendaGrouping.today,
        );

        final result = await viewService
            .watchAgendaView(
              selector: selector,
              display: display,
              agendaConfig: agendaConfig,
            )
            .first
            .timeout(kDefaultStreamTimeout);

        expect(result, hasLength(2));
      });

      test('emits tasks with start dates when using startDate field', () async {
        taskRepo.pushTasks([
          TestData.task(id: '1', startDate: DateTime(2025, 1, 15)),
          TestData.task(id: '2'), // No start date
        ]);
        const selector = EntitySelector(entityType: EntityType.task);
        const display = DisplayConfig();
        const agendaConfig = AgendaConfig(
          dateField: DateField.startDate,
          groupingStrategy: AgendaGrouping.thisWeek,
        );

        final result = await viewService
            .watchAgendaView(
              selector: selector,
              display: display,
              agendaConfig: agendaConfig,
            )
            .first
            .timeout(kDefaultStreamTimeout);

        expect(result, hasLength(1));
      });
    });

    group('watchAllocatedView', () {
      test('throws when entityType is not task', () {
        const selector = EntitySelector(entityType: EntityType.label);
        const display = DisplayConfig();

        expect(
          () => viewService.watchAllocatedView(
            selector: selector,
            display: display,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('emits all matching tasks', () async {
        taskRepo.pushTasks([
          TestData.task(id: '1'),
          TestData.task(id: '2'),
        ]);
        const selector = EntitySelector(entityType: EntityType.task);
        const display = DisplayConfig();

        final result = await viewService
            .watchAllocatedView(selector: selector, display: display)
            .first
            .timeout(kDefaultStreamTimeout);

        expect(result, hasLength(2));
      });
    });

    group('watchDetailEntity', () {
      test('emits project for project parent type', () async {
        final testProject = TestData.project(id: 'project-1');
        projectRepo.pushProjects([testProject]);

        final result = await viewService
            .watchDetailEntity(
              parentType: DetailParentType.project,
              entityId: 'project-1',
            )
            .first
            .timeout(kDefaultStreamTimeout);

        expect(result, isNotNull);
        // ignore: avoid_dynamic_calls, Dynamic access needed for polymorphic entity
        expect(result.id, 'project-1');
      });

      test('emits label for label parent type', () async {
        final testLabel = TestData.label(id: 'label-1');
        labelRepo.pushLabels([testLabel]);

        final result = await viewService
            .watchDetailEntity(
              parentType: DetailParentType.label,
              entityId: 'label-1',
            )
            .first
            .timeout(kDefaultStreamTimeout);

        expect(result, isNotNull);
        // ignore: avoid_dynamic_calls, Dynamic access needed for polymorphic entity
        expect(result.id, 'label-1');
      });
    });

    group('watchViewCount', () {
      test('emits task count for task entity type', () async {
        taskRepo.pushTasks([
          TestData.task(id: '1'),
          TestData.task(id: '2'),
          TestData.task(id: '3'),
        ]);
        const selector = EntitySelector(entityType: EntityType.task);
        const display = DisplayConfig();

        final result = await viewService
            .watchViewCount(selector: selector, display: display)
            .first
            .timeout(kDefaultStreamTimeout);

        expect(result, 3);
      });

      test('emits project count for project entity type', () async {
        projectRepo.pushProjects([
          TestData.project(id: '1'),
          TestData.project(id: '2'),
        ]);
        const selector = EntitySelector(entityType: EntityType.project);
        const display = DisplayConfig();

        final result = await viewService
            .watchViewCount(selector: selector, display: display)
            .first
            .timeout(kDefaultStreamTimeout);

        expect(result, 2);
      });

      test('emits 0 for label entity type', () async {
        const selector = EntitySelector(entityType: EntityType.label);
        const display = DisplayConfig();

        final result = await viewService
            .watchViewCount(selector: selector, display: display)
            .first
            .timeout(kDefaultStreamTimeout);

        expect(result, 0);
      });

      test('emits 0 for goal entity type', () async {
        const selector = EntitySelector(entityType: EntityType.goal);
        const display = DisplayConfig();

        final result = await viewService
            .watchViewCount(selector: selector, display: display)
            .first
            .timeout(kDefaultStreamTimeout);

        expect(result, 0);
      });
    });
  });
}
