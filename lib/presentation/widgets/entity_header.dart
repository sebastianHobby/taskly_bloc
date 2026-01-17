import 'package:flutter/material.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_domain/domain/core/model/project.dart';
import 'package:taskly_domain/domain/core/model/value.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_bloc/presentation/shared/utils/date_display_utils.dart';
import 'package:taskly_bloc/presentation/widgets/date_chip.dart';
import 'package:taskly_bloc/presentation/widgets/values_footer.dart';

/// A reusable header widget for entity detail pages (projects, labels).
///
/// Displays entity information with optional checkbox and metadata.
class EntityHeader extends StatelessWidget {
  const EntityHeader._({
    required this.title,
    required this.completed,
    this.description,
    this.color,
    this.onTap,
    this.onCheckboxChanged,
    this.showCheckbox = true,
    this.showMetadata = true,
    this.metadata,
    this.primaryValue,
    this.secondaryValues = const [],
    this.values,
  });

  /// Creates a header for a project entity.
  factory EntityHeader.project({
    required Project project,
    VoidCallback? onTap,
    ValueChanged<bool?>? onCheckboxChanged,
    bool showCheckbox = true,
    bool showMetadata = true,
  }) {
    return EntityHeader._(
      title: project.name,
      completed: project.completed,
      description: project.description,
      onTap: onTap,
      onCheckboxChanged: onCheckboxChanged,
      showCheckbox: showCheckbox,
      showMetadata: showMetadata,
      metadata: _ProjectMetadata(project: project),
      primaryValue: project.primaryValue,
      secondaryValues: project.secondaryValues,
      values: project.values,
    );
  }

  /// Creates a header for a value entity.
  factory EntityHeader.value({
    required Value value,
    VoidCallback? onTap,
    int? taskCount,
    bool showMetadata = true,
  }) {
    return EntityHeader._(
      title: value.name,
      completed: false,
      color: value.color,
      onTap: onTap,
      showCheckbox: false,
      showMetadata: showMetadata,
      metadata: _ValueMetadata(value: value, taskCount: taskCount),
    );
  }

  final String title;
  final bool completed;
  final String? description;
  final String? color;
  final VoidCallback? onTap;
  final ValueChanged<bool?>? onCheckboxChanged;
  final bool showCheckbox;
  final bool showMetadata;
  final Widget? metadata;
  final Value? primaryValue;
  final List<Value> secondaryValues;
  final List<Value>? values;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Checkbox (if shown)
                  if (showCheckbox) ...[
                    Transform.scale(
                      scale: 1.2,
                      child: Checkbox(
                        value: completed,
                        onChanged: onCheckboxChanged,
                        shape: const CircleBorder(),
                        activeColor: colorScheme.primary,
                        checkColor: colorScheme.onPrimary,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Color indicator (for labels)
                  if (color != null && !showCheckbox) ...[
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: ColorUtils.fromHex(color),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  // Title
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        decoration: completed
                            ? TextDecoration.lineThrough
                            : null,
                        color: completed ? colorScheme.onSurfaceVariant : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Status badge
                  if (showCheckbox)
                    _StatusBadge(
                      isCompleted: completed,
                      colorScheme: colorScheme,
                    ),
                  if (onTap != null) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: onTap,
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: context.l10n.editLabel,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ],
              ),

              if (showMetadata) ...[
                // Values (preferred: primary/secondary footer)
                if (primaryValue != null || secondaryValues.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ValuesFooter(
                    primaryValue: primaryValue,
                    secondaryValues: secondaryValues,
                  ),
                ],

                // Values (legacy fallback: list-of-values chips)
                if ((primaryValue == null && secondaryValues.isEmpty) &&
                    values != null &&
                    values!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: values!.map((value) {
                      return Chip(
                        label: Text(value.name),
                        backgroundColor: ColorUtils.fromHex(
                          value.color,
                        ).withValues(alpha: 0.2),
                        side: BorderSide.none,
                        labelStyle: TextStyle(
                          color: ColorUtils.fromHex(value.color),
                          fontSize: 12,
                        ),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                ],

                // Entity-specific metadata
                if (metadata != null) ...[
                  const SizedBox(height: 12),
                  metadata!,
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.isCompleted,
    required this.colorScheme,
  });

  final bool isCompleted;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 14,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              l10n.projectFormCompletedLabel,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.radio_button_unchecked,
            size: 14,
            color: colorScheme.secondary,
          ),
          const SizedBox(width: 4),
          Text(
            l10n.projectStatusActive,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.secondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectMetadata extends StatelessWidget {
  const _ProjectMetadata({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final hasRepeat =
        project.repeatIcalRrule != null &&
        project.repeatIcalRrule!.trim().isNotEmpty;
    final hasDates =
        project.startDate != null || project.deadlineDate != null || hasRepeat;

    if (!hasDates) return const SizedBox.shrink();

    final isOverdue = DateDisplayUtils.isOverdue(project.deadlineDate);
    final isDueToday = DateDisplayUtils.isDueToday(project.deadlineDate);
    final isDueSoon = DateDisplayUtils.isDueSoon(project.deadlineDate);

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        if (project.startDate != null)
          DateChip.startDate(
            context: context,
            label: DateDisplayUtils.formatRelativeDate(
              context,
              project.startDate!,
            ),
          ),
        if (project.deadlineDate != null)
          DateChip.deadline(
            context: context,
            label: DateDisplayUtils.formatRelativeDate(
              context,
              project.deadlineDate!,
            ),
            isOverdue: isOverdue,
            isDueToday: isDueToday,
            isDueSoon: isDueSoon,
          ),
      ],
    );
  }
}

class _ValueMetadata extends StatelessWidget {
  const _ValueMetadata({
    required this.value,
    this.taskCount,
  });

  final Value value;
  final int? taskCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Wrap(
      spacing: 16,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              l10n.valuesTitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        if (taskCount != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.task_alt,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                '$taskCount ${taskCount == 1 ? 'task' : 'tasks'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
