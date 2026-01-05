import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/theme/app_colors.dart';
import 'package:taskly_bloc/domain/models/settings/alert_severity.dart';
import 'package:taskly_bloc/domain/models/settings/allocation_config.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/services/screens/section_data_result.dart';
import 'package:taskly_bloc/presentation/features/screens/widgets/urgent_banner.dart';
import 'package:taskly_bloc/presentation/features/screens/widgets/value_balance_chart.dart';
import 'package:taskly_bloc/presentation/features/tasks/widgets/task_tile.dart';
import 'package:taskly_bloc/presentation/widgets/taskly/widgets.dart';

class AllocationSectionRenderer extends StatelessWidget {
  const AllocationSectionRenderer({
    required this.data,
    super.key,
    this.onTaskToggle,
  });
  final AllocationSectionResult data;
  final void Function(String, bool?)? onTaskToggle;

  @override
  Widget build(BuildContext context) {
    // print('AllocationSectionRenderer build. Persona: ${data.activePersona}');
    final criticalAlerts =
        data.alertEvaluationResult?.bySeverity[AlertSeverity.critical] ?? [];
    final warningAlerts =
        data.alertEvaluationResult?.bySeverity[AlertSeverity.warning] ?? [];
    final persona = data.activePersona ?? AllocationPersona.realist;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TasklyHeader(
            title: 'My Day',
            subtitle: ' tasks remaining',
            icon: Icons.wb_sunny_outlined,
          ),
        ),

        // Banners
        if (criticalAlerts.isNotEmpty) UrgentBanner(alerts: criticalAlerts),

        if (warningAlerts.isNotEmpty) WarningBanner(alerts: warningAlerts),

        // Content based on Persona
        if (data.allocatedTasks.isEmpty)
          _buildEmptyState(context)
        else
          _buildContent(context, persona),

        // Footer
        if (data.excludedCount > 0) _buildFooter(context, persona),
      ],
    );
  }

  Widget _buildContent(BuildContext context, AllocationPersona persona) {
    // print('Building content for persona: $persona');
    return switch (persona) {
      AllocationPersona.firefighter => _buildUrgencyGroupedList(context),
      AllocationPersona.idealist ||
      AllocationPersona.realist => _buildValueGroupedList(context),
      AllocationPersona.reflector => Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: ValueBalanceChart(
              tasksByValue: data.tasksByValue,
            ),
          ),
          _buildValueGroupedList(context),
        ],
      ),
      AllocationPersona.custom => _buildValueGroupedList(
        context,
      ), // Default to value grouping for custom
    };
  }

  Widget _buildValueGroupedList(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Use tasksByValue if available, otherwise fallback to flat list
    if (data.tasksByValue.isEmpty) {
      return _buildFlatList();
    }

    return Column(
      children: data.tasksByValue.values.map((group) {
        if (group.tasks.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Text(
                    group.valueName.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${group.tasks.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: group.tasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final allocatedTask = group.tasks[index];
                return TaskTile(
                  task: allocatedTask.task,
                  onToggle: (val) =>
                      onTaskToggle?.call(allocatedTask.task.id, val),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildUrgencyGroupedList(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final colorScheme = Theme.of(context).colorScheme;

    final overdue = <Task>[];
    final dueToday = <Task>[];
    final upcoming = <Task>[];
    final noDeadline = <Task>[];

    for (final task in data.allocatedTasks) {
      if (task.deadlineDate == null) {
        noDeadline.add(task);
      } else {
        final deadline = task.deadlineDate!;
        if (deadline.isBefore(today)) {
          overdue.add(task);
        } else if (deadline.isBefore(tomorrow)) {
          dueToday.add(task);
        } else {
          upcoming.add(task);
        }
      }
    }

    return Column(
      children: [
        if (overdue.isNotEmpty)
          _buildUrgencyGroup('Overdue', overdue, colorScheme.error),
        if (dueToday.isNotEmpty)
          _buildUrgencyGroup('Due Today', dueToday, Colors.orange),
        if (upcoming.isNotEmpty)
          _buildUrgencyGroup('Upcoming', upcoming, Colors.blue),
        if (noDeadline.isNotEmpty)
          _buildUrgencyGroup(
            'No Deadline',
            noDeadline,
            colorScheme.onSurfaceVariant,
          ),
      ],
    );
  }

  Widget _buildUrgencyGroup(String title, List<Task> tasks, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tasks.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final task = tasks[index];
            return TaskTile(
              task: task,
              onToggle: (val) => onTaskToggle?.call(task.id, val),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFlatList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.allocatedTasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final task = data.allocatedTasks[index];
        return TaskTile(
          task: task,
          onToggle: (val) => onTaskToggle?.call(task.id, val),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        'No tasks allocated for today.',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, AllocationPersona persona) {
    final count = data.excludedCount;
    final message = switch (persona) {
      AllocationPersona.firefighter =>
        '$count tasks not urgent have been deprioritized.',
      AllocationPersona.idealist =>
        '$count tasks not aligned with your values have been hidden.',
      AllocationPersona.realist => '$count tasks excluded to maintain balance.',
      AllocationPersona.reflector =>
        '$count tasks excluded to focus on neglected values.',
      AllocationPersona.custom =>
        '$count tasks excluded by your custom settings.',
    };

    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 40),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}
