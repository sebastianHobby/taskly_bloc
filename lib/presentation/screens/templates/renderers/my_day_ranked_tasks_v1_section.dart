import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/domain/core/model/task.dart';
import 'package:taskly_bloc/domain/core/model/value.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_item.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';
import 'package:taskly_bloc/domain/services/values/effective_values.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_ranked_tasks_v1_bloc.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_bloc/presentation/widgets/empty_state_widget.dart';
import 'package:taskly_bloc/presentation/widgets/values_footer.dart';
import 'package:taskly_bloc/presentation/entity_views/task_view.dart';

class MyDayRankedTasksV1Section extends StatefulWidget {
  const MyDayRankedTasksV1Section({
    required this.data,
    required this.title,
    required this.enrichment,
    required this.onTaskCheckboxChanged,
    super.key,
  });

  final List<ScreenItem> data;
  final String? title;
  final EnrichmentResultV2? enrichment;
  final void Function(Task task, bool? value)? onTaskCheckboxChanged;

  @override
  State<MyDayRankedTasksV1Section> createState() =>
      _MyDayRankedTasksV1SectionState();
}

class _MyDayRankedTasksV1SectionState extends State<MyDayRankedTasksV1Section> {
  String? _expandedTaskId;
  bool _mixExpanded = false;

  late final MyDayRankedTasksV1Bloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = MyDayRankedTasksV1Bloc(
      tasks: _tasks,
      enrichment: widget.enrichment,
      valueById: _valueById,
    );
  }

  @override
  void didUpdateWidget(covariant MyDayRankedTasksV1Section oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.data == widget.data &&
        oldWidget.enrichment == widget.enrichment) {
      return;
    }

    _bloc.updateInput(
      tasks: _tasks,
      enrichment: widget.enrichment,
      valueById: _valueById,
    );

    final expandedId = _expandedTaskId;
    if (expandedId != null && !_tasks.any((t) => t.id == expandedId)) {
      _expandedTaskId = null;
    }
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  List<Task> get _tasks {
    return widget.data
        .whereType<ScreenItemTask>()
        .map((i) => i.task)
        .whereType<Task>()
        .toList(growable: false);
  }

  Map<String, Value> get _valueById {
    final map = <String, Value>{};

    for (final item in widget.data) {
      if (item case ScreenItemValue(:final value)) {
        map[value.id] = value;
      }
    }

    for (final task in _tasks) {
      for (final value in task.effectiveValues) {
        map[value.id] = value;
      }
    }

    return map;
  }

  List<_RankedTask> _rankedTasks() {
    final rankByTaskId =
        widget.enrichment?.allocationRankByTaskId ?? const <String, int>{};

    final ranked = <_RankedTask>[];
    for (final task in _tasks) {
      final rank = rankByTaskId[task.id];
      ranked.add(_RankedTask(task: task, rank: rank));
    }

    ranked.sort(
      (a, b) {
        final ar = a.rank;
        final br = b.rank;

        if (ar != null && br != null) {
          final byRank = ar.compareTo(br);
          if (byRank != 0) return byRank;
        } else if (ar != null) {
          return -1;
        } else if (br != null) {
          return 1;
        }

        final byName = a.task.name.toLowerCase().compareTo(
          b.task.name.toLowerCase(),
        );
        if (byName != 0) return byName;
        return a.task.id.compareTo(b.task.id);
      },
    );

    return ranked;
  }

  Widget _buildMixRow(BuildContext context, MyDayMixVm mix) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (mix.totalTasks == 0) return const SizedBox.shrink();

    Widget dot(Color c, {required String semanticsLabel}) {
      return Semantics(
        label: semanticsLabel,
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: c,
            shape: BoxShape.circle,
          ),
        ),
      );
    }

    Color resolveDotColor(String? hex) {
      return ColorUtils.fromHex(hex, fallback: Colors.grey);
    }

    final summary = <InlineSpan>[];

    for (var i = 0; i < mix.summarySegments.length; i++) {
      final seg = mix.summarySegments[i];
      if (i > 0) {
        summary.add(
          TextSpan(
            text: '  •  ',
            style: theme.textTheme.labelMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        );
      }

      summary.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: dot(
              resolveDotColor(seg.dotColorHex),
              semanticsLabel: 'Aligned to ${seg.label}',
            ),
          ),
        ),
      );
      summary.add(
        TextSpan(
          text: '${seg.label} (${seg.percent}%)',
          style: theme.textTheme.labelMedium?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (mix.remainingCount > 0) {
      if (summary.isNotEmpty) {
        summary.add(
          TextSpan(
            text: '  •  ',
            style: theme.textTheme.labelMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        );
      }
      summary.add(
        TextSpan(
          text: '+${mix.remainingCount}',
          style: theme.textTheme.labelMedium?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Semantics(
      button: true,
      label: "Today's mix",
      value: _mixExpanded ? 'Expanded' : 'Collapsed',
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: cs.surfaceContainerLowest,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _mixExpanded = !_mixExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                          children: [
                            const TextSpan(text: "Today's mix: "),
                            ...summary,
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      _mixExpanded ? Icons.expand_less : Icons.expand_more,
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),
                if (_mixExpanded) ...[
                  const SizedBox(height: 10),
                  for (final row in mix.expandedRows) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          dot(
                            resolveDotColor(row.dotColorHex),
                            semanticsLabel: 'Aligned to ${row.label}',
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              row.label,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '${row.percent}%',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ranked = _rankedTasks();

    return BlocProvider.value(
      value: _bloc,
      child: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 8),
                child:
                    BlocBuilder<
                      MyDayRankedTasksV1Bloc,
                      MyDayRankedTasksV1State
                    >(
                      builder: (context, state) {
                        return _buildMixRow(context, state.mix);
                      },
                    ),
              );
            }

            if (ranked.isEmpty && index == 1) {
              return EmptyStateWidget.noTasks(
                title: "You're all set for today",
                description: 'Add a task to shape your day.',
                actionLabel: 'Add a task',
                onAction: () => Routing.toTaskNew(context),
              );
            }

            final taskIndex = index - 1;
            if (taskIndex < 0 || taskIndex >= ranked.length) {
              return const SizedBox.shrink();
            }

            final rankedTask = ranked[taskIndex];
            final task = rankedTask.task;

            final isExpanded = _expandedTaskId == task.id;
            final rankLabel = rankedTask.rank != null
                ? '${rankedTask.rank}'
                : '${taskIndex + 1}';

            final titlePrefix = SizedBox(
              width: 28,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  rankLabel,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TaskView(
                  task: task,
                  compact: true,
                  isInFocus: true,
                  titlePrefix: titlePrefix,
                  onCheckboxChanged: (t, val) {
                    widget.onTaskCheckboxChanged?.call(t, val);
                  },
                  onTap: (_) {
                    setState(() {
                      _expandedTaskId = _expandedTaskId == task.id
                          ? null
                          : task.id;
                    });
                  },
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.fromLTRB(56, 0, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (task.description != null &&
                            task.description!.trim().isNotEmpty) ...[
                          Text(
                            task.description!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 10),
                        ],
                        ValuesFooter(
                          primaryValue: task.primaryValue,
                          secondaryValues: task.secondaryValues,
                        ),
                      ],
                    ),
                  ),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 180),
                ),
              ],
            );
          },
          childCount: 1 + (ranked.isEmpty ? 1 : ranked.length),
        ),
      ),
    );
  }
}

final class _RankedTask {
  const _RankedTask({required this.task, required this.rank});

  final Task task;
  final int? rank;
}
