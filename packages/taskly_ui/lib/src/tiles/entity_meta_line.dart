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

    const spacing = 8.0;
    const projectNameMaxChars = 20;

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
          // --- Required slots: values + planned + due (no wrapping) ---
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

          final hasStart =
              model.showDates &&
              !model.showOnlyDeadlineDate &&
              model.startDateLabel != null &&
              model.startDateLabel!.trim().isNotEmpty;

          final hasDeadline =
              model.showDates &&
              model.deadlineDateLabel != null &&
              model.deadlineDateLabel!.trim().isNotEmpty;

          final startChip = hasStart
              ? DateChip.startDate(
                  context: context,
                  label: model.startDateLabel!,
                )
              : null;

          final deadlineChip = hasDeadline
              ? DateChip.deadline(
                  context: context,
                  label: model.deadlineDateLabel!,
                  isOverdue: model.isOverdue,
                  isDueToday: model.isDueToday,
                  isDueSoon: model.isDueSoon,
                )
              : null;

          // Reserve space for required chips by constraining them to a
          // reasonable fraction of the available width.
          final maxWidth = constraints.maxWidth;
          final hasBothDates = startChip != null && deadlineChip != null;

          final dateChipMaxWidth = hasBothDates
              ? maxWidth * 0.30
              : maxWidth * 0.50;

          final Widget? constrainedStart = startChip == null
              ? null
              : ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: dateChipMaxWidth),
                  child: _TapAbsorber(child: startChip),
                );

          final Widget? constrainedDeadline = deadlineChip == null
              ? null
              : ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: dateChipMaxWidth),
                  child: _TapAbsorber(child: deadlineChip),
                );

          // --- Optional extras (project / repeat / priority) with overflow ---
          final optionalWidgets = <Widget>[];
          var hiddenCount = 0;

          final hasProjectName =
              model.projectName != null && model.projectName!.trim().isNotEmpty;

          final projectName = hasProjectName
              ? _capWithEllipsis(model.projectName!.trim(), projectNameMaxChars)
              : null;

          final projectWidget = projectName == null
              ? null
              : _TapAbsorber(
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
                        projectName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.1,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    ],
                  ),
                );

          final repeatWidget = model.hasRepeat
              ? _TapAbsorber(
                  child: Icon(
                    Icons.sync_rounded,
                    size: 14,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
                  ),
                )
              : null;

          final priorityWidget =
              (model.showPriorityMarkerOnRight &&
                  (model.priority == 1 || model.priority == 2) &&
                  model.priorityColor != null)
              ? Tooltip(
                  message:
                      model.priorityPillLabel ?? 'Priority P${model.priority}',
                  child: _TapAbsorber(
                    child: PriorityMarker(color: model.priorityColor!),
                  ),
                )
              : null;

          // Always consider project first, then repeat, then priority.
          final candidateExtras = <Widget?>[
            projectWidget,
            repeatWidget,
            priorityWidget,
          ];

          // Compute remaining width after required content.
          final requiredWidth = _measureRequiredWidth(
            context,
            theme: theme,
            valueCluster: valueCluster,
            constrainedStart: constrainedStart,
            constrainedDeadline: constrainedDeadline,
            spacing: spacing,
          );

          var remaining = (maxWidth - requiredWidth).clamp(0.0, maxWidth);

          for (final extra in candidateExtras) {
            if (extra == null) continue;

            final extraWidth = _measureWidgetWidth(
              context,
              theme: theme,
              widget: extra,
            );

            final needsSpacing = optionalWidgets.isNotEmpty;
            final total = extraWidth + (needsSpacing ? spacing : 0);

            if (remaining >= total) {
              if (needsSpacing) {
                optionalWidgets.add(const SizedBox(width: spacing));
              }
              optionalWidgets.add(extra);
              remaining -= total;
            } else {
              hiddenCount += 1;
            }
          }

          final showEllipsis = hiddenCount > 0 || model.showOverflowEllipsis;

          final overflowWidget = !showEllipsis
              ? null
              : _TapAbsorber(
                  child: Text(
                    '…',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                      fontSize: 14,
                      height: 1,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                );

          if (overflowWidget != null) {
            final overflowWidth = _measureTextWidth(
              context,
              text: '…',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            );

            final needsSpacing = optionalWidgets.isNotEmpty;
            final total = overflowWidth + (needsSpacing ? spacing : 0);

            if (remaining >= total) {
              if (needsSpacing) {
                optionalWidgets.add(const SizedBox(width: spacing));
              }
              optionalWidgets.add(overflowWidget);
            }
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (valueCluster != null) _TapAbsorber(child: valueCluster),
              if (valueCluster != null &&
                  (constrainedStart != null || constrainedDeadline != null))
                const SizedBox(width: spacing),
              ?constrainedStart,
              if (constrainedStart != null && constrainedDeadline != null)
                const SizedBox(width: spacing),
              ?constrainedDeadline,
              if (optionalWidgets.isNotEmpty) const SizedBox(width: spacing),
              ...optionalWidgets,
            ],
          );
        },
      ),
    );
  }
}

String _capWithEllipsis(String text, int maxChars) {
  if (maxChars <= 0) return '…';
  if (text.length <= maxChars) return text;
  return '${text.substring(0, maxChars)}…';
}

double _measureRequiredWidth(
  BuildContext context, {
  required ThemeData theme,
  required Widget? valueCluster,
  required Widget? constrainedStart,
  required Widget? constrainedDeadline,
  required double spacing,
}) {
  // Conservative approximation: measure using known fixed sizes.
  // This is only used to decide whether optional extras can fit.
  var width = 0.0;

  if (valueCluster != null) {
    // Primary icon (18) + optional secondary icon (18) + internal spacing (6).
    final hasSecondary =
        (valueCluster is Row) && (valueCluster.children.length > 1);
    width += hasSecondary ? (18 + 6 + 18) : 18;
  }

  if (valueCluster != null &&
      (constrainedStart != null || constrainedDeadline != null)) {
    width += spacing;
  }

  if (constrainedStart != null) {
    width += (constrainedStart is ConstrainedBox)
        ? constrainedStart.constraints.maxWidth
        : 0;
  }

  if (constrainedStart != null && constrainedDeadline != null) {
    width += spacing;
  }

  if (constrainedDeadline != null) {
    width += (constrainedDeadline is ConstrainedBox)
        ? constrainedDeadline.constraints.maxWidth
        : 0;
  }

  return width;
}

double _measureTextWidth(
  BuildContext context, {
  required String text,
  required TextStyle? style,
}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: Directionality.of(context),
    maxLines: 1,
  )..layout();
  return painter.size.width;
}

double _measureWidgetWidth(
  BuildContext context, {
  required ThemeData theme,
  required Widget widget,
}) {
  // Measure only known widget types we generate above.
  // Fall back to a safe minimum width.
  switch (widget) {
    case _TapAbsorber(child: final Widget child):
      return _measureWidgetWidth(context, theme: theme, widget: child);
    case SizedBox(width: final w) when w != null:
      return w;
    case Icon(size: final s) when s != null:
      return s;
    case Tooltip(child: final Widget child):
      return _measureWidgetWidth(context, theme: theme, widget: child);
    case PriorityMarker(:final width):
      return width;
    case Row(children: final children):
      var w = 0.0;
      for (final c in children) {
        w += _measureWidgetWidth(context, theme: theme, widget: c);
      }
      return w;
    case Text(data: final data) when data != null:
      return _measureTextWidth(
        context,
        text: data,
        style: theme.textTheme.bodySmall,
      );
    default:
      return 20;
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
