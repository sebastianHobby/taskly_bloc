import 'package:flutter/widgets.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/presentation/entity_views/project_view.dart';

/// Legacy compatibility wrapper for project tiles.
///
/// Prefer using [ProjectView] directly.
class ProjectListTile extends StatelessWidget {
  const ProjectListTile({
    required this.project,
    this.onTap,
    super.key,
  });

  final Project project;
  final void Function(Project)? onTap;

  @override
  Widget build(BuildContext context) {
    return ProjectView(project: project, onTap: onTap);
  }
}
