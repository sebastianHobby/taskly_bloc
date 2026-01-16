import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_definition.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_preference.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_manage_trackers_cubit.dart';

final class JournalManageTrackersSectionRendererV1 extends StatelessWidget {
  const JournalManageTrackersSectionRendererV1({
    required this.definitions,
    required this.preferenceByTrackerId,
    super.key,
  });

  final List<TrackerDefinition> definitions;
  final Map<String, TrackerPreference> preferenceByTrackerId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<JournalManageTrackersCubit>(
      create: (_) => getIt<JournalManageTrackersCubit>(),
      child:
          BlocListener<JournalManageTrackersCubit, JournalManageTrackersState>(
            listenWhen: (prev, next) =>
                prev.status.runtimeType != next.status.runtimeType,
            listener: (context, state) {
              if (state.status case JournalManageTrackersError(
                :final message,
              )) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Builder(
              builder: (context) {
                final userDefinitions =
                    definitions
                        .where((d) => d.deletedAt == null)
                        .where((d) => d.systemKey == null)
                        .toList(growable: false)
                      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

                final active = userDefinitions
                    .where((d) => d.isActive)
                    .toList(growable: false);
                final archived = userDefinitions
                    .where((d) => !d.isActive)
                    .toList(growable: false);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Trackers',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        BlocBuilder<
                          JournalManageTrackersCubit,
                          JournalManageTrackersState
                        >(
                          builder: (context, state) {
                            final busy =
                                state.status is JournalManageTrackersSaving;
                            return FilledButton.icon(
                              onPressed: busy
                                  ? null
                                  : () async {
                                      final cubit = context
                                          .read<JournalManageTrackersCubit>();
                                      final name =
                                          await _showCreateTrackerDialog(
                                            context,
                                          );
                                      if (!context.mounted) return;
                                      if (name == null || name.trim().isEmpty) {
                                        return;
                                      }
                                      final maxSort = userDefinitions.isEmpty
                                          ? 90
                                          : userDefinitions
                                                .map((d) => d.sortOrder)
                                                .reduce(
                                                  (a, b) => a > b ? a : b,
                                                );

                                      await cubit.createTracker(
                                        name: name,
                                        sortOrder: maxSort + 10,
                                      );
                                    },
                              icon: const Icon(Icons.add),
                              label: const Text('Add'),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (active.isEmpty && archived.isEmpty)
                      const Text('No trackers yet.'),
                    if (active.isNotEmpty) ...[
                      Text(
                        'Active',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ReorderableListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        buildDefaultDragHandles: false,
                        onReorder: (oldIndex, newIndex) async {
                          final list = [...active];
                          if (newIndex > oldIndex) newIndex -= 1;
                          final item = list.removeAt(oldIndex);
                          list.insert(newIndex, item);

                          await context
                              .read<JournalManageTrackersCubit>()
                              .reorderDefinitions(ordered: list);
                        },
                        children: [
                          for (final (index, d) in active.indexed)
                            _TrackerCard(
                              key: ValueKey('tracker_${d.id}'),
                              definition: d,
                              preference: preferenceByTrackerId[d.id],
                              dragIndex: index,
                            ),
                        ],
                      ),
                    ],
                    if (archived.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Archived',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      for (final d in archived)
                        _TrackerCard(
                          key: ValueKey('tracker_${d.id}'),
                          definition: d,
                          preference: preferenceByTrackerId[d.id],
                        ),
                    ],
                  ],
                );
              },
            ),
          ),
    );
  }
}

class _TrackerCard extends StatelessWidget {
  const _TrackerCard({
    required this.definition,
    required this.preference,
    this.dragIndex,
    super.key,
  });

  final TrackerDefinition definition;
  final TrackerPreference? preference;
  final int? dragIndex;

  @override
  Widget build(BuildContext context) {
    final pref = preference;
    final pinned = pref?.pinned ?? false;
    final quickAdd = pref?.showInQuickAdd ?? false;

    return Card(
      key: key,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            ListTile(
              leading: dragIndex == null
                  ? const Icon(Icons.label_outline)
                  : ReorderableDragStartListener(
                      index: dragIndex!,
                      child: const Icon(Icons.drag_handle),
                    ),
              title: Text(definition.name),
              subtitle: Text(
                definition.isOutcome ? 'Outcome' : 'Factor',
              ),
              trailing: PopupMenuButton<_TrackerAction>(
                onSelected: (action) async {
                  final cubit = context.read<JournalManageTrackersCubit>();
                  switch (action) {
                    case _TrackerAction.archive:
                      await cubit.setArchived(
                        definition: definition,
                        archived: true,
                      );
                    case _TrackerAction.unarchive:
                      await cubit.setArchived(
                        definition: definition,
                        archived: false,
                      );
                    case _TrackerAction.delete:
                      final confirmed = await _confirmDelete(
                        context,
                        definition,
                      );
                      if (!context.mounted) return;
                      if (confirmed != true) return;
                      await cubit.deleteTrackerAndData(definition: definition);
                  }
                },
                itemBuilder: (context) => [
                  if (definition.isActive)
                    const PopupMenuItem(
                      value: _TrackerAction.archive,
                      child: Text('Archive'),
                    )
                  else
                    const PopupMenuItem(
                      value: _TrackerAction.unarchive,
                      child: Text('Unarchive'),
                    ),
                  const PopupMenuItem(
                    value: _TrackerAction.delete,
                    child: Text('Delete…'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Pinned'),
                    value: pinned,
                    onChanged: definition.isActive
                        ? (value) => context
                              .read<JournalManageTrackersCubit>()
                              .setPinned(
                                definition: definition,
                                existing: pref,
                                pinned: value,
                              )
                        : null,
                  ),
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show in quick add'),
                    value: quickAdd,
                    onChanged: definition.isActive
                        ? (value) => context
                              .read<JournalManageTrackersCubit>()
                              .setShowInQuickAdd(
                                definition: definition,
                                existing: pref,
                                showInQuickAdd: value,
                              )
                        : null,
                  ),
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Outcome (vs factor)'),
                    value: definition.isOutcome,
                    onChanged: definition.isActive
                        ? (value) => context
                              .read<JournalManageTrackersCubit>()
                              .setOutcome(
                                definition: definition,
                                isOutcome: value,
                              )
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(
    BuildContext context,
    TrackerDefinition definition,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete tracker?'),
          content: Text(
            'This deletes "${definition.name}" and removes its local history and stats. This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

enum _TrackerAction { archive, unarchive, delete }

Future<String?> _showCreateTrackerDialog(BuildContext context) async {
  final controller = TextEditingController();
  try {
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create tracker'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'e.g. Read, Walk, Stretch',
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
    return result;
  } finally {
    controller.dispose();
  }
}
