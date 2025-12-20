import 'package:flutter/material.dart';

import 'package:taskly_bloc/core/domain/domain.dart';

/// A single list tile representing a domain `Project`.
class ProjectListTile extends StatelessWidget {
  const ProjectListTile({
    required this.project,
    required this.onCheckboxChanged,
    required this.onTap,
    super.key,
  });

  final Project project;
  final void Function(Project, bool?) onCheckboxChanged;
  final void Function(Project) onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => onTap(project),
      title: Text(
        project.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: (project.name.isEmpty) ? null : null,
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
