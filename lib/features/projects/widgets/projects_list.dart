import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/value_repository_contract.dart';
import 'package:taskly_bloc/features/projects/bloc/project_list_bloc.dart';
import 'package:taskly_bloc/features/projects/view/project_detail_view.dart';
import 'package:taskly_bloc/core/widgets/wolt_modal_helpers.dart';
import 'package:taskly_bloc/features/projects/widgets/project_list_tile.dart';

class ProjectsListView extends StatelessWidget {
  const ProjectsListView({
    required this.projects,
    required this.projectRepository,
    required this.valueRepository,
    required this.labelRepository,
    super.key,
  });

  final List<Project> projects;
  final ProjectRepositoryContract projectRepository;
  final ValueRepositoryContract valueRepository;
  final LabelRepositoryContract labelRepository;

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
              ProjectOverviewEvent.toggleProjectCompletion(project: project),
            );
          },
          onTap: (project) async {
            await showDetailModal<void>(
              context: context,
              childBuilder: (modalSheetContext) => ProjectDetailSheetPage(
                projectId: project.id,
                projectRepository: projectRepository,
                valueRepository: valueRepository,
                labelRepository: labelRepository,
                onSuccess: (String message) {
                  Navigator.of(modalSheetContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message)),
                  );
                },
                onError: (errorMessage) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(errorMessage)),
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
