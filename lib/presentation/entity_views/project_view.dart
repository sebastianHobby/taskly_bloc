import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/presentation/features/projects/widgets/project_list_tile.dart';

/// The canonical, entity-level project UI entrypoint.
///
/// This starts as a delegating wrapper and is migrated into the
/// `ProjectView` implementation in later phases.
class ProjectView extends StatelessWidget {
  const ProjectView({
    required this.project,
    this.onCheckboxChanged,
    this.onTap,
    this.compact = false,
    this.taskCount,
    this.completedTaskCount,
    this.nextTask,
    this.showNextTask = false,
    this.showPinnedIndicator = true,
    super.key,
  });

  final Project project;
  final bool compact;
  final void Function(Project)? onTap;
  final void Function(Project, bool?)? onCheckboxChanged;
  final int? taskCount;
  final int? completedTaskCount;
  final Task? nextTask;
  final bool showNextTask;
  final bool showPinnedIndicator;

  @override
  Widget build(BuildContext context) {
    return ProjectListTile(
      project: project,
      onCheckboxChanged: onCheckboxChanged,
      onTap: onTap,
      compact: compact,
      taskCount: taskCount,
      completedTaskCount: completedTaskCount,
      nextTask: nextTask,
      showNextTask: showNextTask,
      showPinnedIndicator: showPinnedIndicator,
    );
  }
}
