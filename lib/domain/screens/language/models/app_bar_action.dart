import 'package:json_annotation/json_annotation.dart';

/// Actions that can appear in the AppBar of a unified screen.
///
/// Used by [ScreenChrome.appBarActions] to declaratively specify what actions
/// are available in the screen's AppBar.
enum AppBarAction {
  /// Settings/tune button - navigates to a settings route.
  /// Requires [ScreenChrome.settingsRoute] to be set.
  @JsonValue('settings_link')
  settingsLink,

  /// Help/about dialog button.
  /// Shows screen-specific help content.
  @JsonValue('help')
  help,
}
