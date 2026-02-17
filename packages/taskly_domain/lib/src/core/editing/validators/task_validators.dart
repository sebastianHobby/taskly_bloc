import 'package:taskly_domain/src/core/editing/validation_error.dart';
import 'package:taskly_domain/src/forms/field_key.dart';
import 'package:taskly_domain/src/core/model/task.dart';
import 'package:taskly_domain/src/services/values/task_value_policy.dart';

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

  static List<ValidationError> valueIds(
    List<String>? valueIds, {
    String? projectId,
    String? projectPrimaryValueId,
  }) {
    final result = TaskValuePolicy.validate(
      valueIds: valueIds,
      projectId: projectId,
      projectPrimaryValueId: projectPrimaryValueId,
    );
    return TaskValuePolicy.toValidationErrors(result.issues);
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

  static Map<FieldKey, List<ValidationError>> reminderShape({
    required TaskReminderKind reminderKind,
    required DateTime? reminderAtUtc,
    required int? reminderMinutesBeforeDue,
    required DateTime? deadlineDate,
  }) {
    switch (reminderKind) {
      case TaskReminderKind.none:
        if (reminderAtUtc == null && reminderMinutesBeforeDue == null) {
          return const {};
        }
        return const {
          TaskFieldKeys.reminderKind: [
            ValidationError(
              code: 'invalid_reminder_shape',
              messageKey: 'taskFormReminderInvalid',
            ),
          ],
        };
      case TaskReminderKind.absolute:
        if (reminderAtUtc != null && reminderMinutesBeforeDue == null) {
          return const {};
        }
        return const {
          TaskFieldKeys.reminderKind: [
            ValidationError(
              code: 'invalid_reminder_shape',
              messageKey: 'taskFormReminderInvalid',
            ),
          ],
          TaskFieldKeys.reminderAtUtc: [
            ValidationError(
              code: 'required',
              messageKey: 'taskFormReminderAtRequired',
            ),
          ],
        };
      case TaskReminderKind.beforeDue:
        final minutes = reminderMinutesBeforeDue;
        if (deadlineDate == null) {
          return const {
            TaskFieldKeys.deadlineDate: [
              ValidationError(
                code: 'required_for_reminder',
                messageKey: 'taskFormReminderDueDateRequired',
              ),
            ],
          };
        }
        if (reminderAtUtc == null &&
            minutes != null &&
            minutes >= 0 &&
            minutes <= 10080) {
          return const {};
        }
        return const {
          TaskFieldKeys.reminderMinutesBeforeDue: [
            ValidationError(
              code: 'invalid',
              messageKey: 'taskFormReminderBeforeDueInvalid',
            ),
          ],
        };
    }
  }
}
