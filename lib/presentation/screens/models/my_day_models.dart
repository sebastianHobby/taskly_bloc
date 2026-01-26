import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/my_day.dart' as my_day;
import 'package:taskly_domain/my_day.dart' show MyDayRitualStatus;
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/services.dart';

enum MyDayPlannedItemType { task, routine }

final class MyDayPlannedItem {
  MyDayPlannedItem.task({
    required Task this.task,
    required this.bucket,
    required this.sortIndex,
    required this.qualifyingValueId,
  }) : type = MyDayPlannedItemType.task,
       id = task.id,
       routine = null,
       routineSnapshot = null,
       completed = task.occurrence?.isCompleted ?? task.completed,
       isCatchUpDay = false;

  MyDayPlannedItem.routine({
    required Routine this.routine,
    required RoutineCadenceSnapshot this.routineSnapshot,
    required this.bucket,
    required this.sortIndex,
    required this.qualifyingValueId,
    required this.completed,
    required this.isCatchUpDay,
  }) : type = MyDayPlannedItemType.routine,
       id = routine.id,
       task = null;

  final MyDayPlannedItemType type;
  final String id;
  final my_day.MyDayPickBucket bucket;
  final int sortIndex;
  final String? qualifyingValueId;
  final Task? task;
  final Routine? routine;
  final RoutineCadenceSnapshot? routineSnapshot;
  final bool completed;
  final bool isCatchUpDay;

  String? get valueId {
    final fromPick = qualifyingValueId;
    if (fromPick != null && fromPick.isNotEmpty) return fromPick;
    return task?.effectivePrimaryValueId ?? routine?.valueId;
  }
}

final class MyDaySummary {
  const MyDaySummary({required this.doneCount, required this.totalCount});

  final int doneCount;
  final int totalCount;
}

final class MyDayViewModel {
  const MyDayViewModel({
    required this.tasks,
    required this.plannedItems,
    required this.ritualStatus,
    required this.summary,
    required this.mix,
    required this.pinnedTasks,
    required this.completedPicks,
    required this.selectedTotalCount,
    required this.todaySelectedTaskIds,
    required this.todaySelectedRoutineIds,
  });

  final List<Task> tasks;
  final List<MyDayPlannedItem> plannedItems;
  final MyDayRitualStatus ritualStatus;
  final MyDaySummary summary;
  final MyDayMixVm mix;

  final List<Task> pinnedTasks;
  final List<Task> completedPicks;

  final int selectedTotalCount;

  final Set<String> todaySelectedTaskIds;
  final Set<String> todaySelectedRoutineIds;
}

final class MyDayMixVm {
  const MyDayMixVm({
    required this.summarySegments,
    required this.remainingCount,
    required this.expandedRows,
    required this.totalTasks,
  });

  factory MyDayMixVm.from({
    required List<Task> tasks,
    required Map<String, String?> qualifyingByTaskId,
    required Map<String, Value> valueById,
  }) {
    if (tasks.isEmpty) return empty;

    final counts = <String?, int>{};

    for (final task in tasks) {
      String? valueId = qualifyingByTaskId[task.id];
      valueId ??= task.effectivePrimaryValueId;
      valueId ??= task.effectiveValues.isNotEmpty
          ? task.effectiveValues.first.id
          : null;

      counts.update(valueId, (v) => v + 1, ifAbsent: () => 1);
    }

    final rows =
        counts.entries
            .map(
              (e) {
                final valueId = e.key;
                final count = e.value;
                final percent = ((count / tasks.length) * 100).round();

                if (valueId == null) {
                  return MyDayMixRowVm(
                    valueId: null,
                    label: 'Unaligned',
                    dotColorHex: null,
                    count: count,
                    percent: percent,
                  );
                }

                final value = valueById[valueId];
                return MyDayMixRowVm(
                  valueId: valueId,
                  label: value?.name ?? 'Unknown value',
                  dotColorHex: value?.color,
                  count: count,
                  percent: percent,
                );
              },
            )
            .toList(growable: false)
          ..sort(
            (a, b) {
              final byCount = b.count.compareTo(a.count);
              if (byCount != 0) return byCount;

              int priorityWeightFor(MyDayMixRowVm row) {
                final valueId = row.valueId;
                if (valueId == null) return -1;
                return valueById[valueId]?.priority.weight ?? 0;
              }

              final byPriority = priorityWeightFor(b).compareTo(
                priorityWeightFor(a),
              );
              if (byPriority != 0) return byPriority;

              return a.label.toLowerCase().compareTo(b.label.toLowerCase());
            },
          );

    final summary = rows
        .take(2)
        .map(
          (r) => MyDayMixSegmentVm(
            label: r.label,
            dotColorHex: r.dotColorHex,
            percent: r.percent,
          ),
        )
        .toList(growable: false);

    final remaining = (rows.length - summary.length).clamp(0, 999);
    final expanded = rows.take(3).toList(growable: false);

    return MyDayMixVm(
      summarySegments: summary,
      remainingCount: remaining,
      expandedRows: expanded,
      totalTasks: tasks.length,
    );
  }

  final List<MyDayMixSegmentVm> summarySegments;
  final int remainingCount;
  final List<MyDayMixRowVm> expandedRows;
  final int totalTasks;

  static const empty = MyDayMixVm(
    summarySegments: <MyDayMixSegmentVm>[],
    remainingCount: 0,
    expandedRows: <MyDayMixRowVm>[],
    totalTasks: 0,
  );
}

final class MyDayMixSegmentVm {
  const MyDayMixSegmentVm({
    required this.label,
    required this.dotColorHex,
    required this.percent,
  });

  final String label;
  final String? dotColorHex;
  final int percent;
}

final class MyDayMixRowVm {
  const MyDayMixRowVm({
    required this.valueId,
    required this.label,
    required this.dotColorHex,
    required this.count,
    required this.percent,
  });

  final String? valueId;
  final String label;
  final String? dotColorHex;
  final int count;
  final int percent;
}
