import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/features/routines/model/routine_list_item.dart';
import 'package:taskly_bloc/presentation/shared/ui/routine_tile_model_mapper.dart';
import 'package:taskly_ui/taskly_ui_feed.dart';

class RoutinesListView extends StatelessWidget {
  const RoutinesListView({
    required this.items,
    required this.onEditRoutine,
    super.key,
  });

  final List<RoutineListItem> items;
  final ValueChanged<String> onEditRoutine;

  @override
  Widget build(BuildContext context) {
    final rows = [
      for (final item in items)
        TasklyRowSpec.routine(
          key: 'routine-${item.routine.id}',
          data: buildRoutineRowData(
            context,
            routine: item.routine,
            snapshot: item.snapshot,
            labels: buildRoutineListLabels(context),
          ),
          actions: TasklyRoutineRowActions(
            onTap: () => onEditRoutine(item.routine.id),
            onEdit: () => onEditRoutine(item.routine.id),
          ),
        ),
    ];

    return TasklyFeedRenderer(
      spec: TasklyFeedSpec.content(
        sections: [
          TasklySectionSpec.standardList(id: 'routines', rows: rows),
        ],
      ),
    );
  }
}
