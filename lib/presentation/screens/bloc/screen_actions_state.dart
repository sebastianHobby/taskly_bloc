import 'package:taskly_domain/analytics.dart';

sealed class ScreenActionsState {
  const ScreenActionsState();
}

final class ScreenActionsIdleState extends ScreenActionsState {
  const ScreenActionsIdleState();
}

enum ScreenActionsFailureKind {
  completionFailed,
  deleteFailed,
  moveFailed,
  invalidOccurrenceData,
}

final class ScreenActionsFailureState extends ScreenActionsState {
  const ScreenActionsFailureState({
    required this.failureKind,
    required this.fallbackMessage,
    this.shouldShowSnackBar = true,
    this.entityType,
    this.entityId,
    this.error,
  });

  final ScreenActionsFailureKind failureKind;
  final String fallbackMessage;

  /// When false, the error was handled elsewhere (e.g. globally reported).
  final bool shouldShowSnackBar;

  /// Optional entity context for dedupe keying.
  final EntityType? entityType;
  final String? entityId;
  final Object? error;
}
