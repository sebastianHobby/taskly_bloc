import 'package:taskly_domain/queries.dart';
import 'package:taskly_bloc/domain/screens/language/models/data_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/fab_operation.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_chrome.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_gate_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_spec.dart';
import 'package:taskly_bloc/domain/screens/templates/params/agenda_section_params_v2.dart';
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

  /// Canonical system screens shown in the main navigation UI.
  static List<ScreenSpec> get navigationScreens => [
    myDay,
    inbox,
    scheduled,
    someday,
  ];

  /// All system screens.
  static List<ScreenSpec> get all => [...navigationScreens];

  static const Map<String, int> _defaultSortOrders = {
    'my_day': 0,
    'inbox': 1,
    'scheduled': 2,
    'someday': 3,
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
  };

  static ScreenSpec? getByKey(String screenKey) {
    final normalized = screenKey.replaceAll('-', '_');

    return _byKey[normalized];
  }
}
