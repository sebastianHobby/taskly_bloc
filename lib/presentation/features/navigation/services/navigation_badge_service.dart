import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/models/screens/screen_category.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/screens/view_definition.dart';
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
    // Only show badges for workspace screens (task lists, projects, etc.)
    // Wellbeing and settings screens don't need task count badges
    if (screen.category != ScreenCategory.workspace) {
      return null;
    }

    return screen.view.when(
      collection: (selector, display, supportBlocks) {
        switch (selector.entityType) {
          case EntityType.task:
            final query = _queryBuilder.buildTaskQuery(
              selector: selector,
              display: display,
              now: _nowFactory(),
            );
            return _taskRepository.watchCount(query);
          case EntityType.project:
            final query = _queryBuilder.buildProjectQuery(
              selector: selector,
              display: display,
            );
            return _projectRepository.watchCount(query);
          case EntityType.label:
          case EntityType.goal:
            return null;
        }
      },
      agenda: (selector, display, config, supportBlocks) => null,
      detail: (parentType, childView, supportBlocks) => null,
      allocated: (selector, display, supportBlocks) => null,
    );
  }
}
