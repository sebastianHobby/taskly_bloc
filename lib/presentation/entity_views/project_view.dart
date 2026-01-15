import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/analytics/model/entity_type.dart';
import 'package:taskly_bloc/domain/core/model/task.dart';
import 'package:taskly_bloc/presentation/theme/app_colors.dart';
import 'package:taskly_bloc/presentation/widgets/widgets.dart';

enum ProjectViewVariant {
  /// Default list-row style used across most list templates.
  list,

  /// Rounded card variant intended for the Scheduled agenda timeline.
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
    this.taskCount,
    this.completedTaskCount,
    this.nextTask,
    this.showNextTask = false,
    this.showPinnedIndicator = true,
    this.groupedValueId,
    this.showPrimaryValueChip = true,
    this.maxSecondaryValueChips = 1,
    this.excludeValueIdFromChips,
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

  /// Optional recommended next task for this project.
  final Task? nextTask;

  /// Whether to display the next task subtitle.
  final bool showNextTask;

  /// Whether to show a pinned indicator when the project is pinned.
  final bool showPinnedIndicator;

  /// When set, the project is being rendered under a value grouping.
  ///
  /// Used to render compact, icon-only value chips for the grouped layout.
  final String? groupedValueId;

  /// Whether to show the primary value chip in the value line.
  ///
  /// Useful when the project is displayed under a value grouping where the
  /// value is already implied by the section header.
  final bool showPrimaryValueChip;

  /// Maximum number of secondary value chips to show.
  ///
  /// Defaults to 1 to keep list rows compact.
  final int maxSecondaryValueChips;

  /// When set, excludes this value id from any chips shown in the value line.
  ///
  /// This is typically the current value group id.
  final String? excludeValueIdFromChips;

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

  double? get _progressValue {
    if (taskCount == null || taskCount == 0) return null;
    return completedTaskCount != null ? completedTaskCount! / taskCount! : null;
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

    final groupedId = groupedValueId?.trim();
    final isValueGrouped = groupedId != null && groupedId.isNotEmpty;

    Value? groupedValue;
    if (isValueGrouped) {
      final primary = project.primaryValue;
      if (primary?.id == groupedId) {
        groupedValue = primary;
      } else {
        for (final v in project.secondaryValues) {
          if (v.id == groupedId) {
            groupedValue = v;
            break;
          }
        }
      }
    }

    final primaryValueForChip = isValueGrouped
        ? (groupedValue ?? project.primaryValue)
        : project.primaryValue;

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
              // Leading: progress ring.
              _ProjectProgressRing(
                value: _progressValue,
                isOverdue: isOverdue,
                semanticsLabel: project.name,
                taskCount: taskCount,
                completedTaskCount: completedTaskCount,
                centerChild: Icon(
                  Icons.folder_outlined,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
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
                        if (showPrimaryValueChip &&
                            primaryValueForChip != null) ...[
                          const SizedBox(width: 12),
                          ValueChip(
                            value: primaryValueForChip,
                            variant: ValueChipVariant.solid,
                            iconOnly: isValueGrouped,
                          ),
                        ],
                      ],
                    ),

                    _MetaLine(
                      formatDate: _formatMonthDay,
                      startDate: project.startDate,
                      deadlineDate: project.deadlineDate,
                      isOverdue: isOverdue,
                      isDueToday: isDueToday,
                      isDueSoon: isDueSoon,
                      hasRepeat: project.repeatIcalRrule != null,
                      secondaryValues: project.secondaryValues,
                      groupedValueId: groupedValueId,
                      maxSecondaryValueChips: maxSecondaryValueChips,
                      excludeValueIdFromChips: excludeValueIdFromChips,
                      isPinned: showPinnedIndicator && project.isPinned,
                      priority: project.priority,
                    ),
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

    final groupedId = groupedValueId?.trim();
    final isValueGrouped = groupedId != null && groupedId.isNotEmpty;

    Value? groupedValue;
    if (isValueGrouped) {
      final primary = project.primaryValue;
      if (primary?.id == groupedId) {
        groupedValue = primary;
      } else {
        for (final v in project.secondaryValues) {
          if (v.id == groupedId) {
            groupedValue = v;
            break;
          }
        }
      }
    }

    final primaryValueForChip = isValueGrouped
        ? (groupedValue ?? project.primaryValue)
        : project.primaryValue;

    return Material(
      key: Key('project-${project.id}'),
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap != null
            ? onTap!(project)
            : Routing.toEntity(context, EntityType.project, project.id),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProjectProgressRing(
                value: _progressValue,
                isOverdue: isOverdue,
                semanticsLabel: project.name,
                taskCount: taskCount,
                completedTaskCount: completedTaskCount,
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
                                  ? colorScheme.onSurface.withValues(alpha: 0.5)
                                  : colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (showPrimaryValueChip &&
                            primaryValueForChip != null) ...[
                          const SizedBox(width: 12),
                          ValueChip(
                            value: primaryValueForChip,
                            variant: ValueChipVariant.solid,
                            iconOnly: isValueGrouped,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    _MetaLine(
                      formatDate: _formatMonthDay,
                      startDate: project.startDate,
                      deadlineDate: project.deadlineDate,
                      isOverdue: isOverdue,
                      isDueToday: isDueToday,
                      isDueSoon: isDueSoon,
                      hasRepeat: project.repeatIcalRrule != null,
                      secondaryValues: project.secondaryValues,
                      groupedValueId: groupedValueId,
                      maxSecondaryValueChips: maxSecondaryValueChips,
                      excludeValueIdFromChips: excludeValueIdFromChips,
                      isPinned: showPinnedIndicator && project.isPinned,
                      priority: project.priority,
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

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.formatDate,
    required this.secondaryValues,
    required this.groupedValueId,
    required this.maxSecondaryValueChips,
    required this.excludeValueIdFromChips,
    required this.isPinned,
    required this.priority,
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
  final List<Value> secondaryValues;
  final String? groupedValueId;
  final int maxSecondaryValueChips;
  final String? excludeValueIdFromChips;
  final bool isPinned;
  final int? priority;

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

    final groupedId = groupedValueId?.trim();
    final isValueGrouped = groupedId != null && groupedId.isNotEmpty;

    final leftChildren = <Widget>[];

    if (maxSecondaryValueChips > 0) {
      final filteredSecondary = secondaryValues
          .where(
            (v) =>
                v.id != excludeValueIdFromChips &&
                (!isValueGrouped || v.id != groupedId),
          )
          .toList(growable: false);

      if (filteredSecondary.isNotEmpty) {
        final visible = filteredSecondary.take(maxSecondaryValueChips).toList();
        for (final v in visible) {
          leftChildren.add(
            Tooltip(
              message: v.name,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: ValueChip(
                  value: v,
                  variant: ValueChipVariant.outlined,
                  iconOnly: isValueGrouped,
                ),
              ),
            ),
          );
        }

        final remaining = filteredSecondary.length - visible.length;
        if (remaining > 0) {
          final allNames = filteredSecondary.map((v) => v.name).join(', ');
          leftChildren.add(
            Tooltip(
              message: allNames,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                constraints: const BoxConstraints(minHeight: 20),
                child: Text(
                  '+$remaining',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    height: 1.1,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }
      }
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

    if (isPinned) {
      leftChildren.add(
        Tooltip(
          message: 'Pinned',
          child: Icon(
            Icons.push_pin,
            size: 14,
            color: scheme.primary,
          ),
        ),
      );
    }

    final p = priority;
    if (p != null) {
      leftChildren.add(
        Tooltip(
          message: 'Priority P$p',
          child: Icon(
            Icons.flag,
            size: 14,
            color: _priorityColor(scheme, p),
          ),
        ),
      );
    }

    final dateTokens = <Widget>[];
    if (startDate != null) {
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

    if (leftChildren.isEmpty && dateTokens.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
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
    this.centerChild,
  });

  final double? value;
  final bool isOverdue;
  final String semanticsLabel;
  final int? taskCount;
  final int? completedTaskCount;
  final Widget? centerChild;

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
            centerChild ??
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
