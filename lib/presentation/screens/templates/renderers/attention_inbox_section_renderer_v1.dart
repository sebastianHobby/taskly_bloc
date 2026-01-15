import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/domain/analytics/model/entity_type.dart';
import 'package:taskly_bloc/domain/attention/model/attention_item.dart';
import 'package:taskly_bloc/domain/attention/model/attention_resolution.dart';
import 'package:taskly_bloc/domain/attention/model/attention_rule.dart';
import 'package:taskly_bloc/domain/screens/templates/params/attention_inbox_section_params_v1.dart';
import 'package:taskly_bloc/presentation/features/attention/bloc/attention_inbox_bloc.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';

/// Renders the Attention Inbox as a USM section (no Scaffold/AppBar).
class AttentionInboxSectionRendererV1 extends StatelessWidget {
  const AttentionInboxSectionRendererV1({
    required this.params,
    super.key,
  });

  final AttentionInboxSectionParamsV1 params;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AttentionInboxBloc>(
      create: (_) => getIt<AttentionInboxBloc>(),
      child: const _ApplyInitialQueryParams(child: _AttentionInboxBody()),
    );
  }
}

class _ApplyInitialQueryParams extends StatefulWidget {
  const _ApplyInitialQueryParams({required this.child});

  final Widget child;

  @override
  State<_ApplyInitialQueryParams> createState() =>
      _ApplyInitialQueryParamsState();
}

class _ApplyInitialQueryParamsState extends State<_ApplyInitialQueryParams> {
  var _applied = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_applied) return;
    _applied = true;

    final bucketParam = GoRouterState.of(
      context,
    ).uri.queryParameters['bucket']?.toLowerCase();
    if (bucketParam == null || bucketParam.isEmpty) return;

    final bloc = context.read<AttentionInboxBloc>();

    switch (bucketParam) {
      case 'action':
        bloc.add(
          const AttentionInboxEvent.bucketChanged(
            bucket: AttentionBucket.action,
          ),
        );
        bloc.add(
          const AttentionInboxEvent.minSeverityChanged(minSeverity: null),
        );
      case 'review':
        bloc.add(
          const AttentionInboxEvent.bucketChanged(
            bucket: AttentionBucket.review,
          ),
        );
        bloc.add(
          const AttentionInboxEvent.minSeverityChanged(minSeverity: null),
        );
      case 'critical':
        bloc.add(
          const AttentionInboxEvent.bucketChanged(
            bucket: AttentionBucket.action,
          ),
        );
        bloc.add(
          const AttentionInboxEvent.minSeverityChanged(
            minSeverity: AttentionSeverity.critical,
          ),
        );
      case 'warning':
        bloc.add(
          const AttentionInboxEvent.bucketChanged(
            bucket: AttentionBucket.action,
          ),
        );
        bloc.add(
          const AttentionInboxEvent.minSeverityChanged(
            minSeverity: AttentionSeverity.warning,
          ),
        );
      case 'info':
        bloc.add(
          const AttentionInboxEvent.bucketChanged(
            bucket: AttentionBucket.action,
          ),
        );
        bloc.add(
          const AttentionInboxEvent.minSeverityChanged(
            minSeverity: AttentionSeverity.info,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _AttentionInboxBody extends StatelessWidget {
  const _AttentionInboxBody();

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

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Inbox',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
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
              const SizedBox(height: 8),
              _BucketSelector(viewConfig: viewConfig),
              const SizedBox(height: 8),
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
              if (selectionMode)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _SelectionBar(selectedCount: selectedKeys.length),
                ),
            ],
          ),
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
      builder: (_) {
        return BlocProvider.value(
          value: bloc,
          child: _FiltersSheet(config: config),
        );
      },
    );
  }
}

enum _InboxMenuAction { clearSelection, markAllReviewed }

String _labelForAction(AttentionResolutionAction action) {
  return switch (action) {
    AttentionResolutionAction.reviewed => 'Reviewed',
    AttentionResolutionAction.skipped => 'Skipped',
    AttentionResolutionAction.snoozed => 'Snoozed (+1 day)',
    AttentionResolutionAction.dismissed => 'Dismissed',
  };
}

// === Below are copied UI helpers from the legacy page, kept private ===

class _BucketSelector extends StatelessWidget {
  const _BucketSelector({required this.viewConfig});

  final AttentionInboxViewConfig viewConfig;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AttentionInboxBloc>();

    return SegmentedButton<AttentionBucket>(
      segments: const [
        ButtonSegment(value: AttentionBucket.action, label: Text('Action')),
        ButtonSegment(value: AttentionBucket.review, label: Text('Review')),
      ],
      selected: {viewConfig.bucket},
      onSelectionChanged: (values) {
        final bucket = values.first;
        bloc.add(AttentionInboxEvent.bucketChanged(bucket: bucket));
      },
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
              Icons.notifications_outlined,
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

class _GroupedList extends StatelessWidget {
  const _GroupedList({
    required this.groups,
    required this.selectionMode,
    required this.onTapItem,
    required this.onToggleSelected,
    required this.selectedKeys,
  });

  final List<AttentionInboxGroupVm> groups;
  final bool selectionMode;
  final void Function(AttentionItem item) onTapItem;
  final void Function(String key) onToggleSelected;
  final Set<String> selectedKeys;

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

  List<String> _detailLines() {
    final raw = item.metadata?['detail_lines'];
    if (raw is! List) return const <String>[];
    return raw.whereType<String>().where((s) => s.trim().isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    final enabledActions = item.availableActions.isEmpty
        ? AttentionResolutionAction.values
        : item.availableActions;

    final detailLines = _detailLines();

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
        subtitle: (item.description.isNotEmpty || detailLines.isNotEmpty)
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.description.isNotEmpty)
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  for (final line in detailLines)
                    Text(
                      line,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
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
                  child: Text('Dismissed'),
                ),
            ];
          },
        ),
      ),
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
