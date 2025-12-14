import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/data/dtos/projects/project_dto.dart';
import 'package:taskly_bloc/features/projects/projects.dart';

class ProjectListTile extends StatelessWidget {
  const ProjectListTile({
    required this.projectDto,
    super.key,
    this.onTap, // added callback
  });

  final ProjectDto projectDto;
  final VoidCallback? onTap; // added field

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(
        projectDto.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        projectDto.description!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      leading: Checkbox(
        shape: const ContinuousRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        value: projectDto.completed,
        onChanged: (bool? newValue) {
          // Create event to update project with new completed status
          context.read<ProjectListBloc>().add(
            ProjectListEvent.toggleProjectCompletion(projectDto: projectDto),
          );
        },
      ),
      //   trailing: onTap == null ? null : const Icon(Icons.chevron_right),
    );
  }
}
