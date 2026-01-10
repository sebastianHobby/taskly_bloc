import 'dart:math' as math;

import 'package:taskly_bloc/domain/models/settings/allocation_config.dart';
import 'package:taskly_bloc/domain/models/task.dart';

/// Score helpers for allocation strategies.
class AllocationScoring {
  static double deadlineUrgencyScore({
    required Task task,
    required DateTime now,
    required double overdueEmergencyMultiplier,
    required OverdueEmergencyGrowth overdueEmergencyGrowth,
  }) {
    final deadline = task.deadlineDate;
    if (deadline == null) return 0;

    final daysUntilDeadline = deadline.difference(now).inDays;

    if (daysUntilDeadline < 0) {
      final daysOverdue = -daysUntilDeadline;
      final growth = _overdueGrowthFactor(
        daysOverdue: daysOverdue,
        overdueEmergencyGrowth: overdueEmergencyGrowth,
      );

      return (overdueEmergencyMultiplier * growth).clamp(0.0, 10.0);
    }

    return 1.0 / (1.0 + daysUntilDeadline / 7.0);
  }

  static double overdueEmergencyFactor({
    required int daysOverdue,
    required double overdueEmergencyMultiplier,
    required OverdueEmergencyGrowth overdueEmergencyGrowth,
  }) {
    final growth = _overdueGrowthFactor(
      daysOverdue: daysOverdue,
      overdueEmergencyGrowth: overdueEmergencyGrowth,
    );

    return (overdueEmergencyMultiplier * growth).clamp(0.0, 10.0);
  }

  static double taskPriorityMultiplier({
    required Task task,
    required double taskPriorityBoost,
  }) {
    final priority = task.priority;
    if (priority == null) return 1;

    final clampedPriority = priority.clamp(1, 4);
    final priorityStrength = (5 - clampedPriority) / 4;

    return 1.0 + (taskPriorityBoost - 1.0) * priorityStrength;
  }

  static double recencyMultiplier({
    required Task task,
    required DateTime now,
    required double recencyPenalty,
  }) {
    if (recencyPenalty <= 0) return 1;

    final ageDays = now.difference(task.createdAt).inDays;
    const windowDays = 7;
    if (ageDays >= windowDays) return 1;

    final freshness = 1.0 - (ageDays / windowDays);
    return (1.0 - recencyPenalty * freshness).clamp(0.0, 1.0);
  }

  static double _overdueGrowthFactor({
    required int daysOverdue,
    required OverdueEmergencyGrowth overdueEmergencyGrowth,
  }) {
    if (daysOverdue <= 0) return 1;

    return switch (overdueEmergencyGrowth) {
      OverdueEmergencyGrowth.linear => 1.0 + daysOverdue / 7.0,
      OverdueEmergencyGrowth.exponential => math.pow(2.0, daysOverdue / 7.0),
    }.toDouble();
  }
}
