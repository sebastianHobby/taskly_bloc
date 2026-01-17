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

    default:
      return error.messageKey;
  }
}
