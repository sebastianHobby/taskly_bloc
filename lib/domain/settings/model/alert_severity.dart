import 'package:json_annotation/json_annotation.dart';

/// Severity levels for allocation alerts.
///
/// Determines banner styling and sort order.
enum AlertSeverity {
  /// Red banner, highest priority
  @JsonValue('critical')
  critical,

  /// Amber banner, medium priority
  @JsonValue('warning')
  warning,

  /// Blue banner, informational
  @JsonValue('notice')
  notice,
}

extension AlertSeverityX on AlertSeverity {
  /// Sort order (lower = more severe)
  int get sortOrder => switch (this) {
    AlertSeverity.critical => 0,
    AlertSeverity.warning => 1,
    AlertSeverity.notice => 2,
  };

  String get displayName => switch (this) {
    AlertSeverity.critical => 'Critical',
    AlertSeverity.warning => 'Warning',
    AlertSeverity.notice => 'Notice',
  };
}
