import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/analytics/model/entity_type.dart';
import 'package:taskly_bloc/domain/services/values/effective_values.dart';
import 'package:taskly_bloc/domain/screens/runtime/entity_action_service.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/field_catalog/field_catalog.dart';
import 'package:taskly_bloc/presentation/theme/app_colors.dart';
import 'package:taskly_bloc/presentation/widgets/widgets.dart';

enum TaskViewVariant {
  /// Default list-row style used across most list templates.
  list,

  /// Rounded card variant intended for the Scheduled agenda timeline.
  agendaCard,
}

/// The canonical, entity-level task UI entrypoint.
///
/// Per-screen customization should happen by selecting an entity-level
/// variant (added later) rather than by re-implementing field rendering.
class TaskView extends StatelessWidget {
  const TaskView({
    required this.task,
    required this.onCheckboxChanged,
    this.onTap,
    this.compact = false,
    this.isInFocus = false,
    this.titlePrefix,
    this.trailing,
    this.variant = TaskViewVariant.list,
    super.key,
  });

  final Task task;
  final void Function(Task, bool?) onCheckboxChanged;

  /// Optional tap handler. If null, navigates to task detail via EntityNavigator.
  final void Function(Task)? onTap;

  /// Whether to use a compact (2-row) layout.
  final bool compact;

  /// Whether this task is currently in the user's focus list (My Day).
  ///
  /// Used by screens like Anytime and Scheduled to provide subtle focus cues.
  final bool isInFocus;

  /// Optional widget shown inline before the task title.
  ///
  /// Used by some list templates (e.g. Agenda) to display a tag pill like
  /// START/DUE without overlaying the tile content.
  final Widget? titlePrefix;

  /// Optional widget shown at the end of the title row.
  ///
  /// Intended for per-row actions in list templates (e.g., pin/unpin).
  final Widget? trailing;

  /// Visual variant used to align with the Scheduled agenda mock.
  final TaskViewVariant variant;

  bool _isOverdue(DateTime? deadline) {
    if (deadline == null || task.completed) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
    return deadlineDay.isBefore(today);
  }

  bool _isDueToday(DateTime? deadline) {
    if (deadline == null || task.completed) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
    return deadlineDay.isAtSameMomentAs(today);
  }

  bool _isDueSoon(DateTime? deadline) {
    if (deadline == null || task.completed) return false;
    final now = DateTime.now();
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

  Widget _buildListRow(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectivePrimaryValue = task.effectivePrimaryValue;
    final effectiveSecondaryValues = task.effectiveSecondaryValues;

    final isOverdue = _isOverdue(task.deadlineDate);
    final isDueToday = _isDueToday(task.deadlineDate);
    final isDueSoon = _isDueSoon(task.deadlineDate);

    return Material(
      key: Key('task-${task.id}'),
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap != null
            ? onTap!(task)
            : Routing.toEntity(context, EntityType.task, task.id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isInFocus
                ? colorScheme.primary.withValues(alpha: 0.04)
                : null,
            border: Border(
              left: isInFocus
                  ? BorderSide(
                      color: colorScheme.primary.withValues(alpha: 0.65),
                      width: 3,
                    )
                  : BorderSide.none,
              bottom: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: _TaskCheckbox(
                  completed: task.completed,
                  isOverdue: isOverdue,
                  onChanged: (value) => onCheckboxChanged(task, value),
                  taskName: task.name,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (titlePrefix != null) ...[
                          titlePrefix!,
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            task.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              decoration: task.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: task.completed
                                  ? colorScheme.onSurface.withValues(alpha: 0.5)
                                  : colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (trailing != null) ...[
                          const SizedBox(width: 8),
                          trailing!,
                        ],
                        const SizedBox(width: 6),
                        _TaskTodayStatusMenuButton(
                          taskId: task.id,
                          isPinnedToMyDay: task.isPinned,
                          isInMyDayAuto: isInFocus,
                        ),
                      ],
                    ),
                    // Explicitly removed subtitle/description logic to align with list view mockup
                    /*
                    if (!compact && subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isReasonSubtitle
                              ? (reasonColor ?? colorScheme.onSurfaceVariant)
                              : colorScheme.onSurfaceVariant,
                          fontWeight: isReasonSubtitle ? FontWeight.w500 : null,
                        ),
                        maxLines: isReasonSubtitle ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    */
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
                      onTapValues: () {
                        EditorLauncher.fromGetIt().openTaskEditor(
                          context,
                          taskId: task.id,
                          openToValues: true,
                        );
                      },
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

  Widget _buildAgendaCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectivePrimaryValue = task.effectivePrimaryValue;
    final effectiveSecondaryValues = task.effectiveSecondaryValues;

    final isOverdue = _isOverdue(task.deadlineDate);
    final isDueToday = _isDueToday(task.deadlineDate);
    final isDueSoon = _isDueSoon(task.deadlineDate);

    // Keep checkbox interaction (important affordance), but switch the container
    // and hierarchy to a card style that matches the Scheduled mock better.
    return Material(
      key: Key('task-${task.id}'),
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap != null
            ? onTap!(task)
            : Routing.toEntity(context, EntityType.task, task.id),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          decoration: BoxDecoration(
            color: isInFocus
                ? Color.alphaBlend(
                    colorScheme.primary.withValues(alpha: 0.06),
                    colorScheme.surfaceContainerLow,
                  )
                : colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: isInFocus
                ? Border(
                    left: BorderSide(
                      color: colorScheme.primary.withValues(alpha: 0.55),
                      width: 4,
                    ),
                    top: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                    right: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                    bottom: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                  )
                : Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                  ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: _TaskCheckbox(
                  completed: task.completed,
                  isOverdue: isOverdue,
                  onChanged: (value) => onCheckboxChanged(task, value),
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
                        if (titlePrefix != null) ...[
                          titlePrefix!,
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Text(
                            task.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration: task.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: task.completed
                                  ? colorScheme.onSurface.withValues(alpha: 0.5)
                                  : colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (trailing != null) ...[
                          const SizedBox(width: 8),
                          trailing!,
                        ],
                        const SizedBox(width: 10),
                        _TaskTodayStatusMenuButton(
                          taskId: task.id,
                          isPinnedToMyDay: task.isPinned,
                          isInMyDayAuto: isInFocus,
                          compact: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
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
                      onTapValues: () {
                        EditorLauncher.fromGetIt().openTaskEditor(
                          context,
                          taskId: task.id,
                          openToValues: true,
                        );
                      },
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
    required this.priority,
    this.primaryValue,
    this.projectName,
    this.projectId,
    this.startDate,
    this.deadlineDate,
    this.isOverdue = false,
    this.isDueToday = false,
    this.isDueSoon = false,
    this.hasRepeat = false,
    this.onTapValues,
  });

  final Value? primaryValue;
  final String? projectName;
  final String? projectId;
  final DateTime? startDate;
  final DateTime? deadlineDate;
  final bool isOverdue;
  final bool isDueToday;
  final bool isDueSoon;
  final bool hasRepeat;
  final String Function(BuildContext, DateTime) formatDate;
  final List<Value> secondaryValues;
  final int? priority;
  final VoidCallback? onTapValues;

  Color _priorityColor(ColorScheme scheme, int p) {
    return switch (p) {
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
          onTap: () {
            Routing.toEntity(context, EntityType.value, pValue.id);
          },
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
            onTap: onTapValues,
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

    final pName = projectName?.trim();
    if (pName != null && pName.isNotEmpty) {
      leftChildren.add(
        ProjectPill(
          projectName: pName,
          onTap: projectId == null
              ? null
              : () {
                  Routing.toEntity(context, EntityType.project, projectId!);
                },
        ),
      );
    }

    if (leftChildren.isEmpty && startDate == null && deadlineDate == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showBothDates =
              startDate != null &&
              deadlineDate != null &&
              constraints.maxWidth >= 420;

          final dateTokens = <Widget>[];
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
            // If there's no deadline, we can still show start date.
            dateTokens.add(
              DateChip.startDate(
                context: context,
                label: formatDate(context, startDate!),
              ),
            );
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

enum _TaskOverflowAction {
  togglePinnedToMyDay,
  edit,
  moveToProject,
  alignValues,
  delete,
}

class _TaskTodayStatusMenuButton extends StatelessWidget {
  const _TaskTodayStatusMenuButton({
    required this.taskId,
    required this.isPinnedToMyDay,
    required this.isInMyDayAuto,
    this.compact = false,
  });

  final String taskId;
  final bool isPinnedToMyDay;
  final bool isInMyDayAuto;
  final bool compact;

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
              child: Icon(
                statusIcon,
                size: compact ? 18 : 20,
                color: iconColor,
              ),
            ),
          );

    return PopupMenuButton<_TaskOverflowAction>(
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
      onSelected: (action) async {
        switch (action) {
          case _TaskOverflowAction.togglePinnedToMyDay:
            final messenger = ScaffoldMessenger.maybeOf(context);
            try {
              final service = getIt<EntityActionService>();
              if (isPinnedToMyDay) {
                await service.unpinTask(taskId);
                _showSnackBar(messenger, 'Unpinned (may still stay in My Day)');
              } else {
                await service.pinTask(taskId);
                _showSnackBar(messenger, 'Pinned to My Day');
              }
            } catch (_) {
              _showSnackBar(messenger, 'Could not update My Day pin');
            }
          case _TaskOverflowAction.edit:
            await EditorLauncher.fromGetIt().openTaskEditor(
              context,
              taskId: taskId,
            );
          case _TaskOverflowAction.moveToProject:
            await EditorLauncher.fromGetIt().openTaskEditor(
              context,
              taskId: taskId,
              openToProjectPicker: true,
            );
          case _TaskOverflowAction.alignValues:
            await EditorLauncher.fromGetIt().openTaskEditor(
              context,
              taskId: taskId,
              openToValues: true,
            );
          case _TaskOverflowAction.delete:
            await getIt<EntityActionService>().deleteTask(taskId);
        }
      },
      itemBuilder: (context) {
        final pinLabel = isPinnedToMyDay
            ? 'Unpin from My Day'
            : 'Pin to My Day';
        return [
          PopupMenuItem(
            value: _TaskOverflowAction.togglePinnedToMyDay,
            child: Text(pinLabel),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: _TaskOverflowAction.edit,
            child: Text('Edit'),
          ),
          const PopupMenuItem(
            value: _TaskOverflowAction.moveToProject,
            child: Text('Move to project…'),
          ),
          const PopupMenuItem(
            value: _TaskOverflowAction.alignValues,
            child: Text('Align values…'),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: _TaskOverflowAction.delete,
            child: Text('Delete'),
          ),
        ];
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
  final ValueChanged<bool?> onChanged;
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
          onChanged: (bool? value) {
            HapticFeedback.lightImpact();
            onChanged(value);
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
