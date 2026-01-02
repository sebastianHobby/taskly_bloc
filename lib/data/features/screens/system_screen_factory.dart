import 'package:taskly_bloc/data/services/system_screen_seeder.dart'
    show SystemScreenSeeder;
import 'package:taskly_bloc/domain/models/screens/display_config.dart';
import 'package:taskly_bloc/domain/models/screens/entity_selector.dart';
import 'package:taskly_bloc/domain/models/screens/screen_category.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/screens/view_definition.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart';

/// Factory for creating system screen definitions.
///
/// Creates screen definitions with empty IDs. The repository will generate
/// deterministic v5 IDs based on screenKey when seeding.
///
/// System screens are seeded to the database on login via [SystemScreenSeeder].
class SystemScreenFactory {
  SystemScreenFactory._();

  // =========================================================================
  // Screen Keys
  // =========================================================================

  /// All system screen keys in display order.
  static const List<String> allKeys = [
    inbox,
    today,
    upcoming,
    nextActions,
    projects,
    labels,
    values,
    wellbeing,
    journal,
    trackers,
    allocationSettings,
    navigationSettings,
    settings,
  ];

  // Screen keys as constants for type-safe references
  static const String inbox = 'inbox';
  static const String today = 'today';
  static const String upcoming = 'upcoming';
  static const String nextActions = 'next_actions';
  static const String projects = 'projects';
  static const String labels = 'labels';
  static const String values = 'values';
  static const String wellbeing = 'wellbeing';
  static const String journal = 'journal';
  static const String trackers = 'trackers';
  static const String allocationSettings = 'allocation_settings';
  static const String navigationSettings = 'navigation_settings';
  static const String settings = 'settings';

  /// Default sort orders for system screens.
  static const Map<String, int> defaultSortOrders = {
    inbox: 0,
    today: 1,
    upcoming: 2,
    nextActions: 3,
    projects: 4,
    labels: 5,
    values: 6,
    wellbeing: 100,
    journal: 101,
    trackers: 102,
    allocationSettings: 200,
    navigationSettings: 201,
    settings: 202,
  };

  // =========================================================================
  // Factory Methods
  // =========================================================================

  /// Check if a screen key is a system screen.
  static bool isSystemScreen(String screenKey) {
    return allKeys.contains(screenKey);
  }

  /// Get the category for a screen key.
  static ScreenCategory getCategoryForKey(String screenKey) {
    switch (screenKey) {
      case wellbeing:
      case journal:
      case trackers:
        return ScreenCategory.wellbeing;
      case allocationSettings:
      case navigationSettings:
      case settings:
        return ScreenCategory.settings;
      default:
        return ScreenCategory.workspace;
    }
  }

  /// Creates all system screen definitions for a user.
  ///
  /// Screens are created with empty IDs. The repository will generate
  /// deterministic v5 IDs based on screenKey during seeding.
  static List<ScreenDefinition> createAll(String userId) {
    final now = DateTime.now();
    return [
      _createInbox(userId, now),
      _createToday(userId, now),
      _createUpcoming(userId, now),
      _createNextActions(userId, now),
      _createProjects(userId, now),
      _createLabels(userId, now),
      _createValues(userId, now),
      _createWellbeing(userId, now),
      _createJournal(userId, now),
      _createTrackers(userId, now),
      _createAllocationSettings(userId, now),
      _createNavigationSettings(userId, now),
      _createSettings(userId, now),
    ];
  }

  /// Creates a specific system screen definition by key.
  ///
  /// Returns null if the screenKey is not a system screen.
  static ScreenDefinition? create(String userId, String screenKey) {
    final now = DateTime.now();
    return switch (screenKey) {
      inbox => _createInbox(userId, now),
      today => _createToday(userId, now),
      upcoming => _createUpcoming(userId, now),
      nextActions => _createNextActions(userId, now),
      projects => _createProjects(userId, now),
      labels => _createLabels(userId, now),
      values => _createValues(userId, now),
      wellbeing => _createWellbeing(userId, now),
      journal => _createJournal(userId, now),
      trackers => _createTrackers(userId, now),
      allocationSettings => _createAllocationSettings(userId, now),
      navigationSettings => _createNavigationSettings(userId, now),
      settings => _createSettings(userId, now),
      _ => null,
    };
  }

  // =========================================================================
  // Screen Definitions
  // =========================================================================

  static ScreenDefinition _createInbox(String userId, DateTime now) {
    return _taskScreen(
      userId: userId,
      screenKey: inbox,
      name: 'Inbox',
      iconName: 'inbox',
      sortOrder: defaultSortOrders[inbox]!,
      filter: const QueryFilter<TaskPredicate>(
        shared: [
          TaskBoolPredicate(
            field: TaskBoolField.completed,
            operator: BoolOperator.isFalse,
          ),
          TaskProjectPredicate(operator: ProjectOperator.isNull),
        ],
      ),
      now: now,
    );
  }

  static ScreenDefinition _createToday(String userId, DateTime now) {
    return _taskScreen(
      userId: userId,
      screenKey: today,
      name: 'Today',
      iconName: 'today',
      sortOrder: defaultSortOrders[today]!,
      filter: const QueryFilter<TaskPredicate>(
        shared: [
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
      now: now,
    );
  }

  static ScreenDefinition _createUpcoming(String userId, DateTime now) {
    return _taskScreen(
      userId: userId,
      screenKey: upcoming,
      name: 'Upcoming',
      iconName: 'upcoming',
      sortOrder: defaultSortOrders[upcoming]!,
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
      now: now,
    );
  }

  static ScreenDefinition _createNextActions(String userId, DateTime now) {
    return _taskScreen(
      userId: userId,
      screenKey: nextActions,
      name: 'Next Actions',
      iconName: 'next_actions',
      sortOrder: defaultSortOrders[nextActions]!,
      filter: const QueryFilter<TaskPredicate>(
        shared: [
          TaskBoolPredicate(
            field: TaskBoolField.completed,
            operator: BoolOperator.isFalse,
          ),
          TaskProjectPredicate(operator: ProjectOperator.isNotNull),
        ],
      ),
      now: now,
    );
  }

  static ScreenDefinition _createProjects(String userId, DateTime now) {
    return _projectScreen(
      userId: userId,
      screenKey: projects,
      name: 'Projects',
      iconName: 'projects',
      sortOrder: defaultSortOrders[projects]!,
      now: now,
    );
  }

  static ScreenDefinition _createLabels(String userId, DateTime now) {
    return _labelScreen(
      userId: userId,
      screenKey: labels,
      name: 'Labels',
      iconName: 'labels',
      sortOrder: defaultSortOrders[labels]!,
      now: now,
    );
  }

  static ScreenDefinition _createValues(String userId, DateTime now) {
    return _labelScreen(
      userId: userId,
      screenKey: values,
      name: 'Values',
      iconName: 'values',
      sortOrder: defaultSortOrders[values]!,
      now: now,
    );
  }

  static ScreenDefinition _createWellbeing(String userId, DateTime now) {
    return _utilityScreen(
      userId: userId,
      screenKey: wellbeing,
      name: 'Wellbeing',
      iconName: 'wellbeing',
      sortOrder: defaultSortOrders[wellbeing]!,
      category: ScreenCategory.wellbeing,
      now: now,
    );
  }

  static ScreenDefinition _createJournal(String userId, DateTime now) {
    return _utilityScreen(
      userId: userId,
      screenKey: journal,
      name: 'Journal',
      iconName: 'journal',
      sortOrder: defaultSortOrders[journal]!,
      category: ScreenCategory.wellbeing,
      now: now,
    );
  }

  static ScreenDefinition _createTrackers(String userId, DateTime now) {
    return _utilityScreen(
      userId: userId,
      screenKey: trackers,
      name: 'Trackers',
      iconName: 'trackers',
      sortOrder: defaultSortOrders[trackers]!,
      category: ScreenCategory.wellbeing,
      now: now,
    );
  }

  static ScreenDefinition _createAllocationSettings(
    String userId,
    DateTime now,
  ) {
    return _utilityScreen(
      userId: userId,
      screenKey: allocationSettings,
      name: 'Allocation',
      iconName: 'allocation_settings',
      sortOrder: defaultSortOrders[allocationSettings]!,
      category: ScreenCategory.settings,
      now: now,
    );
  }

  static ScreenDefinition _createNavigationSettings(
    String userId,
    DateTime now,
  ) {
    return _utilityScreen(
      userId: userId,
      screenKey: navigationSettings,
      name: 'Navigation',
      iconName: 'navigation_settings',
      sortOrder: defaultSortOrders[navigationSettings]!,
      category: ScreenCategory.settings,
      now: now,
    );
  }

  static ScreenDefinition _createSettings(String userId, DateTime now) {
    return _utilityScreen(
      userId: userId,
      screenKey: settings,
      name: 'Settings',
      iconName: 'settings',
      sortOrder: defaultSortOrders[settings]!,
      category: ScreenCategory.settings,
      now: now,
    );
  }

  // =========================================================================
  // Helper Methods
  // =========================================================================

  static ScreenDefinition _taskScreen({
    required String userId,
    required String screenKey,
    required String name,
    required String iconName,
    required int sortOrder,
    required QueryFilter<TaskPredicate> filter,
    required DateTime now,
  }) {
    return ScreenDefinition(
      id: '', // Repository generates v5 ID based on screenKey
      screenKey: screenKey,
      name: name,
      view: ViewDefinition.collection(
        selector: EntitySelector(
          entityType: EntityType.task,
          taskFilter: filter,
        ),
        display: const DisplayConfig(
          sorting: [
            SortCriterion(field: SortField.deadlineDate),
            SortCriterion(field: SortField.name),
          ],
          showCompleted: false,
        ),
      ),
      createdAt: now,
      updatedAt: now,
      isSystem: true,
      sortOrder: sortOrder,
      iconName: iconName,
    );
  }

  static ScreenDefinition _projectScreen({
    required String userId,
    required String screenKey,
    required String name,
    required String iconName,
    required int sortOrder,
    required DateTime now,
  }) {
    return ScreenDefinition(
      id: '', // Repository generates v5 ID based on screenKey
      screenKey: screenKey,
      name: name,
      view: ViewDefinition.collection(
        selector: EntitySelector(
          entityType: EntityType.project,
          projectFilter: const QueryFilter.matchAll(),
        ),
        display: const DisplayConfig(
          sorting: [SortCriterion(field: SortField.name)],
          showCompleted: false,
        ),
      ),
      createdAt: now,
      updatedAt: now,
      isSystem: true,
      sortOrder: sortOrder,
      iconName: iconName,
    );
  }

  static ScreenDefinition _labelScreen({
    required String userId,
    required String screenKey,
    required String name,
    required String iconName,
    required int sortOrder,
    required DateTime now,
  }) {
    return ScreenDefinition(
      id: '', // Repository generates v5 ID based on screenKey
      screenKey: screenKey,
      name: name,
      view: ViewDefinition.collection(
        selector: const EntitySelector(entityType: EntityType.label),
        display: const DisplayConfig(
          sorting: [SortCriterion(field: SortField.name)],
          showCompleted: false,
        ),
      ),
      createdAt: now,
      updatedAt: now,
      isSystem: true,
      sortOrder: sortOrder,
      iconName: iconName,
    );
  }

  static ScreenDefinition _utilityScreen({
    required String userId,
    required String screenKey,
    required String name,
    required String iconName,
    required int sortOrder,
    required ScreenCategory category,
    required DateTime now,
  }) {
    return ScreenDefinition(
      id: '', // Repository generates v5 ID based on screenKey
      screenKey: screenKey,
      name: name,
      view: ViewDefinition.collection(
        selector: const EntitySelector(
          entityType: EntityType.task,
          taskFilter: QueryFilter.matchAll(),
        ),
        display: const DisplayConfig(showCompleted: false),
      ),
      createdAt: now,
      updatedAt: now,
      isSystem: true,
      sortOrder: sortOrder,
      iconName: iconName,
      category: category,
    );
  }
}
