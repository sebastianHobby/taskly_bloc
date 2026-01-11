import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/routing/routing.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/models/analytics/entity_type.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/presentation/field_catalog/field_catalog.dart';
import 'package:taskly_bloc/presentation/widgets/widgets.dart';

/// The canonical, entity-level project UI entrypoint.
///
/// Per-screen customization should happen by selecting an entity-level
/// variant (added later) rather than by re-implementing field rendering.
class ProjectView extends StatelessWidget {
  const ProjectView({
    required this.project,
    this.onCheckboxChanged,
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

  /// Callback when a project's completion checkbox is toggled.
  ///
  /// If null, no checkbox is shown.
  final void Function(Project, bool?)? onCheckboxChanged;

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

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateChip? _buildStrictDateToken(
    BuildContext context, {
    required DateTime? startDate,
    required DateTime? deadlineDate,
    required bool isOverdue,
    required bool isDueToday,
    required bool isDueSoon,
    required String Function(BuildContext, DateTime) formatDate,
  }) {
    if (deadlineDate != null) {
      return DateChip.deadline(
        context: context,
        label: formatDate(context, deadlineDate),
        isOverdue: isOverdue,
        isDueToday: isDueToday,
        isDueSoon: isDueSoon,
      );
    }

    if (startDate != null) {
      final startDay = DateTime(startDate.year, startDate.month, startDate.day);
      if (!startDay.isBefore(_today())) {
        return DateChip.startDate(
          context: context,
          label: formatDate(context, startDate),
        );
      }
    }

    return null;
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
    final isDueToday = _isDueToday(project.deadlineDate);
    final isDueSoon = _isDueSoon(project.deadlineDate);

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

    return Card(
      key: Key('project-${project.id}'),
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isOverdue
              ? colorScheme.error.withValues(alpha: 0.3)
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isOverdue ? 1.5 : 1,
        ),
      ),
      color: project.completed
          ? colorScheme.surfaceContainerLowest.withValues(alpha: 0.5)
          : colorScheme.surface,
      child: InkWell(
        onTap: () => onTap != null
            ? onTap!(project)
            : Routing.toEntity(context, EntityType.project, project.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leading widget: optional completion checkbox.
              if (onCheckboxChanged != null)
                _ProjectCheckbox(
                  completed: project.completed,
                  isOverdue: isOverdue,
                  onChanged: (value) {
                    HapticFeedback.lightImpact();
                    onCheckboxChanged?.call(project, value);
                  },
                  projectName: project.name,
                ),
              if (onCheckboxChanged != null) const SizedBox(width: 12),

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
                      ],
                    ),

                    // Row 2 (full only): Description or next task
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

                    // Meta row: dates + values
                    _MetaLine(
                      startDate: project.startDate,
                      deadlineDate: project.deadlineDate,
                      isOverdue: isOverdue,
                      isDueToday: isDueToday,
                      isDueSoon: isDueSoon,
                      formatDate: DateLabelFormatter.format,
                      hasRepeat: project.repeatIcalRrule != null,
                      primaryValue: project.primaryValue,
                      secondaryValues: project.secondaryValues,
                      buildDateToken: (context) => _buildStrictDateToken(
                        context,
                        startDate: project.startDate,
                        deadlineDate: project.deadlineDate,
                        isOverdue: isOverdue,
                        isDueToday: isDueToday,
                        isDueSoon: isDueSoon,
                        formatDate: DateLabelFormatter.format,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PriorityFlag(priority: project.priority),
                  const SizedBox(height: 8),
                  _ProjectProgressRing(
                    value: _progressValue,
                    isOverdue: isOverdue,
                    semanticsLabel: project.name,
                    taskCount: taskCount,
                    completedTaskCount: completedTaskCount,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectCheckbox extends StatelessWidget {
  const _ProjectCheckbox({
    required this.completed,
    required this.isOverdue,
    required this.onChanged,
    required this.projectName,
  });

  final bool completed;
  final bool isOverdue;
  final ValueChanged<bool?> onChanged;
  final String projectName;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: completed
          ? 'Mark "$projectName" as active'
          : 'Mark "$projectName" as complete',
      child: SizedBox(
        width: 24,
        height: 24,
        child: Checkbox(
          value: completed,
          onChanged: onChanged,
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
        dimension: 36,
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
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.formatDate,
    required this.primaryValue,
    required this.secondaryValues,
    required this.buildDateToken,
    this.startDate,
    this.deadlineDate,
    this.isOverdue = false,
    this.isDueToday = false,
    this.isDueSoon = false,
    this.hasRepeat = false,
  });

  final DateTime? startDate;
  final DateTime? deadlineDate;
  final bool isOverdue;
  final bool isDueToday;
  final bool isDueSoon;
  final bool hasRepeat;
  final String Function(BuildContext, DateTime) formatDate;
  final Value? primaryValue;
  final List<Value> secondaryValues;
  final DateChip? Function(BuildContext context) buildDateToken;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final dateToken = buildDateToken(context);

    final children = <Widget>[];

    if (primaryValue != null) {
      children.add(
        ValueChip(
          value: primaryValue!,
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

    if (hasRepeat) {
      children.add(
        Icon(
          Icons.sync_rounded,
          size: 14,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      );
    }

    if (children.isEmpty && dateToken == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Wrap(
              spacing: 12,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: children,
            ),
          ),
          if (dateToken != null) ...[
            const SizedBox(width: 12),
            dateToken,
          ],
        ],
      ),
    );
  }
}
