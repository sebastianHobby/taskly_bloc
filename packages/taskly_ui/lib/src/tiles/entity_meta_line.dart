import 'package:flutter/material.dart';

import 'package:taskly_ui/src/primitives/value_chip.dart';
import 'package:taskly_ui/src/primitives/value_chip_widget.dart';
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
            variant: ValueChipVariant.outlined,
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
          leftChildren.add(
            _ValueDotsCluster(
              values: model.secondaryValues,
              maxDots: model.maxSecondaryValues,
              onTap: model.onTapValues,
            ),
          );
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
                  child: _TapAbsorber(child: PriorityMarker(color: color)),
                ),
              );
            }
          }

          if (model.hasRepeat) {
            final repeatIcon = _TapAbsorber(
              child: Icon(
                Icons.sync_rounded,
                size: 14,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
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
              _TapAbsorber(
                child: Icon(
                  Icons.more_horiz_rounded,
                  size: 16,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            );
          }
          rightTokens.addAll(dateTokens);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing:
                      model.secondaryValuePresentation ==
                          EntitySecondaryValuePresentation.dotsCluster
                      ? 6
                      : 12,
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
    final scheme = Theme.of(context).colorScheme;

    final dotsToShow = values.take(maxDots).toList(growable: false);

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(dotsToShow.length, (index) {
        final v = dotsToShow[index];
        return Padding(
          padding: EdgeInsets.only(left: index == 0 ? 0 : 2),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: v.color.withValues(alpha: 0.85),
              shape: BoxShape.circle,
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
          ),
        );
      }),
    );

    final tooltip = values.map((v) => v.label).join(', ');

    final result = Tooltip(
      message: tooltip,
      child: content,
    );

    if (onTap == null) return result;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
        child: result,
      ),
    );
  }
}

class _TapAbsorber extends StatelessWidget {
  const _TapAbsorber({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: child,
    );
  }
}
