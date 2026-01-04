import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/models/screens/data_config.dart';
import 'package:taskly_bloc/domain/models/screens/display_config.dart';
import 'package:taskly_bloc/domain/models/screens/fab_operation.dart';
import 'package:taskly_bloc/domain/models/screens/screen_category.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/screens/screen_source.dart';
import 'package:taskly_bloc/domain/models/screens/section.dart';
import 'package:taskly_bloc/domain/models/screens/support_block.dart';
import 'package:taskly_bloc/domain/queries/label_query.dart';
import 'package:taskly_bloc/domain/queries/project_query.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/services/screens/section_data_result.dart';

/// System screen definitions for built-in screens.
///
/// These definitions describe how system screens render using the
/// unified screen model. They are equivalent to the hardcoded
/// logic in legacy screen views.
abstract class SystemScreenDefinitions {
  SystemScreenDefinitions._();

  /// Inbox screen - tasks without a project
  static final inbox = ScreenDefinition.dataDriven(
    id: 'inbox',
    screenKey: 'inbox',
    name: 'Inbox',
    screenType: ScreenType.list,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    screenSource: ScreenSource.systemTemplate,
    category: ScreenCategory.workspace,
    fabOperations: [FabOperation.createTask],
    sections: [
      Section.data(
        config: DataConfig.task(query: TaskQuery.inbox()),
      ),
    ],
  );

  /// My Day screen - unified Focus view with allocation alerts
  ///
  /// Replaces both Today and Next Actions screens.
  /// Shows persona-driven allocation with alert banners for excluded tasks.
  static final myDay = ScreenDefinition.dataDriven(
    id: 'my_day',
    screenKey: 'my_day',
    name: 'My Day',
    screenType: ScreenType.focus,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    screenSource: ScreenSource.systemTemplate,
    category: ScreenCategory.workspace,
    sections: [
      const Section.allocation(
        displayMode: AllocationDisplayMode.pinnedFirst,
        showExcludedWarnings: true,
        showExcludedSection: true,
      ),
    ],
  );

  /// Upcoming screen - future tasks
  static final upcoming = ScreenDefinition.dataDriven(
    id: 'upcoming',
    screenKey: 'upcoming',
    name: 'Upcoming',
    screenType: ScreenType.list,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    screenSource: ScreenSource.systemTemplate,
    category: ScreenCategory.workspace,
    fabOperations: [FabOperation.createTask],
    sections: [
      Section.agenda(
        dateField: AgendaDateField.deadlineDate,
        grouping: AgendaGrouping.byDate,
      ),
    ],
  );

  /// Logbook screen - completed tasks
  static final logbook = ScreenDefinition.dataDriven(
    id: 'logbook',
    screenKey: 'logbook',
    name: 'Logbook',
    screenType: ScreenType.list,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    screenSource: ScreenSource.systemTemplate,
    category: ScreenCategory.workspace,
    sections: [
      Section.data(
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
        title: 'Completed',
      ),
    ],
  );

  /// Projects screen - list of projects
  static final projects = ScreenDefinition.dataDriven(
    id: 'projects',
    screenKey: 'projects',
    name: 'Projects',
    screenType: ScreenType.list,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    screenSource: ScreenSource.systemTemplate,
    category: ScreenCategory.workspace,
    fabOperations: [FabOperation.createProject],
    sections: [
      Section.data(
        config: DataConfig.project(query: const ProjectQuery()),
      ),
    ],
  );

  /// Labels screen - list of labels
  static final labels = ScreenDefinition.dataDriven(
    id: 'labels',
    screenKey: 'labels',
    name: 'Labels',
    screenType: ScreenType.list,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    screenSource: ScreenSource.systemTemplate,
    category: ScreenCategory.workspace,
    fabOperations: [FabOperation.createLabel],
    sections: [
      Section.data(
        config: DataConfig.label(query: const LabelQuery()),
      ),
    ],
  );

  /// Values screen - list of values (labels with type=value)
  static final values = ScreenDefinition.dataDriven(
    id: 'values',
    screenKey: 'values',
    name: 'Values',
    screenType: ScreenType.list,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    screenSource: ScreenSource.systemTemplate,
    category: ScreenCategory.workspace,
    fabOperations: [FabOperation.createValue],
    sections: [
      Section.data(
        config: DataConfig.value(query: const LabelQuery()),
      ),
    ],
  );

  /// Orphan Tasks screen - incomplete tasks without any value assigned
  static final orphanTasks = ScreenDefinition.dataDriven(
    id: 'orphan_tasks',
    screenKey: 'orphan_tasks',
    name: 'Unassigned Tasks',
    screenType: ScreenType.list,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    screenSource: ScreenSource.systemTemplate,
    category: ScreenCategory.workspace,
    sections: [
      Section.data(
        config: DataConfig.task(
          query: const TaskQuery(
            filter: QueryFilter<TaskPredicate>(
              shared: [
                TaskBoolPredicate(
                  field: TaskBoolField.completed,
                  operator: BoolOperator.isFalse,
                ),
                TaskLabelPredicate(
                  operator: LabelOperator.isNull,
                  labelType: LabelType.value,
                  includeInherited: true,
                ),
              ],
            ),
          ),
        ),
        display: DisplayConfig(
          groupByCompletion: false,
          enableSwipeToDelete: false,
          showCompleted: false,
        ),
        title: 'Tasks without values',
      ),
    ],
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Navigation-only screens (no sections, route to standalone pages)
  // ─────────────────────────────────────────────────────────────────────────

  /// Settings screen - app configuration
  static final settings = ScreenDefinition.navigationOnly(
    id: 'settings',
    screenKey: 'settings',
    name: 'Settings',
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    screenSource: ScreenSource.systemTemplate,
    category: ScreenCategory.settings,
  );

  /// Wellbeing dashboard - mood tracking and analytics
  static final wellbeing = ScreenDefinition.navigationOnly(
    id: 'wellbeing',
    screenKey: 'wellbeing',
    name: 'Wellbeing',
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    screenSource: ScreenSource.systemTemplate,
    category: ScreenCategory.wellbeing,
  );

  /// Workflows - automation and scheduled tasks
  static final workflows = ScreenDefinition.navigationOnly(
    id: 'workflows',
    screenKey: 'workflows',
    name: 'Workflows',
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    screenSource: ScreenSource.systemTemplate,
    category: ScreenCategory.settings,
  );

  /// Screen management - customize screens and navigation
  static final screenManagement = ScreenDefinition.navigationOnly(
    id: 'screen_management',
    screenKey: 'screen_management',
    name: 'Screens',
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    screenSource: ScreenSource.systemTemplate,
    category: ScreenCategory.settings,
  );

  /// Get all system screens
  static List<ScreenDefinition> get all => [
    inbox,
    myDay,
    upcoming,
    logbook,
    projects,
    labels,
    values,
    // Navigation-only screens
    settings,
    wellbeing,
    workflows,
    screenManagement,
  ];

  /// Get a system screen by screenKey
  static ScreenDefinition? getByKey(String screenKey) {
    return switch (screenKey) {
      'inbox' => inbox,
      'my_day' => myDay,
      'upcoming' => upcoming,
      'logbook' => logbook,
      'projects' => projects,
      'labels' => labels,
      'values' => values,
      'orphan_tasks' => orphanTasks,
      'settings' => settings,
      'wellbeing' => wellbeing,
      'workflows' => workflows,
      'screen_management' => screenManagement,
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
  /// These are used when user has not customized the sort order.
  static const Map<String, int> defaultSortOrders = {
    'inbox': 0,
    'my_day': 1,
    'upcoming': 2,
    'logbook': 3,
    'projects': 4,
    'labels': 5,
    'values': 6,
    'orphan_tasks': 7,
    'settings': 100,
    'wellbeing': 101,
    'workflows': 102,
    'screen_management': 103,
  };

  /// Returns the default sort order for a screen key.
  ///
  /// Returns 999 for unknown keys (sorts them last).
  static int getDefaultSortOrder(String screenKey) {
    return defaultSortOrders[screenKey] ?? 999;
  }

  /// Create a screen definition for a specific project
  static DataDrivenScreenDefinition forProject({
    required String projectId,
    required String projectName,
    String? projectColor,
  }) {
    return DataDrivenScreenDefinition(
      id: 'project_$projectId',
      screenKey: 'project_detail',
      name: projectName,
      screenType: ScreenType.list,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      screenSource: ScreenSource.userDefined,
      iconName: 'folder',
      category: ScreenCategory.workspace,
      supportBlocks: [
        SupportBlock.entityHeader(
          entityType: 'project',
          entityId: projectId,
          showCheckbox: true,
          showMetadata: true,
        ),
      ],
      sections: [
        Section.data(
          config: DataConfig.task(
            query: TaskQuery.forProject(projectId: projectId),
          ),
          display: const DisplayConfig(
            groupByCompletion: true,
            completedCollapsed: true,
            enableSwipeToDelete: true,
            showCompleted: true,
          ),
          title: 'Tasks',
        ),
      ],
    );
  }

  /// Create a screen definition for a specific label
  static DataDrivenScreenDefinition forLabel({
    required String labelId,
    required String labelName,
    String? labelColor,
  }) {
    return DataDrivenScreenDefinition(
      id: 'label_$labelId',
      screenKey: 'label_detail',
      name: labelName,
      screenType: ScreenType.list,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      screenSource: ScreenSource.userDefined,
      iconName: 'label',
      category: ScreenCategory.workspace,
      supportBlocks: [
        SupportBlock.entityHeader(
          entityType: 'label',
          entityId: labelId,
          showCheckbox: false,
          showMetadata: true,
        ),
      ],
      sections: [
        Section.data(
          config: DataConfig.task(
            query: TaskQuery.forLabel(labelId: labelId),
          ),
          display: const DisplayConfig(
            groupByCompletion: true,
            completedCollapsed: true,
            enableSwipeToDelete: true,
            showCompleted: true,
          ),
          title: 'Tasks',
        ),
        Section.data(
          config: DataConfig.project(
            query: ProjectQuery.byLabels([labelId]),
          ),
          display: const DisplayConfig(
            enableSwipeToDelete: false,
          ),
          title: 'Projects',
        ),
      ],
    );
  }
}
