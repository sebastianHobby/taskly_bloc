import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/data/models/projects/project_model.dart';
import 'package:taskly_bloc/features/projects/bloc/projects_bloc.dart';

class ProjectListTile extends StatelessWidget {
  const ProjectListTile({
    required this.project,
    super.key,
  });

  final ProjectModel project;
  //  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    // final captionColor = theme.textTheme.bodySmall?.color;
    bool completed = project.completed;
    return ListTile(
      //    onTap: onTap,
      title: Text(
        project.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        project.description!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      leading: Checkbox(
        shape: const ContinuousRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        value: completed,
        onChanged: (bool? newValue) {
          completed = newValue ?? false;
          final updatedProject = project.copyWith(completed: completed);
          // Create event to update project with new completed status
          context.read<ProjectsBloc>().add(
            ProjectsEvent.updateProject(
              initialProject: project,
              updatedProject: updatedProject,
            ),
          );
        },
      ),
      //   trailing: onTap == null ? null : const Icon(Icons.chevron_right),
    );
  }
}
