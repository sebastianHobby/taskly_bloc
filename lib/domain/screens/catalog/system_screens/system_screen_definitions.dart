import 'package:taskly_bloc/domain/screens/language/models/app_bar_action.dart';
import 'package:taskly_bloc/domain/screens/language/models/data_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/display_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/enrichment_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/fab_operation.dart';
import 'package:taskly_bloc/domain/screens/language/models/related_data_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_chrome.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_definition.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_gate_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_source.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_ref.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/screens/templates/params/allocation_alerts_section_params.dart';
import 'package:taskly_bloc/domain/screens/templates/params/agenda_section_params.dart';
import 'package:taskly_bloc/domain/screens/templates/params/allocation_section_params.dart';
import 'package:taskly_bloc/domain/screens/templates/params/attention_tile_variants.dart';
import 'package:taskly_bloc/domain/screens/templates/params/check_in_summary_section_params.dart';
import 'package:taskly_bloc/domain/screens/templates/params/data_list_section_params.dart';
import 'package:taskly_bloc/domain/screens/templates/params/entity_header_section_params.dart';
import 'package:taskly_bloc/domain/screens/templates/params/issues_summary_section_params.dart';
import 'package:taskly_bloc/domain/screens/templates/params/screen_item_tile_variants.dart';
import 'package:taskly_bloc/domain/queries/value_query.dart';
import 'package:taskly_bloc/domain/queries/project_query.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';

/// System screen definitions for built-in screens.
///
/// These definitions describe how system screens render using the
/// unified screen model. They are equivalent to the hardcoded
/// logic in legacy screen views.
abstract class SystemScreenDefinitions {
  SystemScreenDefinitions._();

  /// Browse screen - navigation hub.
  ///
  /// In L4, navigation shows only fixed system screens. Browse provides access
  /// to the remaining system screens (beyond the compact bottom bar) and
  /// additional system screens.
  static final browse = ScreenDefinition(
    id: 'browse',
    screenKey: 'browse',
    name: 'Browse',
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    screenSource: ScreenSource.systemTemplate,
    sections: const [
      SectionRef(
        templateId: SectionTemplateId.browseHub,
        params: <String, dynamic>{},
      ),
    ],
  );

  /// My Day screen - unified Focus view with allocation alerts
  ///
  /// Replaces both Today and Next Actions screens.
  /// Shows focus-mode-driven allocation with alert banners for excluded tasks.
  static final myDay = ScreenDefinition(
    id: 'my_day',
    screenKey: 'my_day',
    name: 'My Day',
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    screenSource: ScreenSource.systemTemplate,
    chrome: const ScreenChrome(
      appBarActions: [AppBarAction.settingsLink],
      settingsRoute: 'focus_setup',
    ),
    gate: ScreenGateConfig(
      criteria: const ScreenGateCriteria.allocationFocusModeNotSelected(),
      section: const SectionRef(
        templateId: SectionTemplateId.myDayFocusModeRequired,
        params: <String, dynamic>{},
      ),
    ),
    sections: [
      SectionRef(
        templateId: SectionTemplateId.checkInSummary,
        params: const CheckInSummarySectionParams(
          reviewItemTileVariant: ReviewItemTileVariant.standard,
        ).toJson(),
      ),
      SectionRef(
        templateId: SectionTemplateId.allocationAlerts,
        params: const AllocationAlertsSectionParams(
          attentionItemTileVariant: AttentionItemTileVariant.standard,
        ).toJson(),
      ),
      SectionRef(
        templateId: SectionTemplateId.allocation,
        params: const AllocationSectionParams(
          taskTileVariant: TaskTileVariant.listTile,
          displayMode: AllocationDisplayMode.groupedByValue,
          showExcludedWarnings: true,
          showExcludedSection: true,
        ).toJson(),
      ),
    ],
  );

  /// Scheduled screen - future tasks (formerly Planned)
  static final scheduled = ScreenDefinition(
    id: 'scheduled',
    screenKey: 'scheduled',
    name: 'Scheduled',
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    screenSource: ScreenSource.systemTemplate,
    chrome: const ScreenChrome(
      fabOperations: [FabOperation.createTask],
    ),
    sections: [
      SectionRef(
        templateId: SectionTemplateId.agenda,
        params: const AgendaSectionParams(
          taskTileVariant: TaskTileVariant.listTile,
          projectTileVariant: ProjectTileVariant.listTile,
          dateField: AgendaDateField.deadlineDate,
          grouping: AgendaGrouping.byDate,
        ).toJson(),
      ),
    ],
  );

  /// Someday screen - Inbox and tasks without dates
  static final someday = ScreenDefinition(
    id: 'someday',
    screenKey: 'someday',
    name: 'Someday',
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    screenSource: ScreenSource.systemTemplate,
    chrome: const ScreenChrome(
      fabOperations: [FabOperation.createTask],
    ),
    sections: [
      SectionRef(
        templateId: SectionTemplateId.issuesSummary,
        params: const IssuesSummarySectionParams(
          attentionItemTileVariant: AttentionItemTileVariant.standard,
          entityTypes: ['task'],
        ).toJson(),
      ),
      SectionRef(
        templateId: SectionTemplateId.somedayBacklog,
        params: const <String, dynamic>{},
      ),
    ],
  );

  /// Logbook screen - completed tasks
  static final logbook = ScreenDefinition(
    id: 'logbook',
    screenKey: 'logbook',
    name: 'Logbook',
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    screenSource: ScreenSource.systemTemplate,
    sections: [
      SectionRef(
        templateId: SectionTemplateId.taskList,
        params: DataListSectionParams(
          config: DataConfig.task(
            query: const TaskQuery(
              filter: QueryFilter<TaskPredicate>(
                shared: [
                  TaskBoolPredicate(
                    field: TaskBoolField.completed,
                    operator: BoolOperator.isTrue,
                  ),
                ],
              ),
            ),
          ),
          taskTileVariant: TaskTileVariant.listTile,
          projectTileVariant: ProjectTileVariant.listTile,
          valueTileVariant: ValueTileVariant.compactCard,
        ).toJson(),
        overrides: const SectionOverrides(title: 'Completed'),
      ),
    ],
  );

  /// Projects screen - list of projects
  static final projects = ScreenDefinition(
    id: 'projects',
    screenKey: 'projects',
    name: 'Projects',
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    screenSource: ScreenSource.systemTemplate,
    chrome: const ScreenChrome(
      fabOperations: [FabOperation.createProject],
    ),
    sections: [
      SectionRef(
        templateId: SectionTemplateId.projectList,
        params: DataListSectionParams(
          config: DataConfig.project(query: const ProjectQuery()),
          taskTileVariant: TaskTileVariant.listTile,
          projectTileVariant: ProjectTileVariant.listTile,
          valueTileVariant: ValueTileVariant.compactCard,
          relatedData: [
            RelatedDataConfig.tasks(
              additionalFilter: TaskQuery(
                filter: QueryFilter(
                  shared: const [
                    TaskBoolPredicate(
                      field: TaskBoolField.completed,
                      operator: BoolOperator.isFalse,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ).toJson(),
      ),
    ],
  );

  /// Values screen - list of values (labels with type=value)
  static final values = ScreenDefinition(
    id: 'values',
    screenKey: 'values',
    name: 'Values',
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    screenSource: ScreenSource.systemTemplate,
    chrome: const ScreenChrome(
      fabOperations: [FabOperation.createValue],
    ),
    sections: [
      SectionRef(
        templateId: SectionTemplateId.valueList,
        params: DataListSectionParams(
          config: DataConfig.value(query: const ValueQuery()),
          taskTileVariant: TaskTileVariant.listTile,
          projectTileVariant: ProjectTileVariant.listTile,
          valueTileVariant: ValueTileVariant.compactCard,
          enrichment: const EnrichmentConfig.valueStats(),
        ).toJson(),
      ),
    ],
  );

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Navigation-only screens (no sections, route to standalone pages)
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Settings screen - app configuration
  static final settings = ScreenDefinition(
    id: 'settings',
    screenKey: 'settings',
    name: 'Settings',
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    screenSource: ScreenSource.systemTemplate,
    sections: const [SectionRef(templateId: SectionTemplateId.settingsMenu)],
  );

  /// Statistics - charts and insights
  static final statistics = ScreenDefinition(
    id: 'statistics',
    screenKey: 'statistics',
    name: 'Statistics',
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    screenSource: ScreenSource.systemTemplate,
    sections: const [
      SectionRef(templateId: SectionTemplateId.statisticsDashboard),
    ],
  );

  /// Journal - mood tracking and reflection
  static final journal = ScreenDefinition(
    id: 'journal',
    screenKey: 'journal',
    name: 'Journal',
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    screenSource: ScreenSource.systemTemplate,
    sections: const [SectionRef(templateId: SectionTemplateId.journalTimeline)],
  );

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Sub-screens (not in main navigation, accessed via parent screens)
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Trackers - habit and metric tracking (accessed via Journal)
  static final trackers = ScreenDefinition(
    id: 'trackers',
    screenKey: 'trackers',
    name: 'Trackers',
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    screenSource: ScreenSource.systemTemplate,
    sections: const [
      SectionRef(templateId: SectionTemplateId.trackerManagement),
    ],
  );

  /// Wellbeing dashboard - analytics and insights (accessed via Journal)
  static final wellbeingDashboard = ScreenDefinition(
    id: 'wellbeing_dashboard',
    screenKey: 'wellbeing_dashboard',
    name: 'Wellbeing',
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    screenSource: ScreenSource.systemTemplate,
    sections: const [
      SectionRef(templateId: SectionTemplateId.wellbeingDashboard),
    ],
  );

  /// Allocation settings - configure My Day allocation (accessed via My Day settings)
  static final allocationSettings = ScreenDefinition(
    id: 'allocation_settings',
    screenKey: 'allocation_settings',
    name: 'Allocation Settings',
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    screenSource: ScreenSource.systemTemplate,
    sections: const [
      SectionRef(templateId: SectionTemplateId.allocationSettings),
    ],
  );

  /// Navigation settings - configure navigation bar (accessed via Settings)
  static final navigationSettings = ScreenDefinition(
    id: 'navigation_settings',
    screenKey: 'navigation_settings',
    name: 'Navigation',
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    screenSource: ScreenSource.systemTemplate,
    sections: const [
      SectionRef(templateId: SectionTemplateId.navigationSettings),
    ],
  );

  /// Focus Setup - configure allocation + review cadence
  ///
  /// This is the canonical settings flow (wizard). Legacy entrypoints
  /// (allocation/attention settings) route here.
  static final focusSetup = ScreenDefinition(
    id: 'focus_setup',
    screenKey: 'focus_setup',
    name: 'Focus Setup',
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    screenSource: ScreenSource.systemTemplate,
    chrome: const ScreenChrome(iconName: 'tune'),
    sections: const [
      SectionRef(templateId: SectionTemplateId.focusSetupWizard),
    ],
  );

  /// Check-in - review and resolve attention items
  /// Accessed via checkInSummary support block on My Day
  static final checkIn = ScreenDefinition(
    id: 'check_in',
    screenKey: 'check_in',
    name: 'Check In',
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    screenSource: ScreenSource.systemTemplate,
    sections: [
      SectionRef(
        templateId: SectionTemplateId.checkInSummary,
        params: const CheckInSummarySectionParams(
          reviewItemTileVariant: ReviewItemTileVariant.standard,
        ).toJson(),
      ),
    ],
  );

  /// Attention Rules settings - manage attention rules
  /// Accessed via Settings
  static final attentionRules = ScreenDefinition(
    id: 'attention_rules',
    screenKey: 'attention_rules',
    name: 'Attention Rules',
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    screenSource: ScreenSource.systemTemplate,
    sections: const [SectionRef(templateId: SectionTemplateId.attentionRules)],
  );

  /// Get all system screens that appear in navigation.
  ///
  /// Note: Some screens (logbook) are accessible
  /// via settings but not shown in the main navigation.
  /// Order: My Day, Scheduled, Someday, Journal, Values, Projects, Statistics,
  /// Settings
  static List<ScreenDefinition> get all => [
    myDay,
    scheduled,
    someday,
    journal,
    values,
    projects,
    statistics,
    settings,
    browse,
  ];

  /// Canonical system screens shown in the main navigation UI.
  ///
  /// Order is fixed and cannot be changed by user preferences.
  static List<ScreenDefinition> get navigationScreens => [
    myDay,
    scheduled,
    someday,
    journal,
    values,
    projects,
    statistics,
    settings,
  ];

  /// Get a system screen by screenKey.
  ///
  /// Returns null for unknown screen keys.
  /// Includes both navigable screens and sub-screens.
  static ScreenDefinition? getByKey(String screenKey) {
    return switch (screenKey) {
      // Main navigable screens
      'my_day' => myDay,
      'scheduled' => scheduled,
      'someday' => someday,
      'statistics' => statistics,
      'projects' => projects,
      'values' => values,
      'settings' => settings,
      'journal' => journal,
      'browse' => browse,

      // Settings screens
      // Legacy entrypoints (allocation/attention settings) route to the
      // canonical focus setup flow.
      'allocation_settings' || 'allocation-settings' => focusSetup,
      'attention_rules' || 'attention-rules' => focusSetup,
      'navigation_settings' || 'navigation-settings' => navigationSettings,

      // Sub-screens (accessed via parent screens)
      'trackers' => trackers,
      'wellbeing_dashboard' => wellbeingDashboard,
      'focus_setup' => focusSetup,

      // Attention system screens
      'check_in' => checkIn,
      _ => null,
    };
  }

  /// Alias for [getByKey] for backward compatibility
  static ScreenDefinition? getById(String id) => getByKey(id);

  /// All system screen keys
  static List<String> get allKeys => all.map((s) => s.screenKey).toList();

  /// Returns true if the given screenKey is a system screen
  static bool isSystemScreen(String screenKey) => getByKey(screenKey) != null;

  /// Default sort orders for system screens.
  ///
  /// Order: My Day, Scheduled, Someday, Journal, Values, Projects,
  /// Statistics, Settings.
  static const Map<String, int> defaultSortOrders = {
    'my_day': 0,
    'scheduled': 1,
    'someday': 2,
    'journal': 3,
    'values': 4,
    'projects': 5,
    'statistics': 6,
    'settings': 100,
    'browse': 10,
  };

  /// Returns the default sort order for a screen key.
  ///
  /// Returns 999 for unknown keys (sorts them last).
  static int getDefaultSortOrder(String screenKey) {
    return defaultSortOrders[screenKey] ?? 999;
  }

  /// Create a screen definition for a specific project
  static ScreenDefinition forProject({
    required String projectId,
    required String projectName,
    String? projectColor,
  }) {
    return ScreenDefinition(
      id: 'project_$projectId',
      screenKey: 'project_detail',
      name: projectName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      screenSource: ScreenSource.userDefined,
      chrome: const ScreenChrome(iconName: 'folder'),
      sections: [
        SectionRef(
          templateId: SectionTemplateId.entityHeader,
          params: EntityHeaderSectionParams(
            entityType: 'project',
            entityId: projectId,
            showCheckbox: true,
            showMetadata: true,
          ).toJson(),
        ),
        SectionRef(
          templateId: SectionTemplateId.taskList,
          params: DataListSectionParams(
            config: DataConfig.task(
              query: TaskQuery.forProject(projectId: projectId),
            ),
            taskTileVariant: TaskTileVariant.listTile,
            projectTileVariant: ProjectTileVariant.listTile,
            valueTileVariant: ValueTileVariant.compactCard,
            display: const DisplayConfig(
              groupByCompletion: true,
              completedCollapsed: true,
              enableSwipeToDelete: true,
              showCompleted: true,
            ),
          ).toJson(),
          overrides: const SectionOverrides(title: 'Tasks'),
        ),
      ],
    );
  }

  /// Create a screen definition for a specific value
  static ScreenDefinition forValue({
    required String valueId,
    required String valueName,
    String? valueColor,
  }) {
    return ScreenDefinition(
      id: 'value_$valueId',
      screenKey: 'value_detail',
      name: valueName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      screenSource: ScreenSource.userDefined,
      chrome: const ScreenChrome(iconName: 'value'),
      sections: [
        SectionRef(
          templateId: SectionTemplateId.entityHeader,
          params: EntityHeaderSectionParams(
            entityType: 'value',
            entityId: valueId,
            showCheckbox: false,
            showMetadata: true,
          ).toJson(),
        ),
        SectionRef(
          templateId: SectionTemplateId.taskList,
          params: DataListSectionParams(
            config: DataConfig.task(
              query: TaskQuery.forValue(valueId: valueId),
            ),
            taskTileVariant: TaskTileVariant.listTile,
            projectTileVariant: ProjectTileVariant.listTile,
            valueTileVariant: ValueTileVariant.compactCard,
            display: const DisplayConfig(
              groupByCompletion: true,
              completedCollapsed: true,
              enableSwipeToDelete: true,
              showCompleted: true,
            ),
          ).toJson(),
          overrides: const SectionOverrides(title: 'Tasks'),
        ),
        SectionRef(
          templateId: SectionTemplateId.projectList,
          params: DataListSectionParams(
            config: DataConfig.project(
              query: ProjectQuery.byValues([valueId]),
            ),
            taskTileVariant: TaskTileVariant.listTile,
            projectTileVariant: ProjectTileVariant.listTile,
            valueTileVariant: ValueTileVariant.compactCard,
            display: const DisplayConfig(enableSwipeToDelete: false),
          ).toJson(),
          overrides: const SectionOverrides(title: 'Projects'),
        ),
      ],
    );
  }
}
