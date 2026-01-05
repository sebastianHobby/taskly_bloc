import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/models/priority/allocation_result.dart';
import 'package:taskly_bloc/domain/models/settings/alert_severity.dart';
import 'package:taskly_bloc/domain/models/settings/allocation_config.dart';
import 'package:taskly_bloc/domain/models/settings/evaluated_alert.dart';
import 'package:taskly_bloc/presentation/features/tasks/widgets/task_list_tile.dart';
import 'package:taskly_bloc/presentation/widgets/section_header.dart';

/// Section displaying tasks outside Focus, grouped by alert type.
///
/// Shown at bottom of My Day when alerts are triggered.
/// Reuses existing [SectionHeader] and [TaskListTile] widgets.
class OutsideFocusSection extends StatelessWidget {
  const OutsideFocusSection({
    required this.alertResult,
    required this.persona,
    required this.onTaskTap,
    required this.onTaskComplete,
    this.scrollKey,
    super.key,
  });

  final AlertEvaluationResult alertResult;
  final AllocationPersona persona;
  final void Function(ExcludedTask) onTaskTap;
  final void Function(ExcludedTask, bool) onTaskComplete;

  /// Key for scroll-to functionality
  final GlobalKey? scrollKey;

  @override
  Widget build(BuildContext context) {
    if (!alertResult.hasAlerts) {
      return const SizedBox.shrink();
    }

    return Column(
      key: scrollKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Divider(),

        // Section header using existing SectionHeader widget
        SectionHeader(
          title: persona.excludedSectionTitle,
          icon: Icons.visibility_off_outlined,
          trailing: SectionCountBadge(count: alertResult.totalCount),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        ),

        // Groups by alert rule
        ...alertResult.byRuleId.entries.map((entry) {
          // Get rule name from the first alert in the group
          final ruleName = entry.value.first.ruleName;
          return _AlertGroup(
            ruleName: ruleName,
            alerts: entry.value,
            onTaskTap: onTaskTap,
            onTaskComplete: onTaskComplete,
          );
        }),
      ],
    );
  }
}

/// A group of tasks with the same alert rule.
class _AlertGroup extends StatelessWidget {
  const _AlertGroup({
    required this.ruleName,
    required this.alerts,
    required this.onTaskTap,
    required this.onTaskComplete,
  });

  final String ruleName;
  final List<EvaluatedAlert> alerts;
  final void Function(ExcludedTask) onTaskTap;
  final void Function(ExcludedTask, bool) onTaskComplete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Get highest severity in this group for styling
    final severity = alerts
        .map((a) => a.severity)
        .reduce((a, b) => a.sortOrder < b.sortOrder ? a : b);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group header with severity indicator
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                _SeverityIndicator(severity: severity),
                const SizedBox(width: 8),
                Text(
                  ruleName,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Task tiles - reusing TaskListTile with reason text
          ...alerts.map((alert) {
            return TaskListTile(
              task: alert.excludedTask.task,
              onCheckboxChanged: (task, value) => onTaskComplete(
                alert.excludedTask,
                value ?? false,
              ),
              onTap: (task) => onTaskTap(alert.excludedTask),
              reasonText: alert.reason,
              reasonColor: _severityColor(alert.severity, colorScheme),
              showNextActionIndicator: false,
            );
          }),
        ],
      ),
    );
  }

  Color _severityColor(AlertSeverity severity, ColorScheme colorScheme) {
    return switch (severity) {
      AlertSeverity.critical => colorScheme.error,
      AlertSeverity.warning => Colors.amber.shade700,
      AlertSeverity.notice => colorScheme.primary,
    };
  }
}

/// Small colored dot indicating alert severity.
class _SeverityIndicator extends StatelessWidget {
  const _SeverityIndicator({required this.severity});

  final AlertSeverity severity;

  @override
  Widget build(BuildContext context) {
    final color = switch (severity) {
      AlertSeverity.critical => Theme.of(context).colorScheme.error,
      AlertSeverity.warning => Colors.amber.shade700,
      AlertSeverity.notice => Theme.of(context).colorScheme.primary,
    };

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
