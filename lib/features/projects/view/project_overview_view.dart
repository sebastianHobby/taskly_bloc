import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';
import 'package:taskly_bloc/features/projects/bloc/project_list_bloc.dart';
import 'package:taskly_bloc/features/projects/widgets/project_add_fab.dart';
import 'package:taskly_bloc/features/projects/widgets/projects_list.dart';

class ProjectOverviewPage extends StatelessWidget {
  const ProjectOverviewPage({super.key});
  @override
  Widget build(BuildContext context) {
    final projectRepository = getIt<ProjectRepository>();
    return BlocProvider(
      create: (_) => ProjectOverviewBloc(projectRepository: projectRepository),
      child: const ProjectOverviewView(),
    );
  }
}

class ProjectOverviewView extends StatelessWidget {
  const ProjectOverviewView({super.key});

  @override
  Widget build(BuildContext context) {
    //Todo add localization - just a shell so easy to add in future
    //final l10n = context.l10n;

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
                body: ProjectsList(projects, context),
                floatingActionButton: AddProjectFab(
                  context: context,
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
