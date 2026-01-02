import 'package:taskly_bloc/domain/models/screens/trigger_config.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:rrule/rrule.dart';

/// Evaluates when workflow screens should trigger based on their configuration
class TriggerEvaluator {
  /// Checks if a workflow should trigger now based on its trigger config
  bool shouldTrigger(
    TriggerConfig trigger,
    DateTime? lastReviewedAt,
    DateTime now,
  ) {
    return trigger.when(
      schedule: (rrule, nextTriggerDate) => _shouldTriggerSchedule(
        ScheduleTrigger(rrule: rrule, nextTriggerDate: nextTriggerDate),
        now,
      ),
      notReviewedSince: (days) => _shouldTriggerNotReviewedSince(
        NotReviewedSinceTrigger(days: days),
        lastReviewedAt,
        now,
      ),
      manual: () => false,
    );
  }

  /// Calculates the next trigger date for a workflow
  DateTime? nextTriggerDate(
    TriggerConfig trigger,
    DateTime? lastReviewedAt,
    DateTime now,
  ) {
    return trigger.when(
      schedule: (rrule, nextTriggerDate) => _nextScheduleTriggerDate(
        ScheduleTrigger(rrule: rrule, nextTriggerDate: nextTriggerDate),
        now,
      ),
      notReviewedSince: (days) => _nextNotReviewedSinceTriggerDate(
        NotReviewedSinceTrigger(days: days),
        lastReviewedAt,
        now,
      ),
      manual: () => null,
    );
  }

  bool _shouldTriggerSchedule(ScheduleTrigger trigger, DateTime now) {
    try {
      final recurrenceRule = RecurrenceRule.fromString(trigger.rrule);

      // Check if cached nextTriggerDate is in the past
      if (trigger.nextTriggerDate != null &&
          trigger.nextTriggerDate!.isBefore(now)) {
        return true;
      }

      // If no cached date, calculate next occurrence and check if it's now or past
      final instances = recurrenceRule.getInstances(
        start: now.subtract(const Duration(days: 1)),
      );

      if (instances.isNotEmpty) {
        final nextOccurrence = instances.first;
        return nextOccurrence.isBefore(now) ||
            nextOccurrence.isAtSameMomentAs(now);
      }

      return false;
    } catch (e) {
      // Invalid RRULE, don't trigger
      talker.debug('TriggerEvaluator: Invalid RRULE "${trigger.rrule}"');
      return false;
    }
  }

  bool _shouldTriggerNotReviewedSince(
    NotReviewedSinceTrigger trigger,
    DateTime? lastReviewedAt,
    DateTime now,
  ) {
    if (lastReviewedAt == null) {
      return true; // Never reviewed, should trigger
    }

    final daysSinceReview = now.difference(lastReviewedAt).inDays;
    return daysSinceReview >= trigger.days;
  }

  DateTime? _nextScheduleTriggerDate(ScheduleTrigger trigger, DateTime now) {
    try {
      final recurrenceRule = RecurrenceRule.fromString(trigger.rrule);
      final instances = recurrenceRule.getInstances(start: now);

      return instances.isNotEmpty ? instances.first : null;
    } catch (e) {
      talker.debug(
        'TriggerEvaluator: Invalid RRULE for next trigger "${trigger.rrule}"',
      );
      return null;
    }
  }

  DateTime? _nextNotReviewedSinceTriggerDate(
    NotReviewedSinceTrigger trigger,
    DateTime? lastReviewedAt,
    DateTime now,
  ) {
    if (lastReviewedAt == null) {
      return now; // Should trigger now if never reviewed
    }

    return lastReviewedAt.add(Duration(days: trigger.days));
  }
}
