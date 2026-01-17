import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:taskly_core/logging.dart';

/// Initializes app logging (Talker + file observers).
void bootstrapLogging() {
  // Required by package:logging if we want to adjust levels on non-root loggers.
  // Without this, `Logger('PowerSync').level = ...` throws at runtime.
  hierarchicalLoggingEnabled = true;

  // Initialize Talker logging system first (outside zone so it's always
  // available). Note: File logging observer defers initialization until first
  // log to ensure bindings ready.
  initializeLogging();

  _setupPowerSyncLogging();
}

/// Set up PowerSync logging integration.
///
/// PowerSync SDK uses Dart's `logging` package. By listening to
/// `Logger.root.onRecord`, we can forward all PowerSync logs to Talker.
void _setupPowerSyncLogging() {
  // Set level for PowerSync logs only.
  //
  // Default: INFO (useful sync activity, low noise)
  // Opt-in: FINE via --dart-define=POWERSYNC_VERBOSE_LOGS=true
  const powersyncVerbose = bool.fromEnvironment('POWERSYNC_VERBOSE_LOGS');
  Logger('PowerSync').level = (kDebugMode && powersyncVerbose)
      ? Level.FINE
      : Level.INFO;

  Logger.root.onRecord.listen((record) {
    // Only process PowerSync logs (not other logging package users)
    if (!record.loggerName.contains('PowerSync')) {
      return;
    }

    // Map logging levels to Talker methods
    final message =
        '[${record.loggerName}] ${record.level.name}: ${record.message}';

    // Persist a narrow slice of sync activity to the debug file log.
    // This helps correlate settings writes with PowerSync upload/download.
    final isSettingsSyncSignal =
        record.message.contains('user_profiles') ||
        record.message.contains('ps_crud');

    if (record.level >= Level.SEVERE) {
      talker.error(message, record.error, record.stackTrace);
    } else if (record.level >= Level.WARNING) {
      talker.warning(message);
    } else if (record.level >= Level.INFO) {
      if (isSettingsSyncSignal) {
        talker.warning(message);
      } else {
        talker.info(message);
      }
    } else {
      // FINE, FINER, FINEST -> debug
      talker.debug(message);
    }
  });
}
