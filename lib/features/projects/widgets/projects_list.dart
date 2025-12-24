import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/core/shared/widgets/delete_confirmation.dart';
import 'package:taskly_bloc/core/shared/widgets/swipe_to_delete.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/features/projects/bloc/project_list_bloc.dart';
import 'package:taskly_bloc/routing/routes.dart';
import 'package:taskly_bloc/features/projects/widgets/project_list_tile.dart';

class ProjectsListView extends StatefulWidget {
  const ProjectsListView({
    required this.projects,
    required this.projectRepository,
    required this.labelRepository,
    this.displaySettings = const PageDisplaySettings(),
    this.onDisplaySettingsChanged,
    this.taskCounts = const {},
    this.enableSwipeToDelete = true,
    super.key,
  });

  final List<Project> projects;
  final ProjectRepositoryContract projectRepository;
  final LabelRepositoryContract labelRepository;
  final PageDisplaySettings displaySettings;
  final ValueChanged<PageDisplaySettings>? onDisplaySettingsChanged;
  final Map<String, ProjectTaskCounts> taskCounts;
  final bool enableSwipeToDelete;

  @override
  State<ProjectsListView> createState() => _ProjectsListViewState();
}

class _ProjectsListViewState extends State<ProjectsListView> {
  @override
  Widget build(BuildContext context) {
    // Separate projects into active and completed
    final activeProjects = <Project>[];
    final completedProjects = <Project>[];

    for (final project in widget.projects) {
      if (project.completed) {
        completedProjects.add(project);
      } else {
        activeProjects.add(project);
      }
    }

    // If hiding completed, only show active projects
    if (widget.displaySettings.hideCompleted) {
      return _buildProjectsList(context, activeProjects);
    }

    // Show both active and completed sections
    return ListView(
      children: [
        // Active projects
        ...activeProjects.map((project) => _buildProjectItem(context, project)),

        // Completed section
        if (completedProjects.isNotEmpty) ...[
          const SizedBox(height: 8),
          Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
            ),
            child: ExpansionTile(
              initiallyExpanded:
                  !widget.displaySettings.completedSectionCollapsed,
              onExpansionChanged: (expanded) {
                widget.onDisplaySettingsChanged?.call(
                  widget.displaySettings.copyWith(
                    completedSectionCollapsed: !expanded,
                  ),
                );
              },
              leading: Icon(
                Icons.check_circle,
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.6),
              ),
              title: Text(
                'Completed (${completedProjects.length})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              children: completedProjects
                  .map((project) => _buildProjectItem(context, project))
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProjectsList(BuildContext context, List<Project> projects) {
    return ListView.builder(
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return _buildProjectItem(context, project);
      },
    );
  }

  Widget _buildProjectItem(BuildContext context, Project project) {
    final counts = widget.taskCounts[project.id];

    return SwipeToDelete(
      itemKey: ValueKey(project.id),
      enabled: widget.enableSwipeToDelete,
      confirmDismiss: () => showDeleteConfirmationDialog(
        context: context,
        title: 'Delete Project',
        itemName: project.name,
        description:
            'All tasks in this project will also be deleted. This action cannot be undone.',
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
            ProjectOverviewEvent.toggleProjectCompletion(project: project),
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
  }
}
