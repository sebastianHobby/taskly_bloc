import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/data/id/id_generator.dart';
import 'package:taskly_bloc/domain/analytics/model/entity_type.dart';
import 'package:taskly_bloc/domain/attention/contracts/attention_engine_contract.dart';
import 'package:taskly_bloc/domain/attention/contracts/attention_repository_contract.dart'
    as attention_repo_v2;
import 'package:taskly_bloc/domain/attention/model/attention_item.dart';
import 'package:taskly_bloc/domain/attention/model/attention_resolution.dart';
import 'package:taskly_bloc/domain/attention/model/attention_rule.dart';
import 'package:taskly_bloc/presentation/features/attention/bloc/attention_inbox_bloc.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';

class AttentionInboxPage extends StatelessWidget {
  const AttentionInboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AttentionInboxBloc>(
      create: (_) => AttentionInboxBloc(
        engine: getIt<AttentionEngineContract>(),
        repository: getIt<attention_repo_v2.AttentionRepositoryContract>(),
        idGenerator: getIt<IdGenerator>(),
      ),
      child: const _AttentionInboxScaffold(),
    );
  }
}

class _AttentionInboxScaffold extends StatelessWidget {
  const _AttentionInboxScaffold();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AttentionInboxBloc, AttentionInboxState>(
      listenWhen: (prev, next) {
        final prevUndo = prev.maybeWhen(
          loaded:
              (
                viewConfig,
                groups,
                totalVisibleCount,
                selectedKeys,
                pendingUndo,
                errorMessage,
              ) => pendingUndo,
          orElse: () => null,
        );
        final nextUndo = next.maybeWhen(
          loaded:
              (
                viewConfig,
                groups,
                totalVisibleCount,
                selectedKeys,
                pendingUndo,
                errorMessage,
              ) => pendingUndo,
          orElse: () => null,
        );

        if (prevUndo?.undoId != nextUndo?.undoId) return true;

        final prevErr = prev.maybeWhen(
          loaded:
              (
                viewConfig,
                groups,
                totalVisibleCount,
                selectedKeys,
                pendingUndo,
                errorMessage,
              ) => errorMessage,
          orElse: () => null,
        );
        final nextErr = next.maybeWhen(
          loaded:
              (
                viewConfig,
                groups,
                totalVisibleCount,
                selectedKeys,
                pendingUndo,
                errorMessage,
              ) => errorMessage,
          orElse: () => null,
        );

        return prevErr != nextErr && nextErr != null;
      },
      listener: (context, state) {
        state.maybeWhen(
          loaded:
              (
                viewConfig,
                groups,
                totalVisibleCount,
                selectedKeys,
                pendingUndo,
                errorMessage,
              ) {
                if (errorMessage != null && errorMessage.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(errorMessage)),
                  );
                }

                if (pendingUndo == null) return;

                final label = _labelForAction(pendingUndo.action);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$label: ${pendingUndo.count} item(s)'),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () {
                        context.read<AttentionInboxBloc>().add(
                          AttentionInboxEvent.undoRequested(
                            undoId: pendingUndo.undoId,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
          orElse: () {},
        );
      },
      builder: (context, state) {
        final viewConfig = state.when(
          loading: (viewConfig) => viewConfig,
          loaded:
              (
                viewConfig,
                groups,
                totalVisibleCount,
                selectedKeys,
                pendingUndo,
                errorMessage,
              ) => viewConfig,
          error: (viewConfig, message) => viewConfig,
        );

        final selectedKeys = state.maybeWhen(
          loaded:
              (
                viewConfig,
                groups,
                totalVisibleCount,
                selectedKeys,
                pendingUndo,
                errorMessage,
              ) => selectedKeys,
          orElse: () => const <String>{},
        );

        final selectionMode = selectedKeys.isNotEmpty;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Attention Inbox'),
            actions: [
              IconButton(
                tooltip: 'Filters',
                onPressed: () => _openFilters(context),
                icon: const Icon(Icons.tune),
              ),
              PopupMenuButton<_InboxMenuAction>(
                onSelected: (a) {
                  final bloc = context.read<AttentionInboxBloc>();
                  switch (a) {
                    case _InboxMenuAction.clearSelection:
                      bloc.add(const AttentionInboxEvent.clearSelection());
                    case _InboxMenuAction.markAllReviewed:
                      bloc.add(
                        const AttentionInboxEvent.applyActionToVisible(
                          action: AttentionResolutionAction.reviewed,
                        ),
                      );
                  }
                },
                itemBuilder: (context) {
                  return [
                    if (selectionMode)
                      const PopupMenuItem(
                        value: _InboxMenuAction.clearSelection,
                        child: Text('Clear selection'),
                      ),
                    const PopupMenuItem(
                      value: _InboxMenuAction.markAllReviewed,
                      child: Text('Mark all reviewed'),
                    ),
                  ];
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: _BucketSelector(viewConfig: viewConfig),
              ),
              Expanded(
                child: switch (state) {
                  AttentionInboxLoading() => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  AttentionInboxError(:final message) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(message),
                    ),
                  ),
                  AttentionInboxLoaded(
                    :final groups,
                    :final totalVisibleCount,
                    :final selectedKeys,
                  ) =>
                    totalVisibleCount == 0
                        ? _EmptyBucketState(bucket: viewConfig.bucket)
                        : _GroupedList(
                            groups: groups,
                            selectionMode: selectionMode,
                            onTapItem: (item) => _onTapItem(context, item),
                            onToggleSelected: (key) =>
                                context.read<AttentionInboxBloc>().add(
                                  AttentionInboxEvent.toggleSelected(
                                    itemKey: key,
                                  ),
                                ),
                            selectedKeys: selectedKeys,
                          ),
                },
              ),
            ],
          ),
          bottomNavigationBar: selectionMode
              ? _SelectionBar(selectedCount: selectedKeys.length)
              : null,
        );
      },
    );
  }

  void _onTapItem(BuildContext context, AttentionItem item) {
    final entityType = _toEntityType(item.entityType);
    if (entityType == null) return;
    Routing.toEntity(context, entityType, item.entityId);
  }

  EntityType? _toEntityType(AttentionEntityType t) {
    return switch (t) {
      AttentionEntityType.task => EntityType.task,
      AttentionEntityType.project => EntityType.project,
      AttentionEntityType.value => EntityType.value,
      AttentionEntityType.journal => null,
      AttentionEntityType.tracker => null,
      AttentionEntityType.reviewSession => null,
    };
  }

  Future<void> _openFilters(BuildContext context) async {
    final bloc = context.read<AttentionInboxBloc>();
    final state = bloc.state;

    final config = state.when(
      loading: (viewConfig) => viewConfig,
      loaded:
          (
            viewConfig,
            groups,
            totalVisibleCount,
            selectedKeys,
            pendingUndo,
            errorMessage,
          ) => viewConfig,
      error: (viewConfig, message) => viewConfig,
    );

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return _FiltersSheet(config: config);
      },
    );
  }
}

enum _InboxMenuAction { clearSelection, markAllReviewed }

class _BucketSelector extends StatelessWidget {
  const _BucketSelector({required this.viewConfig});

  final AttentionInboxViewConfig viewConfig;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<AttentionBucket>(
      segments: const [
        ButtonSegment(
          value: AttentionBucket.action,
          label: Text('Action'),
        ),
        ButtonSegment(
          value: AttentionBucket.review,
          label: Text('Review'),
        ),
      ],
      selected: {viewConfig.bucket},
      onSelectionChanged: (selection) {
        final bucket = selection.first;
        context.read<AttentionInboxBloc>().add(
          AttentionInboxEvent.bucketChanged(bucket: bucket),
        );
      },
    );
  }
}

class _GroupedList extends StatelessWidget {
  const _GroupedList({
    required this.groups,
    required this.selectionMode,
    required this.selectedKeys,
    required this.onTapItem,
    required this.onToggleSelected,
  });

  final List<AttentionInboxGroupVm> groups;
  final bool selectionMode;
  final Set<String> selectedKeys;
  final void Function(AttentionItem item) onTapItem;
  final void Function(String key) onToggleSelected;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AttentionInboxBloc>();

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: groups.fold<int>(0, (acc, g) {
        final header = g.title.isEmpty ? 0 : 1;
        return acc + header + g.items.length;
      }),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        var cursor = 0;
        for (final group in groups) {
          final hasHeader = group.title.isNotEmpty;
          if (hasHeader) {
            if (index == cursor) {
              return Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  group.title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              );
            }
            cursor += 1;
          }

          if (index < cursor + group.items.length) {
            final vm = group.items[index - cursor];
            final selected = selectedKeys.contains(vm.key);
            return _AttentionInboxItemCard(
              item: vm.item,
              selectionMode: selectionMode,
              selected: selected,
              onTap: () {
                if (selectionMode) {
                  onToggleSelected(vm.key);
                } else {
                  onTapItem(vm.item);
                }
              },
              onLongPress: () => onToggleSelected(vm.key),
              onToggleSelected: () => onToggleSelected(vm.key),
              onAction: (a) {
                bloc.add(
                  AttentionInboxEvent.applyActionToItem(
                    itemKey: vm.key,
                    action: a,
                  ),
                );
                return Future<void>.value();
              },
            );
          }

          cursor += group.items.length;
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({required this.selectedCount});

  final int selectedCount;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AttentionInboxBloc>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(child: Text('$selectedCount selected')),
            TextButton(
              onPressed: () =>
                  bloc.add(const AttentionInboxEvent.clearSelection()),
              child: const Text('Clear'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () => bloc.add(
                const AttentionInboxEvent.applyActionToSelection(
                  action: AttentionResolutionAction.reviewed,
                ),
              ),
              icon: const Icon(Icons.done),
              label: const Text('Reviewed'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => bloc.add(
                const AttentionInboxEvent.applyActionToSelection(
                  action: AttentionResolutionAction.snoozed,
                ),
              ),
              icon: const Icon(Icons.snooze),
              label: const Text('Snooze'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => bloc.add(
                const AttentionInboxEvent.applyActionToSelection(
                  action: AttentionResolutionAction.dismissed,
                ),
              ),
              icon: const Icon(Icons.close),
              label: const Text('Dismiss'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FiltersSheet extends StatelessWidget {
  const _FiltersSheet({required this.config});

  final AttentionInboxViewConfig config;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AttentionInboxBloc>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: ListView(
        shrinkWrap: true,
        children: [
          const SizedBox(height: 8),
          Text('Filters', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Search',
              prefixIcon: Icon(Icons.search),
            ),
            initialValue: config.searchQuery,
            onChanged: (v) => bloc.add(
              AttentionInboxEvent.searchQueryChanged(query: v),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<AttentionInboxGroupBy>(
            value: config.groupBy,
            decoration: const InputDecoration(labelText: 'Group by'),
            items: const [
              DropdownMenuItem(
                value: AttentionInboxGroupBy.none,
                child: Text('None'),
              ),
              DropdownMenuItem(
                value: AttentionInboxGroupBy.severity,
                child: Text('Severity'),
              ),
              DropdownMenuItem(
                value: AttentionInboxGroupBy.entityType,
                child: Text('Entity type'),
              ),
              DropdownMenuItem(
                value: AttentionInboxGroupBy.rule,
                child: Text('Rule'),
              ),
            ],
            onChanged: (v) {
              if (v == null) return;
              bloc.add(AttentionInboxEvent.groupByChanged(groupBy: v));
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<AttentionInboxSort>(
            value: config.sort,
            decoration: const InputDecoration(labelText: 'Sort'),
            items: const [
              DropdownMenuItem(
                value: AttentionInboxSort.detectedAtDesc,
                child: Text('Newest'),
              ),
              DropdownMenuItem(
                value: AttentionInboxSort.severityDesc,
                child: Text('Severity'),
              ),
              DropdownMenuItem(
                value: AttentionInboxSort.titleAsc,
                child: Text('Title (A–Z)'),
              ),
            ],
            onChanged: (v) {
              if (v == null) return;
              bloc.add(AttentionInboxEvent.sortChanged(sort: v));
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<AttentionSeverity?>(
            value: config.minSeverity,
            decoration: const InputDecoration(labelText: 'Min severity'),
            items: const [
              DropdownMenuItem(value: null, child: Text('Any')),
              DropdownMenuItem(
                value: AttentionSeverity.info,
                child: Text('Info'),
              ),
              DropdownMenuItem(
                value: AttentionSeverity.warning,
                child: Text('Warning'),
              ),
              DropdownMenuItem(
                value: AttentionSeverity.critical,
                child: Text('Critical'),
              ),
            ],
            onChanged: (v) {
              bloc.add(AttentionInboxEvent.minSeverityChanged(minSeverity: v));
            },
          ),
          const SizedBox(height: 16),
          Text('Entity types', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in AttentionEntityType.values)
                FilterChip(
                  label: Text(t.name),
                  selected: config.entityTypeFilter.contains(t),
                  onSelected: (_) => bloc.add(
                    AttentionInboxEvent.entityTypeToggled(entityType: t),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBucketState extends StatelessWidget {
  const _EmptyBucketState({required this.bucket});

  final AttentionBucket bucket;

  @override
  Widget build(BuildContext context) {
    final label = switch (bucket) {
      AttentionBucket.action => 'No action items right now.',
      AttentionBucket.review => 'No review items right now.',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AttentionInboxItemCard extends StatelessWidget {
  const _AttentionInboxItemCard({
    required this.item,
    required this.selectionMode,
    required this.selected,
    required this.onTap,
    required this.onToggleSelected,
    required this.onLongPress,
    required this.onAction,
  });

  final AttentionItem item;
  final bool selectionMode;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback onToggleSelected;
  final VoidCallback onLongPress;
  final Future<void> Function(AttentionResolutionAction action) onAction;

  @override
  Widget build(BuildContext context) {
    final enabledActions = item.availableActions.isEmpty
        ? AttentionResolutionAction.values
        : item.availableActions;

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        onLongPress: onLongPress,
        leading: selectionMode
            ? Checkbox(
                value: selected,
                onChanged: (_) => onToggleSelected(),
              )
            : null,
        title: Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: item.description.isNotEmpty
            ? Text(
                item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: PopupMenuButton<AttentionResolutionAction>(
          tooltip: 'Actions',
          onSelected: onAction,
          itemBuilder: (context) {
            return [
              if (enabledActions.contains(AttentionResolutionAction.reviewed))
                const PopupMenuItem(
                  value: AttentionResolutionAction.reviewed,
                  child: Text('Reviewed'),
                ),
              if (enabledActions.contains(AttentionResolutionAction.skipped))
                const PopupMenuItem(
                  value: AttentionResolutionAction.skipped,
                  child: Text('Skipped'),
                ),
              if (enabledActions.contains(AttentionResolutionAction.snoozed))
                const PopupMenuItem(
                  value: AttentionResolutionAction.snoozed,
                  child: Text('Snooze 1 day'),
                ),
              if (enabledActions.contains(AttentionResolutionAction.dismissed))
                const PopupMenuItem(
                  value: AttentionResolutionAction.dismissed,
                  child: Text('Dismiss'),
                ),
            ];
          },
        ),
      ),
    );
  }
}

String _labelForAction(AttentionResolutionAction action) {
  return switch (action) {
    AttentionResolutionAction.reviewed => 'Reviewed',
    AttentionResolutionAction.skipped => 'Skipped',
    AttentionResolutionAction.snoozed => 'Snoozed (+1 day)',
    AttentionResolutionAction.dismissed => 'Dismissed',
  };
}
