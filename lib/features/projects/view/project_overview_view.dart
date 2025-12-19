import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';
import 'package:taskly_bloc/features/projects/bloc/project_list_bloc.dart';
import 'package:taskly_bloc/features/projects/widgets/project_add_fab.dart';
import 'package:taskly_bloc/features/projects/widgets/projects_list.dart';

class ProjectOverviewPage extends StatelessWidget {
  const ProjectOverviewPage({
    required this.projectRepository,
    super.key,
  });

  final ProjectRepository projectRepository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProjectOverviewBloc(projectRepository: projectRepository),
      child: ProjectOverviewView(projectRepository: projectRepository),
    );
  }
}

class ProjectOverviewView extends StatelessWidget {
  const ProjectOverviewView({
    required this.projectRepository,
    super.key,
  });

  final ProjectRepository projectRepository;

  @override
  Widget build(BuildContext context) {
    //Todo add localization - just a shell so easy to add in future

    // Send event to request data stream subscription
    return BlocBuilder<ProjectOverviewBloc, ProjectOverviewState>(
      builder: (context, state) {
        switch (state) {
          case ProjectOverviewInitial():
            context.read<ProjectOverviewBloc>().add(
              const ProjectOverviewEvent.projectsSubscriptionRequested(),
            );
            return const Center(child: CircularProgressIndicator());

          case ProjectOverviewLoading():
            return const Center(child: CircularProgressIndicator());

          case ProjectOverviewLoaded(projects: final projects):
            if (projects.isEmpty) {
              return const Center(child: Text('No projects found.'));
            } else {
              return Scaffold(
                appBar: AppBar(title: const Text('Projects')),
                body: ProjectsListView(
                  projects: projects,
                  projectRepository: projectRepository,
                ),
                floatingActionButton: AddProjectFab(
                  projectRepository: projectRepository,
                ),
              );
            }

          case ProjectOverviewError(
            message: final message,
          ):
            return Center(child: Text(message));
        }
      },
    );
  }
}
