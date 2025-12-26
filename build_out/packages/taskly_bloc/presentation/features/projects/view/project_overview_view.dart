import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/utils/friendly_error_message.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/settings_repository_contract.dart';
import 'package:taskly_bloc/presentation/features/projects/bloc/project_list_bloc.dart';
import 'package:taskly_bloc/presentation/features/projects/widgets/project_add_fab.dart';
import 'package:taskly_bloc/presentation/features/projects/widgets/projects_list.dart';
import 'package:taskly_bloc/presentation/widgets/page_settings_modal.dart';
import 'package:taskly_bloc/presentation/widgets/empty_state_widget.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';

class ProjectOverviewPage extends StatelessWidget {
  const ProjectOverviewPage({
    required this.projectRepository,
    required this.taskRepository,
    required this.labelRepository,
    required this.settingsRepository,
    required this.pageKey,
    super.key,
  });

  final ProjectRepositoryContract projectRepository;
  final TaskRepositoryContract taskRepository;
  final LabelRepositoryContract labelRepository;
  final SettingsRepositoryContract settingsRepository;
  final PageKey pageKey;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProjectOverviewBloc(
        projectRepository: projectRepository,
        taskRepository: taskRepository,
        withRelated: true,
        settingsRepository: settingsRepository,
        pageKey: pageKey,
      )..add(const ProjectOverviewEvent.subscriptionRequested()),
      child: ProjectOverviewView(
        projectRepository: projectRepository,
        labelRepository: labelRepository,
      ),
    );
  }
}

class ProjectOverviewView extends StatefulWidget {
  const ProjectOverviewView({
    required this.projectRepository,
    required this.labelRepository,
    super.key,
  });

  final ProjectRepositoryContract projectRepository;
  final LabelRepositoryContract labelRepository;

  @override
  State<ProjectOverviewView> createState() => _ProjectOverviewViewState();
}

class _ProjectOverviewViewState extends State<ProjectOverviewView> {
  PageDisplaySettings? _displaySettings;

  @override
  void initState() {
    super.initState();
    _loadDisplaySettings();
  }

  Future<void> _loadDisplaySettings() async {
    final bloc = context.read<ProjectOverviewBloc>();
    final settings = await bloc.loadDisplaySettings();
    if (mounted) {
      setState(() {
        _displaySettings = settings;
      });
    }
  }

  Future<void> _openPageSettings() async {
    final bloc = context.read<ProjectOverviewBloc>();
    final currentPreferences = bloc.currentSortPreferences;

    await showPageSettingsModal(
      context: context,
      displaySettings: _displaySettings ?? const PageDisplaySettings(),
      sortPreferences: currentPreferences,
      availableSortFields: const [
        SortField.deadlineDate,
        SortField.startDate,
        SortField.name,
      ],
      pageTitle: context.l10n.projectsTitle,
      onDisplaySettingsChanged: (PageDisplaySettings settings) {
        setState(() {
          _displaySettings = settings;
        });
        bloc.add(
          ProjectOverviewEvent.displaySettingsChanged(settings: settings),
        );
      },
      onSortPreferencesChanged: (SortPreferences updated) {
        bloc.add(ProjectOverviewEvent.sortChanged(preferences: updated));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.projectsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: _openPageSettings,
          ),
        ],
      ),
      body: BlocBuilder<ProjectOverviewBloc, ProjectOverviewState>(
        builder: (context, state) {
          return switch (state) {
            ProjectOverviewInitial() => const Center(
              child: CircularProgressIndicator(),
            ),
            ProjectOverviewLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            ProjectOverviewLoaded(
              projects: final projects,
              taskCounts: final taskCounts,
            ) =>
              _buildLoadedState(context, projects, taskCounts),
            ProjectOverviewError(error: final error) => Center(
              child: Text(
                friendlyErrorMessageForUi(error, context.l10n),
              ),
            ),
          };
        },
      ),
      floatingActionButton: AddProjectFab(
        projectRepository: widget.projectRepository,
        labelRepository: widget.labelRepository,
      ),
    );
  }

  Widget _buildLoadedState(
    BuildContext context,
    List<Project> projects,
    Map<String, ProjectTaskCounts> taskCounts,
  ) {
    if (projects.isEmpty) {
      return EmptyStateWidget.noProjects(
        title: context.l10n.emptyProjectsTitle,
        description: context.l10n.emptyProjectsDescription,
      );
    }
    return ProjectsListView(
      projects: projects,
      projectRepository: widget.projectRepository,
      labelRepository: widget.labelRepository,
      taskCounts: taskCounts,
      displaySettings: _displaySettings ?? const PageDisplaySettings(),
      onDisplaySettingsChanged: (PageDisplaySettings settings) {
        setState(() {
          _displaySettings = settings;
        });
        context.read<ProjectOverviewBloc>().add(
          ProjectOverviewEvent.displaySettingsChanged(settings: settings),
        );
      },
    );
  }
}
