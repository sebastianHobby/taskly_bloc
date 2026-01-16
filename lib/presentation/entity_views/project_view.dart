import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/analytics/model/entity_type.dart';
import 'package:taskly_bloc/domain/screens/runtime/entity_action_service.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/theme/app_colors.dart';
import 'package:taskly_bloc/presentation/widgets/widgets.dart';

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
    this.onTap,
    this.compact = false,
    this.isInMyDayAuto = false,
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

  /// Whether to use a compact (2-row) layout.
  final bool compact;

  /// Optional tap handler. If null, navigates to project detail via EntityNavigator.
  final void Function(Project)? onTap;

  /// Optional task count to show progress.
  final int? taskCount;

  /// Optional completed task count for progress indicator.
  final int? completedTaskCount;

  /// Optional trailing control, typically used for collapse/expand in grouped
  /// list renderers.
  final Widget? trailing;

  /// Whether to show a compact progress label (e.g. 3/7) near [trailing].
  final bool showTrailingProgressLabel;

  /// Optional widget shown inline before the project title.
  ///
  /// Used by some list templates (e.g. Agenda) to display a tag pill like
  /// START/DUE without overlaying the tile content.
  final Widget? titlePrefix;

  /// Optional status badge shown to the right of the title.
  final Widget? statusBadge;

  /// Whether this project is currently in the user's My Day (auto-selected).
  ///
  /// Not yet supported by allocation, but wired for future use.
  final bool isInMyDayAuto;

  /// Optional accent color used by [ProjectViewVariant.agendaCard].
  final Color? accentColor;

  /// Whether to render the agenda card with dashed outline + end marker.
  ///
  /// Intended for in-progress items in the Scheduled agenda.
  final bool agendaInProgressStyle;

  /// Optional end date for the in-progress end-day marker.
  final DateTime? endDate;

  /// Visual variant used to align with the Scheduled agenda mock.
  final ProjectViewVariant variant;

  bool _isOverdue(DateTime? deadline) {
    if (deadline == null || project.completed) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
    return deadlineDay.isBefore(today);
  }

  bool _isDueToday(DateTime? deadline) {
    if (deadline == null || project.completed) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
    return deadlineDay.isAtSameMomentAs(today);
  }

  bool _isDueSoon(DateTime? deadline) {
    if (deadline == null || project.completed) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
    final daysUntil = deadlineDay.difference(today).inDays;
    return daysUntil > 0 && daysUntil <= 3;
  }

  String _formatMonthDay(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context);
    return DateFormat.MMMd(locale.toLanguageTag()).format(date);
  }

  bool get _hasKnownProgress {
    final total = taskCount;
    final done = completedTaskCount;
    return total != null && done != null && total > 0;
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
    final colorScheme = theme.colorScheme;

    final isOverdue = _isOverdue(project.deadlineDate);
    final isDueToday = _isDueToday(project.deadlineDate);
    final isDueSoon = _isDueSoon(project.deadlineDate);

    return Container(
      key: Key('project-${project.id}'),
      decoration: BoxDecoration(
        color: project.completed
            ? colorScheme.surfaceContainerLowest.withValues(alpha: 0.5)
            : colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: InkWell(
        onTap: () => onTap != null
            ? onTap!(project)
            : Routing.toEntity(context, EntityType.project, project.id),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: compact ? 10 : 12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leading: folder icon (project identity).
              SizedBox.square(
                dimension: 44,
                child: Center(
                  child: Icon(
                    Icons.folder_outlined,
                    size: 22,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Main content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Title + primary value chip
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (titlePrefix != null) ...[
                          titlePrefix!,
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            project.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration: project.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: project.completed
                                  ? colorScheme.onSurface.withValues(alpha: 0.5)
                                  : colorScheme.onSurface,
                            ),
                            maxLines: compact ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _ProjectTodayStatusMenuButton(
                          projectId: project.id,
                          isPinnedToMyDay: project.isPinned,
                          isInMyDayAuto: isInMyDayAuto,
                        ),
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
                      hasRepeat: project.repeatIcalRrule != null,
                      secondaryValues: project.secondaryValues,
                      priority: project.priority,
                      onTapValues: () {
                        EditorLauncher.fromGetIt().openProjectEditor(
                          context,
                          projectId: project.id,
                          openToValues: true,
                        );
                      },
                    ),

                    if (_hasKnownProgress) ...[
                      const SizedBox(height: 8),
                      _ProjectProgressBar(
                        projectName: project.name,
                        isOverdue: isOverdue,
                        taskCount: taskCount!,
                        completedTaskCount: completedTaskCount!,
                      ),
                    ] else if (taskCount == 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        'No tasks yet',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (trailing != null || showTrailingProgressLabel) ...[
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ?trailing,
                    if (showTrailingProgressLabel)
                      _ProjectProgressLabel(
                        taskCount: taskCount,
                        completedTaskCount: completedTaskCount,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgendaCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isOverdue = _isOverdue(project.deadlineDate);
    final isDueToday = _isDueToday(project.deadlineDate);
    final isDueSoon = _isDueSoon(project.deadlineDate);

    final effectiveAccent = accentColor;
    final outline = colorScheme.outlineVariant.withValues(alpha: 0.35);
    final backgroundColor = colorScheme.surfaceContainerLow;

    final endDay = _endDayLabel(context);

    return Material(
      key: Key('project-${project.id}'),
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap != null
            ? onTap!(project)
            : Routing.toEntity(context, EntityType.project, project.id),
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
                SizedBox.square(
                  dimension: 44,
                  child: Center(
                    child: Icon(
                      Icons.folder_outlined,
                      size: 22,
                      color: colorScheme.onSurfaceVariant,
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
                          if (titlePrefix != null) ...[
                            titlePrefix!,
                            const SizedBox(width: 10),
                          ],
                          Expanded(
                            child: Text(
                              project.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                decoration: project.completed
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: project.completed
                                    ? colorScheme.onSurface.withValues(
                                        alpha: 0.5,
                                      )
                                    : colorScheme.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (statusBadge != null) ...[
                            const SizedBox(width: 10),
                            statusBadge!,
                          ],
                          const SizedBox(width: 10),
                          _ProjectTodayStatusMenuButton(
                            projectId: project.id,
                            isPinnedToMyDay: project.isPinned,
                            isInMyDayAuto: isInMyDayAuto,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _MetaLine(
                              primaryValue: project.primaryValue,
                              formatDate: _formatMonthDay,
                              startDate: project.startDate,
                              deadlineDate: project.deadlineDate,
                              isOverdue: isOverdue,
                              isDueToday: isDueToday,
                              isDueSoon: isDueSoon,
                              showDates: !agendaInProgressStyle,
                              hasRepeat: project.repeatIcalRrule != null,
                              secondaryValues: project.secondaryValues,
                              priority: project.priority,
                              onTapValues: () {
                                EditorLauncher.fromGetIt().openProjectEditor(
                                  context,
                                  projectId: project.id,
                                  openToValues: true,
                                );
                              },
                            ),
                          ),
                          if (agendaInProgressStyle && endDay != null) ...[
                            const SizedBox(width: 12),
                            _EndDayMarker(label: endDay),
                          ],
                        ],
                      ),

                      if (_hasKnownProgress) ...[
                        const SizedBox(height: 8),
                        _ProjectProgressBar(
                          projectName: project.name,
                          isOverdue: isOverdue,
                          taskCount: taskCount!,
                          completedTaskCount: completedTaskCount!,
                        ),
                      ],
                    ],
                  ),
                ),

                if (trailing != null || showTrailingProgressLabel) ...[
                  const SizedBox(width: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ?trailing,
                      if (showTrailingProgressLabel)
                        _ProjectProgressLabel(
                          taskCount: taskCount,
                          completedTaskCount: completedTaskCount,
                        ),
                    ],
                  ),
                ],
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
    this.primaryValue,
    this.startDate,
    this.deadlineDate,
    this.isOverdue = false,
    this.isDueToday = false,
    this.isDueSoon = false,
    this.hasRepeat = false,
    this.showDates = true,
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
  final String Function(BuildContext, DateTime) formatDate;
  final List<Value> secondaryValues;
  final int? priority;
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

    final leftChildren = <Widget>[];

    final pValue = primaryValue;
    if (pValue != null) {
      leftChildren.add(
        ValueChip(
          value: pValue,
          variant: ValueChipVariant.solid,
          iconOnly: false,
          onTap: null,
        ),
      );
    }

    if (secondaryValues.isNotEmpty) {
      final allNames = secondaryValues.map((v) => v.name).join(', ');
      leftChildren.add(
        Tooltip(
          message: allNames,
          child: _CountPill(
            label: '+${secondaryValues.length}',
            onTap: null,
          ),
        ),
      );
    }

    if (hasRepeat) {
      leftChildren.add(
        Icon(
          Icons.sync_rounded,
          size: 14,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      );
    }

    final p = priority;
    if (p != null) {
      leftChildren.add(
        Tooltip(
          message: 'Priority P$p',
          child: _CountPill(
            label: 'P$p',
            foregroundColor: _priorityColor(scheme, p),
          ),
        ),
      );
    }

    final hasAnyDates =
        showDates && (startDate != null || deadlineDate != null);
    if (leftChildren.isEmpty && !hasAnyDates) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dateTokens = <Widget>[];
          if (showDates) {
            final showBothDates =
                startDate != null &&
                deadlineDate != null &&
                constraints.maxWidth >= 420;

            if (showBothDates && startDate != null) {
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
            } else if (!showBothDates && startDate != null) {
              dateTokens.add(
                DateChip.startDate(
                  context: context,
                  label: formatDate(context, startDate!),
                ),
              );
            }
          }

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
              if (dateTokens.isNotEmpty) ...[
                const SizedBox(width: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: dateTokens,
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

enum _ProjectOverflowAction {
  togglePinnedToMyDay,
  edit,
  alignValues,
  delete,
}

class _ProjectTodayStatusMenuButton extends StatelessWidget {
  const _ProjectTodayStatusMenuButton({
    required this.projectId,
    required this.isPinnedToMyDay,
    required this.isInMyDayAuto,
  });

  final String projectId;
  final bool isPinnedToMyDay;
  final bool isInMyDayAuto;

  void _showSnackBar(ScaffoldMessengerState? messenger, String message) {
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
  }

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

    return PopupMenuButton<_ProjectOverflowAction>(
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
      onSelected: (action) async {
        switch (action) {
          case _ProjectOverflowAction.togglePinnedToMyDay:
            final messenger = ScaffoldMessenger.maybeOf(context);
            try {
              final service = getIt<EntityActionService>();
              if (isPinnedToMyDay) {
                await service.unpinProject(projectId);
                _showSnackBar(messenger, 'Unpinned (may still stay in My Day)');
              } else {
                await service.pinProject(projectId);
                _showSnackBar(messenger, 'Pinned to My Day');
              }
            } catch (_) {
              _showSnackBar(messenger, 'Could not update My Day pin');
            }
          case _ProjectOverflowAction.edit:
            await EditorLauncher.fromGetIt().openProjectEditor(
              context,
              projectId: projectId,
            );
          case _ProjectOverflowAction.alignValues:
            await EditorLauncher.fromGetIt().openProjectEditor(
              context,
              projectId: projectId,
              openToValues: true,
            );
          case _ProjectOverflowAction.delete:
            await getIt<EntityActionService>().deleteProject(projectId);
        }
      },
      itemBuilder: (context) {
        final pinLabel = isPinnedToMyDay
            ? 'Unpin from My Day'
            : 'Pin to My Day';
        return [
          PopupMenuItem(
            value: _ProjectOverflowAction.togglePinnedToMyDay,
            child: Text(pinLabel),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: _ProjectOverflowAction.edit,
            child: Text('Edit'),
          ),
          const PopupMenuItem(
            value: _ProjectOverflowAction.alignValues,
            child: Text('Align values…'),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: _ProjectOverflowAction.delete,
            child: Text('Delete'),
          ),
        ];
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
