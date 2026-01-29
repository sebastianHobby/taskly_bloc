/// Build-time flags for debug bootstrap behavior.
///
/// These are compile-time constants controlled via `--dart-define`.
abstract final class DebugBootstrapFlags {
  /// Enables the debug bootstrap modal on app launch (debug only).
  static const bool enableDebugBootstrapModal = bool.fromEnvironment(
    'TASKLY_DEBUG_BOOTSTRAP_MODAL',
    defaultValue: true,
  );

  /// Enables the "wipe account + reset onboarding" action in the modal.
  static const bool enableAccountWipeOption = bool.fromEnvironment(
    'TASKLY_DEBUG_BOOTSTRAP_WIPE_ACCOUNT',
    defaultValue: true,
  );
}
