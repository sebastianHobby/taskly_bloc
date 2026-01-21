import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:powersync/powersync.dart' show attachedLogger;
import 'package:taskly_core/logging.dart';

bool _installed = false;

/// Forwards PowerSync SDK logs (emitted via `package:logging`) into Taskly's
/// Talker-based logging.
///
/// PowerSync uses `attachedLogger` (a `Logger('PowerSync')`). It does not emit
/// anywhere by default; callers must subscribe to `Logger.root.onRecord`.
///
/// This is safe to call multiple times.
void installPowerSyncLogForwarding() {
  if (_installed) return;
  _installed = true;

  // Required by package:logging if we want to adjust levels on non-root loggers.
  // Without this, `attachedLogger.level = ...` can throw at runtime.
  hierarchicalLoggingEnabled = true;

  // Default: INFO (useful sync activity, low noise)
  // Opt-in: FINE via --dart-define=POWERSYNC_VERBOSE_LOGS=true
  const powersyncVerbose = bool.fromEnvironment('POWERSYNC_VERBOSE_LOGS');
  attachedLogger.level = (kDebugMode && powersyncVerbose)
      ? Level.FINE
      : Level.INFO;

  Logger.root.onRecord.listen((record) {
    // Only process PowerSync logs (not other logging package users)
    if (!record.loggerName.contains('PowerSync')) {
      return;
    }

    final message =
        '[${record.loggerName}] ${record.level.name}: ${record.message}';

    if (record.level >= Level.SEVERE) {
      talker.error(message, record.error, record.stackTrace);
    } else if (record.level >= Level.WARNING) {
      talker.warning(message);
    } else if (record.level >= Level.INFO) {
      talker.info(message);
    } else {
      // FINE, FINER, FINEST -> debug
      talker.debug(message);
    }
  });
}
