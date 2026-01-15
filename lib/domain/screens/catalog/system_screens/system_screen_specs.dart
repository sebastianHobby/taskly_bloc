import 'package:taskly_bloc/domain/queries/project_query.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/queries/value_query.dart';
import 'package:taskly_bloc/domain/screens/language/models/app_bar_action.dart';
import 'package:taskly_bloc/domain/screens/language/models/data_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/fab_operation.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_chrome.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_gate_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_spec.dart';
import 'package:taskly_bloc/domain/screens/templates/params/agenda_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/attention_banner_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/attention_inbox_section_params_v1.dart';
import 'package:taskly_bloc/domain/screens/templates/params/hierarchy_value_project_task_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/interleaved_list_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/style_pack_v2.dart';

/// Typed system screen specs for the hard-cutover system-screen path.
abstract class SystemScreenSpecs {
  SystemScreenSpecs._();

  static final myDay = ScreenSpec(
    id: 'my_day',
    screenKey: 'my_day',
    name: 'My Day',
    template: const ScreenTemplateSpec.standardScaffoldV1(),
    gate: const ScreenGateSpec(
      criteria: ScreenGateCriteria.myDayPrereqsMissing(),
      template: ScreenTemplateSpec.myDayFocusModeRequired(),
    ),
    chrome: const ScreenChrome(
      fabOperations: [FabOperation.createTask],
      appBarActions: [AppBarAction.settingsLink],
      settingsRoute: 'focus_setup',
    ),
    modules: SlottedModules(
      header: [
        ScreenModuleSpec.attentionBannerV2(
          params: AttentionBannerSectionParamsV2(
            pack: StylePackV2.standard,
            buckets: const ['action', 'review'],
          ),
        ),
      ],
      primary: [
        ScreenModuleSpec.hierarchyValueProjectTaskV2(
          params: HierarchyValueProjectTaskSectionParamsV2(
            sources: const [DataConfig.allocationSnapshotTasksToday()],
            pack: StylePackV2.standard,
            pinnedValueHeaders: true,
            pinnedProjectHeaders: false,
            singleInboxGroupForNoProjectTasks: false,
            enrichment: const EnrichmentPlanV2(
              items: [EnrichmentPlanItemV2.allocationMembership()],
            ),
          ),
          title: 'Today',
        ),
      ],
    ),
  );

  static final reviewInbox = ScreenSpec(
    id: 'review_inbox',
    screenKey: 'review_inbox',
    name: 'Attention',
    template: const ScreenTemplateSpec.standardScaffoldV1(),
    modules: SlottedModules(
      primary: [
        ScreenModuleSpec.attentionInboxV1(
          params: const AttentionInboxSectionParamsV1(
            pack: StylePackV2.standard,
          ),
        ),
      ],
    ),
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
            enrichment: EnrichmentPlanV2(
              items: [
                EnrichmentPlanItemV2.agendaTags(
                  dateField: AgendaDateFieldV2.deadlineDate,
                ),
                EnrichmentPlanItemV2.allocationMembership(),
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
    name: 'Anytime',
    description:
        "Your actionable backlog. Use filters to hide 'start later' items.",
    template: const ScreenTemplateSpec.standardScaffoldV1(),
    chrome: const ScreenChrome(
      fabOperations: [FabOperation.createTask],
    ),
    modules: SlottedModules(
      header: [
        ScreenModuleSpec.attentionBannerV2(
          params: AttentionBannerSectionParamsV2(
            pack: StylePackV2.standard,
            buckets: const ['action', 'review'],
            entityTypes: const ['task', 'project'],
          ),
        ),
      ],
      primary: [
        ScreenModuleSpec.interleavedListV2(
          params: InterleavedListSectionParamsV2(
            sources: [
              DataConfig.task(query: TaskQuery.incomplete()),
              DataConfig.project(query: ProjectQuery.active()),
            ],
            pack: StylePackV2.standard,
            layout: const SectionLayoutSpecV2.hierarchyValueProjectTask(
              pinnedValueHeaders: true,
              pinnedProjectHeaders: false,
              singleInboxGroupForNoProjectTasks: true,
            ),
            enrichment: const EnrichmentPlanV2(
              items: [EnrichmentPlanItemV2.allocationMembership()],
            ),
            filters: const SectionFilterSpecV2(
              enableValueDropdown: true,
              enableProjectsOnlyToggle: true,
              enableFocusOnlyToggle: true,
              enableIncludeFutureStartsToggle: true,
              valueFilterMode: ValueFilterModeV2.anyValues,
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
    template: const ScreenTemplateSpec.focusSetupWizard(),
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
    statistics,
    reviewInbox,
    settings,
  ];

  /// All system screens.
  static List<ScreenSpec> get all => [...navigationScreens];

  static const Map<String, int> _defaultSortOrders = {
    'my_day': 0,
    'scheduled': 1,
    'someday': 2,
    'journal': 4,
    'values': 5,
    'statistics': 7,
    'review_inbox': 9,
    'settings': 100,
  };

  static int getDefaultSortOrder(String screenKey) {
    return _defaultSortOrders[screenKey] ?? 999;
  }

  static bool isSystemScreen(String screenKey) => getByKey(screenKey) != null;

  static final _byKey = <String, ScreenSpec>{
    myDay.screenKey: myDay,
    scheduled.screenKey: scheduled,
    someday.screenKey: someday,
    values.screenKey: values,
    settings.screenKey: settings,
    statistics.screenKey: statistics,
    journal.screenKey: journal,
    trackers.screenKey: trackers,
    allocationSettings.screenKey: allocationSettings,
    focusSetup.screenKey: focusSetup,
    attentionRules.screenKey: attentionRules,
    reviewInbox.screenKey: reviewInbox,
  };

  static ScreenSpec? getByKey(String screenKey) {
    final normalized = screenKey.replaceAll('-', '_');

    return _byKey[normalized];
  }
}
