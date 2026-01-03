import 'package:taskly_bloc/domain/models/screens/data_config.dart';
import 'package:taskly_bloc/domain/models/screens/display_config.dart';
import 'package:taskly_bloc/domain/models/screens/enrichment_config.dart';
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
/// These keys are used to generate deterministic v5 UUIDs.
///
/// ## Preferences Storage
/// User preferences for screens (sortOrder, isActive) are stored in
/// `AppSettings.screenPreferences`, NOT in the screen definition itself.
/// Use [defaultSortOrders] to get the default sort order for a screen key.
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

  /// Default sort orders for system screens.
  ///
  /// These are used when user has not customized the sort order in
  /// their screen preferences.
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

  /// Returns the default sort order for a screen key.
  ///
  /// Returns 999 for unknown keys (sorts them last).
  static int getDefaultSortOrder(String screenKey) {
    return defaultSortOrders[screenKey] ?? 999;
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

  /// Creates all system screen definitions.
  ///
  /// These are pure templates - they don't have IDs assigned.
  /// The SystemScreenProvider is responsible for generating
  /// deterministic v5 IDs based on screenKey + userId.
  static List<ScreenDefinition> createAll() {
    final now = DateTime.now();
    return [
      _createInbox(now),
      _createToday(now),
      _createUpcoming(now),
      _createNextActions(now),
      _createProjects(now),
      _createLabels(now),
      _createValues(now),
      _createWellbeing(now),
      _createJournal(now),
      _createTrackers(now),
      _createAllocationSettings(now),
      _createNavigationSettings(now),
      _createSettings(now),
    ];
  }

  /// Creates a specific system screen definition by key.
  ///
  /// Returns null if the screenKey is not a system screen.
  static ScreenDefinition? create(String screenKey) {
    final now = DateTime.now();
    return switch (screenKey) {
      inbox => _createInbox(now),
      today => _createToday(now),
      upcoming => _createUpcoming(now),
      nextActions => _createNextActions(now),
      projects => _createProjects(now),
      labels => _createLabels(now),
      values => _createValues(now),
      wellbeing => _createWellbeing(now),
      journal => _createJournal(now),
      trackers => _createTrackers(now),
      allocationSettings => _createAllocationSettings(now),
      navigationSettings => _createNavigationSettings(now),
      settings => _createSettings(now),
      _ => null,
    };
  }

  // =========================================================================
  // Screen Definitions
  // =========================================================================

  static ScreenDefinition _createInbox(DateTime now) {
    return _taskScreen(
      screenKey: inbox,
      name: 'Inbox',
      iconName: 'inbox',
      query: TaskQuery.inbox(),
      now: now,
    );
  }

  static ScreenDefinition _createToday(DateTime now) {
    return _agendaScreen(
      screenKey: today,
      name: 'Today',
      iconName: 'today',
      dateField: AgendaDateField.deadlineDate,
      grouping: AgendaGrouping.overdueFirst,
      additionalFilter: TaskQuery.incomplete(),
      now: now,
    );
  }

  static ScreenDefinition _createUpcoming(DateTime now) {
    return _agendaScreen(
      screenKey: upcoming,
      name: 'Upcoming',
      iconName: 'upcoming',
      dateField: AgendaDateField.deadlineDate,
      grouping: AgendaGrouping.byDate,
      additionalFilter: TaskQuery.withDueDate(),
      now: now,
    );
  }

  static ScreenDefinition _createNextActions(DateTime now) {
    return _allocationScreen(
      screenKey: nextActions,
      name: 'Next Actions',
      iconName: 'next_actions',
      sourceFilter: TaskQuery.inProject(),
      now: now,
    );
  }

  static ScreenDefinition _createProjects(DateTime now) {
    return _projectScreen(
      screenKey: projects,
      name: 'Projects',
      iconName: 'projects',
      now: now,
    );
  }

  static ScreenDefinition _createLabels(DateTime now) {
    return _labelScreen(
      screenKey: labels,
      name: 'Labels',
      iconName: 'labels',
      query: LabelQuery.labelsOnly(),
      now: now,
    );
  }

  static ScreenDefinition _createValues(DateTime now) {
    return _valueScreen(
      screenKey: values,
      name: 'Values',
      iconName: 'values',
      now: now,
    );
  }

  static ScreenDefinition _createWellbeing(DateTime now) {
    return _utilityScreen(
      screenKey: wellbeing,
      name: 'Wellbeing',
      iconName: 'wellbeing',
      category: ScreenCategory.wellbeing,
      now: now,
    );
  }

  static ScreenDefinition _createJournal(DateTime now) {
    return _utilityScreen(
      screenKey: journal,
      name: 'Journal',
      iconName: 'journal',
      category: ScreenCategory.wellbeing,
      now: now,
    );
  }

  static ScreenDefinition _createTrackers(DateTime now) {
    return _utilityScreen(
      screenKey: trackers,
      name: 'Trackers',
      iconName: 'trackers',
      category: ScreenCategory.wellbeing,
      now: now,
    );
  }

  static ScreenDefinition _createAllocationSettings(DateTime now) {
    return _utilityScreen(
      screenKey: allocationSettings,
      name: 'Allocation',
      iconName: 'allocation_settings',
      category: ScreenCategory.settings,
      now: now,
    );
  }

  static ScreenDefinition _createNavigationSettings(DateTime now) {
    return _utilityScreen(
      screenKey: navigationSettings,
      name: 'Navigation',
      iconName: 'navigation_settings',
      category: ScreenCategory.settings,
      now: now,
    );
  }

  static ScreenDefinition _createSettings(DateTime now) {
    return _utilityScreen(
      screenKey: settings,
      name: 'Settings',
      iconName: 'settings',
      category: ScreenCategory.settings,
      now: now,
    );
  }

  // =========================================================================
  // Helper Methods
  // =========================================================================

  /// Creates a task-based list screen with a data section
  static DataDrivenScreenDefinition _taskScreen({
    required String screenKey,
    required String name,
    required String iconName,
    required TaskQuery query,
    required DateTime now,
  }) {
    return ScreenDefinition.dataDriven(
      id: '', // Provider generates v5 ID based on screenKey
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
      iconName: iconName,
    );
  }

  /// Creates an agenda-based screen with date grouping
  static DataDrivenScreenDefinition _agendaScreen({
    required String screenKey,
    required String name,
    required String iconName,
    required AgendaDateField dateField,
    required AgendaGrouping grouping,
    required DateTime now,
    TaskQuery? additionalFilter,
  }) {
    return ScreenDefinition.dataDriven(
      id: '', // Provider generates v5 ID based on screenKey
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
      iconName: iconName,
    );
  }

  /// Creates an allocation-based screen (Focus/Next Actions)
  static DataDrivenScreenDefinition _allocationScreen({
    required String screenKey,
    required String name,
    required String iconName,
    required DateTime now,
    TaskQuery? sourceFilter,
    int? maxTasks,
  }) {
    return ScreenDefinition.dataDriven(
      id: '', // Provider generates v5 ID based on screenKey
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
      iconName: iconName,
    );
  }

  /// Creates a project-based list screen
  static DataDrivenScreenDefinition _projectScreen({
    required String screenKey,
    required String name,
    required String iconName,
    required DateTime now,
  }) {
    return ScreenDefinition.dataDriven(
      id: '', // Provider generates v5 ID based on screenKey
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
      iconName: iconName,
    );
  }

  /// Creates a label-based list screen
  static DataDrivenScreenDefinition _labelScreen({
    required String screenKey,
    required String name,
    required String iconName,
    required LabelQuery query,
    required DateTime now,
  }) {
    return ScreenDefinition.dataDriven(
      id: '', // Provider generates v5 ID based on screenKey
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
      iconName: iconName,
    );
  }

  /// Creates a value-based list screen (values are labels with type=value)
  static DataDrivenScreenDefinition _valueScreen({
    required String screenKey,
    required String name,
    required String iconName,
    required DateTime now,
  }) {
    return ScreenDefinition.dataDriven(
      id: '', // Provider generates v5 ID based on screenKey
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
          // Request value statistics enrichment for inline display
          enrichment: EnrichmentConfig.valueStats(),
        ),
      ],
      createdAt: now,
      updatedAt: now,
      isSystem: true,
      iconName: iconName,
    );
  }

  /// Creates a navigation-only utility screen (Wellbeing, Settings, etc.)
  ///
  /// These screens appear in navigation but have custom widget implementations.
  static NavigationOnlyScreenDefinition _utilityScreen({
    required String screenKey,
    required String name,
    required String iconName,
    required ScreenCategory category,
    required DateTime now,
  }) {
    return ScreenDefinition.navigationOnly(
      id: '', // Provider generates v5 ID based on screenKey
      screenKey: screenKey,
      name: name,
      createdAt: now,
      updatedAt: now,
      isSystem: true,
      iconName: iconName,
      category: category,
    );
  }
}
