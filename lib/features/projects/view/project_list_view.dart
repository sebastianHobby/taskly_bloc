import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';
import 'package:taskly_bloc/features/projects/bloc/project_list_bloc.dart';
import 'package:taskly_bloc/features/projects/widgets/project_list_tile.dart';
import 'package:taskly_bloc/routing/routes.dart';

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
        create: (_) => ProjectListBloc(projectRepository: projectRepository),
        child: const ProjectsListView(),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add project',
        onPressed: () async {
          await context.push(
            Routes.editProjectModal,
          );
        },
        heroTag: 'add_project_fab', // used by assistive technologies
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ProjectsListView extends StatelessWidget {
  const ProjectsListView({super.key});

  @override
  Widget build(BuildContext context) {
    //Todo add localization - just a shell so easy to add in future
    //final l10n = context.l10n;

    // Send event to request data stream subscription
    return BlocBuilder<ProjectListBloc, ProjectListState>(
      builder: (context, state) {
        return state.when(
          initial: () {
            context.read<ProjectListBloc>().add(
              const ProjectListEvent.projectsSubscriptionRequested(),
            );
            return const Center(child: CircularProgressIndicator());
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          loaded: (projects) {
            if (projects.isEmpty) {
              return const Center(child: Text('No projects found.'));
            }
            return ListView.builder(
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                return ProjectListTile(
                  projectDto: project,
                  key: super.key,
                  // navigate to editProjectModal and pass the ProjectDto as extra
                  onTap: () async {
                    await context.push(Routes.editProjectModal, extra: project);
                  },
                );
              },
            );
          },
          error: (message) => Center(child: Text(message)),
        );
      },
    );
  }
}
