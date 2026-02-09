import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/review/bloc/weekly_review_cubit.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_bloc/presentation/widgets/icon_picker/icon_catalog.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

Future<void> showWeeklyRatingEvidenceSheet(
  BuildContext context, {
  required WeeklyReviewRatingEntry entry,
}) {
  final reviewBloc = context.read<WeeklyReviewBloc>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) {
      return BlocProvider.value(
        value: reviewBloc,
        child: WeeklyRatingEvidenceSheet(entry: entry),
      );
    },
  );
}

class WeeklyRatingEvidenceSheet extends StatefulWidget {
  const WeeklyRatingEvidenceSheet({
    required this.entry,
    super.key,
  });

  final WeeklyReviewRatingEntry entry;

  @override
  State<WeeklyRatingEvidenceSheet> createState() =>
      _WeeklyRatingEvidenceSheetState();
}

class _WeeklyRatingEvidenceSheetState extends State<WeeklyRatingEvidenceSheet> {
  WeeklyReviewEvidenceRange _range = WeeklyReviewEvidenceRange.lastWeek;

  @override
  void initState() {
    super.initState();
    _requestEvidence();
  }

  void _requestEvidence() {
    context.read<WeeklyReviewBloc>().add(
      WeeklyReviewEvidenceRequested(
        valueId: widget.entry.value.id,
        range: _range,
      ),
    );
  }

  void _onRangeChanged(WeeklyReviewEvidenceRange range) {
    setState(() {
      _range = range;
    });
    _requestEvidence();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final accent = ColorUtils.valueColorForTheme(
      context,
      widget.entry.value.color,
    );
    final iconData =
        getIconDataFromName(widget.entry.value.iconName) ?? Icons.star;

    return BlocBuilder<WeeklyReviewBloc, WeeklyReviewState>(
      builder: (context, state) {
        final evidence = state.evidence;
        final currentEvidence =
            evidence != null &&
                evidence.valueId == widget.entry.value.id &&
                evidence.range == _range
            ? evidence
            : null;
        final status =
            currentEvidence?.status ?? WeeklyReviewEvidenceStatus.loading;
        final taskItems =
            currentEvidence?.taskItems ?? const <WeeklyReviewEvidenceItem>[];
        final routineItems =
            currentEvidence?.routineItems ?? const <WeeklyReviewEvidenceItem>[];

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            tokens.spaceLg,
            tokens.spaceSm,
            tokens.spaceLg,
            tokens.spaceXl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(iconData, color: accent),
                  SizedBox(width: tokens.spaceSm),
                  Expanded(
                    child: Text(
                      l10n.weeklyReviewEvidenceTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: tokens.spaceXs),
              Text(
                l10n.weeklyReviewEvidenceSubtitle(widget.entry.value.name),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: tokens.spaceMd),
              SegmentedButton<WeeklyReviewEvidenceRange>(
                segments: [
                  ButtonSegment(
                    value: WeeklyReviewEvidenceRange.lastWeek,
                    label: Text(l10n.weeklyReviewEvidenceRangeLastWeek),
                  ),
                  ButtonSegment(
                    value: WeeklyReviewEvidenceRange.last30Days,
                    label: Text(l10n.weeklyReviewEvidenceRange30Days),
                  ),
                  ButtonSegment(
                    value: WeeklyReviewEvidenceRange.last90Days,
                    label: Text(l10n.weeklyReviewEvidenceRange90Days),
                  ),
                ],
                selected: {_range},
                onSelectionChanged: (selection) {
                  if (selection.isEmpty) return;
                  _onRangeChanged(selection.first);
                },
              ),
              SizedBox(height: tokens.spaceLg),
              switch (status) {
                WeeklyReviewEvidenceStatus.loading => Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: tokens.spaceLg),
                    child: const CircularProgressIndicator(),
                  ),
                ),
                WeeklyReviewEvidenceStatus.failure => Padding(
                  padding: EdgeInsets.symmetric(vertical: tokens.spaceLg),
                  child: Text(
                    l10n.weeklyReviewEvidenceLoadError,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                WeeklyReviewEvidenceStatus.ready => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _EvidenceSection(
                      title: l10n.weeklyReviewEvidenceTasksTitle,
                      emptyLabel: l10n.weeklyReviewEvidenceTasksEmpty,
                      items: taskItems,
                    ),
                    SizedBox(height: tokens.spaceLg),
                    _EvidenceSection(
                      title: l10n.weeklyReviewEvidenceRoutinesTitle,
                      emptyLabel: l10n.weeklyReviewEvidenceRoutinesEmpty,
                      items: routineItems,
                    ),
                  ],
                ),
                WeeklyReviewEvidenceStatus.idle => const SizedBox.shrink(),
              },
            ],
          ),
        );
      },
    );
  }
}

class _EvidenceSection extends StatelessWidget {
  const _EvidenceSection({
    required this.title,
    required this.emptyLabel,
    required this.items,
  });

  final String title;
  final String emptyLabel;
  final List<WeeklyReviewEvidenceItem> items;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: tokens.spaceSm),
        if (items.isEmpty)
          Text(
            emptyLabel,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => SizedBox(height: tokens.spaceSm),
            itemBuilder: (context, index) {
              return _EvidenceItemRow(item: items[index]);
            },
          ),
      ],
    );
  }
}

class _EvidenceItemRow extends StatelessWidget {
  const _EvidenceItemRow({required this.item});

  final WeeklyReviewEvidenceItem item;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceMd,
        vertical: tokens.spaceSm,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (item.count > 1)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spaceSm,
                vertical: tokens.spaceXxs,
              ),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(tokens.radiusPill),
              ),
              child: Text(
                'x${item.count}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
