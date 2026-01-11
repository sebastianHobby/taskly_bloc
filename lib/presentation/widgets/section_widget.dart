import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/domain/models/settings/focus_mode.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/models/screens/screen_item.dart';
import 'package:taskly_bloc/domain/models/screens/section_template_id.dart';
import 'package:taskly_bloc/domain/models/screens/display_config.dart';
import 'package:taskly_bloc/domain/models/screens/templates/agenda_section_params.dart';
import 'package:taskly_bloc/domain/models/screens/templates/data_list_section_params.dart';
import 'package:taskly_bloc/domain/services/screens/section_data_result.dart';
import 'package:taskly_bloc/domain/services/screens/section_vm.dart';
import 'package:taskly_bloc/domain/attention/contracts/attention_repository_contract.dart'
    as attention_repo_v2;
import 'package:taskly_bloc/domain/interfaces/auth_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/wellbeing_repository_contract.dart';
import 'package:taskly_bloc/domain/services/analytics/analytics_service.dart';

import 'package:taskly_bloc/presentation/features/screens/renderers/allocation_section_renderer.dart';
import 'package:taskly_bloc/presentation/features/screens/renderers/allocation_alerts_section_renderer.dart';
import 'package:taskly_bloc/presentation/features/screens/renderers/agenda_section_renderer.dart';
import 'package:taskly_bloc/presentation/features/screens/renderers/check_in_summary_section_renderer.dart';
import 'package:taskly_bloc/presentation/features/screens/renderers/entity_header_section_renderer.dart';
import 'package:taskly_bloc/presentation/features/screens/renderers/issues_summary_section_renderer.dart';
import 'package:taskly_bloc/presentation/features/screens/renderers/interleaved_list_renderer.dart';
import 'package:taskly_bloc/presentation/features/screens/renderers/project_list_renderer.dart';
import 'package:taskly_bloc/presentation/features/screens/renderers/someday_backlog_renderer.dart';
import 'package:taskly_bloc/presentation/features/screens/renderers/task_list_renderer.dart';
import 'package:taskly_bloc/presentation/features/screens/renderers/value_list_renderer.dart';
import 'package:taskly_bloc/presentation/features/focus_setup/bloc/focus_setup_bloc.dart';
import 'package:taskly_bloc/presentation/features/focus_setup/view/focus_setup_wizard_page.dart';
import 'package:taskly_bloc/presentation/features/navigation/view/navigation_settings_page.dart';
import 'package:taskly_bloc/presentation/features/browse/view/browse_hub_screen.dart';
import 'package:taskly_bloc/presentation/features/screens/view/screen_management_page.dart';
import 'package:taskly_bloc/presentation/features/screens/view/my_day_focus_mode_required_page.dart';
import 'package:taskly_bloc/presentation/features/settings/view/settings_screen.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/bloc/journal_entry/journal_entry_bloc.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/bloc/tracker_management/tracker_management_bloc.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/bloc/wellbeing_dashboard/wellbeing_dashboard_bloc.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/view/journal_screen.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/view/tracker_management_screen.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/view/wellbeing_dashboard_screen.dart';
import 'package:taskly_bloc/presentation/features/workflow/view/workflow_list_page.dart';

/// Widget that renders a section from ScreenBloc state.
///
/// Handles different section types (data, allocation, agenda) and
/// displays appropriate UI for each.
class SectionWidget extends StatelessWidget {
  /// Creates a SectionWidget.
  const SectionWidget({
    required this.section,
    super.key,
    this.displayConfig,
    this.focusMode,
    this.onEntityTap,
    this.onTaskComplete,
    this.onTaskCheckboxChanged,
    this.onProjectCheckboxChanged,
    this.onTaskDelete,
    this.onProjectDelete,
  });

  /// The section data to render
  final SectionVm section;

  /// Optional display configuration override
  final DisplayConfig? displayConfig;

  /// Current focus mode (for allocation sections)
  final FocusMode? focusMode;

  /// Callback when an entity is tapped
  final void Function(dynamic entity)? onEntityTap;

  /// Callback when a task is completed (legacy)
  final void Function(Task task)? onTaskComplete;

  /// Callback when a task checkbox is changed
  final void Function(Task task, bool? value)? onTaskCheckboxChanged;

  /// Callback when a project checkbox is changed
  final void Function(Project project, bool? value)? onProjectCheckboxChanged;

  /// Callback when a task is deleted
  final void Function(Task task)? onTaskDelete;

  /// Callback when a project is deleted
  final void Function(Project project)? onProjectDelete;

  @override
  Widget build(BuildContext context) {
    if (section.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (section.error case final error?) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Text('Section error: $error'),
      );
    }

    if (_isFullScreenTemplate(section.templateId)) {
      return _buildFullScreenTemplate();
    }

    final result = section.data;

    final paramsDisplayConfig = switch (section.params) {
      final DataListSectionParams p => p.display,
      _ => null,
    };

    final effectiveDisplayConfig =
        displayConfig ?? section.displayConfig ?? paramsDisplayConfig;

    final compactTiles = effectiveDisplayConfig?.compactTiles ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: switch (result) {
        final IssuesSummarySectionResult d => IssuesSummarySectionRenderer(
          data: d,
        ),
        final CheckInSummarySectionResult d => CheckInSummarySectionRenderer(
          data: d,
        ),
        final AllocationAlertsSectionResult d =>
          AllocationAlertsSectionRenderer(
            data: d,
          ),
        EntityHeaderProjectSectionResult() ||
        EntityHeaderValueSectionResult() ||
        EntityHeaderMissingSectionResult() => EntityHeaderSectionRenderer(
          data: result! as SectionDataResult,
          onProjectCheckboxChanged: (val) {
            if (result is EntityHeaderProjectSectionResult) {
              onProjectCheckboxChanged?.call(result.project, val);
            }
          },
        ),
        final AllocationSectionResult d => AllocationSectionRenderer(
          data: d,
          onTaskToggle: (taskId, val) {
            final task = d.allocatedTasks.firstWhere((t) => t.id == taskId);
            onTaskCheckboxChanged?.call(task, val);
          },
        ),
        final DataSectionResult d => switch (section.templateId) {
          SectionTemplateId.taskList => TaskListRenderer(
            data: d,
            title: section.title,
            compactTiles: compactTiles,
            onTaskToggle: (taskId, val) {
              final task = d.allTasks.firstWhere((t) => t.id == taskId);
              onTaskCheckboxChanged?.call(task, val);
            },
          ),
          SectionTemplateId.projectList => ProjectListRenderer(
            data: d,
            title: section.title,
            compactTiles: compactTiles,
            onProjectToggle: onProjectCheckboxChanged == null
                ? null
                : (projectId, val) {
                    final project = d.items
                        .whereType<ScreenItemProject>()
                        .map((i) => i.project)
                        .firstWhere((p) => p.id == projectId);
                    onProjectCheckboxChanged?.call(project, val);
                  },
          ),
          SectionTemplateId.valueList => ValueListRenderer(
            data: d,
            title: section.title,
          ),
          SectionTemplateId.interleavedList => InterleavedListRenderer(
            data: d,
            title: section.title,
            compactTiles: compactTiles,
            onTaskToggle: (taskId, val) {
              final task = d.allTasks.firstWhere((t) => t.id == taskId);
              onTaskCheckboxChanged?.call(task, val);
            },
          ),
          SectionTemplateId.somedayNullDates => InterleavedListRenderer(
            data: d,
            title: section.title,
            compactTiles: compactTiles,
            onTaskToggle: (taskId, val) {
              final task = d.allTasks.firstWhere((t) => t.id == taskId);
              onTaskCheckboxChanged?.call(task, val);
            },
          ),
          SectionTemplateId.somedayBacklog => SomedayBacklogRenderer(
            data: d,
            compactTiles: compactTiles,
            onTaskToggle: (taskId, val) {
              final task = d.allTasks.firstWhere((t) => t.id == taskId);
              onTaskCheckboxChanged?.call(task, val);
            },
            onEntityTap: (entity) => onEntityTap?.call(entity),
          ),
          _ => _buildLegacySection(d),
        },
        final AgendaSectionResult d => AgendaSectionRenderer(
          data: d,
          params: section.params as AgendaSectionParams,
          onTaskToggle: (taskId, val) {
            final task = d.agendaData.groups
                .expand((g) => g.items)
                .where((item) => item.isTask && item.task?.id == taskId)
                .map((item) => item.task!)
                .first;
            onTaskCheckboxChanged?.call(task, val);
          },
          onTaskTap: (task) => onEntityTap?.call(task),
        ),
        _ => _buildUnknownSection(),
      },
    );
  }

  static bool _isFullScreenTemplate(String templateId) {
    return switch (templateId) {
      SectionTemplateId.settingsMenu ||
      SectionTemplateId.statisticsDashboard ||
      SectionTemplateId.journalTimeline ||
      SectionTemplateId.workflowList ||
      SectionTemplateId.screenManagement ||
      SectionTemplateId.trackerManagement ||
      SectionTemplateId.wellbeingDashboard ||
      SectionTemplateId.allocationSettings ||
      SectionTemplateId.navigationSettings ||
      SectionTemplateId.attentionRules ||
      SectionTemplateId.focusSetupWizard ||
      SectionTemplateId.browseHub ||
      SectionTemplateId.myDayFocusModeRequired => true,
      _ => false,
    };
  }

  Widget _buildFullScreenTemplate() {
    return switch (section.templateId) {
      SectionTemplateId.browseHub => const BrowseHubScreen(),
      SectionTemplateId.settingsMenu => const SettingsScreen(),
      SectionTemplateId.myDayFocusModeRequired =>
        const MyDayFocusModeRequiredPage(),
      SectionTemplateId.allocationSettings => BlocProvider(
        create: (_) => FocusSetupBloc(
          settingsRepository: getIt<SettingsRepositoryContract>(),
          attentionRepository:
              getIt<attention_repo_v2.AttentionRepositoryContract>(),
        )..add(const FocusSetupEvent.started()),
        child: const FocusSetupWizardPage(),
      ),
      SectionTemplateId.navigationSettings => NavigationSettingsPage(
        screensRepository: getIt<ScreenDefinitionsRepositoryContract>(),
      ),
      SectionTemplateId.attentionRules => BlocProvider(
        create: (_) => FocusSetupBloc(
          settingsRepository: getIt<SettingsRepositoryContract>(),
          attentionRepository:
              getIt<attention_repo_v2.AttentionRepositoryContract>(),
        )..add(const FocusSetupEvent.started()),
        child: const FocusSetupWizardPage(),
      ),
      SectionTemplateId.focusSetupWizard => BlocProvider(
        create: (_) => FocusSetupBloc(
          settingsRepository: getIt<SettingsRepositoryContract>(),
          attentionRepository:
              getIt<attention_repo_v2.AttentionRepositoryContract>(),
        )..add(const FocusSetupEvent.started()),
        child: const FocusSetupWizardPage(),
      ),
      SectionTemplateId.screenManagement => ScreenManagementPage(
        userId: getIt<AuthRepositoryContract>().currentUser!.id,
      ),
      SectionTemplateId.workflowList => WorkflowListPage(
        userId: getIt<AuthRepositoryContract>().currentUser!.id,
      ),
      SectionTemplateId.journalTimeline => BlocProvider(
        create: (_) => JournalEntryBloc(
          getIt<WellbeingRepositoryContract>(),
        ),
        child: const JournalScreen(),
      ),
      SectionTemplateId.trackerManagement => BlocProvider(
        create: (_) => TrackerManagementBloc(
          getIt<WellbeingRepositoryContract>(),
        ),
        child: const TrackerManagementScreen(),
      ),
      SectionTemplateId.wellbeingDashboard => BlocProvider(
        create: (_) => WellbeingDashboardBloc(getIt<AnalyticsService>()),
        child: const WellbeingDashboardScreen(),
      ),
      SectionTemplateId.statisticsDashboard => const Scaffold(
        body: Center(
          child: Text('Statistics dashboard not implemented yet.'),
        ),
      ),
      _ => Text('Unsupported full-screen template: ${section.templateId}'),
    };
  }

  Widget _buildLegacySection(SectionDataResult result) {
    // TODO: Port other renderers
    return Text('Unsupported section type: ${result.runtimeType}');
  }

  Widget _buildUnknownSection() {
    return Text('Unsupported section data: ${section.templateId}');
  }
}
