import 'package:taskly_bloc/domain/models/screens/data_config.dart';
import 'package:taskly_bloc/domain/models/screens/display_config.dart';
import 'package:taskly_bloc/domain/models/screens/screen_category.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/screens/section.dart';
import 'package:taskly_bloc/domain/queries/label_query.dart';
import 'package:taskly_bloc/domain/queries/project_query.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';

/// Factory for creating system screen definitions.
///
/// System screens are the built-in screens that every user gets by default.
/// They include task views (Inbox, Today, Upcoming, etc.), project views,
/// label views, value views, and utility screens (Wellbeing, Settings, etc.).
///
/// ## Screen Key Convention
/// System screens use snake_case identifiers (e.g., `inbox`, `next_actions`).
/// These keys are used to generate deterministic v5 UUIDs during seeding.
///
/// ## ID Generation
/// Screen IDs are NOT generated here. The repository is responsible for
/// generating deterministic v5 IDs based on screenKey during seeding.
class SystemScreenFactory {
  SystemScreenFactory._();

  // =========================================================================
  // Screen Keys (snake_case)
  // =========================================================================

  /// Inbox screen key
  static const String inbox = 'inbox';

  /// Today screen key
  static const String today = 'today';

  /// Upcoming screen key
  static const String upcoming = 'upcoming';

  /// Next Actions screen key
  static const String nextActions = 'next_actions';

  /// Projects screen key
  static const String projects = 'projects';

  /// Labels screen key
  static const String labels = 'labels';

  /// Values screen key
  static const String values = 'values';

  /// Wellbeing screen key
  static const String wellbeing = 'wellbeing';

  /// Journal screen key
  static const String journal = 'journal';

  /// Trackers screen key
  static const String trackers = 'trackers';

  /// Allocation settings screen key
  static const String allocationSettings = 'allocation_settings';

  /// Navigation settings screen key
  static const String navigationSettings = 'navigation_settings';

  /// Settings screen key
  static const String settings = 'settings';

  /// All system screen keys
  static const List<String> allSystemScreenKeys = [
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

  /// Default sort orders for system screens
  static const Map<String, int> defaultSortOrders = {
    inbox: 0,
    today: 1,
    upcoming: 2,
    nextActions: 3,
    projects: 4,
    labels: 5,
    values: 6,
    wellbeing: 7,
    journal: 8,
    trackers: 9,
    allocationSettings: 10,
    navigationSettings: 11,
    settings: 12,
  };

  /// Alias for [allSystemScreenKeys] for convenience.
  static List<String> get allKeys => allSystemScreenKeys;

  /// Returns true if the given screenKey is a system screen.
  static bool isSystemScreen(String screenKey) {
    return allSystemScreenKeys.contains(screenKey);
  }

  /// Returns the [ScreenCategory] for the given system screen key.
  ///
  /// Returns [ScreenCategory.workspace] for unknown keys.
  static ScreenCategory getCategoryForKey(String screenKey) {
    return switch (screenKey) {
      inbox ||
      today ||
      upcoming ||
      nextActions ||
      projects ||
      labels ||
      values => ScreenCategory.workspace,
      wellbeing || journal || trackers => ScreenCategory.wellbeing,
      allocationSettings ||
      navigationSettings ||
      settings => ScreenCategory.settings,
      _ => ScreenCategory.workspace,
    };
  }

  /// Creates all system screen definitions for a user.
  ///
  /// The repository is responsible for generating deterministic v5 IDs
  /// based on screenKey during seeding.
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
      query: TaskQuery.inbox(),
      now: now,
    );
  }

  static ScreenDefinition _createToday(String userId, DateTime now) {
    return _agendaScreen(
      userId: userId,
      screenKey: today,
      name: 'Today',
      iconName: 'today',
      sortOrder: defaultSortOrders[today]!,
      dateField: AgendaDateField.deadlineDate,
      grouping: AgendaGrouping.overdueFirst,
      additionalFilter: TaskQuery.incomplete(),
      now: now,
    );
  }

  static ScreenDefinition _createUpcoming(String userId, DateTime now) {
    return _agendaScreen(
      userId: userId,
      screenKey: upcoming,
      name: 'Upcoming',
      iconName: 'upcoming',
      sortOrder: defaultSortOrders[upcoming]!,
      dateField: AgendaDateField.deadlineDate,
      grouping: AgendaGrouping.byDate,
      additionalFilter: TaskQuery.withDueDate(),
      now: now,
    );
  }

  static ScreenDefinition _createNextActions(String userId, DateTime now) {
    return _allocationScreen(
      userId: userId,
      screenKey: nextActions,
      name: 'Next Actions',
      iconName: 'next_actions',
      sortOrder: defaultSortOrders[nextActions]!,
      sourceFilter: TaskQuery.inProject(),
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
      query: LabelQuery.labelsOnly(),
      now: now,
    );
  }

  static ScreenDefinition _createValues(String userId, DateTime now) {
    return _valueScreen(
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

  /// Creates a task-based list screen with a data section
  static ScreenDefinition _taskScreen({
    required String userId,
    required String screenKey,
    required String name,
    required String iconName,
    required int sortOrder,
    required TaskQuery query,
    required DateTime now,
  }) {
    return ScreenDefinition(
      id: '', // Repository generates v5 ID based on screenKey
      screenKey: screenKey,
      name: name,
      screenType: ScreenType.list,
      sections: [
        Section.data(
          config: DataConfig.task(query: query),
          display: const DisplayConfig(
            sorting: [
              SortCriterion(field: SortField.deadlineDate),
              SortCriterion(field: SortField.name),
            ],
            showCompleted: false,
          ),
        ),
      ],
      createdAt: now,
      updatedAt: now,
      isSystem: true,
      sortOrder: sortOrder,
      iconName: iconName,
    );
  }

  /// Creates an agenda-based screen with date grouping
  static ScreenDefinition _agendaScreen({
    required String userId,
    required String screenKey,
    required String name,
    required String iconName,
    required int sortOrder,
    required AgendaDateField dateField,
    required AgendaGrouping grouping,
    required DateTime now,
    TaskQuery? additionalFilter,
  }) {
    return ScreenDefinition(
      id: '', // Repository generates v5 ID based on screenKey
      screenKey: screenKey,
      name: name,
      screenType: ScreenType.list,
      sections: [
        Section.agenda(
          dateField: dateField,
          grouping: grouping,
          additionalFilter: additionalFilter,
        ),
      ],
      createdAt: now,
      updatedAt: now,
      isSystem: true,
      sortOrder: sortOrder,
      iconName: iconName,
    );
  }

  /// Creates an allocation-based screen (Focus/Next Actions)
  static ScreenDefinition _allocationScreen({
    required String userId,
    required String screenKey,
    required String name,
    required String iconName,
    required int sortOrder,
    required DateTime now,
    TaskQuery? sourceFilter,
    int? maxTasks,
  }) {
    return ScreenDefinition(
      id: '', // Repository generates v5 ID based on screenKey
      screenKey: screenKey,
      name: name,
      screenType: ScreenType.focus,
      sections: [
        Section.allocation(
          sourceFilter: sourceFilter,
          maxTasks: maxTasks,
        ),
      ],
      createdAt: now,
      updatedAt: now,
      isSystem: true,
      sortOrder: sortOrder,
      iconName: iconName,
    );
  }

  /// Creates a project-based list screen
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
      screenType: ScreenType.list,
      sections: [
        Section.data(
          config: DataConfig.project(query: ProjectQuery.active()),
          display: const DisplayConfig(
            sorting: [SortCriterion(field: SortField.name)],
            showCompleted: false,
          ),
        ),
      ],
      createdAt: now,
      updatedAt: now,
      isSystem: true,
      sortOrder: sortOrder,
      iconName: iconName,
    );
  }

  /// Creates a label-based list screen
  static ScreenDefinition _labelScreen({
    required String userId,
    required String screenKey,
    required String name,
    required String iconName,
    required int sortOrder,
    required LabelQuery query,
    required DateTime now,
  }) {
    return ScreenDefinition(
      id: '', // Repository generates v5 ID based on screenKey
      screenKey: screenKey,
      name: name,
      screenType: ScreenType.list,
      sections: [
        Section.data(
          config: DataConfig.label(query: query),
          display: const DisplayConfig(
            sorting: [SortCriterion(field: SortField.name)],
            showCompleted: false,
          ),
        ),
      ],
      createdAt: now,
      updatedAt: now,
      isSystem: true,
      sortOrder: sortOrder,
      iconName: iconName,
    );
  }

  /// Creates a value-based list screen (values are labels with type=value)
  static ScreenDefinition _valueScreen({
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
      screenType: ScreenType.list,
      sections: [
        const Section.data(
          config: DataConfig.value(),
          display: DisplayConfig(
            sorting: [SortCriterion(field: SortField.name)],
            showCompleted: false,
          ),
        ),
      ],
      createdAt: now,
      updatedAt: now,
      isSystem: true,
      sortOrder: sortOrder,
      iconName: iconName,
    );
  }

  /// Creates a utility screen (Wellbeing, Settings, etc.)
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
      screenType: ScreenType.dashboard,
      sections: [], // Utility screens have no data sections
      createdAt: now,
      updatedAt: now,
      isSystem: true,
      sortOrder: sortOrder,
      iconName: iconName,
      category: category,
    );
  }
}
