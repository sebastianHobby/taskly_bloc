import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/screens/entity_selector.dart';
import 'package:taskly_bloc/domain/services/screens/screen_query_builder.dart';

class NavigationBadgeService {
  NavigationBadgeService({
    required ScreenQueryBuilder queryBuilder,
    required TaskRepositoryContract taskRepository,
    required ProjectRepositoryContract projectRepository,
    DateTime Function()? nowFactory,
  }) : _queryBuilder = queryBuilder,
       _taskRepository = taskRepository,
       _projectRepository = projectRepository,
       _nowFactory = nowFactory ?? DateTime.now;

  final ScreenQueryBuilder _queryBuilder;
  final TaskRepositoryContract _taskRepository;
  final ProjectRepositoryContract _projectRepository;
  final DateTime Function() _nowFactory;

  Stream<int>? badgeStreamFor(ScreenDefinition screen) {
    return screen.map(
      collection: (collection) {
        switch (collection.selector.entityType) {
          case EntityType.task:
            final query = _queryBuilder.buildTaskQuery(
              selector: collection.selector,
              display: collection.display,
              now: _nowFactory(),
            );
            return _taskRepository.watchCount(query);
          case EntityType.project:
            final query = _queryBuilder.buildProjectQuery(
              selector: collection.selector,
              display: collection.display,
            );
            return _projectRepository.watchCount(query);
          case EntityType.label:
          case EntityType.goal:
            return null;
        }
      },
      workflow: (workflow) {
        switch (workflow.selector.entityType) {
          case EntityType.task:
            final query = _queryBuilder.buildTaskQuery(
              selector: workflow.selector,
              display: workflow.display,
              now: _nowFactory(),
            );
            return _taskRepository.watchCount(query);
          case EntityType.project:
            final query = _queryBuilder.buildProjectQuery(
              selector: workflow.selector,
              display: workflow.display,
            );
            return _projectRepository.watchCount(query);
          case EntityType.label:
          case EntityType.goal:
            return null;
        }
      },
    );
  }
}
