import 'package:json_annotation/json_annotation.dart';

/// Actions that can appear in the AppBar of a data-driven screen.
///
/// Used by [DataDrivenScreenDefinition.appBarActions] to declaratively specify
/// what actions are available in the screen's AppBar.
enum AppBarAction {
  /// Settings/tune button - navigates to a settings route.
  /// Requires [DataDrivenScreenDefinition.settingsRoute] to be set.
  @JsonValue('settings_link')
  settingsLink,

  /// Help/about dialog button.
  /// Shows screen-specific help content.
  @JsonValue('help')
  help,
}
