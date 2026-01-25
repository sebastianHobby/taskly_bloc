import 'package:flutter/widgets.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_bloc/l10n/l10n.dart';

/// Maps a domain [ValidationError] to user-facing text.
///
/// If [ValidationError.messageKey] matches a known localization key, this
/// returns the localized string. Otherwise it falls back to the raw
/// [messageKey] value.
String validationErrorMessage(BuildContext context, ValidationError error) {
  final l10n = context.l10n;

  switch (error.messageKey) {
    // Task
    case 'taskFormNameRequired':
      return l10n.taskFormNameRequired;
    case 'taskFormNameTooLong':
      return l10n.taskFormNameTooLong;
    case 'taskFormDescriptionTooLong':
      return l10n.taskFormDescriptionTooLong;
    case 'taskFormRepeatRuleTooLong':
      return l10n.taskFormRepeatRuleTooLong;
    case 'taskFormDeadlineAfterStartError':
      return l10n.taskFormDeadlineAfterStartError;
    case 'taskFormValuesRequired':
      return l10n.taskFormValuesRequired;
    case 'taskFormValuesRequireProject':
      return l10n.taskFormValuesRequireProject;
    case 'taskFormValuesRequireProjectPrimary':
      return l10n.taskFormValuesRequireProjectPrimary;
    case 'taskFormValuesMaxTwo':
      return l10n.taskFormValuesMaxTwo;
    case 'taskFormValuesMustBeUnique':
      return l10n.taskFormValuesMustBeUnique;
    case 'taskFormValuesCannotMatchProjectPrimary':
      return l10n.taskFormValuesCannotMatchProjectPrimary;

    // Project
    case 'projectFormTitleRequired':
      return l10n.projectFormTitleRequired;
    case 'projectFormTitleTooLong':
      return l10n.projectFormTitleTooLong;
    case 'projectFormDescriptionTooLong':
      return l10n.projectFormDescriptionTooLong;
    case 'projectFormRepeatRuleTooLong':
      return l10n.projectFormRepeatRuleTooLong;
    case 'projectFormDeadlineAfterStartError':
      return l10n.projectFormDeadlineAfterStartError;
    case 'projectFormValuesRequired':
      return l10n.projectFormValuesRequired;
    case 'projectFormSingleValueOnly':
      return l10n.projectFormSingleValueOnly;

    // Value
    case 'valueFormNameRequired':
      return l10n.valueFormNameRequired;
    case 'valueFormNameTooLong':
      final max = error.args['max'] as int? ?? 30;
      return l10n.valueFormNameTooLong(max);
    case 'validationRequired':
      return l10n.validationRequired;

    default:
      return error.messageKey;
  }
}
