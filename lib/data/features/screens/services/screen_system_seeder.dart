import 'package:taskly_bloc/domain/models/screens/display_config.dart'
    as screen_models;
import 'package:taskly_bloc/domain/models/screens/entity_selector.dart'
    as screen_models;
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart';
import 'package:taskly_bloc/domain/repositories/screen_definitions_repository.dart';
import 'package:uuid/uuid.dart';

/// Seeds the required built-in system screens if they are missing.
class ScreenSystemSeeder {
  ScreenSystemSeeder({required ScreenDefinitionsRepository screensRepository})
    : _screensRepository = screensRepository;

  final ScreenDefinitionsRepository _screensRepository;
  final Uuid _uuid = const Uuid();

  Future<void> seedDefaults() async {
    await _ensureScreen(
      screen: _taskScreen(
        screenId: 'inbox',
        name: 'Inbox',
        iconName: 'inbox',
        sortOrder: 0,
        filter: const QueryFilter<TaskPredicate>(
          shared: [
            TaskBoolPredicate(
              field: TaskBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
            TaskProjectPredicate(operator: ProjectOperator.isNull),
          ],
        ),
      ),
    );

    await _ensureScreen(
      screen: _taskScreen(
        screenId: 'today',
        name: 'Today',
        iconName: 'today',
        sortOrder: 1,
        filter: QueryFilter<TaskPredicate>(
          shared: const [
            TaskBoolPredicate(
              field: TaskBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
            TaskDatePredicate(
              field: TaskDateField.deadlineDate,
              operator: DateOperator.relative,
              relativeComparison: RelativeComparison.onOrBefore,
              relativeDays: 0,
            ),
          ],
        ),
      ),
    );

    await _ensureScreen(
      screen: _taskScreen(
        screenId: 'upcoming',
        name: 'Upcoming',
        iconName: 'upcoming',
        sortOrder: 2,
        filter: const QueryFilter<TaskPredicate>(
          shared: [
            TaskBoolPredicate(
              field: TaskBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
            TaskDatePredicate(
              field: TaskDateField.deadlineDate,
              operator: DateOperator.isNotNull,
            ),
          ],
        ),
      ),
    );

    await _ensureScreen(
      screen: _taskScreen(
        screenId: 'next_actions',
        name: 'Next Actions',
        iconName: 'next_actions',
        sortOrder: 3,
        filter: const QueryFilter<TaskPredicate>(
          shared: [
            TaskBoolPredicate(
              field: TaskBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
            TaskProjectPredicate(operator: ProjectOperator.isNotNull),
          ],
        ),
      ),
    );

    await _ensureScreen(
      screen: _projectScreen(
        screenId: 'projects',
        name: 'Projects',
        iconName: 'projects',
        sortOrder: 4,
      ),
    );

    await _ensureScreen(
      screen: _labelScreen(
        screenId: 'labels',
        name: 'Labels',
        iconName: 'labels',
        sortOrder: 5,
      ),
    );

    await _ensureScreen(
      screen: _labelScreen(
        screenId: 'values',
        name: 'Values',
        iconName: 'values',
        sortOrder: 6,
      ),
    );
  }

  ScreenDefinition _taskScreen({
    required String screenId,
    required String name,
    required String iconName,
    required int sortOrder,
    required QueryFilter<TaskPredicate> filter,
  }) {
    final now = DateTime.now();
    return ScreenDefinition.collection(
      id: _uuid.v4(),
      userId: '',
      screenId: screenId,
      name: name,
      selector: screen_models.EntitySelector(
        entityType: screen_models.EntityType.task,
        taskFilter: filter,
      ),
      display: const screen_models.DisplayConfig(
        sorting: [
          screen_models.SortCriterion(
            field: screen_models.SortField.deadlineDate,
          ),
          screen_models.SortCriterion(field: screen_models.SortField.name),
        ],
        showCompleted: false,
      ),
      createdAt: now,
      updatedAt: now,
      isSystem: true,
      sortOrder: sortOrder,
      iconName: iconName,
    );
  }

  ScreenDefinition _projectScreen({
    required String screenId,
    required String name,
    required String iconName,
    required int sortOrder,
  }) {
    final now = DateTime.now();
    return ScreenDefinition.collection(
      id: _uuid.v4(),
      userId: '',
      screenId: screenId,
      name: name,
      selector: screen_models.EntitySelector(
        entityType: screen_models.EntityType.project,
        projectFilter: const QueryFilter.matchAll(),
      ),
      display: const screen_models.DisplayConfig(
        sorting: [
          screen_models.SortCriterion(field: screen_models.SortField.name),
        ],
        showCompleted: false,
      ),
      createdAt: now,
      updatedAt: now,
      isSystem: true,
      sortOrder: sortOrder,
      iconName: iconName,
    );
  }

  ScreenDefinition _labelScreen({
    required String screenId,
    required String name,
    required String iconName,
    required int sortOrder,
  }) {
    final now = DateTime.now();
    return ScreenDefinition.collection(
      id: _uuid.v4(),
      userId: '',
      screenId: screenId,
      name: name,
      selector: const screen_models.EntitySelector(
        entityType: screen_models.EntityType.label,
      ),
      display: const screen_models.DisplayConfig(
        sorting: [
          screen_models.SortCriterion(field: screen_models.SortField.name),
        ],
        showCompleted: false,
      ),
      createdAt: now,
      updatedAt: now,
      isSystem: true,
      sortOrder: sortOrder,
      iconName: iconName,
    );
  }

  Future<void> _ensureScreen({required ScreenDefinition screen}) async {
    final existing = await _screensRepository
        .watchScreenByScreenId(screen.screenId)
        .first;

    if (existing != null) {
      final shouldUpdate =
          (existing.iconName ?? '').isEmpty ||
          existing.sortOrder != screen.sortOrder ||
          !existing.isSystem;

      if (shouldUpdate) {
        await _screensRepository.updateScreen(
          existing.copyWith(
            iconName: screen.iconName,
            sortOrder: screen.sortOrder,
            isSystem: true,
            isActive: true,
          ),
        );
      }
      return;
    }

    await _screensRepository.createScreen(screen);
  }
}
