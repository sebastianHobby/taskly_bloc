import 'package:flutter/material.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';

class ProjectItem extends StatelessWidget {
  const ProjectItem({
    required this.projectData,
    required this.onCheckboxChanged,
    super.key,
  });

  final ProjectTableData projectData;
  final VoidCallback onCheckboxChanged;
  @override
  Widget build(BuildContext context) {
    return ListTile(
      //    onTap: onTap,
      title: Text(
        projectData.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        projectData.description!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      leading: Checkbox(
        shape: const ContinuousRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        value: projectData.completed,
        onChanged: (_) => onCheckboxChanged(),
      ),
    );
  }
}
