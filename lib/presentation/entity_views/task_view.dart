import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_bloc/domain/screens/templates/params/entity_style_v1.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_bloc/domain/entity_views/tile_capabilities/entity_tile_capabilities.dart';
import 'package:taskly_bloc/presentation/shared/formatters/date_label_formatter.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/screens/tiles/tile_intent.dart';
import 'package:taskly_bloc/presentation/screens/tiles/tile_intent_dispatcher.dart';
import 'package:taskly_bloc/presentation/screens/tiles/tile_overflow_action_catalog.dart';
import 'package:taskly_bloc/presentation/theme/app_colors.dart';
import 'package:taskly_bloc/presentation/widgets/widgets.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';

enum TaskViewVariant {
  /// Default list-row style used across most list templates.
  list,

  /// Rounded card variant intended for the Scheduled agenda.
  agendaCard,
}

/// The canonical, entity-level task UI entrypoint.
///
/// Per-screen customization should happen by selecting an entity-level
/// variant (added later) rather than by re-implementing field rendering.
class TaskView extends StatelessWidget {
  const TaskView({
    required this.task,
    required this.tileCapabilities,
    this.onTap,
    this.compact = false,
    this.isInFocus = false,
    this.variant = TaskViewVariant.list,
    this.agendaMetaDensity = AgendaMetaDensityV1.full,
    this.agendaPriorityEncoding = AgendaPriorityEncodingV1.explicitPill,
    this.agendaActionsVisibility = AgendaActionsVisibilityV1.always,
    this.agendaPrimaryValueIconOnly = false,
    this.agendaMaxSecondaryValues = 2,
    this.agendaShowDeadlineChipOnOngoing = true,
    this.titlePrefix,
    this.statusBadge,
    this.trailing,
    this.accentColor,
    this.agendaInProgressStyle = false,
    this.endDate,
    super.key,
  });

  final Task task;

  /// Domain-sourced capability policy for this tile.
  final EntityTileCapabilities tileCapabilities;

  /// Optional tap handler. If null, navigates to task detail.
  final void Function(Task task)? onTap;

  /// Whether to use a compact (2-row) layout.
  final bool compact;

  /// Whether this task is considered in focus for the current screen.
  final bool isInFocus;

  /// Visual variant.
  final TaskViewVariant variant;

  /// Agenda-only: how dense the meta line should be.
  final AgendaMetaDensityV1 agendaMetaDensity;

  /// Agenda-only: how priority should be encoded.
  ///
  /// Note: list-row variants may also read this to keep priority affordances
  /// consistent across screen templates.
  final AgendaPriorityEncodingV1 agendaPriorityEncoding;

  /// Agenda-only: how row actions should be surfaced.
  final AgendaActionsVisibilityV1 agendaActionsVisibility;

  /// Agenda-only: render primary value as icon-only.
  final bool agendaPrimaryValueIconOnly;

  /// Agenda-only: max number of secondary value chips before summarizing.
  final int agendaMaxSecondaryValues;

  /// Agenda-only: on Ongoing rows, show a deadline chip.
  final bool agendaShowDeadlineChipOnOngoing;

  /// Optional widget shown inline before the task title.
  final Widget? titlePrefix;

  /// Optional status badge shown to the right of the title.
  final Widget? statusBadge;

  /// Optional trailing control.
  final Widget? trailing;

  /// Optional accent color used by [TaskViewVariant.agendaCard].
  final Color? accentColor;

  /// Whether to render the agenda card with dashed outline + end marker.
  ///
  /// Intended for in-progress items in the Scheduled agenda.
  final bool agendaInProgressStyle;

  /// Optional end date for the in-progress end-day marker.
  final DateTime? endDate;

  bool _isOverdue(DateTime? deadline) {
    if (deadline == null || task.completed) return false;
    final now = getIt<NowService>().nowLocal();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
    return deadlineDay.isBefore(today);
  }

  bool _isDueToday(DateTime? deadline) {
    if (deadline == null || task.completed) return false;
    final now = getIt<NowService>().nowLocal();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
    return deadlineDay.isAtSameMomentAs(today);
  }

  bool _isDueSoon(DateTime? deadline) {
    if (deadline == null || task.completed) return false;
    final now = getIt<NowService>().nowLocal();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
    final daysUntil = deadlineDay.difference(today).inDays;
    return daysUntil > 0 && daysUntil <= 3;
  }

  @override
  Widget build(BuildContext context) {
    return switch (variant) {
      TaskViewVariant.list => _buildListRow(context),
      TaskViewVariant.agendaCard => _buildAgendaCard(context),
    };
  }

  void _dispatchCompletion(BuildContext context, bool? value) {
    if (!tileCapabilities.canToggleCompletion) return;

    final dispatcher = context.read<TileIntentDispatcher>();
    final completed = value ?? false;

    final occurrenceDate = task.occurrence?.date;
    final originalOccurrenceDate =
        task.occurrence?.originalDate ?? occurrenceDate;

    unawaited(
      dispatcher.dispatch(
        context,
        TileIntentSetCompletion(
          entityType: EntityType.task,
          entityId: task.id,
          completed: completed,
          scope: tileCapabilities.completionScope,
          occurrenceDate: occurrenceDate,
          originalOccurrenceDate: originalOccurrenceDate,
        ),
      ),
    );
  }

  Widget _buildListRow(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final effectivePrimaryValue = task.effectivePrimaryValue;
    final effectiveSecondaryValues = task.effectiveSecondaryValues;

    final isOverdue = _isOverdue(task.deadlineDate);
    final isDueToday = _isDueToday(task.deadlineDate);
    final isDueSoon = _isDueSoon(task.deadlineDate);

    final resolvedOnTap =
        onTap ??
        (tileCapabilities.canOpenDetails
            ? (Task task) => Routing.toEntity(context, EntityType.task, task.id)
            : null);

    final titlePriorityPrefix = _priorityTitlePrefix(context);
    final titleFontWeight = _priorityTitleWeight();

    return Container(
      key: Key('task-${task.id}'),
      decoration: BoxDecoration(
        color: task.completed
            ? scheme.surfaceContainerLowest.withValues(alpha: 0.5)
            : scheme.surface,
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: InkWell(
        onTap: resolvedOnTap == null ? null : () => resolvedOnTap(task),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: compact ? 10 : 12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox.square(
                dimension: 44,
                child: Center(
                  child: _TaskCheckbox(
                    completed: task.completed,
                    isOverdue: isOverdue,
                    onChanged: tileCapabilities.canToggleCompletion
                        ? (value) => _dispatchCompletion(context, value)
                        : null,
                    taskName: task.name,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (titlePriorityPrefix != null) ...[
                          titlePriorityPrefix,
                          const SizedBox(width: 8),
                        ],
                        if (titlePrefix != null) ...[
                          titlePrefix!,
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            task.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: titleFontWeight,
                              decoration: task.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: task.completed
                                  ? scheme.onSurface.withValues(alpha: 0.5)
                                  : scheme.onSurface,
                            ),
                            maxLines: compact ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    _MetaLine(
                      primaryValue: effectivePrimaryValue,
                      projectName: task.project?.name,
                      projectId: task.projectId,
                      startDate: task.startDate,
                      deadlineDate: task.deadlineDate,
                      isOverdue: isOverdue,
                      isDueToday: isDueToday,
                      isDueSoon: isDueSoon,
                      formatDate: DateLabelFormatter.format,
                      hasRepeat: task.repeatIcalRrule != null,
                      secondaryValues: effectiveSecondaryValues,
                      priority: task.priority,
                      priorityEncoding: agendaPriorityEncoding,
                      primaryValueIconOnly: false,
                      collapseSecondaryValuesToCount: false,
                      showRepeatOnRight: true,
                      showBothDatesIfPresent: true,
                      onTapValues: () {
                        if (!tileCapabilities.canAlignValues) return;
                        final dispatcher = context.read<TileIntentDispatcher>();
                        unawaited(
                          dispatcher.dispatch(
                            context,
                            TileIntentOpenEditor(
                              entityType: EntityType.task,
                              entityId: task.id,
                              openToValues: true,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 72,
                child: Align(
                  alignment: Alignment.topRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (trailing != null) ...[
                        trailing!,
                        const SizedBox(width: 8),
                      ],
                      _TaskTodayStatusMenuButton(
                        taskId: task.id,
                        taskName: task.name,
                        isPinnedToMyDay: task.isPinned,
                        isInMyDayAuto: isInFocus,
                        tileCapabilities: tileCapabilities,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgendaCard(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final effectivePrimaryValue = task.effectivePrimaryValue;
    final effectiveSecondaryValues = task.effectiveSecondaryValues;

    final isOverdue = _isOverdue(task.deadlineDate);
    final isDueToday = _isDueToday(task.deadlineDate);
    final isDueSoon = _isDueSoon(task.deadlineDate);

    final effectiveAccent = accentColor ?? (isInFocus ? scheme.primary : null);
    final outline = scheme.outlineVariant.withValues(alpha: 0.35);

    final endDay = _endDayLabel(context);

    final backgroundColor = isInFocus
        ? Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.06),
            scheme.surfaceContainerLow,
          )
        : scheme.surfaceContainerLow;

    final resolvedOnTap =
        onTap ??
        (tileCapabilities.canOpenDetails
            ? (Task task) => Routing.toEntity(context, EntityType.task, task.id)
            : null);

    final titlePriorityPrefix = _priorityTitlePrefix(context);
    final titleFontWeight = _priorityTitleWeight();

    return Material(
      key: Key('task-${task.id}'),
      color: Colors.transparent,
      child: InkWell(
        onTap: resolvedOnTap == null ? null : () => resolvedOnTap(task),
        borderRadius: BorderRadius.circular(16),
        child: _AgendaCardContainer(
          dashedOutline: agendaInProgressStyle,
          accentColor: effectiveAccent,
          outlineColor: outline,
          backgroundColor: backgroundColor,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              agendaInProgressStyle ? 28 : 14,
              14,
              14,
              14,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: _TaskCheckbox(
                    completed: task.completed,
                    isOverdue: isOverdue,
                    onChanged: tileCapabilities.canToggleCompletion
                        ? (value) => _dispatchCompletion(context, value)
                        : null,
                    taskName: task.name,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (titlePriorityPrefix != null) ...[
                            titlePriorityPrefix,
                            const SizedBox(width: 8),
                          ],
                          if (titlePrefix != null) ...[
                            titlePrefix!,
                            const SizedBox(width: 10),
                          ],
                          Expanded(
                            child: Text(
                              task.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: titleFontWeight,
                                decoration: task.completed
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: task.completed
                                    ? scheme.onSurface.withValues(alpha: 0.5)
                                    : scheme.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (statusBadge != null) ...[
                            const SizedBox(width: 10),
                            statusBadge!,
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _MetaLine(
                              primaryValue: effectivePrimaryValue,
                              projectName: task.project?.name,
                              projectId: task.projectId,
                              startDate: task.startDate,
                              deadlineDate: task.deadlineDate,
                              isOverdue: isOverdue,
                              isDueToday: isDueToday,
                              isDueSoon: isDueSoon,
                              showDates: !agendaInProgressStyle,
                              formatDate: DateLabelFormatter.format,
                              hasRepeat: task.repeatIcalRrule != null,
                              secondaryValues: effectiveSecondaryValues,
                              priority: task.priority,
                              priorityEncoding: agendaPriorityEncoding,
                              primaryValueIconOnly: agendaPrimaryValueIconOnly,
                              maxSecondaryValues: agendaMaxSecondaryValues,
                              metaDensity: agendaMetaDensity,
                              collapseSecondaryValuesToCount: false,
                              showRepeatOnRight: true,
                              showBothDatesIfPresent: false,
                              onTapValues: () {
                                if (!tileCapabilities.canAlignValues) return;
                                final dispatcher = context
                                    .read<TileIntentDispatcher>();
                                unawaited(
                                  dispatcher.dispatch(
                                    context,
                                    TileIntentOpenEditor(
                                      entityType: EntityType.task,
                                      entityId: task.id,
                                      openToValues: true,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          if (agendaInProgressStyle && endDay != null) ...[
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 72,
                              child: Align(
                                alignment: Alignment.topRight,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (trailing != null) ...[
                                      trailing!,
                                      const SizedBox(width: 8),
                                    ],
                                    _TaskTodayStatusMenuButton(
                                      taskId: task.id,
                                      taskName: task.name,
                                      isPinnedToMyDay: task.isPinned,
                                      isInMyDayAuto: isInFocus,
                                      compact: true,
                                      tileCapabilities: tileCapabilities,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            _EndDayMarker(label: endDay),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _endDayLabel(BuildContext context) {
    final end = endDate;
    if (end == null) return null;
    final locale = Localizations.localeOf(context);
    return DateFormat.E(locale.toLanguageTag()).format(end);
  }

  Widget? _priorityTitlePrefix(BuildContext context) {
    if (agendaPriorityEncoding != AgendaPriorityEncodingV1.subtleDot) {
      return null;
    }

    final p = task.priority;
    if (p == null) return null;

    final scheme = Theme.of(context).colorScheme;
    final color = _priorityColorFor(scheme, p);
    final label = 'Priority P$p';

    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  FontWeight _priorityTitleWeight() {
    if (agendaPriorityEncoding != AgendaPriorityEncodingV1.subtleTitleWeight) {
      return FontWeight.w600;
    }

    return switch (task.priority) {
      1 => FontWeight.w800,
      2 => FontWeight.w700,
      3 => FontWeight.w600,
      4 => FontWeight.w600,
      _ => FontWeight.w600,
    };
  }
}

class _AgendaCardContainer extends StatelessWidget {
  const _AgendaCardContainer({
    required this.child,
    required this.backgroundColor,
    required this.outlineColor,
    this.accentColor,
    this.dashedOutline = false,
  });

  final Widget child;
  final Color backgroundColor;
  final Color outlineColor;
  final Color? accentColor;
  final bool dashedOutline;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);

    if (!dashedOutline) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: radius,
          border: accentColor != null
              ? Border(
                  left: BorderSide(color: accentColor!, width: 4),
                  top: BorderSide(color: outlineColor),
                  right: BorderSide(color: outlineColor),
                  bottom: BorderSide(color: outlineColor),
                )
              : Border.all(color: outlineColor),
        ),
        child: child,
      );
    }

    final dashColor =
        Color.lerp(
          accentColor ?? outlineColor,
          outlineColor,
          0.35,
        )?.withValues(alpha: 0.85) ??
        outlineColor;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(color: backgroundColor),
          child: CustomPaint(
            foregroundPainter: _DashedRoundedRectPainter(
              color: dashColor,
              strokeWidth: 1.2,
              radius: 16,
              dashLength: 6,
              gapLength: 4,
            ),
            child: Stack(
              children: [
                if (accentColor != null)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 4,
                    child: ColoredBox(color: accentColor!),
                  ),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EndDayMarker extends StatelessWidget {
  const _EndDayMarker({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.hourglass_bottom_rounded,
          size: 16,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 10,
            height: 1.1,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _DashedRoundedRectPainter extends CustomPainter {
  const _DashedRoundedRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
    required this.dashLength,
    required this.gapLength,
  });

  final Color color;
  final double strokeWidth;
  final double radius;
  final double dashLength;
  final double gapLength;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color;

    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashLength;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0.0, metric.length)),
          paint,
        );
        distance = next + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.radius != radius ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.gapLength != gapLength;
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.formatDate,
    required this.secondaryValues,
    required this.priority,
    // ignore: unused_element_parameter
    this.layout = _MetaLineLayout.singleWrap,
    this.primaryValue,
    this.projectName,
    this.projectId,
    this.startDate,
    this.deadlineDate,
    this.isOverdue = false,
    this.isDueToday = false,
    this.isDueSoon = false,
    this.hasRepeat = false,
    this.showDates = true,
    this.metaDensity = AgendaMetaDensityV1.full,
    this.priorityEncoding = AgendaPriorityEncodingV1.explicitPill,
    this.primaryValueIconOnly = false,
    this.maxSecondaryValues = 2,
    this.collapseSecondaryValuesToCount = false,
    this.showRepeatOnRight = false,
    this.showBothDatesIfPresent = false,
    this.onTapValues,
  });

  final Value? primaryValue;
  final String? projectName;
  final String? projectId;
  final DateTime? startDate;
  final DateTime? deadlineDate;
  final _MetaLineLayout layout;
  final bool isOverdue;
  final bool isDueToday;
  final bool isDueSoon;
  final bool hasRepeat;
  final bool showDates;
  final AgendaMetaDensityV1 metaDensity;
  final AgendaPriorityEncodingV1 priorityEncoding;
  final String Function(BuildContext, DateTime) formatDate;
  final List<Value> secondaryValues;
  final int? priority;
  final bool primaryValueIconOnly;
  final int maxSecondaryValues;
  final bool collapseSecondaryValuesToCount;
  final bool showRepeatOnRight;
  final bool showBothDatesIfPresent;
  final VoidCallback? onTapValues;

  Color _priorityColor(ColorScheme scheme, int p) =>
      _priorityColorFor(scheme, p);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final effectiveExpanded = switch (metaDensity) {
      AgendaMetaDensityV1.full => true,
      AgendaMetaDensityV1.minimal => false,

      // Task tiles don't currently implement an expansion affordance.
      // Treat "expandable" density as collapsed.
      AgendaMetaDensityV1.minimalExpandable => false,
    };

    final leftChildren = <Widget>[];

    final valueLineChildren = <Widget>[];

    final otherMetaChildren = <Widget>[];

    final pValue = primaryValue;
    if (pValue != null) {
      final valueChip = Tooltip(
        message: pValue.name,
        child: ValueChip(
          value: pValue,
          variant: ValueChipVariant.solid,
          iconOnly: primaryValueIconOnly,
          onTap: onTapValues,
        ),
      );

      if (layout == _MetaLineLayout.splitPinnedDates) {
        valueLineChildren.add(valueChip);
      } else {
        leftChildren.add(valueChip);
      }
    }

    if (secondaryValues.isNotEmpty) {
      final allNames = secondaryValues.map((v) => v.name).join(', ');
      if (collapseSecondaryValuesToCount || !effectiveExpanded) {
        final countPill = Tooltip(
          message: allNames,
          child: _CountPill(
            label: '+${secondaryValues.length}',
            onTap: onTapValues,
          ),
        );

        if (layout == _MetaLineLayout.splitPinnedDates) {
          valueLineChildren.add(countPill);
        } else {
          leftChildren.add(countPill);
        }
      } else {
        final remaining =
            secondaryValues.length -
            secondaryValues.take(maxSecondaryValues).length;

        final dots = ValueDotsCluster(
          values: secondaryValues,
          maxDots: maxSecondaryValues,
          onTap: onTapValues,
        );

        if (layout == _MetaLineLayout.splitPinnedDates) {
          valueLineChildren.add(dots);
        } else {
          leftChildren.add(dots);
        }

        if (remaining > 0) {
          final remainingPill = Tooltip(
            message: allNames,
            child: _CountPill(
              label: '+$remaining',
              onTap: onTapValues,
            ),
          );

          if (layout == _MetaLineLayout.splitPinnedDates) {
            valueLineChildren.add(remainingPill);
          } else {
            leftChildren.add(remainingPill);
          }
        }
      }
    }

    final p = priority;
    if (p != null &&
        priorityEncoding == AgendaPriorityEncodingV1.explicitPill) {
      final priorityPill = Tooltip(
        message: 'Priority P$p',
        child: _CountPill(
          label: 'P$p',
          foregroundColor: _priorityColor(scheme, p),
        ),
      );

      if (layout == _MetaLineLayout.splitPinnedDates) {
        otherMetaChildren.add(priorityPill);
      } else {
        leftChildren.add(priorityPill);
      }
    }

    final pName = projectName?.trim();
    if (pName != null && pName.isNotEmpty) {
      final projectPill = ProjectPill(
        projectName: pName,
        onTap: projectId == null
            ? null
            : () {
                Routing.toEntity(context, EntityType.project, projectId!);
              },
      );

      if (layout == _MetaLineLayout.splitPinnedDates) {
        otherMetaChildren.add(projectPill);
      } else {
        leftChildren.add(projectPill);
      }
    } else if (projectId == null || projectId!.isEmpty) {
      const inboxPill = ProjectPill(projectName: 'Inbox');
      if (layout == _MetaLineLayout.splitPinnedDates) {
        otherMetaChildren.add(inboxPill);
      } else {
        leftChildren.add(inboxPill);
      }
    }

    final hasAnyDates =
        showDates && (startDate != null || deadlineDate != null);

    final hasAnyMeta = switch (layout) {
      _MetaLineLayout.singleWrap => leftChildren.isNotEmpty,
      _MetaLineLayout.splitPinnedDates =>
        valueLineChildren.isNotEmpty || otherMetaChildren.isNotEmpty,
    };

    if (!hasAnyMeta && !hasAnyDates) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dateTokens = <Widget>[];
          if (showDates) {
            final shouldShowBoth =
                showBothDatesIfPresent ||
                (startDate != null &&
                    deadlineDate != null &&
                    constraints.maxWidth >= 420);

            if (startDate != null && (deadlineDate == null || shouldShowBoth)) {
              dateTokens.add(
                DateChip.startDate(
                  context: context,
                  label: formatDate(context, startDate!),
                ),
              );
            }
            if (deadlineDate != null) {
              dateTokens.add(
                DateChip.deadline(
                  context: context,
                  label: formatDate(context, deadlineDate!),
                  isOverdue: isOverdue,
                  isDueToday: isDueToday,
                  isDueSoon: isDueSoon,
                ),
              );
            }
          }

          final repeatIcon = hasRepeat && effectiveExpanded
              ? Icon(
                  Icons.sync_rounded,
                  size: 14,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                )
              : null;

          if (layout == _MetaLineLayout.splitPinnedDates) {
            final line1Left = valueLineChildren;

            final line2 = <Widget>[
              if (hasRepeat && repeatIcon != null && !showRepeatOnRight)
                repeatIcon,
              ...otherMetaChildren,
              if (hasRepeat && repeatIcon != null && showRepeatOnRight)
                repeatIcon,
            ];

            final showLine1 = line1Left.isNotEmpty || dateTokens.isNotEmpty;
            final showLine2 = line2.isNotEmpty;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showLine1)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: line1Left,
                        ),
                      ),
                      if (dateTokens.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 12,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: dateTokens,
                        ),
                      ],
                    ],
                  ),
                if (showLine1 && showLine2) const SizedBox(height: 6),
                if (showLine2)
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: line2,
                  ),
              ],
            );
          }

          final rightTokens = <Widget>[];
          if (hasRepeat && showRepeatOnRight && repeatIcon != null) {
            rightTokens.add(repeatIcon);
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

enum _MetaLineLayout {
  singleWrap,
  splitPinnedDates,
}

Color _priorityColorFor(ColorScheme scheme, int p) {
  return switch (p) {
    1 => AppColors.rambutan80,
    2 => AppColors.cempedak80,
    3 => AppColors.blueberry80,
    4 => scheme.onSurfaceVariant,
    _ => scheme.onSurfaceVariant,
  };
}

class _CountPill extends StatelessWidget {
  const _CountPill({
    required this.label,
    this.onTap,
    this.foregroundColor,
  });

  final String label;
  final VoidCallback? onTap;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = foregroundColor ?? scheme.onSurfaceVariant;

    final content = Container(
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
          color: fg,
        ),
      ),
    );

    if (onTap == null) return content;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: content,
    );
  }
}

class _TaskTodayStatusMenuButton extends StatelessWidget {
  const _TaskTodayStatusMenuButton({
    required this.taskId,
    required this.taskName,
    required this.isPinnedToMyDay,
    required this.isInMyDayAuto,
    required this.tileCapabilities,
    this.compact = false,
  });

  final String taskId;
  final String taskName;
  final bool isPinnedToMyDay;
  final bool isInMyDayAuto;
  final EntityTileCapabilities tileCapabilities;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final statusLabel = switch ((isPinnedToMyDay, isInMyDayAuto)) {
      (true, _) => 'Pinned to My Day',
      (false, true) => 'In My Day',
      _ => null,
    };

    final statusIcon = switch ((isPinnedToMyDay, isInMyDayAuto)) {
      (true, _) => Icons.push_pin,
      (false, true) => Icons.wb_sunny_outlined,
      _ => null,
    };

    final iconColor = scheme.onSurfaceVariant.withValues(alpha: 0.85);

    final statusWidget = (statusIcon == null)
        ? null
        : Tooltip(
            message: statusLabel,
            child: Semantics(
              label: statusLabel,
              child: Icon(
                statusIcon,
                size: compact ? 18 : 20,
                color: iconColor,
              ),
            ),
          );

    final actions = TileOverflowActionCatalog.forTask(
      taskId: taskId,
      taskName: taskName,
      isPinnedToMyDay: isPinnedToMyDay,
      tileCapabilities: tileCapabilities,
    );

    final hasAnyEnabledAction = actions.any((a) => a.enabled);
    if (!hasAnyEnabledAction) {
      return statusWidget ?? const SizedBox.shrink();
    }

    return PopupMenuButton<TileOverflowActionId>(
      tooltip: 'More',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (statusWidget != null) ...[
              statusWidget,
              const SizedBox(width: 8),
            ],
            Icon(
              Icons.more_horiz,
              size: compact ? 18 : 20,
              color: iconColor,
            ),
          ],
        ),
      ),
      onSelected: (actionId) async {
        final dispatcher = context.read<TileIntentDispatcher>();
        final action = actions.firstWhere((a) => a.id == actionId);

        AppLog.routineThrottledStructured(
          'tile_overflow.task.${actionId.name}.$taskId',
          const Duration(seconds: 2),
          'tile_overflow',
          'selected',
          fields: {
            'entityType': 'task',
            'entityId': taskId,
            'action': actionId.name,
          },
        );

        return dispatcher.dispatch(context, action.intent);
      },
      itemBuilder: (context) {
        final items = <PopupMenuEntry<TileOverflowActionId>>[];
        TileOverflowActionGroup? lastGroup;

        for (final action in actions) {
          if (lastGroup != null && action.group != lastGroup) {
            if (items.isNotEmpty) items.add(const PopupMenuDivider());
          }
          lastGroup = action.group;

          items.add(
            PopupMenuItem<TileOverflowActionId>(
              value: action.id,
              enabled: action.enabled,
              child: Text(action.label),
            ),
          );
        }

        return items;
      },
    );
  }
}

class _TaskCheckbox extends StatelessWidget {
  const _TaskCheckbox({
    required this.completed,
    required this.isOverdue,
    required this.onChanged,
    required this.taskName,
  });

  final bool completed;
  final bool isOverdue;
  final ValueChanged<bool?>? onChanged;
  final String taskName;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: completed
          ? 'Mark "$taskName" as incomplete'
          : 'Mark "$taskName" as complete',
      child: SizedBox(
        width: 24,
        height: 24,
        child: Checkbox(
          value: completed,
          onChanged: onChanged == null
              ? null
              : (bool? value) {
                  HapticFeedback.lightImpact();
                  onChanged!(value);
                },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          side: BorderSide(
            color: isOverdue
                ? colorScheme.error
                : completed
                ? colorScheme.primary
                : colorScheme.outline,
            width: 2,
          ),
          activeColor: colorScheme.primary,
          checkColor: colorScheme.onPrimary,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
