import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_item.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';
import 'package:taskly_bloc/presentation/screens/tiles/screen_item_tile_registry.dart';
import 'package:taskly_bloc/presentation/widgets/sliver_separated_list.dart';
import 'package:taskly_bloc/presentation/widgets/taskly/widgets.dart';

class TaskListRendererV2 extends StatelessWidget {
  const TaskListRendererV2({
    required this.data,
    required this.params,
    super.key,
    this.title,
    this.compactTiles = false,
    this.onTaskToggle,
  });

  final DataV2SectionResult data;
  final ListSectionParamsV2 params;
  final String? title;
  final bool compactTiles;
  final void Function(String, bool?)? onTaskToggle;

  @override
  Widget build(BuildContext context) {
    const registry = ScreenItemTileRegistry();
    final tasks = data.items.whereType<ScreenItemTask>().toList(
      growable: false,
    );

    final showAgendaTagPills = params.enrichment.items.any(
      (i) => i.maybeWhen(agendaTags: (_) => true, orElse: () => false),
    );

    if (tasks.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final header = title == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TasklyHeader(title: title!),
          );

    return params.layout.when(
      flatList: (separator) {
        return SliverSeparatedList(
          header: header,
          itemCount: tasks.length,
          separatorBuilder: (context, index) => _separatorFor(
            separator: separator,
            current: tasks[index],
            next: tasks[index + 1],
          ),
          itemBuilder: (context, index) {
            final item = tasks[index];
            final prefix = _titlePrefixForTask(
              item,
              showAgendaTagPills: showAgendaTagPills,
            );

            return registry.build(
              context,
              item: item,
              onTaskToggle: onTaskToggle,
              compactTiles: compactTiles,
              titlePrefix: prefix,
            );
          },
        );
      },
      hierarchyValueProjectTask: (_, __, ___) {
        // This renderer only receives tasks; hierarchy is implemented in the
        // interleaved renderer where values/projects are available.
        return SliverSeparatedList(
          header: header,
          itemCount: tasks.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = tasks[index];
            final prefix = _titlePrefixForTask(
              item,
              showAgendaTagPills: showAgendaTagPills,
            );
            return registry.build(
              context,
              item: item,
              onTaskToggle: onTaskToggle,
              compactTiles: compactTiles,
              titlePrefix: prefix,
            );
          },
        );
      },
    );
  }

  Widget? _titlePrefixForTask(
    ScreenItemTask item, {
    required bool showAgendaTagPills,
  }) {
    if (!showAgendaTagPills) return null;
    final tag = data.enrichment?.agendaTagByTaskId[item.task.id];
    if (tag == null) return null;

    final label = switch (tag) {
      AgendaTagV2.starts => 'Starts',
      AgendaTagV2.due => 'Due',
      AgendaTagV2.inProgress => 'In progress',
    };

    return _TagPill(label: label);
  }
}

Widget _separatorFor({
  required ListSeparatorV2 separator,
  required ScreenItem current,
  required ScreenItem next,
}) {
  return switch (separator) {
    ListSeparatorV2.divider => const Divider(height: 1),
    ListSeparatorV2.spaced8 => const SizedBox(height: 8),
    ListSeparatorV2.interleavedAuto =>
      current is ScreenItemTask && next is ScreenItemTask
          ? const Divider(height: 1)
          : const SizedBox(height: 8),
  };
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
