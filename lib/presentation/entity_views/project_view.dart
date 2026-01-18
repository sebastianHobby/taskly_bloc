import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_bloc/domain/screens/templates/params/entity_style_v1.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/screens/tiles/tile_intent.dart';
import 'package:taskly_bloc/presentation/screens/tiles/tile_intent_dispatcher.dart';
import 'package:taskly_bloc/presentation/screens/tiles/tile_overflow_action_catalog.dart';
import 'package:taskly_bloc/presentation/theme/app_colors.dart';
import 'package:taskly_bloc/presentation/shared/ui/value_chip_data.dart';
import 'package:taskly_bloc/presentation/widgets/widgets.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_ui/taskly_ui.dart';

enum ProjectViewVariant {
  /// Default list-row style used across most list templates.
  list,

  /// Rounded card variant intended for the Scheduled agenda.
  agendaCard,
}

/// The canonical, entity-level project UI entrypoint.
///
/// Per-screen customization should happen by selecting an entity-level
/// variant (added later) rather than by re-implementing field rendering.
class ProjectView extends StatelessWidget {
  const ProjectView({
    required this.project,
    required this.tileCapabilities,
    this.onTap,
    this.compact = false,
    this.isInMyDayAuto = false,
    this.agendaMetaDensity = AgendaMetaDensityV1.full,
    this.agendaPriorityEncoding = AgendaPriorityEncodingV1.explicitPill,
    this.agendaActionsVisibility = AgendaActionsVisibilityV1.always,
    this.agendaPrimaryValueIconOnly = false,
    this.agendaMaxSecondaryValues = 2,
    this.agendaShowDeadlineChipOnOngoing = true,
    this.accentColor,
    this.statusBadge,
    this.agendaInProgressStyle = false,
    this.endDate,
    this.taskCount,
    this.completedTaskCount,
    this.trailing,
    this.showTrailingProgressLabel = false,
    super.key,
    this.titlePrefix,
    this.variant = ProjectViewVariant.list,
  });

  final Project project;

  /// Domain-sourced capability policy for this tile.
  final EntityTileCapabilities tileCapabilities;

  /// Optional tap handler. If null, navigates to project detail.
  final void Function(Project project)? onTap;

  /// Whether to use a compact layout.
  final bool compact;

  /// Whether this project is in My Day automatically.
  final bool isInMyDayAuto;

  /// Agenda-only: how dense the meta line should be.
  final AgendaMetaDensityV1 agendaMetaDensity;

  /// Agenda-only: how priority should be encoded.
  final AgendaPriorityEncodingV1 agendaPriorityEncoding;

  /// Agenda-only: how row actions should be surfaced.
  final AgendaActionsVisibilityV1 agendaActionsVisibility;

  /// Agenda-only: render primary value as icon-only.
  final bool agendaPrimaryValueIconOnly;

  /// Agenda-only: max number of secondary values before summarizing.
  final int agendaMaxSecondaryValues;

  /// Agenda-only: on Ongoing rows, show a deadline chip.
  final bool agendaShowDeadlineChipOnOngoing;

  /// Optional accent color used by [ProjectViewVariant.agendaCard].
  final Color? accentColor;

  /// Optional status badge shown to the right of the title.
  final Widget? statusBadge;

  /// Whether to render the agenda card with dashed outline + end marker.
  final bool agendaInProgressStyle;

  /// Optional end date for the in-progress end-day marker.
  final DateTime? endDate;

  /// Optional: total tasks in this project.
  final int? taskCount;

  /// Optional: completed tasks in this project.
  final int? completedTaskCount;

  /// Optional trailing control.
  final Widget? trailing;

  /// Whether to show a small progress label under the trailing/actions.
  final bool showTrailingProgressLabel;

  /// Optional widget shown inline before the project title.
  final Widget? titlePrefix;

  /// Visual variant.
  final ProjectViewVariant variant;

  bool get _hasKnownProgress {
    final total = taskCount;
    final done = completedTaskCount;
    if (total == null || done == null) return false;
    return total > 0;
  }

  bool _isOverdue(DateTime? deadline) {
    if (deadline == null || project.completed) return false;
    final now = getIt<NowService>().nowLocal();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
    return deadlineDay.isBefore(today);
  }

  bool _isDueToday(DateTime? deadline) {
    if (deadline == null || project.completed) return false;
    final now = getIt<NowService>().nowLocal();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
    return deadlineDay.isAtSameMomentAs(today);
  }

  bool _isDueSoon(DateTime? deadline) {
    if (deadline == null || project.completed) return false;
    final now = getIt<NowService>().nowLocal();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
    final daysUntil = deadlineDay.difference(today).inDays;
    return daysUntil > 0 && daysUntil <= 3;
  }

  String _formatMonthDay(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context);
    return DateFormat.MMMd(locale.toLanguageTag()).format(date);
  }

  @override
  Widget build(BuildContext context) {
    return switch (variant) {
      ProjectViewVariant.list => _buildListRow(context),
      ProjectViewVariant.agendaCard => _buildAgendaCard(context),
    };
  }

  Widget _buildListRow(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final isOverdue = _isOverdue(project.deadlineDate);
    final isDueToday = _isDueToday(project.deadlineDate);
    final isDueSoon = _isDueSoon(project.deadlineDate);

    final resolvedOnTap =
        onTap ??
        (tileCapabilities.canOpenDetails
            ? (Project p) => Routing.toEntity(context, EntityType.project, p.id)
            : null);

    final titlePriorityPrefix = _priorityTitlePrefix(context);
    final titleFontWeight = _priorityTitleWeight();

    return Container(
      key: Key('project-${project.id}'),
      decoration: BoxDecoration(
        color: project.completed
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
        onTap: resolvedOnTap == null ? null : () => resolvedOnTap(project),
        child: Stack(
          children: [
            Padding(
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
                      child: Icon(
                        Icons.folder_outlined,
                        size: 22,
                        color: scheme.onSurfaceVariant,
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
                                project.name,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: titleFontWeight,
                                  decoration: project.completed
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: project.completed
                                      ? scheme.onSurface.withValues(alpha: 0.5)
                                      : scheme.onSurface,
                                ),
                                maxLines: compact ? 1 : 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (statusBadge != null) ...[
                              const SizedBox(width: 10),
                              statusBadge!,
                            ],
                          ],
                        ),
                        _MetaLine(
                          primaryValue: project.primaryValue,
                          formatDate: _formatMonthDay,
                          startDate: project.startDate,
                          deadlineDate: project.deadlineDate,
                          isOverdue: isOverdue,
                          isDueToday: isDueToday,
                          isDueSoon: isDueSoon,
                          showDates: true,
                          showOnlyDeadlineDate: false,
                          hasRepeat: project.repeatIcalRrule != null,
                          secondaryValues: project.secondaryValues,
                          priority: project.priority,
                          metaDensity: agendaMetaDensity,
                          priorityEncoding: agendaPriorityEncoding,
                          primaryValueIconOnly: agendaPrimaryValueIconOnly,
                          maxSecondaryValues: agendaMaxSecondaryValues,
                          collapseSecondaryValuesToCount: false,
                          showRepeatOnRight: true,
                          showBothDatesIfPresent: true,
                          onTapValues: () {
                            if (!tileCapabilities.canAlignValues) return;
                            final dispatcher = context
                                .read<TileIntentDispatcher>();
                            unawaited(
                              dispatcher.dispatch(
                                context,
                                TileIntentOpenEditor(
                                  entityType: EntityType.project,
                                  entityId: project.id,
                                  openToValues: true,
                                ),
                              ),
                            );
                          },
                        ),
                        if (taskCount == 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            'No tasks yet',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 72,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (trailing != null) ...[
                              trailing!,
                              const SizedBox(width: 8),
                            ],
                            _ProjectTodayStatusMenuButton(
                              projectId: project.id,
                              projectName: project.name,
                              isPinnedToMyDay: project.isPinned,
                              isInMyDayAuto: isInMyDayAuto,
                              isRepeating: project.isRepeating,
                              seriesEnded: project.seriesEnded,
                              tileCapabilities: tileCapabilities,
                            ),
                          ],
                        ),
                        if (showTrailingProgressLabel)
                          _ProjectProgressLabel(
                            taskCount: taskCount,
                            completedTaskCount: completedTaskCount,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_hasKnownProgress)
              Positioned(
                left: 16,
                right: 16,
                bottom: 0,
                child: _ProjectProgressBar(
                  projectName: project.name,
                  isOverdue: isOverdue,
                  taskCount: taskCount!,
                  completedTaskCount: completedTaskCount!,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgendaCard(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final isOverdue = _isOverdue(project.deadlineDate);
    final isDueToday = _isDueToday(project.deadlineDate);
    final isDueSoon = _isDueSoon(project.deadlineDate);

    final effectiveAccent = accentColor;
    final outline = scheme.outlineVariant.withValues(alpha: 0.35);

    final endDay = _endDayLabel(context);

    final backgroundColor = scheme.surfaceContainerLow;

    final resolvedOnTap =
        onTap ??
        (tileCapabilities.canOpenDetails
            ? (Project p) => Routing.toEntity(context, EntityType.project, p.id)
            : null);

    final showOverflowActions = _resolveAgendaActionsVisibility(context);

    final titlePriorityPrefix = _priorityTitlePrefix(context);
    final titleFontWeight = _priorityTitleWeight();

    return Material(
      key: Key('project-${project.id}'),
      color: Colors.transparent,
      child: InkWell(
        onTap: resolvedOnTap == null ? null : () => resolvedOnTap(project),
        borderRadius: BorderRadius.circular(16),
        child: _AgendaCardContainer(
          dashedOutline: agendaInProgressStyle,
          accentColor: effectiveAccent,
          outlineColor: outline,
          backgroundColor: backgroundColor,
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  agendaInProgressStyle ? 28 : 14,
                  10,
                  14,
                  10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox.square(
                      dimension: 44,
                      child: Center(
                        child: Icon(
                          Icons.folder_outlined,
                          size: 22,
                          color: scheme.onSurfaceVariant,
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
                                const SizedBox(width: 10),
                              ],
                              Expanded(
                                child: Text(
                                  project.name,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: titleFontWeight,
                                    decoration: project.completed
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: project.completed
                                        ? scheme.onSurface.withValues(
                                            alpha: 0.5,
                                          )
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
                                child: _MetaLineWithExpansion(
                                  primaryValue: project.primaryValue,
                                  formatDate: _formatMonthDay,
                                  startDate: project.startDate,
                                  deadlineDate: project.deadlineDate,
                                  isOverdue: isOverdue,
                                  isDueToday: isDueToday,
                                  isDueSoon: isDueSoon,
                                  showDates:
                                      !agendaInProgressStyle ||
                                      agendaShowDeadlineChipOnOngoing,
                                  showOnlyDeadlineDate: agendaInProgressStyle,
                                  hasRepeat: project.repeatIcalRrule != null,
                                  secondaryValues: project.secondaryValues,
                                  priority: project.priority,
                                  metaDensity: agendaMetaDensity,
                                  priorityEncoding: agendaPriorityEncoding,
                                  primaryValueIconOnly:
                                      agendaPrimaryValueIconOnly,
                                  maxSecondaryValues: agendaMaxSecondaryValues,
                                  onTapValues: () {
                                    if (!tileCapabilities.canAlignValues) {
                                      return;
                                    }
                                    final dispatcher = context
                                        .read<TileIntentDispatcher>();
                                    unawaited(
                                      dispatcher.dispatch(
                                        context,
                                        TileIntentOpenEditor(
                                          entityType: EntityType.project,
                                          entityId: project.id,
                                          openToValues: true,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          if (taskCount == 0) ...[
                            const SizedBox(height: 12),
                            Text(
                              'No tasks yet',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 72,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (trailing != null) ...[
                            trailing!,
                            const SizedBox(height: 6),
                          ],
                          if (showOverflowActions)
                            _ProjectTodayStatusMenuButton(
                              projectId: project.id,
                              projectName: project.name,
                              isPinnedToMyDay: project.isPinned,
                              isInMyDayAuto: isInMyDayAuto,
                              isRepeating: project.isRepeating,
                              seriesEnded: project.seriesEnded,
                              tileCapabilities: tileCapabilities,
                            )
                          else
                            _HoverOrFocusVisibility(
                              child: _ProjectTodayStatusMenuButton(
                                projectId: project.id,
                                projectName: project.name,
                                isPinnedToMyDay: project.isPinned,
                                isInMyDayAuto: isInMyDayAuto,
                                isRepeating: project.isRepeating,
                                seriesEnded: project.seriesEnded,
                                tileCapabilities: tileCapabilities,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (agendaInProgressStyle && endDay != null) ...[
                      const SizedBox(width: 12),
                      _EndDayMarker(label: endDay),
                    ],
                  ],
                ),
              ),
              if (_hasKnownProgress)
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 0,
                  child: _ProjectProgressBar(
                    projectName: project.name,
                    isOverdue: isOverdue,
                    taskCount: taskCount!,
                    completedTaskCount: completedTaskCount!,
                  ),
                ),
            ],
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

  bool _resolveAgendaActionsVisibility(BuildContext context) {
    if (agendaActionsVisibility == AgendaActionsVisibilityV1.always) {
      return true;
    }

    // On touch platforms, hover/focus is not discoverable; keep actions visible.
    return switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => true,
      _ => false,
    };
  }

  FontWeight _priorityTitleWeight() {
    final p = project.priority;
    if (p == null) return FontWeight.w600;

    if (agendaPriorityEncoding != AgendaPriorityEncodingV1.subtleTitleWeight) {
      return FontWeight.w600;
    }

    return switch (p) {
      1 => FontWeight.w700,
      2 => FontWeight.w600,
      3 => FontWeight.w600,
      _ => FontWeight.w600,
    };
  }

  Widget? _priorityTitlePrefix(BuildContext context) {
    final p = project.priority;
    if (p == null) return null;

    if (agendaPriorityEncoding != AgendaPriorityEncodingV1.subtleDot) {
      return null;
    }

    final scheme = Theme.of(context).colorScheme;
    final dotColor = scheme.onSurfaceVariant.withValues(alpha: 0.75);

    return Tooltip(
      message: 'Priority $p',
      child: Icon(
        Icons.circle,
        size: 8,
        color: dotColor,
        semanticLabel: 'Priority $p',
      ),
    );
  }
}

class _HoverOrFocusVisibility extends StatefulWidget {
  const _HoverOrFocusVisibility({required this.child});

  final Widget child;

  @override
  State<_HoverOrFocusVisibility> createState() =>
      _HoverOrFocusVisibilityState();
}

class _HoverOrFocusVisibilityState extends State<_HoverOrFocusVisibility> {
  bool _show = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowFocusHighlight: (hasFocus) {
        setState(() => _show = hasFocus);
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _show = true),
        onExit: (_) => setState(() => _show = false),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 120),
          opacity: _show ? 1 : 0,
          child: IgnorePointer(
            ignoring: !_show,
            child: widget.child,
          ),
        ),
      ),
    );
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

class _ProjectProgressBar extends StatelessWidget {
  const _ProjectProgressBar({
    required this.projectName,
    required this.isOverdue,
    required this.taskCount,
    required this.completedTaskCount,
  });

  final String projectName;
  final bool isOverdue;
  final int taskCount;
  final int completedTaskCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final clampedTotal = taskCount <= 0 ? 1 : taskCount;
    final progress = (completedTaskCount / clampedTotal).clamp(0.0, 1.0);

    final fill = isOverdue ? scheme.error : scheme.primary;
    final track = scheme.outlineVariant.withValues(alpha: 0.35);

    return Semantics(
      label: 'Project progress for $projectName',
      value: '$completedTaskCount of $taskCount',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 2,
          backgroundColor: track,
          valueColor: AlwaysStoppedAnimation<Color>(fill),
        ),
      ),
    );
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
    this.startDate,
    this.deadlineDate,
    this.isOverdue = false,
    this.isDueToday = false,
    this.isDueSoon = false,
    this.hasRepeat = false,
    this.showDates = true,
    this.showOnlyDeadlineDate = false,
    this.metaDensity = AgendaMetaDensityV1.full,
    this.priorityEncoding = AgendaPriorityEncodingV1.explicitPill,
    this.primaryValueIconOnly = false,
    this.maxSecondaryValues = 2,
    this.expanded = true,
    this.collapseSecondaryValuesToCount = false,
    this.showRepeatOnRight = false,
    this.showBothDatesIfPresent = false,
    this.onTapValues,
  });

  final Value? primaryValue;
  final DateTime? startDate;
  final DateTime? deadlineDate;
  final _MetaLineLayout layout;
  final bool isOverdue;
  final bool isDueToday;
  final bool isDueSoon;
  final bool hasRepeat;
  final bool showDates;
  final bool showOnlyDeadlineDate;
  final AgendaMetaDensityV1 metaDensity;
  final AgendaPriorityEncodingV1 priorityEncoding;
  final String Function(BuildContext, DateTime) formatDate;
  final List<Value> secondaryValues;
  final int? priority;
  final bool primaryValueIconOnly;
  final int maxSecondaryValues;
  final bool expanded;
  final bool collapseSecondaryValuesToCount;
  final bool showRepeatOnRight;
  final bool showBothDatesIfPresent;
  final VoidCallback? onTapValues;

  Color _priorityColor(ColorScheme scheme, int priority) {
    return switch (priority) {
      1 => AppColors.rambutan80,
      2 => AppColors.cempedak80,
      3 => AppColors.blueberry80,
      4 => scheme.onSurfaceVariant,
      _ => scheme.onSurfaceVariant,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final effectiveExpanded = switch (metaDensity) {
      AgendaMetaDensityV1.full => true,
      AgendaMetaDensityV1.minimal => false,
      AgendaMetaDensityV1.minimalExpandable => expanded,
    };

    final leftChildren = <Widget>[];
    final valueLineChildren = <Widget>[];
    final otherMetaChildren = <Widget>[];

    final pValue = primaryValue;
    if (primaryValueIconOnly) {
      if (pValue != null || secondaryValues.isNotEmpty) {
        final cluster = _IconOnlyValuesCluster(
          primaryValue: pValue,
          secondaryValues: secondaryValues,
          expanded: effectiveExpanded,
          maxSecondaryValues: maxSecondaryValues,
          onTapValues: onTapValues,
        );

        if (layout == _MetaLineLayout.splitPinnedDates) {
          valueLineChildren.add(cluster);
        } else {
          leftChildren.add(cluster);
        }
      }
    } else {
      if (pValue != null) {
        final valueChip = Tooltip(
          message: pValue.name,
          child: ValueChip(
            data: pValue.toChipData(context),
            variant: ValueChipVariant.solid,
            iconOnly: false,
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
              onTap: null,
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
                onTap: null,
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
    }

    final repeatIcon = hasRepeat && effectiveExpanded
        ? Icon(
            Icons.sync_rounded,
            size: 14,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
          )
        : null;

    if (hasRepeat && repeatIcon != null && !showRepeatOnRight) {
      if (layout == _MetaLineLayout.splitPinnedDates) {
        otherMetaChildren.add(repeatIcon);
      } else {
        leftChildren.add(repeatIcon);
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
            final showBothDates =
                showBothDatesIfPresent ||
                (startDate != null &&
                    deadlineDate != null &&
                    constraints.maxWidth >= 420);

            if (!showOnlyDeadlineDate &&
                startDate != null &&
                (deadlineDate == null || showBothDates)) {
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

          if (layout == _MetaLineLayout.splitPinnedDates) {
            final line2 = <Widget>[
              ...otherMetaChildren,
              if (hasRepeat && showRepeatOnRight && repeatIcon != null)
                repeatIcon,
            ];

            final showLine1 =
                valueLineChildren.isNotEmpty || dateTokens.isNotEmpty;
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
                          children: valueLineChildren,
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
          if (hasRepeat && showRepeatOnRight && effectiveExpanded) {
            rightTokens.add(
              Icon(
                Icons.sync_rounded,
                size: 14,
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

class _IconOnlyValuesCluster extends StatelessWidget {
  const _IconOnlyValuesCluster({
    required this.secondaryValues,
    required this.expanded,
    required this.maxSecondaryValues,
    this.primaryValue,
    this.onTapValues,
  });

  final Value? primaryValue;
  final List<Value> secondaryValues;
  final bool expanded;
  final int maxSecondaryValues;
  final VoidCallback? onTapValues;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // UX-102B: show primary icon+name when there's room.
        final showPrimaryName = constraints.maxWidth >= 260;

        final children = <Widget>[];

        final p = primaryValue;
        if (p != null) {
          final chip = ValueChip(
            data: p.toChipData(context),
            variant: ValueChipVariant.solid,
            iconOnly: !showPrimaryName,
            onTap: onTapValues,
          );

          children.add(
            showPrimaryName ? Tooltip(message: p.name, child: chip) : chip,
          );
        }

        if (secondaryValues.isNotEmpty) {
          final allNames = secondaryValues.map((v) => v.name).join(', ');
          if (!expanded) {
            children.add(
              Tooltip(
                message: allNames,
                child: _CountPill(
                  label: '+${secondaryValues.length}',
                  onTap: null,
                ),
              ),
            );
          } else {
            final remaining =
                secondaryValues.length -
                secondaryValues.take(maxSecondaryValues).length;

            children.add(
              ValueDotsCluster(
                values: secondaryValues,
                maxDots: maxSecondaryValues,
                onTap: onTapValues,
              ),
            );

            if (remaining > 0) {
              children.add(
                Tooltip(
                  message: allNames,
                  child: _CountPill(
                    label: '+$remaining',
                    onTap: null,
                  ),
                ),
              );
            }
          }
        }

        if (children.isEmpty) {
          return const SizedBox.shrink();
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: _separated(children, const SizedBox(width: 6)),
        );
      },
    );
  }

  List<Widget> _separated(Iterable<Widget> items, Widget separator) {
    final result = <Widget>[];
    for (final item in items) {
      if (result.isNotEmpty) result.add(separator);
      result.add(item);
    }
    return result;
  }
}

class _MetaLineWithExpansion extends StatefulWidget {
  const _MetaLineWithExpansion({
    required this.formatDate,
    required this.secondaryValues,
    required this.priority,
    required this.metaDensity,
    required this.priorityEncoding,
    required this.primaryValueIconOnly,
    required this.maxSecondaryValues,
    this.primaryValue,
    this.startDate,
    this.deadlineDate,
    this.isOverdue = false,
    this.isDueToday = false,
    this.isDueSoon = false,
    this.hasRepeat = false,
    this.showDates = true,
    this.showOnlyDeadlineDate = false,
    this.onTapValues,
  });

  final Value? primaryValue;
  final DateTime? startDate;
  final DateTime? deadlineDate;
  final bool isOverdue;
  final bool isDueToday;
  final bool isDueSoon;
  final bool hasRepeat;
  final bool showDates;
  final bool showOnlyDeadlineDate;
  final String Function(BuildContext, DateTime) formatDate;
  final List<Value> secondaryValues;
  final int? priority;
  final AgendaMetaDensityV1 metaDensity;
  final AgendaPriorityEncodingV1 priorityEncoding;
  final bool primaryValueIconOnly;
  final int maxSecondaryValues;
  final VoidCallback? onTapValues;

  @override
  State<_MetaLineWithExpansion> createState() => _MetaLineWithExpansionState();
}

class _MetaLineWithExpansionState extends State<_MetaLineWithExpansion> {
  bool _expanded = false;

  bool get _canToggle {
    if (widget.metaDensity != AgendaMetaDensityV1.minimalExpandable) {
      return false;
    }

    return widget.secondaryValues.isNotEmpty ||
        widget.hasRepeat ||
        (widget.priority != null &&
            widget.priorityEncoding == AgendaPriorityEncodingV1.explicitPill) ||
        (!widget.showOnlyDeadlineDate && widget.startDate != null);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveExpanded =
        widget.metaDensity == AgendaMetaDensityV1.minimalExpandable
        ? _expanded
        : widget.metaDensity == AgendaMetaDensityV1.full;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _MetaLine(
            primaryValue: widget.primaryValue,
            formatDate: widget.formatDate,
            startDate: widget.startDate,
            deadlineDate: widget.deadlineDate,
            isOverdue: widget.isOverdue,
            isDueToday: widget.isDueToday,
            isDueSoon: widget.isDueSoon,
            showDates: widget.showDates,
            showOnlyDeadlineDate: widget.showOnlyDeadlineDate,
            hasRepeat: widget.hasRepeat,
            showRepeatOnRight: true,
            secondaryValues: widget.secondaryValues,
            priority: widget.priority,
            metaDensity: widget.metaDensity,
            priorityEncoding: widget.priorityEncoding,
            primaryValueIconOnly: widget.primaryValueIconOnly,
            maxSecondaryValues: widget.maxSecondaryValues,
            expanded: effectiveExpanded,
            onTapValues: widget.onTapValues,
          ),
        ),
        if (_canToggle) ...[
          const SizedBox(width: 6),
          IconButton(
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            tooltip: _expanded ? 'Less details' : 'More details',
            onPressed: () => setState(() => _expanded = !_expanded),
            icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
          ),
        ],
      ],
    );
  }
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

class _ProjectTodayStatusMenuButton extends StatelessWidget {
  const _ProjectTodayStatusMenuButton({
    required this.projectId,
    required this.projectName,
    required this.isPinnedToMyDay,
    required this.isInMyDayAuto,
    required this.isRepeating,
    required this.seriesEnded,
    required this.tileCapabilities,
  });

  final String projectId;
  final String projectName;
  final bool isPinnedToMyDay;
  final bool isInMyDayAuto;
  final bool isRepeating;
  final bool seriesEnded;
  final EntityTileCapabilities tileCapabilities;

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
              child: Icon(statusIcon, size: 20, color: iconColor),
            ),
          );

    final actions = TileOverflowActionCatalog.forProject(
      projectId: projectId,
      projectName: projectName,
      isPinnedToMyDay: isPinnedToMyDay,
      isRepeating: isRepeating,
      seriesEnded: seriesEnded,
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
              size: 20,
              color: iconColor,
            ),
          ],
        ),
      ),
      onSelected: (actionId) async {
        final dispatcher = context.read<TileIntentDispatcher>();
        final action = actions.firstWhere((a) => a.id == actionId);

        AppLog.routineThrottledStructured(
          'tile_overflow.project.${actionId.name}.$projectId',
          const Duration(seconds: 2),
          'tile_overflow',
          'selected',
          fields: {
            'entityType': 'project',
            'entityId': projectId,
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

class _ProjectProgressLabel extends StatelessWidget {
  const _ProjectProgressLabel({
    required this.taskCount,
    required this.completedTaskCount,
  });

  final int? taskCount;
  final int? completedTaskCount;

  @override
  Widget build(BuildContext context) {
    final total = taskCount;
    final done = completedTaskCount;
    if (total == null || done == null || total <= 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        '$done/$total',
        style: theme.textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
