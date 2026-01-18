import 'package:taskly_core/logging.dart';

/// Initializes app logging (Talker + file observers).
void bootstrapLogging() {
  // Initialize Talker logging system first (outside zone so it's always
  // available). Note: File logging observer defers initialization until first
  // log to ensure bindings ready.
  initializeLogging();
}
