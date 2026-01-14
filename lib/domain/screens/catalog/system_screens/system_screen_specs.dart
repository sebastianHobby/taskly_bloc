import 'package:taskly_bloc/domain/queries/project_query.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/queries/value_query.dart';
import 'package:taskly_bloc/domain/screens/language/models/app_bar_action.dart';
import 'package:taskly_bloc/domain/screens/language/models/data_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/fab_operation.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_chrome.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_gate_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_spec.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/templates/params/agenda_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/allocation_alerts_section_params.dart';
import 'package:taskly_bloc/domain/screens/templates/params/allocation_section_params.dart';
import 'package:taskly_bloc/domain/screens/templates/params/check_in_summary_section_params.dart';
import 'package:taskly_bloc/domain/screens/templates/params/hierarchy_value_project_task_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/issues_summary_section_params.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/screen_item_tile_variants.dart';
import 'package:taskly_bloc/domain/screens/templates/params/style_pack_v2.dart';

/// Typed system screen specs for the hard-cutover system-screen path.
abstract class SystemScreenSpecs {
  SystemScreenSpecs._();

  static final browse = ScreenSpec(
    id: 'browse',
    screenKey: 'browse',
    name: 'Browse',
    template: const ScreenTemplateSpec.browseHub(),
  );

  static final myDay = ScreenSpec(
    id: 'my_day',
    screenKey: 'my_day',
    name: 'My Day',
    template: const ScreenTemplateSpec.standardScaffoldV1(),
    gate: const ScreenGateSpec(
      criteria: ScreenGateCriteria.allocationFocusModeNotSelected(),
      template: ScreenTemplateSpec.myDayFocusModeRequired(),
    ),
    chrome: const ScreenChrome(
      fabOperations: [FabOperation.createTask],
      appBarActions: [AppBarAction.settingsLink],
      settingsRoute: 'focus_setup',
    ),
    modules: SlottedModules(
      header: [
        ScreenModuleSpec.checkInSummary(
          params: CheckInSummarySectionParams(
            pack: StylePackV2.standard,
          ),
        ),
        ScreenModuleSpec.allocationAlerts(
          params: AllocationAlertsSectionParams(
            pack: StylePackV2.standard,
          ),
        ),
      ],
      primary: [
        ScreenModuleSpec.allocation(
          params: AllocationSectionParams(
            taskTileVariant: TaskTileVariant.listTile,
            displayMode: AllocationDisplayMode.groupedByValue,
          ),
        ),
      ],
    ),
  );

  static final reviewInbox = ScreenSpec(
    id: 'review_inbox',
    screenKey: 'review_inbox',
    name: 'Review Inbox',
    template: const ScreenTemplateSpec.reviewInbox(),
  );

  static final scheduled = ScreenSpec(
    id: 'scheduled',
    screenKey: 'scheduled',
    name: 'Scheduled',
    template: const ScreenTemplateSpec.standardScaffoldV1(),
    chrome: const ScreenChrome(
      fabOperations: [FabOperation.createTask],
    ),
    modules: SlottedModules(
      primary: [
        ScreenModuleSpec.agendaV2(
          params: AgendaSectionParamsV2(
            dateField: AgendaDateFieldV2.deadlineDate,
            pack: StylePackV2.standard,
            layout: const SectionLayoutSpecV2.timelineMonthSections(
              pinnedSectionHeaders: true,
            ),
            enrichment: EnrichmentPlanV2(
              items: [
                EnrichmentPlanItemV2.agendaTags(
                  dateField: AgendaDateFieldV2.deadlineDate,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  static final someday = ScreenSpec(
    id: 'someday',
    screenKey: 'someday',
    name: 'Someday',
    template: const ScreenTemplateSpec.standardScaffoldV1(),
    chrome: const ScreenChrome(
      fabOperations: [FabOperation.createTask],
    ),
    modules: SlottedModules(
      header: [
        ScreenModuleSpec.issuesSummary(
          params: IssuesSummarySectionParams(
            pack: StylePackV2.standard,
            entityTypes: const ['task'],
          ),
        ),
      ],
      primary: [
        ScreenModuleSpec.hierarchyValueProjectTaskV2(
          params: HierarchyValueProjectTaskSectionParamsV2(
            sources: [
              DataConfig.task(
                query: TaskQuery(
                  filter: QueryFilter<TaskPredicate>(
                    shared: const [
                      TaskBoolPredicate(
                        field: TaskBoolField.completed,
                        operator: BoolOperator.isFalse,
                      ),
                      TaskDatePredicate(
                        field: TaskDateField.startDate,
                        operator: DateOperator.isNull,
                      ),
                      TaskDatePredicate(
                        field: TaskDateField.deadlineDate,
                        operator: DateOperator.isNull,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            pack: StylePackV2.standard,
            pinnedValueHeaders: true,
            pinnedProjectHeaders: false,
            singleInboxGroupForNoProjectTasks: true,
            filters: SectionFilterSpecV2(
              enableValueDropdown: true,
              enableProjectsOnlyToggle: true,
              valueFilterMode: ValueFilterModeV2.anyValues,
            ),
          ),
        ),
      ],
    ),
  );

  static final projects = ScreenSpec(
    id: 'projects',
    screenKey: 'projects',
    name: 'Projects',
    template: const ScreenTemplateSpec.standardScaffoldV1(),
    chrome: const ScreenChrome(
      fabOperations: [FabOperation.createProject],
    ),
    modules: SlottedModules(
      primary: [
        ScreenModuleSpec.projectListV2(
          params: ListSectionParamsV2(
            config: DataConfig.project(query: const ProjectQuery()),
            pack: StylePackV2.standard,
            layout: const SectionLayoutSpecV2.flatList(
              separator: ListSeparatorV2.spaced8,
            ),
          ),
        ),
      ],
    ),
  );

  static final values = ScreenSpec(
    id: 'values',
    screenKey: 'values',
    name: 'Values',
    template: const ScreenTemplateSpec.standardScaffoldV1(),
    chrome: const ScreenChrome(
      fabOperations: [FabOperation.createValue],
    ),
    modules: SlottedModules(
      primary: [
        ScreenModuleSpec.valueListV2(
          params: ListSectionParamsV2(
            config: DataConfig.value(query: const ValueQuery()),
            pack: StylePackV2.standard,
            layout: const SectionLayoutSpecV2.flatList(
              separator: ListSeparatorV2.spaced8,
            ),
            enrichment: const EnrichmentPlanV2(
              items: [EnrichmentPlanItemV2.valueStats()],
            ),
          ),
        ),
      ],
    ),
  );

  static final settings = ScreenSpec(
    id: 'settings',
    screenKey: 'settings',
    name: 'Settings',
    template: const ScreenTemplateSpec.settingsMenu(),
  );

  static final statistics = ScreenSpec(
    id: 'statistics',
    screenKey: 'statistics',
    name: 'Statistics',
    template: const ScreenTemplateSpec.statisticsDashboard(),
  );

  static final journal = ScreenSpec(
    id: 'journal',
    screenKey: 'journal',
    name: 'Journal',
    template: const ScreenTemplateSpec.journalHub(),
  );

  static final trackers = ScreenSpec(
    id: 'trackers',
    screenKey: 'trackers',
    name: 'Trackers',
    template: const ScreenTemplateSpec.trackerManagement(),
  );

  static final allocationSettings = ScreenSpec(
    id: 'allocation_settings',
    screenKey: 'allocation_settings',
    name: 'Allocation Settings',
    template: const ScreenTemplateSpec.allocationSettings(),
  );

  static final navigationSettings = ScreenSpec(
    id: 'navigation_settings',
    screenKey: 'navigation_settings',
    name: 'Navigation',
    template: const ScreenTemplateSpec.navigationSettings(),
  );

  static final focusSetup = ScreenSpec(
    id: 'focus_setup',
    screenKey: 'focus_setup',
    name: 'Focus Setup',
    template: const ScreenTemplateSpec.focusSetupWizard(),
  );

  static final attentionRules = ScreenSpec(
    id: 'attention_rules',
    screenKey: 'attention_rules',
    name: 'Attention Rules',
    template: const ScreenTemplateSpec.attentionRules(),
  );

  /// Canonical system screens shown in the main navigation UI.
  static List<ScreenSpec> get navigationScreens => [
    myDay,
    scheduled,
    someday,
    journal,
    values,
    projects,
    statistics,
    settings,
  ];

  /// All system screens.
  ///
  /// Note: this includes Browse, which is typically shown separately.
  static List<ScreenSpec> get all => [...navigationScreens, browse];

  static const Map<String, int> _defaultSortOrders = {
    'my_day': 0,
    'scheduled': 1,
    'someday': 2,
    'journal': 4,
    'values': 5,
    'projects': 6,
    'statistics': 7,
    'browse': 8,
    'review_inbox': 9,
    'settings': 100,
  };

  static int getDefaultSortOrder(String screenKey) {
    return _defaultSortOrders[screenKey] ?? 999;
  }

  static bool isSystemScreen(String screenKey) => getByKey(screenKey) != null;

  static final _byKey = <String, ScreenSpec>{
    browse.screenKey: browse,
    myDay.screenKey: myDay,
    scheduled.screenKey: scheduled,
    someday.screenKey: someday,
    projects.screenKey: projects,
    values.screenKey: values,
    settings.screenKey: settings,
    statistics.screenKey: statistics,
    journal.screenKey: journal,
    trackers.screenKey: trackers,
    allocationSettings.screenKey: allocationSettings,
    navigationSettings.screenKey: navigationSettings,
    focusSetup.screenKey: focusSetup,
    attentionRules.screenKey: attentionRules,
    reviewInbox.screenKey: reviewInbox,
  };

  static ScreenSpec? getByKey(String screenKey) {
    final normalized = screenKey.replaceAll('-', '_');

    return _byKey[normalized];
  }
}
