import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/routines/model/routine_list_item.dart';
import 'package:taskly_bloc/presentation/features/routines/model/routine_sort_order.dart';
import 'package:taskly_bloc/presentation/features/routines/selection/routine_selection_bloc.dart';
import 'package:taskly_bloc/presentation/features/routines/selection/routine_selection_models.dart';
import 'package:taskly_bloc/presentation/shared/utils/routine_completion_utils.dart';
import 'package:taskly_bloc/presentation/shared/ui/routine_tile_model_mapper.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_ui/taskly_ui_feed.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class RoutinesListView extends StatelessWidget {
  const RoutinesListView({
    required this.items,
    required this.sortOrder,
    required this.onEditRoutine,
    required this.onLogRoutine,
    this.embedded = false,
    this.showSectionHeaders = true,
    this.entityRowPadding,
    super.key,
  });

  final List<RoutineListItem> items;
  final RoutineSortOrder sortOrder;
  final ValueChanged<String> onEditRoutine;
  final ValueChanged<String> onLogRoutine;
  final bool embedded;
  final bool showSectionHeaders;
  final EdgeInsetsGeometry? entityRowPadding;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final selection = context.read<RoutineSelectionBloc>();

    final List<RoutineListItem> visibleItems;
    final List<TasklySectionSpec> sections;

    if (sortOrder == RoutineSortOrder.scheduledFirst) {
      final split = _splitScheduled(items);
      visibleItems = [...split.scheduled, ...split.flexible];
      if (showSectionHeaders) {
        sections = _buildScheduledSections(
          context,
          scheduled: split.scheduled,
          flexible: split.flexible,
          onEditRoutine: onEditRoutine,
          onLogRoutine: onLogRoutine,
          selection: selection,
        );
      } else {
        sections = _buildFlatRowsSection(
          context,
          visibleItems,
          onEditRoutine: onEditRoutine,
          onLogRoutine: onLogRoutine,
          selection: selection,
        );
      }
    } else {
      final sorted = _sortItems(items, sortOrder);
      visibleItems = sorted;
      sections = showSectionHeaders
          ? _buildFlatSection(
              context,
              sorted,
              onEditRoutine: onEditRoutine,
              onLogRoutine: onLogRoutine,
              selection: selection,
            )
          : _buildFlatRowsSection(
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
              completedToday: _isRoutineComplete(item),
              isActive: item.routine.isActive,
            ),
          )
          .toList(growable: false),
    );

    final rowPadding =
        entityRowPadding ??
        EdgeInsets.symmetric(
          horizontal: tokens.sectionPaddingH,
        );

    if (embedded) {
      return _EmbeddedRoutinesList(
        sections: sections,
        entityRowPadding: rowPadding,
      );
    }

    return TasklyFeedRenderer(
      spec: TasklyFeedSpec.content(
        sections: sections,
      ),
      entityRowPadding: rowPadding,
    );
  }
}

class _EmbeddedRoutinesList extends StatelessWidget {
  const _EmbeddedRoutinesList({
    required this.sections,
    required this.entityRowPadding,
  });

  final List<TasklySectionSpec> sections;
  final EdgeInsetsGeometry entityRowPadding;

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) return const SizedBox.shrink();

    final tokens = TasklyTokens.of(context);
    final children = <Widget>[];
    for (var i = 0; i < sections.length; i += 1) {
      final section = sections[i];
      children.add(
        TasklyFeedRenderer.buildSection(
          section,
          entityRowPadding: entityRowPadding,
        ),
      );
      final isLast = i == sections.length - 1;
      if (!isLast) {
        children.add(SizedBox(height: tokens.feedSectionSpacing));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

({List<RoutineListItem> scheduled, List<RoutineListItem> flexible})
_splitScheduled(List<RoutineListItem> items) {
  final scheduled = <RoutineListItem>[];
  final flexible = <RoutineListItem>[];

  for (final item in items) {
    if (item.routine.scheduleMode == RoutineScheduleMode.scheduled) {
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

List<TasklySectionSpec> _buildFlatRowsSection(
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
      completed: _isRoutineComplete(item),
      showScheduleRow:
          item.routine.periodType == RoutinePeriodType.week &&
          item.routine.scheduleMode == RoutineScheduleMode.scheduled,
      highlightCompleted: false,
      dayKeyUtc: item.dayKeyUtc,
      completionsInPeriod: item.completionsInPeriod,
      labels: selectionMode
          ? null
          : buildRoutineExecutionLabels(
              context,
              completed: _isRoutineComplete(item),
            ),
    ),
    style: selectionMode
        ? const TasklyRoutineRowStyle.bulkSelection()
        : const TasklyRoutineRowStyle.standard(),
    actions: TasklyRoutineRowActions(
      onTap: handleTap,
      onPrimaryAction: selectionMode
          ? null
          : () => onLogRoutine(item.routine.id),
      onLongPress: () => selection.enterSelectionMode(initialSelection: key),
      onToggleSelected: selectionMode
          ? () => selection.toggleSelection(key, extendRange: false)
          : null,
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
    final aValue = a.routine.value;
    final bValue = b.routine.value;
    if (aValue == null && bValue == null) return byName(a, b);
    if (aValue == null) return 1;
    if (bValue == null) return -1;

    final byPriority = bValue.priority.weight.compareTo(aValue.priority.weight);
    if (byPriority != 0) return byPriority;
    final byValueName = aValue.name.compareTo(bValue.name);
    if (byValueName != 0) return byValueName;
    return byName(a, b);
  }

  int byValueName(RoutineListItem a, RoutineListItem b) {
    final aValue = a.routine.value;
    final bValue = b.routine.value;
    if (aValue == null && bValue == null) return byName(a, b);
    if (aValue == null) return 1;
    if (bValue == null) return -1;

    final byValueName = aValue.name.compareTo(bValue.name);
    if (byValueName != 0) return byValueName;
    final byPriority = bValue.priority.weight.compareTo(aValue.priority.weight);
    if (byPriority != 0) return byPriority;
    return byName(a, b);
  }

  sorted.sort(
    switch (sortOrder) {
      RoutineSortOrder.scheduledFirst => byName,
      RoutineSortOrder.alphabetical => byName,
      RoutineSortOrder.priority => byPriority,
      RoutineSortOrder.valueName => byValueName,
      RoutineSortOrder.mostRecent => byMostRecent,
    },
  );

  return sorted;
}

bool _isRoutineComplete(RoutineListItem item) {
  return isRoutineCompleteForDay(
    routine: item.routine,
    snapshot: item.snapshot,
    dayKeyUtc: item.dayKeyUtc,
    completionsInPeriod: item.completionsInPeriod,
  );
}
