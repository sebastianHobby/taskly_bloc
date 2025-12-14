import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/data/dtos/projects/project_dto.dart';
import 'package:taskly_bloc/features/projects/bloc/project_detail_bloc.dart';
import 'package:taskly_bloc/features/projects/models/project_models.dart';

class ProjectItem extends StatelessWidget {
  const ProjectItem({
    required this.project,
    super.key,
  });

  final ProjectDto project;
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
          final ProjectActionRequestUpdate updateRequest =
              ProjectActionRequestUpdate(
                name: project.name,
                completed: completed,
                description: project.description,
                projectToUpdate: project,
              );
          // Create event to update project with new completed status
          context.read<ProjectDetailBloc>().add(
            ProjectDetailEvent.updateProject(updateRequest: updateRequest),
          );
        },
      ),
    );
  }
}
