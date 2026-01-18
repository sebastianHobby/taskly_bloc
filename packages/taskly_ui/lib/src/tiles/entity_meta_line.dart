import 'package:flutter/material.dart';

import 'package:taskly_ui/src/entities/value_chip.dart';
import 'package:taskly_ui/src/primitives/date_chip.dart';
import 'package:taskly_ui/src/primitives/priority_marker.dart';
import 'package:taskly_ui/src/tiles/entity_tile_models.dart';

class EntityMetaLine extends StatelessWidget {
  const EntityMetaLine({required this.model, super.key});

  final EntityMetaLineModel model;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final leftChildren = <Widget>[];

    final primary = model.primaryValue;
    if (primary != null) {
      leftChildren.add(
        Tooltip(
          message: primary.label,
          child: ValueChip(
            data: primary,
            variant: ValueChipVariant.solid,
            iconOnly: model.primaryValueIconOnly,
            onTap: model.onTapValues,
          ),
        ),
      );
    }

    if (model.secondaryValues.isNotEmpty) {
      switch (model.secondaryValuePresentation) {
        case EntitySecondaryValuePresentation.singleOutlinedIconOnly:
          final v = model.secondaryValues.first;
          leftChildren.add(
            Tooltip(
              message: v.label,
              child: ValueChip(
                data: v,
                variant: ValueChipVariant.outlined,
                iconOnly: true,
                onTap: model.onTapValues,
              ),
            ),
          );
        case EntitySecondaryValuePresentation.dotsCluster:
          final allNames = model.secondaryValues.map((v) => v.label).join(', ');
          if (model.collapseSecondaryValuesToCount) {
            leftChildren.add(
              Tooltip(
                message: allNames,
                child: _CountPill(label: '+${model.secondaryValues.length}'),
              ),
            );
          } else {
            final remaining =
                model.secondaryValues.length -
                model.secondaryValues.take(model.maxSecondaryValues).length;

            leftChildren.add(
              _ValueDotsCluster(
                values: model.secondaryValues,
                maxDots: model.maxSecondaryValues,
                onTap: model.onTapValues,
              ),
            );

            if (remaining > 0) {
              leftChildren.add(
                Tooltip(
                  message: allNames,
                  child: _CountPill(label: '+$remaining'),
                ),
              );
            }
          }
      }
    }

    final hasAnyDates =
        model.showDates &&
        (model.startDateLabel != null || model.deadlineDateLabel != null);

    if (leftChildren.isEmpty && !hasAnyDates) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dateTokens = <Widget>[];
          if (model.showDates) {
            final shouldShowBoth =
                model.showBothDatesIfPresent ||
                (model.startDateLabel != null &&
                    model.deadlineDateLabel != null &&
                    constraints.maxWidth >= 420);

            if (!model.showOnlyDeadlineDate &&
                model.startDateLabel != null &&
                (model.deadlineDateLabel == null || shouldShowBoth)) {
              dateTokens.add(
                DateChip.startDate(
                  context: context,
                  label: model.startDateLabel!,
                ),
              );
            }

            if (model.deadlineDateLabel != null) {
              dateTokens.add(
                DateChip.deadline(
                  context: context,
                  label: model.deadlineDateLabel!,
                  isOverdue: model.isOverdue,
                  isDueToday: model.isDueToday,
                  isDueSoon: model.isDueSoon,
                ),
              );
            }
          }

          final statusTokens = <Widget>[];

          if (model.showPriorityMarkerOnRight) {
            final p = model.priority;
            final color = model.priorityColor;
            if ((p == 1 || p == 2) && color != null) {
              statusTokens.add(
                Tooltip(
                  message: model.priorityPillLabel ?? 'Priority P$p',
                  child: PriorityMarker(color: color),
                ),
              );
            }
          }

          if (model.hasRepeat) {
            final repeatIcon = Icon(
              Icons.sync_rounded,
              size: 14,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
            );

            if (model.showRepeatOnRight) {
              statusTokens.add(repeatIcon);
            } else {
              leftChildren.add(repeatIcon);
            }
          }

          final showStatusTokens =
              !model.enableRightOverflowDemotion || constraints.maxWidth >= 360;
          final showOverflowIndicator =
              model.showOverflowIndicatorOnRight && !showStatusTokens;

          final rightTokens = <Widget>[];
          if (showStatusTokens) {
            rightTokens.addAll(statusTokens);
          } else if (showOverflowIndicator && statusTokens.isNotEmpty) {
            rightTokens.add(
              Icon(
                Icons.more_horiz_rounded,
                size: 16,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            );
          }
          rightTokens.addAll(dateTokens);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: leftChildren,
                ),
              ),
              if (rightTokens.isNotEmpty) ...[
                const SizedBox(width: 12),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 12,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: rightTokens,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outlineVariant),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      constraints: const BoxConstraints(minHeight: 20),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 10,
          height: 1.1,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ValueDotsCluster extends StatelessWidget {
  const _ValueDotsCluster({
    required this.values,
    required this.maxDots,
    this.onTap,
  });

  final List<ValueChipData> values;
  final int maxDots;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final dotsToShow = values.take(maxDots).toList(growable: false);

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final v in dotsToShow) ...[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: v.color.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ],
    );

    final wrapped = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.9),
        ),
      ),
      child: content,
    );

    final tooltip = values.map((v) => v.label).join(', ');

    final result = Tooltip(
      message: tooltip,
      child: wrapped,
    );

    if (onTap == null) return result;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: result,
    );
  }
}
