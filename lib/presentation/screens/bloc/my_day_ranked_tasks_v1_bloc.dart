import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';

final class MyDayRankedTasksV1Bloc extends Cubit<MyDayRankedTasksV1State> {
  MyDayRankedTasksV1Bloc({
    required List<Task> tasks,
    required EnrichmentResultV2? enrichment,
    required Map<String, Value> valueById,
  }) : super(
         MyDayRankedTasksV1State(
           mix: MyDayMixVm.from(
             tasks: tasks,
             enrichment: enrichment,
             valueById: valueById,
           ),
         ),
       );

  void updateInput({
    required List<Task> tasks,
    required EnrichmentResultV2? enrichment,
    required Map<String, Value> valueById,
  }) {
    emit(
      MyDayRankedTasksV1State(
        mix: MyDayMixVm.from(
          tasks: tasks,
          enrichment: enrichment,
          valueById: valueById,
        ),
      ),
    );
  }
}

@immutable
final class MyDayRankedTasksV1State {
  const MyDayRankedTasksV1State({required this.mix});

  final MyDayMixVm mix;
}

@immutable
final class MyDayMixVm {
  const MyDayMixVm({
    required this.summarySegments,
    required this.remainingCount,
    required this.expandedRows,
    required this.totalTasks,
  });

  factory MyDayMixVm.from({
    required List<Task> tasks,
    required EnrichmentResultV2? enrichment,
    required Map<String, Value> valueById,
  }) {
    if (tasks.isEmpty) return empty;

    final qualifyingValueIdByTaskId =
        enrichment?.qualifyingValueIdByTaskId ?? const <String, String>{};

    final counts = <String?, int>{};

    for (final task in tasks) {
      String? valueId = qualifyingValueIdByTaskId[task.id];
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

@immutable
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

@immutable
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
