import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_item.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/presentation/screens/tiles/screen_item_tile_registry.dart';
import 'package:taskly_bloc/presentation/widgets/taskly/widgets.dart';

/// Renderer for project list sections.
///
/// Displays a list of projects with task count and completion statistics
/// derived from related tasks if available.
class ProjectListRenderer extends StatelessWidget {
  const ProjectListRenderer({
    required this.data,
    super.key,
    this.title,
    this.compactTiles = false,
  });

  final DataSectionResult data;
  final String? title;
  final bool compactTiles;

  @override
  Widget build(BuildContext context) {
    const registry = ScreenItemTileRegistry();
    final projects = data.items.whereType<ScreenItemProject>().toList();
    final relatedTasks = data.relatedTasks;

    if (projects.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TasklyHeader(title: title!),
          ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: projects.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = projects[index];
            final project = item.project;

            // Calculate task stats from relatedTasks
            final projectTasks = relatedTasks
                .where((t) => t.projectId == project.id)
                .toList();
            final taskCount = projectTasks.length;
            final completedTaskCount = projectTasks
                .where((t) => t.completed)
                .length;

            return registry.build(
              context,
              item: item,
              projectStats: ProjectTileStats(
                taskCount: taskCount,
                completedTaskCount: completedTaskCount,
              ),
              compactTiles: compactTiles,
            );
          },
        ),
      ],
    );
  }
}
