import 'package:freezed_annotation/freezed_annotation.dart';

/// Pack-only styling selector for V2 list-like templates.
///
/// This is a hard-cutover replacement for the former per-entity tile policy.
enum StylePackV2 {
  /// Comfortable spacing and default density.
  @JsonValue('standard')
  standard,

  /// Denser spacing; still must maintain usability.
  @JsonValue('compact')
  compact,
}
