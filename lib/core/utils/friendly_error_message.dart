import 'package:taskly_bloc/data/repositories/repository_exceptions.dart';
import 'package:taskly_bloc/core/l10n/gen/app_localizations.dart';
import 'package:taskly_bloc/core/utils/not_found_entity.dart';

/// Returns a user-friendly error message for display in the UI.
///
/// This avoids leaking raw exception strings to end users.
String friendlyErrorMessage(Object error) {
  if (error is RepositoryException) {
    return error.message;
  }

  // Keep a conservative default for unexpected errors.
  return 'Something went wrong. Please try again.';
}

/// Returns a user-friendly error message localized for the current UI locale.
///
/// Prefer this in UI code where an [AppLocalizations] instance is available.
String friendlyErrorMessageForUi(Object error, AppLocalizations l10n) {
  if (error is String) {
    return error;
  }

  if (error is NotFoundEntity) {
    return switch (error) {
      NotFoundEntity.task => l10n.taskNotFound,
      NotFoundEntity.project => l10n.projectNotFound,
      NotFoundEntity.label => l10n.labelNotFound,
    };
  }

  if (error is RepositoryException) {
    return error.message;
  }

  return l10n.genericErrorFallback;
}
