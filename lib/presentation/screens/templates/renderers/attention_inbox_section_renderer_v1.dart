import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_domain/domain/analytics/model/entity_type.dart';
import 'package:taskly_domain/domain/attention/model/attention_item.dart';
import 'package:taskly_domain/domain/attention/model/attention_resolution.dart';
import 'package:taskly_domain/domain/attention/model/attention_rule.dart';
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
          const AttentionInboxEvent.bucketFilterSet(
            buckets: {AttentionBucket.action},
          ),
        );
        bloc.add(
          const AttentionInboxEvent.minSeverityChanged(minSeverity: null),
        );
      case 'review':
        bloc.add(
          const AttentionInboxEvent.bucketFilterSet(
            buckets: {AttentionBucket.review},
          ),
        );
        bloc.add(
          const AttentionInboxEvent.minSeverityChanged(minSeverity: null),
        );
      case 'critical':
        bloc.add(
          const AttentionInboxEvent.minSeverityChanged(
            minSeverity: AttentionSeverity.critical,
          ),
        );
      case 'warning':
        bloc.add(
          const AttentionInboxEvent.minSeverityChanged(
            minSeverity: AttentionSeverity.warning,
          ),
        );
      case 'info':
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

  bool _hasActiveFilters(AttentionInboxViewConfig c) {
    return c.minSeverity != null ||
        c.bucketFilter.length != AttentionBucket.values.length ||
        c.entityTypeFilter.isNotEmpty ||
        c.searchQuery.trim().isNotEmpty;
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

        final hasActiveFilters = _hasActiveFilters(viewConfig);

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
                      'Attention',
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
                ],
              ),
              const SizedBox(height: 8),
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
                  ) =>
                    totalVisibleCount == 0
                        ? const _EmptyInboxState()
                        : _GroupedEntityList(
                            groups: groups,
                            onTapEntity: (entityType, entityId) {
                              final t = _toEntityType(entityType);
                              if (t == null) return;
                              Routing.toEntity(context, t, entityId);
                            },
                            onShowReasons: (entity) =>
                                _openReasonsSheet(context, entity),
                            onAction: (entity, action) =>
                                _openActionSheet(context, entity, action),
                          ),
                },
              ),
            ],
          ),
        );
      },
    );
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

  Future<void> _openReasonsSheet(
    BuildContext context,
    AttentionInboxEntityVm entity,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: ListView(
            shrinkWrap: true,
            children: [
              const SizedBox(height: 8),
              Text(
                'Reasons',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final r in entity.reasons)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: SeverityIcon(severity: r.item.severity),
                  title: Text(r.item.title),
                  subtitle: r.item.description.isNotEmpty
                      ? Text(r.item.description)
                      : null,
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openActionSheet(
    BuildContext context,
    AttentionInboxEntityVm entity,
    AttentionResolutionAction action,
  ) async {
    final bloc = context.read<AttentionInboxBloc>();

    final selected = <String>{
      for (final r in entity.reasons) r.key,
    };

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setState) {
            final label = _labelForAction(action);
            final allSelected = selected.length == entity.reasons.length;

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: ListView(
                shrinkWrap: true,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  if (action == AttentionResolutionAction.dismissed)
                    Text(
                      'Dismiss until state changes. If the situation changes, it will reappear.',
                      style: Theme.of(sheetContext).textTheme.bodySmall
                          ?.copyWith(
                            color: Theme.of(
                              sheetContext,
                            ).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: allSelected,
                    onChanged: (v) {
                      setState(() {
                        selected
                          ..clear()
                          ..addAll(
                            v ?? false
                                ? entity.reasons.map((r) => r.key)
                                : const <String>[],
                          );
                      });
                    },
                    title: const Text('All reasons'),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(height: 1),
                  for (final r in entity.reasons)
                    CheckboxListTile(
                      value: selected.contains(r.key),
                      onChanged: (v) {
                        setState(() {
                          if (v ?? false) {
                            selected.add(r.key);
                          } else {
                            selected.remove(r.key);
                          }
                        });
                      },
                      title: Text(r.item.title),
                      subtitle: r.item.description.isNotEmpty
                          ? Text(r.item.description)
                          : null,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: selected.isEmpty
                        ? null
                        : () {
                            Navigator.of(sheetContext).pop();
                            bloc.add(
                              AttentionInboxEvent.applyActionToMany(
                                action: action,
                                itemKeys: selected.toList(growable: false),
                              ),
                            );
                          },
                    child: Text(label),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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

String _labelForAction(AttentionResolutionAction action) {
  return switch (action) {
    AttentionResolutionAction.reviewed => 'Reviewed',
    AttentionResolutionAction.skipped => 'Skipped',
    AttentionResolutionAction.snoozed => 'Snoozed (+1 day)',
    AttentionResolutionAction.dismissed => 'Dismissed',
  };
}

// === Below are copied UI helpers from the legacy page, kept private ===

class _EmptyInboxState extends StatelessWidget {
  const _EmptyInboxState();

  @override
  Widget build(BuildContext context) {
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
              'All caught up.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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

    if (viewConfig.bucketFilter.length != AttentionBucket.values.length) {
      final showAction = viewConfig.bucketFilter.contains(
        AttentionBucket.action,
      );
      final showReview = viewConfig.bucketFilter.contains(
        AttentionBucket.review,
      );
      final label = switch ((showAction, showReview)) {
        (true, false) => 'Type: Action',
        (false, true) => 'Type: Review',
        _ => 'Type: Custom',
      };

      chips.add(
        InputChip(
          label: Text(label),
          onDeleted: () {
            bloc.add(
              const AttentionInboxEvent.bucketFilterSet(
                buckets: {AttentionBucket.action, AttentionBucket.review},
              ),
            );
          },
        ),
      );
    }

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

class _GroupedEntityList extends StatelessWidget {
  const _GroupedEntityList({
    required this.groups,
    required this.onTapEntity,
    required this.onShowReasons,
    required this.onAction,
  });

  final List<AttentionInboxGroupVm> groups;
  final void Function(AttentionEntityType entityType, String entityId)
  onTapEntity;
  final void Function(AttentionInboxEntityVm entity) onShowReasons;
  final void Function(
    AttentionInboxEntityVm entity,
    AttentionResolutionAction action,
  )
  onAction;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: groups.fold<int>(0, (acc, g) {
        final header = g.title.isEmpty ? 0 : 1;
        return acc + header + g.entities.length;
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

          if (index < cursor + group.entities.length) {
            final entity = group.entities[index - cursor];
            return _AttentionInboxEntityCard(
              entity: entity,
              onTap: () => onTapEntity(entity.entityType, entity.entityId),
              onShowReasons: () => onShowReasons(entity),
              onAction: (a) => onAction(entity, a),
            );
          }

          cursor += group.entities.length;
        }

        return const SizedBox.shrink();
      },
    );
  }
}

enum _EntityMenuAction { open, showReasons, snooze, dismiss }

class _AttentionInboxEntityCard extends StatelessWidget {
  const _AttentionInboxEntityCard({
    required this.entity,
    required this.onTap,
    required this.onShowReasons,
    required this.onAction,
  });

  final AttentionInboxEntityVm entity;
  final VoidCallback onTap;
  final VoidCallback onShowReasons;
  final void Function(AttentionResolutionAction action) onAction;

  String? _entityDisplayName(AttentionItem item) {
    final metadata = item.metadata;
    if (metadata == null) return null;

    final explicit = metadata['entity_display_name'];
    if (explicit is String && explicit.trim().isNotEmpty) {
      return explicit.trim();
    }

    final key = switch (item.entityType) {
      AttentionEntityType.task => 'task_name',
      AttentionEntityType.project => 'project_name',
      AttentionEntityType.value => 'value_name',
      AttentionEntityType.journal => null,
      AttentionEntityType.tracker => null,
      AttentionEntityType.reviewSession => null,
    };

    if (key == null) return null;
    final v = metadata[key];
    if (v is String && v.trim().isNotEmpty) return v.trim();
    return null;
  }

  (IconData, String)? _entityBadge(AttentionEntityType t) {
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
    final headline = entity.headline.item;
    final badge = _entityBadge(entity.entityType);
    final entityName = _entityDisplayName(headline);

    final moreCount = entity.reasons.length - 1;
    final showMore = moreCount > 0;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SeverityIcon(severity: entity.severity),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (badge != null && entityName != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          children: [
                            Icon(
                              badge.$1,
                              size: 14,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${badge.$2} • $entityName',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Text(
                        badge?.$2 ?? 'Item',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            headline.title,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (showMore)
                          TextButton(
                            onPressed: onShowReasons,
                            child: Text('+$moreCount more'),
                          ),
                      ],
                    ),
                    if (headline.description.isNotEmpty)
                      Text(
                        headline.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              PopupMenuButton<_EntityMenuAction>(
                tooltip: 'Actions',
                onSelected: (a) {
                  switch (a) {
                    case _EntityMenuAction.open:
                      onTap();
                    case _EntityMenuAction.showReasons:
                      onShowReasons();
                    case _EntityMenuAction.snooze:
                      onAction(AttentionResolutionAction.snoozed);
                    case _EntityMenuAction.dismiss:
                      onAction(AttentionResolutionAction.dismissed);
                  }
                },
                itemBuilder: (context) {
                  return const [
                    PopupMenuItem(
                      value: _EntityMenuAction.open,
                      child: Text('Open'),
                    ),
                    PopupMenuItem(
                      value: _EntityMenuAction.showReasons,
                      child: Text('View reasons'),
                    ),
                    PopupMenuItem(
                      value: _EntityMenuAction.snooze,
                      child: Text('Snooze…'),
                    ),
                    PopupMenuItem(
                      value: _EntityMenuAction.dismiss,
                      child: Text('Dismiss…'),
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
          Text('Type', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('Action'),
                selected: config.bucketFilter.contains(AttentionBucket.action),
                onSelected: (_) {
                  bloc.add(
                    const AttentionInboxEvent.bucketFilterToggled(
                      bucket: AttentionBucket.action,
                    ),
                  );
                },
              ),
              FilterChip(
                label: const Text('Review'),
                selected: config.bucketFilter.contains(AttentionBucket.review),
                onSelected: (_) {
                  bloc.add(
                    const AttentionInboxEvent.bucketFilterToggled(
                      bucket: AttentionBucket.review,
                    ),
                  );
                },
              ),
            ],
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
