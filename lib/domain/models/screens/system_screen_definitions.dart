import 'package:taskly_bloc/domain/models/screens/data_config.dart';
import 'package:taskly_bloc/domain/models/screens/display_config.dart';
import 'package:taskly_bloc/domain/models/screens/screen_category.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/screens/section.dart';
import 'package:taskly_bloc/domain/models/screens/support_block.dart';
import 'package:taskly_bloc/domain/queries/label_query.dart';
import 'package:taskly_bloc/domain/queries/project_query.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';

/// System screen definitions for built-in screens.
///
/// These definitions describe how system screens render using the
/// unified screen model. They are equivalent to the hardcoded
/// logic in legacy screen views.
abstract class SystemScreenDefinitions {
  SystemScreenDefinitions._();

  /// Inbox screen - tasks without a project
  static final inbox = ScreenDefinition(
    id: 'inbox',
    screenKey: 'inbox',
    name: 'Inbox',
    screenType: ScreenType.list,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    isSystem: true,
    iconName: 'inbox',
    category: ScreenCategory.workspace,
    sections: [
      Section.data(
        config: DataConfig.task(query: TaskQuery.inbox()),
      ),
    ],
  );

  /// Today screen - tasks due/starting today
  static final today = ScreenDefinition(
    id: 'today',
    screenKey: 'today',
    name: 'Today',
    screenType: ScreenType.list,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    isSystem: true,
    iconName: 'today',
    category: ScreenCategory.workspace,
    sections: [
      Section.agenda(
        dateField: AgendaDateField.deadlineDate,
        grouping: AgendaGrouping.overdueFirst,
        title: 'Due',
      ),
    ],
  );

  /// Upcoming screen - future tasks
  static final upcoming = ScreenDefinition(
    id: 'upcoming',
    screenKey: 'upcoming',
    name: 'Upcoming',
    screenType: ScreenType.list,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    isSystem: true,
    iconName: 'upcoming',
    category: ScreenCategory.workspace,
    sections: [
      Section.agenda(
        dateField: AgendaDateField.deadlineDate,
        grouping: AgendaGrouping.byDate,
      ),
    ],
  );

  /// Logbook screen - completed tasks
  static final logbook = ScreenDefinition(
    id: 'logbook',
    screenKey: 'logbook',
    name: 'Logbook',
    screenType: ScreenType.list,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    isSystem: true,
    iconName: 'done_all',
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
  static final projects = ScreenDefinition(
    id: 'projects',
    screenKey: 'projects',
    name: 'Projects',
    screenType: ScreenType.list,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    isSystem: true,
    iconName: 'folder',
    category: ScreenCategory.workspace,
    sections: [
      Section.data(
        config: DataConfig.project(query: const ProjectQuery()),
      ),
    ],
  );

  /// Labels screen - list of labels
  static final labels = ScreenDefinition(
    id: 'labels',
    screenKey: 'labels',
    name: 'Labels',
    screenType: ScreenType.list,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    isSystem: true,
    iconName: 'label',
    category: ScreenCategory.workspace,
    sections: [
      Section.data(
        config: DataConfig.label(query: const LabelQuery()),
      ),
    ],
  );

  /// Values screen - list of values (labels with type=value)
  static final values = ScreenDefinition(
    id: 'values',
    screenKey: 'values',
    name: 'Values',
    screenType: ScreenType.list,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    isSystem: true,
    iconName: 'star',
    category: ScreenCategory.workspace,
    sections: [
      Section.data(
        config: DataConfig.value(query: const LabelQuery()),
      ),
    ],
  );

  /// Next Actions / Focus screen - allocated tasks
  static final nextActions = ScreenDefinition(
    id: 'next_actions',
    screenKey: 'next_actions',
    name: 'Next Actions',
    screenType: ScreenType.focus,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    isSystem: true,
    iconName: 'bolt',
    category: ScreenCategory.workspace,
    sections: [
      const Section.allocation(),
    ],
  );

  /// Get all system screens
  static List<ScreenDefinition> get all => [
    inbox,
    today,
    upcoming,
    logbook,
    projects,
    labels,
    values,
    nextActions,
  ];

  /// Get a system screen by ID
  static ScreenDefinition? getById(String id) {
    return switch (id) {
      'inbox' => inbox,
      'today' => today,
      'upcoming' => upcoming,
      'logbook' => logbook,
      'projects' => projects,
      'labels' => labels,
      'values' => values,
      'next_actions' => nextActions,
      _ => null,
    };
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
      screenType: ScreenType.list,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isSystem: false,
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
  static ScreenDefinition forLabel({
    required String labelId,
    required String labelName,
    String? labelColor,
  }) {
    return ScreenDefinition(
      id: 'label_$labelId',
      screenKey: 'label_detail',
      name: labelName,
      screenType: ScreenType.list,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isSystem: false,
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
