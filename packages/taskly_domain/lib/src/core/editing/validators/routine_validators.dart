import 'package:taskly_domain/src/core/editing/validation_error.dart';
import 'package:taskly_domain/src/routines/model/routine_period_type.dart';
import 'package:taskly_domain/src/routines/model/routine_schedule_mode.dart';

final class RoutineValidators {
  RoutineValidators._();

  static const int maxNameLength = 100;

  static List<ValidationError> name(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) {
      return const [
        ValidationError(code: 'required', messageKey: 'routineFormNameEmpty'),
      ];
    }
    if (trimmed.length > maxNameLength) {
      return [
        ValidationError(
          code: 'max_length',
          messageKey: 'routineFormNameTooLong',
          args: const {'max': maxNameLength},
        ),
      ];
    }
    return const [];
  }

  static List<ValidationError> projectId(String? projectId) {
    if (projectId == null || projectId.trim().isEmpty) {
      return const [
        ValidationError(code: 'required', messageKey: 'validationRequired'),
      ];
    }
    return const [];
  }

  static List<ValidationError> targetCount(
    int? count, {
    required RoutinePeriodType periodType,
    required RoutineScheduleMode scheduleMode,
  }) {
    if (scheduleMode == RoutineScheduleMode.scheduled &&
        periodType != RoutinePeriodType.day) {
      return const [];
    }
    if (count == null) {
      return const [
        ValidationError(code: 'required', messageKey: 'validationRequired'),
      ];
    }
    if (count <= 0) {
      return const [
        ValidationError(
          code: 'invalid',
          messageKey: 'validationMustBeGreaterThanZero',
        ),
      ];
    }

    return const [];
  }

  static List<ValidationError> scheduleDays(
    List<int> days, {
    required RoutinePeriodType periodType,
    required RoutineScheduleMode scheduleMode,
  }) {
    if (periodType != RoutinePeriodType.week ||
        scheduleMode != RoutineScheduleMode.scheduled) {
      return const [];
    }
    if (days.isEmpty) {
      return const [
        ValidationError(code: 'required', messageKey: 'validationRequired'),
      ];
    }
    final hasInvalid = days.any((d) => d < 1 || d > 7);
    if (hasInvalid) {
      return const [
        ValidationError(code: 'invalid', messageKey: 'validationInvalid'),
      ];
    }
    final unique = days.toSet();
    if (unique.length != days.length) {
      return const [
        ValidationError(code: 'invalid', messageKey: 'validationInvalid'),
      ];
    }
    return const [];
  }

  static List<ValidationError> scheduleMonthDays(
    List<int> days, {
    required RoutinePeriodType periodType,
    required RoutineScheduleMode scheduleMode,
  }) {
    if (periodType != RoutinePeriodType.month ||
        scheduleMode != RoutineScheduleMode.scheduled) {
      return const [];
    }
    if (days.isEmpty) {
      return const [
        ValidationError(code: 'required', messageKey: 'validationRequired'),
      ];
    }
    final hasInvalid = days.any((d) => d < 1 || d > 31);
    if (hasInvalid) {
      return const [
        ValidationError(code: 'invalid', messageKey: 'validationInvalid'),
      ];
    }
    final unique = days.toSet();
    if (unique.length != days.length) {
      return const [
        ValidationError(code: 'invalid', messageKey: 'validationInvalid'),
      ];
    }
    return const [];
  }
}
