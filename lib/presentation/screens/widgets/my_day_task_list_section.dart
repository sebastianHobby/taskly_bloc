import 'package:flutter/material.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_bloc/presentation/entity_views/task_view.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_bloc.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_bloc/presentation/widgets/values_footer.dart';
import 'package:taskly_ui/taskly_ui.dart';

class MyDayTaskListSection extends StatefulWidget {
  const MyDayTaskListSection({
    required this.tasks,
    required this.mix,
    super.key,
  });

  final List<Task> tasks;
  final MyDayMixVm mix;

  @override
  State<MyDayTaskListSection> createState() => _MyDayTaskListSectionState();
}

class _MyDayTaskListSectionState extends State<MyDayTaskListSection> {
  String? _expandedTaskId;
  bool _mixExpanded = false;

  @override
  void didUpdateWidget(covariant MyDayTaskListSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    final expandedId = _expandedTaskId;
    if (expandedId != null && !widget.tasks.any((t) => t.id == expandedId)) {
      _expandedTaskId = null;
    }
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
    final tasks = widget.tasks;

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 8),
              child: _buildMixRow(context, widget.mix),
            );
          }

          if (tasks.isEmpty && index == 1) {
            return EmptyStateWidget.noTasks(
              title: "You're all set for today",
              description: 'Add a task to shape your day.',
              actionLabel: 'Add a task',
              onAction: () => EditorLauncher.fromGetIt().openTaskEditor(
                context,
                taskId: null,
                defaultProjectId: null,
                defaultValueIds: null,
                showDragHandle: true,
              ),
            );
          }

          final taskIndex = index - 1;
          if (taskIndex < 0 || taskIndex >= tasks.length) {
            return const SizedBox.shrink();
          }

          final task = tasks[taskIndex];

          final isExpanded = _expandedTaskId == task.id;
          final rankLabel = '${taskIndex + 1}';

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
                tileCapabilities: EntityTileCapabilitiesResolver.forTask(task),
                isInFocus: true,
                titlePrefix: titlePrefix,
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
                        primaryValue: task.effectivePrimaryValue,
                        secondaryValues: task.effectiveSecondaryValues,
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
        childCount: 1 + (tasks.isEmpty ? 1 : tasks.length),
      ),
    );
  }
}
