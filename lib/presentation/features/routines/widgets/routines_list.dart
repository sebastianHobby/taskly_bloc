import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/routines/model/routine_list_item.dart';
import 'package:taskly_bloc/presentation/features/routines/model/routine_sort_order.dart';
import 'package:taskly_bloc/presentation/features/routines/selection/routine_selection_bloc.dart';
import 'package:taskly_bloc/presentation/features/routines/selection/routine_selection_models.dart';
import 'package:taskly_bloc/presentation/shared/ui/routine_tile_model_mapper.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/time.dart';
import 'package:taskly_ui/taskly_ui_feed.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class RoutinesListView extends StatelessWidget {
  const RoutinesListView({
    required this.items,
    required this.sortOrder,
    required this.onEditRoutine,
    required this.onLogRoutine,
    super.key,
  });

  final List<RoutineListItem> items;
  final RoutineSortOrder sortOrder;
  final ValueChanged<String> onEditRoutine;
  final ValueChanged<String> onLogRoutine;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final selection = context.read<RoutineSelectionBloc>();

    final List<RoutineListItem> visibleItems;
    final List<TasklySectionSpec> sections;

    if (sortOrder == RoutineSortOrder.scheduledFirst) {
      final split = _splitScheduled(items);
      visibleItems = [...split.scheduled, ...split.flexible];
      sections = _buildScheduledSections(
        context,
        scheduled: split.scheduled,
        flexible: split.flexible,
        onEditRoutine: onEditRoutine,
        onLogRoutine: onLogRoutine,
        selection: selection,
      );
    } else {
      final sorted = _sortItems(items, sortOrder);
      visibleItems = sorted;
      sections = _buildFlatSection(
        context,
        sorted,
        onEditRoutine: onEditRoutine,
        onLogRoutine: onLogRoutine,
        selection: selection,
      );
    }

    selection.updateVisibleEntities(
      visibleItems
          .map(
            (item) => RoutineSelectionMeta(
              key: RoutineSelectionKey(item.routine.id),
              displayName: item.routine.name,
              completedToday: _completedToday(item),
              isActive: item.routine.isActive,
            ),
          )
          .toList(growable: false),
    );

    return TasklyFeedRenderer(
      spec: TasklyFeedSpec.content(
        sections: sections,
      ),
      entityRowPadding: EdgeInsets.symmetric(
        horizontal: tokens.sectionPaddingH,
      ),
    );
  }
}

({List<RoutineListItem> scheduled, List<RoutineListItem> flexible})
_splitScheduled(List<RoutineListItem> items) {
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
  return (scheduled: scheduled, flexible: flexible);
}

List<TasklySectionSpec> _buildScheduledSections(
  BuildContext context, {
  required List<RoutineListItem> scheduled,
  required List<RoutineListItem> flexible,
  required ValueChanged<String> onEditRoutine,
  required ValueChanged<String> onLogRoutine,
  required RoutineSelectionBloc selection,
}) {
  return <TasklySectionSpec>[
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
            _buildRow(
              context,
              item,
              onEditRoutine: onEditRoutine,
              onLogRoutine: onLogRoutine,
              selection: selection,
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
            _buildRow(
              context,
              item,
              onEditRoutine: onEditRoutine,
              onLogRoutine: onLogRoutine,
              selection: selection,
            ),
        ],
      ),
  ];
}

List<TasklySectionSpec> _buildFlatSection(
  BuildContext context,
  List<RoutineListItem> items, {
  required ValueChanged<String> onEditRoutine,
  required ValueChanged<String> onLogRoutine,
  required RoutineSelectionBloc selection,
}) {
  if (items.isEmpty) return const <TasklySectionSpec>[];
  return [
    TasklySectionSpec.standardList(
      id: 'routines-all',
      rows: [
        TasklyRowSpec.header(
          key: 'routines-all-header',
          title: context.l10n.routinesTitle,
          trailingLabel: '${items.length}',
        ),
        for (final item in items)
          _buildRow(
            context,
            item,
            onEditRoutine: onEditRoutine,
            onLogRoutine: onLogRoutine,
            selection: selection,
          ),
      ],
    ),
  ];
}

TasklyRowSpec _buildRow(
  BuildContext context,
  RoutineListItem item, {
  required ValueChanged<String> onEditRoutine,
  required ValueChanged<String> onLogRoutine,
  required RoutineSelectionBloc selection,
}) {
  final key = RoutineSelectionKey(item.routine.id);
  final selectionMode = selection.isSelectionMode;
  final isSelected = selection.isSelected(key);

  void handleTap() {
    if (selection.shouldInterceptTapAsSelection()) {
      selection.handleEntityTap(key);
      return;
    }
    onEditRoutine(item.routine.id);
  }

  return TasklyRowSpec.routine(
    key: 'routine-${item.routine.id}',
    data: buildRoutineRowData(
      context,
      routine: item.routine,
      snapshot: item.snapshot,
      selected: isSelected,
      completed: _completedToday(item),
      showScheduleRow: item.routine.routineType == RoutineType.weeklyFixed,
      showProgress:
          item.routine.routineType == RoutineType.weeklyFlexible ||
          item.routine.routineType == RoutineType.monthlyFlexible,
      highlightCompleted: false,
      dayKeyUtc: item.dayKeyUtc,
      completionsInPeriod: item.completionsInPeriod,
      labels: selectionMode
          ? const TasklyRoutineRowLabels(primaryActionLabel: '')
          : buildRoutineExecutionLabels(
              context,
              completed: _completedToday(item),
            ),
    ),
    actions: TasklyRoutineRowActions(
      onTap: handleTap,
      onPrimaryAction: selectionMode
          ? null
          : () => onLogRoutine(item.routine.id),
      onLongPress: () => selection.enterSelectionMode(initialSelection: key),
      onToggleSelected: () =>
          selection.toggleSelection(key, extendRange: false),
    ),
  );
}

List<RoutineListItem> _sortItems(
  List<RoutineListItem> items,
  RoutineSortOrder sortOrder,
) {
  final sorted = items.toList(growable: false);
  int byName(RoutineListItem a, RoutineListItem b) {
    return a.routine.name.compareTo(b.routine.name);
  }

  int byMostRecent(RoutineListItem a, RoutineListItem b) {
    return b.routine.updatedAt.compareTo(a.routine.updatedAt);
  }

  int byPriority(RoutineListItem a, RoutineListItem b) {
    final aPriority = a.routine.value?.priority.weight ?? 0;
    final bPriority = b.routine.value?.priority.weight ?? 0;
    final byPriority = bPriority.compareTo(aPriority);
    if (byPriority != 0) return byPriority;
    return byName(a, b);
  }

  sorted.sort(
    switch (sortOrder) {
      RoutineSortOrder.scheduledFirst => byName,
      RoutineSortOrder.alphabetical => byName,
      RoutineSortOrder.priority => byPriority,
      RoutineSortOrder.mostRecent => byMostRecent,
    },
  );

  return sorted;
}

bool _completedToday(RoutineListItem item) {
  final today = dateOnly(item.dayKeyUtc);
  return item.completionsInPeriod.any(
    (completion) =>
        completion.routineId == item.routine.id &&
        dateOnly(completion.completedAtUtc).isAtSameMomentAs(today),
  );
}
