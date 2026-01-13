import 'package:flutter/foundation.dart';

/// Compile-time flags to enable/disable UI prototypes.
///
/// Prototypes are intentionally gated behind `kDebugMode` to ensure they do not
/// affect production builds.
abstract final class PrototypeFlags {
  /// Enabled in debug builds only.
  ///
  /// Keeping this as a single switch makes prototypes easy to remove later and
  /// ensures they never surface in production releases.
  static bool get isMyDayPrototypeEnabled => kDebugMode;
}
