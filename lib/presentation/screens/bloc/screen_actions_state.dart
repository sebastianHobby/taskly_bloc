import 'package:taskly_domain/analytics.dart';

sealed class ScreenActionsState {
  const ScreenActionsState();
}

final class ScreenActionsIdleState extends ScreenActionsState {
  const ScreenActionsIdleState();
}

enum ScreenActionsFailureKind {
  completionFailed,
  pinFailed,
  deleteFailed,
  moveFailed,
  invalidOccurrenceData,
}

final class ScreenActionsFailureState extends ScreenActionsState {
  const ScreenActionsFailureState({
    required this.failureKind,
    required this.fallbackMessage,
    this.entityType,
    this.entityId,
    this.error,
  });

  final ScreenActionsFailureKind failureKind;
  final String fallbackMessage;

  /// Optional entity context for dedupe keying.
  final EntityType? entityType;
  final String? entityId;
  final Object? error;
}
