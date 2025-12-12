import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';

import 'package:taskly_bloc/features/projects/projects.dart';
import 'package:taskly_bloc/features/projects/widgets/project_list_tile.dart';

class ProjectsPage extends StatelessWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final projectRepository = getIt<ProjectRepository>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
      ),
      body: BlocProvider(
        create: (_) => ProjectsBloc(projectRepository: projectRepository),
        child: const ProjectsView(),
      ),
    );
  }
}

class ProjectsView extends StatelessWidget {
  const ProjectsView({super.key});
  // final l10n = context.l10n;

  @override
  Widget build(BuildContext context) {
    // Send event to request data stream subscription
    return BlocBuilder<ProjectsBloc, ProjectsState>(
      builder: (context, state) {
        switch (state) {
          case ProjectsInitial():
            context.read<ProjectsBloc>().add(
              const ProjectsSubscriptionRequested(),
            );

          case ProjectsLoading():
            return const Center(child: CircularProgressIndicator());
          case ProjectsLoaded():
            if (state.projects.isEmpty) {
              return const Center(child: Text('No projects found.'));
            }
            return ListView.builder(
              itemCount: state.projects.length,
              itemBuilder: (context, index) {
                final project = state.projects[index];
                //  return ProjectListTile(project: project, key: super.key);
                return ProjectListTile(project: project, key: super.key);
              },
            );
          case ProjectsError():
        }

        return const SizedBox();
      },
    );
  }
}
