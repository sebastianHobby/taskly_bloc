import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';
import 'package:taskly_bloc/features/projects/bloc/project_list_bloc.dart';
import 'package:taskly_bloc/features/projects/view/project_detail_view.dart';
import 'package:taskly_bloc/core/widgets/wolt_modal_helpers.dart';
import 'package:taskly_bloc/features/projects/widgets/project_list_tile.dart';

class ProjectsListView extends StatelessWidget {
  const ProjectsListView({
    required this.projects,
    required this.projectRepository,
    super.key,
  });

  final List<ProjectTableData> projects;
  final ProjectRepository projectRepository;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return ProjectListTile(
          project: project,
          onCheckboxChanged: (project, _) {
            context.read<ProjectOverviewBloc>().add(
              ProjectOverviewEvent.toggleProjectCompletion(
                projectData: project,
              ),
            );
          },
          onTap: (project) async {
            await showDetailModal<void>(
              context: context,
              childBuilder: (modalSheetContext) => ProjectDetailSheetPage(
                projectId: project.id,
                projectRepository: projectRepository,
                onSuccess: (String message) {
                  Navigator.of(modalSheetContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message)),
                  );
                },
                onError: (errorMessage) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $errorMessage')),
                  );
                },
              ),
              showDragHandle: true,
            );
          },
        );
      },
    );
  }
}
