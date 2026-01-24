import 'package:taskly_domain/src/core/editing/validation_error.dart';
import 'package:taskly_domain/src/forms/field_key.dart';

final class TaskValidators {
  TaskValidators._();

  static List<ValidationError> name(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) {
      return const [
        ValidationError(code: 'required', messageKey: 'taskFormNameRequired'),
      ];
    }
    if (trimmed.length > 120) {
      return const [
        ValidationError(code: 'max_length', messageKey: 'taskFormNameTooLong'),
      ];
    }
    return const [];
  }

  static List<ValidationError> description(String? value) {
    if (value != null && value.length > 200) {
      return const [
        ValidationError(
          code: 'max_length',
          messageKey: 'taskFormDescriptionTooLong',
        ),
      ];
    }
    return const [];
  }

  static List<ValidationError> repeatRule(String? value) {
    if (value != null && value.length > 500) {
      return const [
        ValidationError(
          code: 'max_length',
          messageKey: 'taskFormRepeatRuleTooLong',
        ),
      ];
    }
    return const [];
  }

  static List<ValidationError> valueIds(List<String>? valueIds) {
    final ids = valueIds ?? const <String>[];
    final hasValue = ids.any((id) => id.trim().isNotEmpty);
    if (hasValue) return const [];
    return const [
      ValidationError(
        code: 'required',
        messageKey: 'taskFormValuesRequired',
      ),
    ];
  }

  static Map<FieldKey, List<ValidationError>> dateOrder(
    DateTime? startDate,
    DateTime? deadlineDate,
  ) {
    if (startDate == null || deadlineDate == null) return const {};

    final startDay = DateTime(startDate.year, startDate.month, startDate.day);
    final deadlineDay = DateTime(
      deadlineDate.year,
      deadlineDate.month,
      deadlineDate.day,
    );

    if (!deadlineDay.isBefore(startDay)) return const {};

    const errors = [
      ValidationError(
        code: 'deadline_before_start',
        messageKey: 'taskFormDeadlineAfterStartError',
      ),
    ];
    return {
      TaskFieldKeys.startDate: errors,
      TaskFieldKeys.deadlineDate: errors,
    };
  }
}
