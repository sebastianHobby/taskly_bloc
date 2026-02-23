import 'package:taskly_domain/src/core/editing/validation_error.dart';
import 'package:taskly_domain/src/forms/field_key.dart';

final class ProjectValidators {
  ProjectValidators._();

  static const int maxDescriptionLength = 8000;

  static List<ValidationError> name(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) {
      return const [
        ValidationError(
          code: 'required',
          messageKey: 'projectFormTitleRequired',
        ),
      ];
    }
    if (trimmed.length > 120) {
      return const [
        ValidationError(
          code: 'max_length',
          messageKey: 'projectFormTitleTooLong',
        ),
      ];
    }
    return const [];
  }

  static List<ValidationError> description(String? value) {
    if (value != null && value.length > maxDescriptionLength) {
      return const [
        ValidationError(
          code: 'max_length',
          messageKey: 'projectFormDescriptionTooLong',
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
          messageKey: 'projectFormRepeatRuleTooLong',
        ),
      ];
    }
    return const [];
  }

  static List<ValidationError> valueIds(List<String>? valueIds) {
    final ids = valueIds ?? const <String>[];
    final hasValue = ids.any((id) => id.trim().isNotEmpty);
    if (!hasValue) {
      return const [
        ValidationError(
          code: 'required',
          messageKey: 'projectFormValuesRequired',
        ),
      ];
    }
    final normalized = ids.where((id) => id.trim().isNotEmpty).toList();
    if (normalized.length > 1) {
      return const [
        ValidationError(
          code: 'max_items',
          messageKey: 'projectFormSingleValueOnly',
        ),
      ];
    }
    return const [];
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
        messageKey: 'projectFormDeadlineAfterStartError',
      ),
    ];
    return {
      ProjectFieldKeys.startDate: errors,
      ProjectFieldKeys.deadlineDate: errors,
    };
  }

  static Map<FieldKey, List<ValidationError>> recurrenceShape({
    required String? repeatIcalRrule,
    required DateTime? startDate,
  }) {
    final hasRecurrence = (repeatIcalRrule ?? '').trim().isNotEmpty;
    if (!hasRecurrence || startDate != null) return const {};

    const errors = [
      ValidationError(code: 'required', messageKey: 'validationRequired'),
    ];
    return {ProjectFieldKeys.startDate: errors};
  }
}
