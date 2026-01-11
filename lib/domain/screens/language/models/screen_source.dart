import 'package:freezed_annotation/freezed_annotation.dart';

/// The source/origin of a screen definition.
///
/// Distinguishes between built-in system templates and user-created screens.
enum ScreenSource {
  /// System-provided screen template (e.g., Inbox, Today, Projects).
  /// These are built into the app and cannot be deleted, only hidden.
  @JsonValue('system_template')
  systemTemplate,

  /// User-defined custom screen created by the user.
  /// These can be fully edited and deleted.
  @JsonValue('user_defined')
  userDefined,
}
