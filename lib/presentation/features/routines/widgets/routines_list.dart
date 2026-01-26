import 'package:flutter/material.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/routines/model/routine_list_item.dart';
import 'package:taskly_bloc/presentation/shared/ui/routine_tile_model_mapper.dart';
import 'package:taskly_domain/routines.dart';
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
    final scheduled = <RoutineListItem>[];
    final flexible = <RoutineListItem>[];

    for (final item in items) {
      if (item.routine.routineType == RoutineType.weeklyFixed) {
        scheduled.add(item);
      } else {
        flexible.add(item);
      }
    }

    int byName(RoutineListItem a, RoutineListItem b) {
      return a.routine.name.compareTo(b.routine.name);
    }

    scheduled.sort(byName);
    flexible.sort(byName);

    final sections = <TasklySectionSpec>[
      if (scheduled.isNotEmpty)
        TasklySectionSpec.standardList(
          id: 'routines-scheduled',
          rows: [
            TasklyRowSpec.header(
              key: 'routines-scheduled-header',
              title: context.l10n.routinePanelScheduledTitle,
              trailingLabel: '${scheduled.length}',
            ),
            for (final item in scheduled)
              TasklyRowSpec.routine(
                key: 'routine-${item.routine.id}',
                data: buildRoutineRowData(
                  context,
                  routine: item.routine,
                  snapshot: item.snapshot,
                  isCatchUpDay: item.isCatchUpDay,
                  labels: buildRoutineListLabels(context),
                ),
                actions: TasklyRoutineRowActions(
                  onTap: () => onEditRoutine(item.routine.id),
                  onEdit: () => onEditRoutine(item.routine.id),
                ),
              ),
          ],
        ),
      if (flexible.isNotEmpty)
        TasklySectionSpec.standardList(
          id: 'routines-flexible',
          rows: [
            TasklyRowSpec.header(
              key: 'routines-flexible-header',
              title: context.l10n.routinePanelFlexibleTitle,
              trailingLabel: '${flexible.length}',
            ),
            for (final item in flexible)
              TasklyRowSpec.routine(
                key: 'routine-${item.routine.id}',
                data: buildRoutineRowData(
                  context,
                  routine: item.routine,
                  snapshot: item.snapshot,
                  isCatchUpDay: item.isCatchUpDay,
                  labels: buildRoutineListLabels(context),
                ),
                actions: TasklyRoutineRowActions(
                  onTap: () => onEditRoutine(item.routine.id),
                  onEdit: () => onEditRoutine(item.routine.id),
                ),
              ),
          ],
        ),
    ];

    return TasklyFeedRenderer(
      spec: TasklyFeedSpec.content(
        sections: sections,
      ),
    );
  }
}
