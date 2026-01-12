import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/analytics/model/entity_type.dart';
import 'package:taskly_bloc/domain/core/model/task.dart';
import 'package:taskly_bloc/presentation/widgets/widgets.dart';

/// The canonical, entity-level project UI entrypoint.
///
/// Per-screen customization should happen by selecting an entity-level
/// variant (added later) rather than by re-implementing field rendering.
class ProjectView extends StatelessWidget {
  const ProjectView({
    required this.project,
    this.onTap,
    this.compact = false,
    this.taskCount,
    this.completedTaskCount,
    this.nextTask,
    this.showNextTask = false,
    this.showPinnedIndicator = true,
    super.key,
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

  /// Optional recommended next task for this project.
  final Task? nextTask;

  /// Whether to display the next task subtitle.
  final bool showNextTask;

  /// Whether to show a pinned indicator when the project is pinned.
  final bool showPinnedIndicator;

  bool _isOverdue(DateTime? deadline) {
    if (deadline == null || project.completed) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
    return deadlineDay.isBefore(today);
  }

  String _formatMonthDay(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context);
    return DateFormat.MMMd(locale.toLanguageTag()).format(date);
  }

  double? get _progressValue {
    if (taskCount == null || taskCount == 0) return null;
    return completedTaskCount != null ? completedTaskCount! / taskCount! : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isOverdue = _isOverdue(project.deadlineDate);

    final hasDescription =
        project.description != null && project.description!.trim().isNotEmpty;
    final canShowNextTask = showNextTask && nextTask != null;
    final subtitle = (!compact && (hasDescription || canShowNextTask))
        ? (hasDescription
              ? project.description!.trim()
              : '${context.l10n.projectNextTaskPrefix} ${nextTask!.name}')
        : null;
    final isNextTaskSubtitle =
        subtitle != null && !hasDescription && canShowNextTask;

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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leading: progress ring.
              _ProjectProgressRing(
                value: _progressValue,
                isOverdue: isOverdue,
                semanticsLabel: project.name,
                taskCount: taskCount,
                completedTaskCount: completedTaskCount,
              ),
              const SizedBox(width: 12),

              // Main content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Title + indicators + priority flag
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showPinnedIndicator && project.isPinned) ...[
                          const PinnedIndicator(),
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        PriorityFlag(priority: project.priority),
                      ],
                    ),

                    // Row 2 (full only): Description or next task
                    // Explicitly removed description logic to align with list view mockup
                    /* 
                    if (!compact && subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isNextTaskSubtitle
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          fontStyle: isNextTaskSubtitle
                              ? FontStyle.italic
                              : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    */

                    // Values row
                    _ValueLine(
                      primaryValue: project.primaryValue,
                      secondaryValues: project.secondaryValues,
                    ),

                    // Dates row (Start + Deadline + Repeat)
                    _ProjectDatesRow(
                      startDate: project.startDate,
                      deadlineDate: project.deadlineDate,
                      hasRepeat: project.repeatIcalRrule != null,
                      formatMonthDay: (date) => _formatMonthDay(context, date),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValueLine extends StatelessWidget {
  const _ValueLine({
    required this.primaryValue,
    required this.secondaryValues,
  });

  final Value? primaryValue;
  final List<Value> secondaryValues;

  @override
  Widget build(BuildContext context) {
    final primary = primaryValue;
    final children = <Widget>[];

    if (primary != null) {
      children.add(
        ValueChip(
          value: primary,
          variant: ValueChipVariant.solid,
        ),
      );
    }

    if (secondaryValues.isNotEmpty) {
      children.add(
        ValueChip(
          value: secondaryValues.first,
          variant: ValueChipVariant.outlined,
        ),
      );
    }

    if (children.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      ),
    );
  }
}

class _ProjectDatesRow extends StatelessWidget {
  const _ProjectDatesRow({
    required this.formatMonthDay,
    this.startDate,
    this.deadlineDate,
    this.hasRepeat = false,
  });

  final DateTime? startDate;
  final DateTime? deadlineDate;
  final bool hasRepeat;
  final String Function(DateTime date) formatMonthDay;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (startDate == null && deadlineDate == null && !hasRepeat) {
      return const SizedBox.shrink();
    }

    final children = <Widget>[];

    if (startDate != null) {
      children.add(
        _IconLabel(
          icon: Icons.calendar_today,
          label: formatMonthDay(startDate!),
          color: scheme.onSurfaceVariant,
        ),
      );
    }

    if (deadlineDate != null) {
      children.add(
        _IconLabel(
          icon: Icons.sports_score,
          label: formatMonthDay(deadlineDate!),
          color: scheme.onSurfaceVariant,
        ),
      );
    }

    if (hasRepeat) {
      children.add(
        Icon(
          Icons.repeat,
          size: 16,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      ),
    );
  }
}

class _IconLabel extends StatelessWidget {
  const _IconLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ProjectProgressRing extends StatelessWidget {
  const _ProjectProgressRing({
    required this.value,
    required this.isOverdue,
    required this.semanticsLabel,
    this.taskCount,
    this.completedTaskCount,
  });

  final double? value;
  final bool isOverdue;
  final String semanticsLabel;
  final int? taskCount;
  final int? completedTaskCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final ringValue = value;
    final hasValue = ringValue != null;
    final displayValue = (ringValue ?? 0).clamp(0.0, 1.0);

    final color = isOverdue ? scheme.error : scheme.primary;
    final trackColor = scheme.outlineVariant.withValues(alpha: 0.4);

    final semanticsValue = (taskCount != null && completedTaskCount != null)
        ? '$completedTaskCount of $taskCount'
        : hasValue
        ? '${(displayValue * 100).round()}%'
        : 'No tasks';

    final percentLabel = '${(displayValue * 100).round()}%';

    return Semantics(
      label: 'Project progress for $semanticsLabel',
      value: semanticsValue,
      child: SizedBox.square(
        dimension: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: 1,
              strokeWidth: 3,
              strokeCap: StrokeCap.round,
              valueColor: AlwaysStoppedAnimation<Color>(trackColor),
            ),
            CircularProgressIndicator(
              value: displayValue,
              strokeWidth: 3,
              strokeCap: StrokeCap.round,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
            Text(
              percentLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
