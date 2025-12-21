import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/utils/friendly_error_message.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/value_repository_contract.dart';
import 'package:taskly_bloc/features/projects/bloc/project_list_bloc.dart';
import 'package:taskly_bloc/features/projects/widgets/project_add_fab.dart';
import 'package:taskly_bloc/features/projects/widgets/projects_list.dart';

class ProjectOverviewPage extends StatelessWidget {
  const ProjectOverviewPage({
    required this.projectRepository,
    required this.valueRepository,
    required this.labelRepository,
    super.key,
  });

  final ProjectRepositoryContract projectRepository;
  final ValueRepositoryContract valueRepository;
  final LabelRepositoryContract labelRepository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ProjectOverviewBloc(projectRepository: projectRepository)
            ..add(const ProjectOverviewEvent.projectsSubscriptionRequested()),
      child: ProjectOverviewView(
        projectRepository: projectRepository,
        valueRepository: valueRepository,
        labelRepository: labelRepository,
      ),
    );
  }
}

class ProjectOverviewView extends StatelessWidget {
  const ProjectOverviewView({
    required this.projectRepository,
    required this.valueRepository,
    required this.labelRepository,
    super.key,
  });

  final ProjectRepositoryContract projectRepository;
  final ValueRepositoryContract valueRepository;
  final LabelRepositoryContract labelRepository;

  @override
  Widget build(BuildContext context) {
    // Send event to request data stream subscription
    return BlocBuilder<ProjectOverviewBloc, ProjectOverviewState>(
      builder: (context, state) {
        switch (state) {
          case ProjectOverviewInitial():
            return const Center(child: CircularProgressIndicator());

          case ProjectOverviewLoading():
            return const Center(child: CircularProgressIndicator());

          case ProjectOverviewLoaded(projects: final projects):
            if (projects.isEmpty) {
              return Center(child: Text(context.l10n.noProjectsFound));
            } else {
              return Scaffold(
                appBar: AppBar(title: Text(context.l10n.projectsTitle)),
                body: ProjectsListView(
                  projects: projects,
                  projectRepository: projectRepository,
                  valueRepository: valueRepository,
                  labelRepository: labelRepository,
                ),
                floatingActionButton: AddProjectFab(
                  projectRepository: projectRepository,
                  valueRepository: valueRepository,
                  labelRepository: labelRepository,
                ),
              );
            }

          case ProjectOverviewError(
            error: final error,
          ):
            return Center(
              child: Text(
                friendlyErrorMessageForUi(error, context.l10n),
              ),
            );
        }
      },
    );
  }
}
