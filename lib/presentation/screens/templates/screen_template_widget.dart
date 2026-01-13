import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/domain/attention/contracts/attention_repository_contract.dart'
    as attention_repo_v2;
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/journal_repository_contract.dart';
import 'package:taskly_bloc/domain/analytics/model/entity_type.dart';
import 'package:taskly_bloc/domain/core/model/project.dart';
import 'package:taskly_bloc/domain/core/model/task.dart';
import 'package:taskly_bloc/domain/core/model/value.dart';
import 'package:taskly_bloc/domain/services/analytics/analytics_service.dart';
import 'package:taskly_bloc/domain/screens/language/models/app_bar_action.dart';
import 'package:taskly_bloc/domain/screens/language/models/fab_operation.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_spec.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_spec_data.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_vm.dart';
import 'package:taskly_bloc/presentation/features/browse/view/browse_hub_screen.dart';
import 'package:taskly_bloc/presentation/features/focus_setup/bloc/focus_setup_bloc.dart';
import 'package:taskly_bloc/presentation/features/focus_setup/view/focus_setup_wizard_page.dart';
import 'package:taskly_bloc/presentation/features/navigation/view/navigation_settings_page.dart';
import 'package:taskly_bloc/presentation/features/settings/view/settings_screen.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/bloc/journal_entry/journal_entry_bloc.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/bloc/tracker_management/tracker_management_bloc.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/bloc/wellbeing_dashboard/wellbeing_dashboard_bloc.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/view/journal_screen.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/view/tracker_management_screen.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/view/wellbeing_dashboard_screen.dart';
import 'package:taskly_bloc/presentation/features/projects/widgets/project_add_fab.dart';
import 'package:taskly_bloc/presentation/features/tasks/widgets/task_add_fab.dart';
import 'package:taskly_bloc/presentation/features/values/widgets/add_value_fab.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/screens/view/my_day_focus_mode_required_page.dart';
import 'package:taskly_bloc/presentation/widgets/section_widget.dart';

/// Switchboard for rendering a typed [ScreenTemplateSpec].
class ScreenTemplateWidget extends StatelessWidget {
  const ScreenTemplateWidget({
    required this.data,
    super.key,
  });

  final ScreenSpecData data;

  @override
  Widget build(BuildContext context) {
    return data.template.when(
      standardScaffoldV1: () => _StandardScaffoldV1Template(data: data),
      settingsMenu: () => const SettingsScreen(),
      trackerManagement: () => BlocProvider(
        create: (_) =>
            TrackerManagementBloc(getIt<JournalRepositoryContract>()),
        child: const TrackerManagementScreen(),
      ),
      statisticsDashboard: () => const Scaffold(
        body: Center(
          child: Text('Statistics dashboard not implemented yet.'),
        ),
      ),
      wellbeingDashboard: () => BlocProvider(
        create: (_) => WellbeingDashboardBloc(getIt<AnalyticsService>()),
        child: const WellbeingDashboardScreen(),
      ),
      journalTimeline: () => BlocProvider(
        create: (_) => JournalEntryBloc(getIt<JournalRepositoryContract>()),
        child: const JournalScreen(),
      ),
      navigationSettings: () => NavigationSettingsPage(
        screensRepository: getIt<ScreenDefinitionsRepositoryContract>(),
      ),
      allocationSettings: () => BlocProvider(
        create: (_) => FocusSetupBloc(
          settingsRepository: getIt<SettingsRepositoryContract>(),
          attentionRepository:
              getIt<attention_repo_v2.AttentionRepositoryContract>(),
        )..add(const FocusSetupEvent.started()),
        child: const FocusSetupWizardPage(),
      ),
      attentionRules: () => BlocProvider(
        create: (_) => FocusSetupBloc(
          settingsRepository: getIt<SettingsRepositoryContract>(),
          attentionRepository:
              getIt<attention_repo_v2.AttentionRepositoryContract>(),
        )..add(const FocusSetupEvent.started()),
        child: const FocusSetupWizardPage(),
      ),
      focusSetupWizard: () => BlocProvider(
        create: (_) => FocusSetupBloc(
          settingsRepository: getIt<SettingsRepositoryContract>(),
          attentionRepository:
              getIt<attention_repo_v2.AttentionRepositoryContract>(),
        )..add(const FocusSetupEvent.started()),
        child: const FocusSetupWizardPage(),
      ),
      browseHub: () => const BrowseHubScreen(),
      myDayFocusModeRequired: () => const MyDayFocusModeRequiredPage(),
    );
  }
}

class _StandardScaffoldV1Template extends StatelessWidget {
  const _StandardScaffoldV1Template({required this.data});

  final ScreenSpecData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spec = data.spec;

    final appBarActions = _buildAppBarActions(context, spec);
    final fab = _buildFab(spec);

    final slivers = <Widget>[
      ...data.sections.header.map((s) => _ModuleSliver(section: s)),
      ...data.sections.primary.map((s) => _ModuleSliver(section: s)),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(spec.name),
        actions: appBarActions,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: CustomScrollView(slivers: slivers),
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: fab ?? const SizedBox.shrink(key: ValueKey('no-fab')),
      ),
    );
  }

  List<Widget> _buildAppBarActions(BuildContext context, ScreenSpec spec) {
    return spec.chrome.appBarActions
        .map((action) {
          return switch (action) {
            AppBarAction.settingsLink => IconButton(
              icon: const Icon(Icons.tune),
              onPressed: spec.chrome.settingsRoute != null
                  ? () =>
                        Routing.toScreenKey(context, spec.chrome.settingsRoute!)
                  : null,
            ),
            AppBarAction.help => const SizedBox.shrink(),
          };
        })
        .toList(growable: false);
  }

  Widget? _buildFab(ScreenSpec spec) {
    final operations = spec.chrome.fabOperations;
    if (operations.isEmpty) return null;

    final operation = operations.first;

    return switch (operation) {
      FabOperation.createTask => AddTaskFab(
        taskRepository: getIt(),
        projectRepository: getIt(),
        valueRepository: getIt(),
      ),
      FabOperation.createProject => AddProjectFab(
        projectRepository: getIt(),
        valueRepository: getIt(),
      ),
      FabOperation.createValue => AddValueFab(
        valueRepository: getIt(),
        tooltip: 'Create value',
        heroTag: 'create_value_fab',
      ),
    };
  }
}

class _ModuleSliver extends StatelessWidget {
  const _ModuleSliver({required this.section});

  final SectionVm section;

  @override
  Widget build(BuildContext context) {
    return SectionWidget(
      section: section,
      onEntityTap: (entity) {
        if (entity is Task) {
          Routing.toEntity(context, EntityType.task, entity.id);
        } else if (entity is Project) {
          Routing.toEntity(context, EntityType.project, entity.id);
        } else if (entity is Value) {
          Routing.toEntity(context, EntityType.value, entity.id);
        }
      },
    );
  }
}
