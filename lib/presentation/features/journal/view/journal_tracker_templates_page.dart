import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_manage_library_bloc.dart';
import 'package:taskly_bloc/presentation/features/journal/utils/tracker_icon_utils.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class JournalTrackerTemplatesPage extends StatelessWidget {
  const JournalTrackerTemplatesPage({
    required this.kind,
    super.key,
  });

  final String kind;

  bool get _isAggregate => kind.trim().toLowerCase() == 'aggregate';

  bool _matchesKind(TrackerDefinition def) {
    final aggregate =
        def.opKind.trim().toLowerCase() == 'add' ||
        def.scope.trim().toLowerCase() == 'day' ||
        def.aggregationKind.trim().toLowerCase() == 'avg';
    return _isAggregate ? aggregate : !aggregate;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<JournalManageLibraryBloc>(
      create: (context) => JournalManageLibraryBloc(
        repository: context.read<JournalRepositoryContract>(),
        errorReporter: context.read<AppErrorReporter>(),
        nowUtc: context.read<NowService>().nowUtc,
      ),
      child: BlocBuilder<JournalManageLibraryBloc, JournalManageLibraryState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: Text(context.l10n.journalTrackerTemplatesTitle),
            ),
            body: switch (state) {
              JournalManageLibraryLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              JournalManageLibraryError(:final message) => Center(
                child: Text(message),
              ),
              JournalManageLibraryLoaded() => _TemplateList(
                trackers:
                    state.trackers
                        .where((d) => d.deletedAt == null)
                        .where(_matchesKind)
                        .toList(growable: false)
                      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
                onToggleActive: (tracker, isActive) async {
                  await context
                      .read<JournalManageLibraryBloc>()
                      .setTrackerActive(
                        def: tracker,
                        isActive: isActive,
                      );
                },
                onCreateFromScratch: () => Routing.toJournalTrackerConfigure(
                  context,
                  kind: kind,
                ),
              ),
            },
          );
        },
      ),
    );
  }
}

class _TemplateList extends StatelessWidget {
  const _TemplateList({
    required this.trackers,
    required this.onToggleActive,
    required this.onCreateFromScratch,
  });

  final List<TrackerDefinition> trackers;
  final Future<void> Function(TrackerDefinition tracker, bool isActive)
  onToggleActive;
  final VoidCallback onCreateFromScratch;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final theme = Theme.of(context);

    if (trackers.isEmpty) {
      return Center(child: Text(context.l10n.journalNoEntryTrackers));
    }

    return ListView(
      padding: EdgeInsets.all(tokens.spaceLg),
      children: [
        Text(
          context.l10n.journalPopularTrackersTitle,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: tokens.spaceMd),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: trackers.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: tokens.spaceSm,
            crossAxisSpacing: tokens.spaceSm,
            childAspectRatio: 0.95,
          ),
          itemBuilder: (context, index) {
            final tracker = trackers[index];
            return _TemplateCard(
              tracker: tracker,
              onToggleActive: onToggleActive,
            );
          },
        ),
        SizedBox(height: tokens.spaceLg),
        Text(
          context.l10n.customLabel,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: tokens.spaceMd),
        InkWell(
          borderRadius: BorderRadius.circular(tokens.radiusLg),
          onTap: onCreateFromScratch,
          child: Ink(
            padding: EdgeInsets.all(tokens.spaceMd),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(tokens.radiusLg),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(tokens.radiusSm),
                  ),
                  child: Icon(
                    Icons.add,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                SizedBox(width: tokens.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.journalCreateFromScratchLabel,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: tokens.spaceXxs),
                      Text(
                        context.l10n.journalCreateFromScratchSubtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: tokens.spaceMd),
        Container(
          padding: EdgeInsets.all(tokens.spaceMd),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(tokens.radiusLg),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(width: tokens.spaceXs),
                  Text(
                    context.l10n.journalProTipLabel.toUpperCase(),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              SizedBox(height: tokens.spaceSm),
              Text(
                context.l10n.journalTemplateProTipBody,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.tracker,
    required this.onToggleActive,
  });

  final TrackerDefinition tracker;
  final Future<void> Function(TrackerDefinition tracker, bool isActive)
  onToggleActive;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final theme = Theme.of(context);
    final selected = tracker.isActive;
    return InkWell(
      borderRadius: BorderRadius.circular(tokens.radiusLg),
      onTap: () => onToggleActive(tracker, !selected),
      child: Ink(
        padding: EdgeInsets.all(tokens.spaceMd),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(tokens.radiusLg),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(tokens.radiusSm),
                  ),
                  child: Icon(
                    trackerIconData(tracker),
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const Spacer(),
                Icon(
                  selected ? Icons.check_circle : Icons.add_circle_outline,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            SizedBox(height: tokens.spaceSm),
            Text(
              tracker.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: tokens.spaceXxs),
            Text(
              _metaLabel(context, tracker),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _metaLabel(BuildContext context, TrackerDefinition tracker) {
    final valueType = tracker.valueType.trim().toLowerCase();
    if (valueType == 'quantity') {
      final agg = tracker.aggregationKind.trim().toLowerCase();
      final aggLabel = agg == 'avg'
          ? context.l10n.journalTrackerAggregationAverageLabel
          : context.l10n.journalTrackerAggregationSumLabel;
      final unit = (tracker.unitKind ?? '').trim();
      if (unit.isNotEmpty) return '$aggLabel ($unit)';
      return aggLabel;
    }
    if (valueType == 'rating') {
      final min = tracker.minInt ?? 1;
      final max = tracker.maxInt ?? 5;
      return '${context.l10n.journalMeasurementRatingTitle} ($min-$max)';
    }
    if (valueType == 'yes_no') {
      return context.l10n.journalMeasurementToggleTitle;
    }
    return context.l10n.journalSystemDefaultToggleOnlyLabel;
  }
}
