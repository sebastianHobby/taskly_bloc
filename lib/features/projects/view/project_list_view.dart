import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';
import 'package:taskly_bloc/features/projects/bloc/project_list_bloc.dart';
import 'package:taskly_bloc/features/projects/widgets/project_list_tile.dart';
import 'package:taskly_bloc/routing/routes.dart';

class ProjectsPage extends StatelessWidget {
  const ProjectsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final projectRepository = getIt<ProjectRepository>();
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              ProjectOverviewBloc(projectRepository: projectRepository),
        ),
        BlocProvider(
          create: (_) =>
              ProjectDetailBloc(projectRepository: projectRepository),
        ),
      ],
      child: const ProjectOverviewView(),
    );
  }
}

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
                child: ProjectDetailSheetView(
                  initialData: project,
                  onSuccess: (message) {
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

class ProjectOverviewView extends StatelessWidget {
  const ProjectOverviewView({super.key});

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
                  project: project,
                  onCheckboxChanged: (project, _) {
                    context.read<ProjectListBloc>().add(
                      ProjectListEvent.toggleProjectCompletion(
                        projectData: project,
                      ),
                    );
                  },
                  onTap: (project) async {
                    context.go(
                      '/editProject/${project.id}',
                    );
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
