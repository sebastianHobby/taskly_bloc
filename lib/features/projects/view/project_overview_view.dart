import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/shared/widgets/delete_confirmation.dart';
import 'package:taskly_bloc/core/shared/widgets/swipe_to_delete.dart';
import 'package:taskly_bloc/core/utils/friendly_error_message.dart';
import 'package:taskly_bloc/data/adapters/page_sort_adapter.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/domain/project.dart';
import 'package:taskly_bloc/domain/project_task_counts.dart';
import 'package:taskly_bloc/features/projects/bloc/project_list_bloc.dart';
import 'package:taskly_bloc/features/projects/widgets/project_add_fab.dart';
import 'package:taskly_bloc/features/projects/widgets/project_list_tile.dart';
import 'package:taskly_bloc/core/shared/models/sort_preferences.dart';
import 'package:taskly_bloc/core/shared/widgets/sort_bottom_sheet.dart';
import 'package:taskly_bloc/routing/routes.dart';
import 'package:taskly_bloc/core/shared/widgets/empty_state_widget.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';

class ProjectOverviewPage extends StatelessWidget {
  const ProjectOverviewPage({
    required this.projectRepository,
    required this.taskRepository,
    required this.labelRepository,
    required this.sortAdapter,
    super.key,
  });

  final ProjectRepositoryContract projectRepository;
  final TaskRepositoryContract taskRepository;
  final LabelRepositoryContract labelRepository;
  final PageSortAdapter sortAdapter;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProjectOverviewBloc(
        projectRepository: projectRepository,
        taskRepository: taskRepository,
        withRelated: true,
        sortAdapter: sortAdapter,
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
  Future<void> _openGroupSortSheet() async {
    final bloc = context.read<ProjectOverviewBloc>();
    final currentPreferences = bloc.currentSortPreferences;

    await showSortBottomSheet(
      context: context,
      current: currentPreferences,
      availableSortFields: const [
        SortField.deadlineDate,
        SortField.startDate,
        SortField.name,
      ],
      onChanged: (updated) {
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
            icon: const Icon(Icons.sort),
            tooltip: context.l10n.sortMenuTitle,
            onPressed: _openGroupSortSheet,
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
    return ListView.builder(
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        final counts = taskCounts[project.id];
        return SwipeToDelete(
          itemKey: ValueKey(project.id),
          confirmDismiss: () => showDeleteConfirmationDialog(
            context: context,
            title: 'Delete Project',
            itemName: project.name,
            description:
                'All tasks in this project will also be deleted. '
                'This action cannot be undone.',
          ),
          onDismissed: () {
            context.read<ProjectOverviewBloc>().add(
              ProjectOverviewEvent.deleteProject(project: project),
            );
            showDeleteSnackBar(
              context: context,
              message: 'Project deleted',
            );
          },
          child: ProjectListTile(
            project: project,
            taskCount: counts?.totalCount,
            completedTaskCount: counts?.completedCount,
            onCheckboxChanged: (project, _) {
              context.read<ProjectOverviewBloc>().add(
                ProjectOverviewEvent.toggleProjectCompletion(
                  project: project,
                ),
              );
            },
            onTap: (project) async {
              await context.pushNamed(
                AppRouteName.projectDetail,
                pathParameters: {'projectId': project.id},
              );
            },
          ),
        );
      },
    );
  }
}
