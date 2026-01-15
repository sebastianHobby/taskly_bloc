import 'package:flutter/foundation.dart';
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
import 'package:taskly_bloc/presentation/screens/templates/renderers/attention_support_section_widgets.dart';

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

  bool _isMobilePlatform() {
    if (kIsWeb) return false;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => true,
      _ => false,
    };
  }

  bool _hasActiveFilters(AttentionInboxViewConfig c) {
    return c.minSeverity != null ||
        c.entityTypeFilter.isNotEmpty ||
        c.searchQuery.trim().isNotEmpty;
  }

  String _bucketTitle(AttentionBucket bucket) {
    return switch (bucket) {
      AttentionBucket.action => 'Action items',
      AttentionBucket.review => 'Review items',
    };
  }

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
                actionVisibleCount,
                reviewVisibleCount,
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
                actionVisibleCount,
                reviewVisibleCount,
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
                actionVisibleCount,
                reviewVisibleCount,
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
                actionVisibleCount,
                reviewVisibleCount,
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
                actionVisibleCount,
                reviewVisibleCount,
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
                actionVisibleCount,
                reviewVisibleCount,
                selectedKeys,
                pendingUndo,
                errorMessage,
              ) => viewConfig,
          error: (viewConfig, message) => viewConfig,
        );

        final (actionCount, reviewCount) = state.maybeWhen(
          loaded:
              (
                viewConfig,
                groups,
                totalVisibleCount,
                actionVisibleCount,
                reviewVisibleCount,
                selectedKeys,
                pendingUndo,
                errorMessage,
              ) => (actionVisibleCount, reviewVisibleCount),
          orElse: () => (0, 0),
        );

        final selectedKeys = state.maybeWhen(
          loaded:
              (
                viewConfig,
                groups,
                totalVisibleCount,
                actionVisibleCount,
                reviewVisibleCount,
                selectedKeys,
                pendingUndo,
                errorMessage,
              ) => selectedKeys,
          orElse: () => const <String>{},
        );

        final selectionMode = selectedKeys.isNotEmpty;
        final hasActiveFilters = _hasActiveFilters(viewConfig);
        final enableSwipeActions = _isMobilePlatform() && !selectionMode;

        final filtersButton = IconButton(
          tooltip: 'Filters',
          onPressed: () => _openFilters(context),
          icon: const Icon(Icons.tune),
        );

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _bucketTitle(viewConfig.bucket),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (hasActiveFilters)
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        filtersButton,
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    filtersButton,
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
              _BucketSelector(
                viewConfig: viewConfig,
                actionCount: actionCount,
                reviewCount: reviewCount,
              ),
              if (hasActiveFilters) ...[
                const SizedBox(height: 8),
                _AppliedFiltersChips(viewConfig: viewConfig),
              ],
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
                            enableSwipeActions: enableSwipeActions,
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
            actionVisibleCount,
            reviewVisibleCount,
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
  const _BucketSelector({
    required this.viewConfig,
    required this.actionCount,
    required this.reviewCount,
  });

  final AttentionInboxViewConfig viewConfig;
  final int actionCount;
  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AttentionInboxBloc>();

    return SegmentedButton<AttentionBucket>(
      segments: [
        ButtonSegment(
          value: AttentionBucket.action,
          label: Text('Action • $actionCount'),
        ),
        ButtonSegment(
          value: AttentionBucket.review,
          label: Text('Review • $reviewCount'),
        ),
      ],
      selected: {viewConfig.bucket},
      onSelectionChanged: (values) {
        final bucket = values.first;
        bloc.add(AttentionInboxEvent.bucketChanged(bucket: bucket));
      },
    );
  }
}

class _AppliedFiltersChips extends StatelessWidget {
  const _AppliedFiltersChips({required this.viewConfig});

  final AttentionInboxViewConfig viewConfig;

  String _severityLabel(AttentionSeverity s) {
    return switch (s) {
      AttentionSeverity.critical => 'Severity: Critical',
      AttentionSeverity.warning => 'Severity: Warning+',
      AttentionSeverity.info => 'Severity: Info+',
    };
  }

  (IconData, String)? _entityTypeLabel(AttentionEntityType t) {
    return switch (t) {
      AttentionEntityType.task => (Icons.check_box_outlined, 'Task'),
      AttentionEntityType.project => (Icons.folder_outlined, 'Project'),
      AttentionEntityType.value => (Icons.flag_outlined, 'Value'),
      AttentionEntityType.journal => null,
      AttentionEntityType.tracker => null,
      AttentionEntityType.reviewSession => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AttentionInboxBloc>();

    final chips = <Widget>[];

    final minSeverity = viewConfig.minSeverity;
    if (minSeverity != null) {
      chips.add(
        InputChip(
          label: Text(_severityLabel(minSeverity)),
          onDeleted: () {
            bloc.add(
              const AttentionInboxEvent.minSeverityChanged(
                minSeverity: null,
              ),
            );
          },
        ),
      );
    }

    final query = viewConfig.searchQuery.trim();
    if (query.isNotEmpty) {
      chips.add(
        InputChip(
          label: Text('Search: "$query"'),
          onDeleted: () {
            bloc.add(const AttentionInboxEvent.searchQueryChanged(query: ''));
          },
        ),
      );
    }

    final types = viewConfig.entityTypeFilter.toList(growable: false)
      ..sort((a, b) => a.name.compareTo(b.name));
    for (final t in types) {
      final label = _entityTypeLabel(t);
      if (label == null) continue;
      chips.add(
        InputChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(label.$1, size: 16),
              const SizedBox(width: 6),
              Text(label.$2),
            ],
          ),
          onDeleted: () {
            bloc.add(AttentionInboxEvent.entityTypeToggled(entityType: t));
          },
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chips,
            ),
          ],
        ),
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
    required this.enableSwipeActions,
    required this.onTapItem,
    required this.onToggleSelected,
    required this.selectedKeys,
  });

  final List<AttentionInboxGroupVm> groups;
  final bool selectionMode;
  final bool enableSwipeActions;
  final void Function(AttentionItem item) onTapItem;
  final void Function(String key) onToggleSelected;
  final Set<String> selectedKeys;

  Widget _swipeBackground(
    BuildContext context, {
    required Color color,
    required IconData icon,
    required String label,
    required Alignment alignment,
    required EdgeInsets padding,
  }) {
    return Container(
      color: color,
      alignment: alignment,
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

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
            final card = _AttentionInboxItemCard(
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

            if (!enableSwipeActions) return card;

            final enabledActions = vm.item.availableActions.isEmpty
                ? AttentionResolutionAction.values
                : vm.item.availableActions;

            final startAction = vm.item.bucket == AttentionBucket.review
                ? AttentionResolutionAction.reviewed
                : AttentionResolutionAction.snoozed;
            const endAction = AttentionResolutionAction.dismissed;

            final allowStart = enabledActions.contains(startAction);
            final allowEnd = enabledActions.contains(endAction);

            final direction = allowStart && allowEnd
                ? DismissDirection.horizontal
                : allowStart
                ? DismissDirection.startToEnd
                : allowEnd
                ? DismissDirection.endToStart
                : DismissDirection.none;

            if (direction == DismissDirection.none) return card;

            final startLabel = startAction == AttentionResolutionAction.reviewed
                ? 'Reviewed'
                : 'Snooze';
            final startIcon = startAction == AttentionResolutionAction.reviewed
                ? Icons.done
                : Icons.snooze;
            final startColor = startAction == AttentionResolutionAction.reviewed
                ? Colors.green
                : Colors.orange;

            return Dismissible(
              key: ValueKey('attn_swipe_${vm.key}'),
              direction: direction,
              background: allowStart
                  ? _swipeBackground(
                      context,
                      color: startColor,
                      icon: startIcon,
                      label: startLabel,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 16),
                    )
                  : null,
              secondaryBackground: allowEnd
                  ? _swipeBackground(
                      context,
                      color: Theme.of(context).colorScheme.error,
                      icon: Icons.close,
                      label: 'Dismiss',
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                    )
                  : null,
              confirmDismiss: (d) async {
                final action = switch (d) {
                  DismissDirection.startToEnd => startAction,
                  DismissDirection.endToStart => endAction,
                  _ => null,
                };

                if (action == null) return false;

                bloc.add(
                  AttentionInboxEvent.applyActionToItem(
                    itemKey: vm.key,
                    action: action,
                  ),
                );
                return true;
              },
              child: card,
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

  @override
  Widget build(BuildContext context) {
    final enabledActions = item.availableActions.isEmpty
        ? AttentionResolutionAction.values
        : item.availableActions;

    final tileLeading = selectionMode
        ? Checkbox(
            value: selected,
            onChanged: (_) => onToggleSelected(),
          )
        : null;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: AttentionItemTile(
                  item: item,
                  leading: tileLeading,
                ),
              ),
              PopupMenuButton<AttentionResolutionAction>(
                tooltip: 'Actions',
                onSelected: onAction,
                itemBuilder: (context) {
                  return [
                    if (enabledActions.contains(
                      AttentionResolutionAction.reviewed,
                    ))
                      const PopupMenuItem(
                        value: AttentionResolutionAction.reviewed,
                        child: Text('Reviewed'),
                      ),
                    if (enabledActions.contains(
                      AttentionResolutionAction.skipped,
                    ))
                      const PopupMenuItem(
                        value: AttentionResolutionAction.skipped,
                        child: Text('Skipped'),
                      ),
                    if (enabledActions.contains(
                      AttentionResolutionAction.snoozed,
                    ))
                      const PopupMenuItem(
                        value: AttentionResolutionAction.snoozed,
                        child: Text('Snooze 1 day'),
                      ),
                    if (enabledActions.contains(
                      AttentionResolutionAction.dismissed,
                    ))
                      const PopupMenuItem(
                        value: AttentionResolutionAction.dismissed,
                        child: Text('Dismissed'),
                      ),
                  ];
                },
              ),
            ],
          ),
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 520;

            if (isCompact) {
              return Row(
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
                  PopupMenuButton<AttentionResolutionAction>(
                    tooltip: 'Bulk actions',
                    onSelected: (a) {
                      bloc.add(
                        AttentionInboxEvent.applyActionToSelection(action: a),
                      );
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: AttentionResolutionAction.snoozed,
                        child: Text('Snooze'),
                      ),
                      PopupMenuItem(
                        value: AttentionResolutionAction.dismissed,
                        child: Text('Dismiss'),
                      ),
                    ],
                    child: const Icon(Icons.more_vert),
                  ),
                ],
              );
            }

            return Row(
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
            );
          },
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
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.tune),
            title: const Text('Manage rules'),
            subtitle: const Text('Configure what shows up in Attention'),
            onTap: () {
              Navigator.of(context).pop();
              Routing.toScreenKey(context, 'attention_rules');
            },
          ),
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
              for (final t in const [
                AttentionEntityType.task,
                AttentionEntityType.project,
                AttentionEntityType.value,
              ])
                FilterChip(
                  label: _EntityTypeChipLabel(entityType: t),
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

class _EntityTypeChipLabel extends StatelessWidget {
  const _EntityTypeChipLabel({required this.entityType});

  final AttentionEntityType entityType;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (entityType) {
      AttentionEntityType.task => (Icons.check_box_outlined, 'Task'),
      AttentionEntityType.project => (Icons.folder_outlined, 'Project'),
      AttentionEntityType.value => (Icons.flag_outlined, 'Value'),
      _ => (Icons.help_outline, entityType.name),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}
