import 'package:flutter/foundation.dart';

/// A stable identifier for a screen.
///
/// In routing, screen keys are represented as URL segments where underscores
/// become hyphens (e.g. `my_day` -> `my-day`).
@immutable
final class ScreenKey {
  const ScreenKey(this.value);

  /// Parses a route segment into a [ScreenKey].
  ///
  /// This reverses [toRouteSegment].
  factory ScreenKey.fromRouteSegment(String segment) {
    return ScreenKey(segment.replaceAll('-', '_'));
  }

  /// The canonical internal value (typically snake_case).
  final String value;

  /// Converts this key into a URL-safe route segment.
  String toRouteSegment() => value.replaceAll('_', '-');

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) => other is ScreenKey && other.value == value;

  @override
  int get hashCode => value.hashCode;
}
