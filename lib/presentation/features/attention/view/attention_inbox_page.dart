import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_domain/attention.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/presentation/features/attention/bloc/attention_inbox_bloc.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';

class AttentionInboxPage extends StatelessWidget {
  const AttentionInboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attention'),
        actions: [
          IconButton(
            tooltip: 'Attention rules',
            onPressed: () => Routing.pushScreenKey(context, 'attention_rules'),
            icon: const Icon(Icons.tune_outlined),
          ),
        ],
      ),
      body: BlocProvider<AttentionInboxBloc>(
        create: (_) => getIt<AttentionInboxBloc>(),
        child: const _AttentionInboxBody(),
      ),
    );
  }
}

class _AttentionInboxBody extends StatefulWidget {
  const _AttentionInboxBody();

  @override
  State<_AttentionInboxBody> createState() => _AttentionInboxBodyState();
}

class _AttentionInboxBodyState extends State<_AttentionInboxBody> {
  String? _lastUndoId;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AttentionInboxBloc, AttentionInboxState>(
      listenWhen: (prev, next) {
        final prevUndo = prev is AttentionInboxLoaded
            ? prev.pendingUndo?.undoId
            : null;
        final nextUndo = next is AttentionInboxLoaded
            ? next.pendingUndo?.undoId
            : null;
        return nextUndo != null && nextUndo != prevUndo;
      },
      listener: (context, state) {
        if (state is! AttentionInboxLoaded) return;
        final pending = state.pendingUndo;
        if (pending == null || pending.undoId == _lastUndoId) return;

        _lastUndoId = pending.undoId;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Applied ${pending.action.name} to ${pending.count}'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                context.read<AttentionInboxBloc>().add(
                  AttentionInboxEvent.undoRequested(undoId: pending.undoId),
                );
              },
            ),
          ),
        );
      },
      child: BlocBuilder<AttentionInboxBloc, AttentionInboxState>(
        builder: (context, state) {
          return switch (state) {
            AttentionInboxLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            AttentionInboxError(:final message) => _ErrorState(
              message: message,
              onRetry: () => context.read<AttentionInboxBloc>().add(
                const AttentionInboxEvent.subscriptionRequested(),
              ),
            ),
            AttentionInboxLoaded() => _LoadedState(state: state),
          };
        },
      ),
    );
  }
}

class _LoadedState extends StatelessWidget {
  const _LoadedState({required this.state});

  final AttentionInboxLoaded state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (state.totalVisibleCount == 0) {
      return Center(
        child: Text(
          'All caught up',
          style: theme.textTheme.titleMedium,
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SegmentedButton<AttentionBucket>(
            segments: [
              ButtonSegment(
                value: AttentionBucket.action,
                label: Text('Action (${state.actionVisibleCount})'),
              ),
              ButtonSegment(
                value: AttentionBucket.review,
                label: Text('Review (${state.reviewVisibleCount})'),
              ),
            ],
            selected: {state.viewConfig.bucket},
            onSelectionChanged: (selected) {
              if (selected.isEmpty) return;
              context.read<AttentionInboxBloc>().add(
                AttentionInboxEvent.bucketChanged(bucket: selected.first),
              );
            },
          ),
        ),
        if (state.errorMessage != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              state.errorMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              for (final group in state.groups) ...[
                _GroupHeader(title: group.title),
                const SizedBox(height: 8),
                for (final entity in group.entities) ...[
                  _AttentionEntityCard(entity: entity),
                  const SizedBox(height: 12),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _AttentionEntityCard extends StatelessWidget {
  const _AttentionEntityCard({required this.entity});

  final AttentionInboxEntityVm entity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = entity.headline.item;

    return Card(
      child: ListTile(
        leading: _SeverityIndicator(severity: entity.severity),
        title: Text(item.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.description.isNotEmpty)
              Text(
                item.description,
                style: theme.textTheme.bodySmall,
              ),
            if (entity.reasons.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${entity.reasons.length} reasons',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
        trailing: _ActionMenu(
          actions: item.availableActions,
          onSelected: (action) {
            context.read<AttentionInboxBloc>().add(
              AttentionInboxEvent.applyActionToItem(
                itemKey: entity.headline.key,
                action: action,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SeverityIndicator extends StatelessWidget {
  const _SeverityIndicator({required this.severity});

  final AttentionSeverity severity;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (severity) {
      AttentionSeverity.critical => scheme.error,
      AttentionSeverity.warning => scheme.tertiary,
      AttentionSeverity.info => scheme.primary,
    };

    return CircleAvatar(
      radius: 10,
      backgroundColor: color,
      child: const SizedBox.shrink(),
    );
  }
}

class _ActionMenu extends StatelessWidget {
  const _ActionMenu({required this.actions, required this.onSelected});

  final List<AttentionResolutionAction> actions;
  final ValueChanged<AttentionResolutionAction> onSelected;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    return PopupMenuButton<AttentionResolutionAction>(
      tooltip: 'Resolve',
      onSelected: onSelected,
      itemBuilder: (context) {
        return actions
            .map(
              (action) => PopupMenuItem(
                value: action,
                child: Text(_actionLabel(action)),
              ),
            )
            .toList(growable: false);
      },
    );
  }

  String _actionLabel(AttentionResolutionAction action) {
    return switch (action) {
      AttentionResolutionAction.reviewed => 'Mark reviewed',
      AttentionResolutionAction.skipped => 'Skip',
      AttentionResolutionAction.snoozed => 'Snooze',
      AttentionResolutionAction.dismissed => 'Dismiss',
    };
  }
}
