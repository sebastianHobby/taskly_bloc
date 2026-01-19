import 'package:flutter/material.dart';

import 'package:taskly_ui/src/primitives/date_chip.dart';
import 'package:taskly_ui/src/primitives/priority_marker.dart';
import 'package:taskly_ui/src/models/value_chip_data.dart';
import 'package:taskly_ui/src/tiles/entity_tile_models.dart';

class EntityMetaLine extends StatelessWidget {
  const EntityMetaLine({required this.model, super.key});

  final EntityMetaLineModel model;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final hasAnyValues =
        model.showValuesInMetaLine &&
        (model.primaryValue != null || model.secondaryValues.isNotEmpty);

    final hasAnyDates =
        model.showDates &&
        (model.startDateLabel != null || model.deadlineDateLabel != null);

    if (!hasAnyValues &&
        !hasAnyDates &&
        !model.hasRepeat &&
        !model.showPriorityMarkerOnRight &&
        (model.projectName == null || model.projectName!.trim().isEmpty)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          Widget? valueCluster;
          if (model.showValuesInMetaLine) {
            final primaryValue = model.primaryValue;
            final secondaryValue = model.secondaryValues.isEmpty
                ? null
                : model.secondaryValues.first;

            if (primaryValue != null || secondaryValue != null) {
              valueCluster = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (primaryValue != null)
                    _ValueIcon(data: primaryValue, useValueColor: true),
                  if (secondaryValue != null) ...[
                    const SizedBox(width: 6),
                    _ValueIcon(data: secondaryValue, useValueColor: false),
                  ],
                ],
              );
            }
          }

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

          final hasProjectName =
              model.projectName != null && model.projectName!.trim().isNotEmpty;
          final hasOtherTokens =
              hasProjectName ||
              dateTokens.isNotEmpty ||
              model.hasRepeat ||
              (model.showPriorityMarkerOnRight &&
                  (model.priority == 1 || model.priority == 2) &&
                  model.priorityColor != null);

          final tokens = <Widget>[
            if (valueCluster != null) _TapAbsorber(child: valueCluster),
            if (valueCluster != null && hasOtherTokens)
              _TapAbsorber(
                child: Text(
                  '•',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                    fontSize: 12,
                    height: 1,
                  ),
                ),
              ),
            if (hasProjectName)
              _TapAbsorber(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.folder_outlined,
                      size: 12,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      model.projectName!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.1,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ...dateTokens,
            if (model.hasRepeat)
              _TapAbsorber(
                child: Icon(
                  Icons.sync_rounded,
                  size: 14,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
                ),
              ),
            if (model.showPriorityMarkerOnRight)
              if (model.priority == 1 || model.priority == 2)
                if (model.priorityColor != null)
                  Tooltip(
                    message:
                        model.priorityPillLabel ??
                        'Priority P${model.priority}',
                    child: _TapAbsorber(
                      child: PriorityMarker(color: model.priorityColor!),
                    ),
                  ),
          ];

          return Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: tokens,
          );
        },
      ),
    );
  }
}

class _ValueIcon extends StatelessWidget {
  const _ValueIcon({required this.data, required this.useValueColor});

  final ValueChipData data;
  final bool useValueColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = useValueColor
        ? data.color.withValues(alpha: 0.95)
        : scheme.onSurfaceVariant.withValues(alpha: 0.7);

    return Tooltip(
      message: data.label,
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.8), width: 1.25),
        ),
        child: Center(
          child: Icon(data.icon, size: 12, color: color.withValues(alpha: 1)),
        ),
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
