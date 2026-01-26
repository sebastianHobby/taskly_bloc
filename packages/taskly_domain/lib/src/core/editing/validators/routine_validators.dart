import 'package:taskly_domain/src/core/editing/validation_error.dart';
import 'package:taskly_domain/src/routines/model/routine_type.dart';

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

  static List<ValidationError> valueId(String? valueId) {
    if (valueId == null || valueId.trim().isEmpty) {
      return const [
        ValidationError(code: 'required', messageKey: 'validationRequired'),
      ];
    }
    return const [];
  }

  static List<ValidationError> targetCount(
    int? count, {
    required RoutineType routineType,
  }) {
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

    final max = switch (routineType) {
      RoutineType.weeklyFixed => 7,
      RoutineType.weeklyFlexible => 7,
      RoutineType.monthlyFixed => 1,
      RoutineType.monthlyFlexible => 4,
    };
    if (count > max) {
      return [
        ValidationError(
          code: 'max_value',
          messageKey: 'validationMaxValue',
          args: {'max': max},
        ),
      ];
    }
    return const [];
  }

  static List<ValidationError> scheduleDays(
    List<int> days, {
    required RoutineType routineType,
  }) {
    if (routineType != RoutineType.weeklyFixed &&
        routineType != RoutineType.weeklyFlexible) {
      return const [];
    }
    if (days.isEmpty) return const [];
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

  static List<ValidationError> preferredWeeks(
    List<int> weeks, {
    required RoutineType routineType,
  }) {
    if (routineType != RoutineType.monthlyFlexible) return const [];
    if (weeks.isEmpty) {
      return const [
        ValidationError(code: 'required', messageKey: 'validationRequired'),
      ];
    }
    final hasInvalid = weeks.any((w) => w < 1 || w > 5);
    if (hasInvalid) {
      return const [
        ValidationError(code: 'invalid', messageKey: 'validationInvalid'),
      ];
    }
    final unique = weeks.toSet();
    if (unique.length != weeks.length) {
      return const [
        ValidationError(code: 'invalid', messageKey: 'validationInvalid'),
      ];
    }
    return const [];
  }

  static List<ValidationError> fixedMonthlyFields({
    required int? fixedDayOfMonth,
    required int? fixedWeekday,
    required int? fixedWeekOfMonth,
    required RoutineType routineType,
  }) {
    if (routineType != RoutineType.monthlyFixed) return const [];

    final hasDayOfMonth = fixedDayOfMonth != null;
    final hasWeekday = fixedWeekday != null;
    final hasWeekOfMonth = fixedWeekOfMonth != null;

    if (!hasDayOfMonth && !(hasWeekday && hasWeekOfMonth)) {
      return const [
        ValidationError(code: 'required', messageKey: 'validationRequired'),
      ];
    }

    if (fixedDayOfMonth != null &&
        (fixedDayOfMonth < 1 || fixedDayOfMonth > 31)) {
      return const [
        ValidationError(code: 'invalid', messageKey: 'validationInvalid'),
      ];
    }
    if (fixedWeekday != null &&
        (fixedWeekday < 1 || fixedWeekday > 7)) {
      return const [
        ValidationError(code: 'invalid', messageKey: 'validationInvalid'),
      ];
    }
    if (fixedWeekOfMonth != null &&
        (fixedWeekOfMonth < 1 || fixedWeekOfMonth > 5)) {
      return const [
        ValidationError(code: 'invalid', messageKey: 'validationInvalid'),
      ];
    }

    return const [];
  }
}
