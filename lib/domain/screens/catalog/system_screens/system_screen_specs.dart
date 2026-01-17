import 'package:taskly_domain/queries.dart';
import 'package:taskly_bloc/domain/screens/language/models/data_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/app_bar_action.dart';
import 'package:taskly_bloc/domain/screens/language/models/fab_operation.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_chrome.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_gate_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_spec.dart';
import 'package:taskly_bloc/domain/screens/templates/params/agenda_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/attention_inbox_section_params_v1.dart';
import 'package:taskly_bloc/domain/screens/templates/params/hierarchy_value_project_task_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';

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
      showHeaderAccessoryInAppBar: false,
      fabOperations: [FabOperation.createTask],
    ),
    modules: SlottedModules(
      header: [
        const ScreenModuleSpec.myDayHeroV1(),
      ],
      primary: [
        ScreenModuleSpec.myDayRankedTasksV1(title: 'Today'),
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
          params: const AttentionInboxSectionParamsV1(),
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
      showHeaderAccessoryInAppBar: false,
      fabOperations: [FabOperation.createTask],
    ),
    modules: SlottedModules(
      primary: [
        ScreenModuleSpec.agendaV2(
          params: AgendaSectionParamsV2(
            dateField: AgendaDateFieldV2.deadlineDate,
            layout: AgendaLayoutV2.dayCardsFeed,
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

  static final inbox = ScreenSpec(
    id: 'inbox',
    screenKey: 'inbox',
    name: 'Inbox',
    template: const ScreenTemplateSpec.standardScaffoldV1(),
    chrome: const ScreenChrome(
      showHeaderAccessoryInAppBar: false,
      fabOperations: [FabOperation.createTask],
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
      showHeaderAccessoryInAppBar: false,
      fabOperations: [FabOperation.createTask],
    ),
    modules: SlottedModules(
      primary: [
        ScreenModuleSpec.hierarchyValueProjectTaskV2(
          params: HierarchyValueProjectTaskSectionParamsV2(
            sources: [
              DataConfig.task(query: TaskQuery.incomplete()),
              DataConfig.project(query: ProjectQuery.active()),
            ],
            pinnedValueHeaders: true,
            pinnedProjectHeaders: false,
            singleInboxGroupForNoProjectTasks: true,
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
    name: 'My Values',
    template: const ScreenTemplateSpec.standardScaffoldV1(),
    chrome: const ScreenChrome(
      appBarActions: [AppBarAction.createValue],
    ),
    modules: SlottedModules(
      primary: [
        ScreenModuleSpec.valueListV2(
          params: ListSectionParamsV2(
            config: DataConfig.value(query: const ValueQuery()),
            separator: ListSeparatorV2.spaced8,
            enrichment: const EnrichmentPlanV2(
              items: [EnrichmentPlanItemV2.valueStats()],
            ),
          ),
        ),
        const ScreenModuleSpec.createValueCtaV1(),
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
    template: const ScreenTemplateSpec.standardScaffoldV1(),
    chrome: const ScreenChrome(
      appBarActions: [AppBarAction.journalManageTrackers],
    ),
    modules: const SlottedModules(
      header: [
        ScreenModuleSpec.journalTodayComposerV1(),
        ScreenModuleSpec.journalHistoryTeaserV1(),
      ],
      primary: [
        ScreenModuleSpec.journalTodayEntriesV1(),
      ],
    ),
  );

  static final journalHistory = ScreenSpec(
    id: 'journal_history',
    screenKey: 'journal_history',
    name: 'Journal History',
    template: const ScreenTemplateSpec.standardScaffoldV1(),
    modules: const SlottedModules(
      primary: [
        ScreenModuleSpec.journalHistoryListV1(),
      ],
    ),
  );

  static final journalManageTrackers = ScreenSpec(
    id: 'journal_manage_trackers',
    screenKey: 'journal_manage_trackers',
    name: 'Manage Trackers',
    template: const ScreenTemplateSpec.standardScaffoldV1(),
    modules: const SlottedModules(
      primary: [
        ScreenModuleSpec.journalManageTrackersV1(),
      ],
    ),
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
    inbox,
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
    'inbox': 1,
    'scheduled': 2,
    'someday': 3,
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
    inbox.screenKey: inbox,
    scheduled.screenKey: scheduled,
    someday.screenKey: someday,
    values.screenKey: values,
    settings.screenKey: settings,
    statistics.screenKey: statistics,
    journal.screenKey: journal,
    journalHistory.screenKey: journalHistory,
    journalManageTrackers.screenKey: journalManageTrackers,
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
