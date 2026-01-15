sealed class ScreenActionsState {
  const ScreenActionsState();
}

final class ScreenActionsIdleState extends ScreenActionsState {
  const ScreenActionsIdleState();
}

final class ScreenActionsFailureState extends ScreenActionsState {
  const ScreenActionsFailureState({
    required this.message,
    this.error,
  });

  final String message;
  final Object? error;
}
