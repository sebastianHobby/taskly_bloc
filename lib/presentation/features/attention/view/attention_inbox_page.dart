import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/data/id/id_generator.dart';
import 'package:taskly_bloc/domain/analytics/model/entity_type.dart';
import 'package:taskly_bloc/domain/attention/contracts/attention_engine_contract.dart';
import 'package:taskly_bloc/domain/attention/contracts/attention_repository_contract.dart'
    as attention_repo_v2;
import 'package:taskly_bloc/domain/attention/model/attention_item.dart';
import 'package:taskly_bloc/domain/attention/model/attention_resolution.dart';
import 'package:taskly_bloc/domain/attention/model/attention_rule.dart';
import 'package:taskly_bloc/domain/attention/query/attention_query.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';

class AttentionInboxPage extends StatefulWidget {
  const AttentionInboxPage({super.key});

  @override
  State<AttentionInboxPage> createState() => _AttentionInboxPageState();
}

class _AttentionInboxPageState extends State<AttentionInboxPage> {
  late final AttentionEngineContract _engine = getIt<AttentionEngineContract>();
  late final attention_repo_v2.AttentionRepositoryContract _repository =
      getIt<attention_repo_v2.AttentionRepositoryContract>();
  late final IdGenerator _idGenerator = getIt<IdGenerator>();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Attention Inbox'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Action'),
              Tab(text: 'Review'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _BucketTab(
              bucket: AttentionBucket.action,
              items$: _engine.watch(
                const AttentionQuery(buckets: {AttentionBucket.action}),
              ),
              onTapItem: _onTapItem,
              onAction: _recordResolution,
            ),
            _BucketTab(
              bucket: AttentionBucket.review,
              items$: _engine.watch(
                const AttentionQuery(buckets: {AttentionBucket.review}),
              ),
              onTapItem: _onTapItem,
              onAction: _recordResolution,
            ),
          ],
        ),
      ),
    );
  }

  void _onTapItem(AttentionItem item) {
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

  Future<void> _recordResolution(
    AttentionItem item,
    AttentionResolutionAction action,
  ) async {
    final now = DateTime.now();

    final details = switch (action) {
      AttentionResolutionAction.snoozed => <String, dynamic>{
        'snooze_until': now
            .toUtc()
            .add(const Duration(days: 1))
            .toIso8601String(),
      },
      AttentionResolutionAction.dismissed => _dismissDetails(item),
      AttentionResolutionAction.reviewed ||
      AttentionResolutionAction.skipped => null,
    };

    if (action == AttentionResolutionAction.dismissed && details == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Dismiss is unavailable (missing state hash).',
          ),
        ),
      );
      return;
    }

    final resolution = AttentionResolution(
      id: _idGenerator.attentionResolutionId(),
      ruleId: item.ruleId,
      entityId: item.entityId,
      entityType: item.entityType,
      resolvedAt: now,
      createdAt: now,
      resolutionAction: action,
      actionDetails: details,
    );

    await _repository.recordResolution(resolution);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Recorded: ${_labelForAction(action)}')),
    );
  }

  Map<String, dynamic>? _dismissDetails(AttentionItem item) {
    final raw = item.metadata?['state_hash'];
    if (raw is! String || raw.isEmpty) return null;
    return <String, dynamic>{'state_hash': raw};
  }

  String _labelForAction(AttentionResolutionAction action) {
    return switch (action) {
      AttentionResolutionAction.reviewed => 'Reviewed',
      AttentionResolutionAction.skipped => 'Skipped',
      AttentionResolutionAction.snoozed => 'Snoozed (+1 day)',
      AttentionResolutionAction.dismissed => 'Dismissed',
    };
  }
}

class _BucketTab extends StatelessWidget {
  const _BucketTab({
    required this.bucket,
    required this.items$,
    required this.onTapItem,
    required this.onAction,
  });

  final AttentionBucket bucket;
  final Stream<List<AttentionItem>> items$;
  final void Function(AttentionItem item) onTapItem;
  final Future<void> Function(AttentionItem item, AttentionResolutionAction a)
  onAction;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AttentionItem>>(
      stream: items$,
      builder: (context, snapshot) {
        final items = snapshot.data;
        if (items == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (items.isEmpty) {
          return _EmptyBucketState(bucket: bucket);
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = items[index];
            return _AttentionInboxItemCard(
              item: item,
              onTap: () => onTapItem(item),
              onAction: (a) => onAction(item, a),
            );
          },
        );
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
    required this.onTap,
    required this.onAction,
  });

  final AttentionItem item;
  final VoidCallback? onTap;
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
