import 'package:flutter/material.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';

/// A single list tile representing a ProjectTableData.
class ProjectListTile extends StatelessWidget {
  const ProjectListTile({
    required this.project,
    required this.onCheckboxChanged,
    required this.onTap,
    super.key,
  });

  final ProjectTableData project;
  final void Function(ProjectTableData, bool?) onCheckboxChanged;
  final void Function(ProjectTableData) onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => onTap(project),
      title: Text(
        project.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: (project.description == null || project.description!.isEmpty)
          ? null
          : Text(
              project.description!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      leading: Checkbox(
        shape: const ContinuousRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        value: project.completed,
        onChanged: (value) => onCheckboxChanged(project, value),
      ),
    );
  }
}
