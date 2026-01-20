import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/entity_tiles/mappers/task_tile_mapper.dart';
import 'package:taskly_bloc/presentation/screens/tiles/tile_overflow_action_catalog.dart';
import 'package:taskly_bloc/presentation/screens/tiles/tile_overflow_menu.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_ui/taskly_ui_entities.dart';

class MyDayAcceptedBucketsSection extends StatefulWidget {
  const MyDayAcceptedBucketsSection({
    required this.acceptedDue,
    required this.acceptedStarts,
    required this.acceptedFocus,
    super.key,
  });

  final List<Task> acceptedDue;
  final List<Task> acceptedStarts;
  final List<Task> acceptedFocus;

  @override
  State<MyDayAcceptedBucketsSection> createState() =>
      _MyDayAcceptedBucketsSectionState();
}

class _MyDayAcceptedBucketsSectionState
    extends State<MyDayAcceptedBucketsSection> {
  bool _dueExpanded = false;
  bool _startsExpanded = false;
  bool _focusExpanded = true;

  @override
  Widget build(BuildContext context) {
    final hasAny =
        widget.acceptedDue.isNotEmpty ||
        widget.acceptedStarts.isNotEmpty ||
        widget.acceptedFocus.isNotEmpty;

    if (!hasAny) return const SizedBox.shrink();

    return Column(
      children: [
        if (widget.acceptedDue.isNotEmpty) ...[
          _BucketCard(
            title: 'Overdue & due',
            tasks: widget.acceptedDue,
            expanded: _dueExpanded,
            onToggleExpanded: () =>
                setState(() => _dueExpanded = !_dueExpanded),
          ),
          const SizedBox(height: 10),
        ],
        if (widget.acceptedStarts.isNotEmpty) ...[
          _BucketCard(
            title: 'Starts today',
            tasks: widget.acceptedStarts,
            expanded: _startsExpanded,
            onToggleExpanded: () =>
                setState(() => _startsExpanded = !_startsExpanded),
          ),
          const SizedBox(height: 10),
        ],
        if (widget.acceptedFocus.isNotEmpty) ...[
          _BucketCard(
            title: "Today's Focus",
            tasks: widget.acceptedFocus,
            expanded: _focusExpanded,
            onToggleExpanded: () =>
                setState(() => _focusExpanded = !_focusExpanded),
          ),
        ],
      ],
    );
  }
}

class _BucketCard extends StatelessWidget {
  const _BucketCard({
    required this.title,
    required this.tasks,
    required this.expanded,
    required this.onToggleExpanded,
  });

  static const _previewCount = 4;

  final String title;
  final List<Task> tasks;
  final bool expanded;
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final visible = expanded
        ? tasks
        : tasks.take(_previewCount).toList(growable: false);
    final remaining = tasks.length - visible.length;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: cs.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '$title · ${tasks.length}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            for (final task in visible) _AcceptedTaskTile(task: task),
            if (tasks.length > _previewCount)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: onToggleExpanded,
                    child: Text(
                      expanded
                          ? 'Show fewer'
                          : 'Show $remaining more (${tasks.length})',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AcceptedTaskTile extends StatelessWidget {
  const _AcceptedTaskTile({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final tileCapabilities = EntityTileCapabilitiesResolver.forTask(task);

    final overflowActions = TileOverflowActionCatalog.forTask(
      taskId: task.id,
      taskName: task.name,
      isPinnedToMyDay: task.isPinned,
      isRepeating: task.isRepeating,
      seriesEnded: task.seriesEnded,
      tileCapabilities: tileCapabilities,
    );

    final hasAnyEnabledAction = overflowActions.any((a) => a.enabled);

    final model = buildTaskListRowTileModel(
      context,
      task: task,
      tileCapabilities: tileCapabilities,
      showProjectLabel: true,
    );

    return TaskEntityTile(
      model: model,
      markers: TaskTileMarkers(pinned: task.isPinned),
      actions: TaskTileActions(
        onTap: model.onTap,
        onToggleCompletion: buildTaskToggleCompletionHandler(
          context,
          task: task,
          tileCapabilities: tileCapabilities,
        ),
        onOverflowMenuRequestedAt: hasAnyEnabledAction
            ? (pos) => showTileOverflowMenu(
                context,
                position: pos,
                entityTypeLabel: 'task',
                entityId: task.id,
                actions: overflowActions,
              )
            : null,
      ),
    );
  }
}
