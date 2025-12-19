import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/features/projects/bloc/project_list_bloc.dart';
import 'package:taskly_bloc/features/projects/view/project_detail_view.dart';
import 'package:taskly_bloc/features/projects/widgets/project_list_tile.dart';

ListView ProjectsList(List<ProjectTableData> projects, BuildContext context) {
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
          late PersistentBottomSheetController controller;
          controller = Scaffold.of(context).showBottomSheet(
            (ctx) => Material(
              color: Theme.of(ctx).colorScheme.surface,
              child: SafeArea(
                top: false,
                child: ProjectDetailSheetPage(
                  projectId: project.id,
                  onSuccess: (String message) {
                    controller.close();
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
              ),
            ),
            elevation: 8,
          );
        },
      );
    },
  );
}
