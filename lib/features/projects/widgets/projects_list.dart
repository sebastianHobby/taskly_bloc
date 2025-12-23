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

class ProjectsListView extends StatelessWidget {
  const ProjectsListView({
    required this.projects,
    required this.projectRepository,
    required this.labelRepository,
    this.enableSwipeToDelete = true,
    super.key,
  });

  final List<Project> projects;
  final ProjectRepositoryContract projectRepository;
  final LabelRepositoryContract labelRepository;
  final bool enableSwipeToDelete;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return SwipeToDelete(
          itemKey: ValueKey(project.id),
          enabled: enableSwipeToDelete,
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
      },
    );
  }
}
