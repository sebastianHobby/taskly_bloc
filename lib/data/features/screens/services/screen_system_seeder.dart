import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/models/screens/display_config.dart'
    as screen_models;
import 'package:taskly_bloc/domain/models/screens/entity_selector.dart'
    as screen_models;
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart';
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';
import 'package:uuid/uuid.dart';

/// Seeds the required built-in system screens if they are missing.
class ScreenSystemSeeder {
  ScreenSystemSeeder({required ScreenDefinitionsRepositoryContract screensRepository})
    : _screensRepository = screensRepository;

  final ScreenDefinitionsRepositoryContract _screensRepository;
  final Uuid _uuid = const Uuid();

  /// Seeds all default system screens for the current user.
  ///
  /// Must be called after authentication. PowerSync/Supabase automatically
  /// set user_id on created records based on the current session.
  Future<void> seedDefaults() async {
    talker.serviceLog('ScreenSystemSeeder', 'seedDefaults START');
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
    talker.serviceLog(
      'ScreenSystemSeeder',
      'seedDefaults END - all screens seeded',
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
    talker.serviceLog(
      'ScreenSystemSeeder',
      '_ensureScreen: checking screenId="${screen.screenId}"',
    );
    try {
      final existing = await _screensRepository
          .watchScreenByScreenId(screen.screenId)
          .first;
      talker.serviceLog(
        'ScreenSystemSeeder',
        '_ensureScreen: existing=${existing == null ? "null" : "found(id=${existing.id})"}',
      );

      if (existing != null) {
        final shouldUpdate =
            (existing.iconName ?? '').isEmpty ||
            existing.sortOrder != screen.sortOrder ||
            !existing.isSystem;
        talker.serviceLog(
          'ScreenSystemSeeder',
          '_ensureScreen: shouldUpdate=$shouldUpdate',
        );

        if (shouldUpdate) {
          await _screensRepository.updateScreen(
            existing.copyWith(
              iconName: screen.iconName,
              sortOrder: screen.sortOrder,
              isSystem: true,
              isActive: true,
            ),
          );
          talker.serviceLog(
            'ScreenSystemSeeder',
            '_ensureScreen: updated ${screen.screenId}',
          );
        }
        return;
      }

      await _screensRepository.createScreen(screen);
      talker.serviceLog(
        'ScreenSystemSeeder',
        '_ensureScreen: created ${screen.screenId}',
      );
    } catch (e, st) {
      talker.handle(
        e,
        st,
        '[ScreenSystemSeeder] _ensureScreen ERROR for screenId="${screen.screenId}"',
      );
      rethrow;
    }
  }
}
