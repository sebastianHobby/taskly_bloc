import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/screens/language/models/app_bar_action.dart';
import 'package:taskly_bloc/domain/screens/language/models/badge_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/fab_operation.dart';

part 'screen_chrome.freezed.dart';
part 'screen_chrome.g.dart';

/// Declarative configuration for screen UI chrome.
///
/// This groups UI metadata (icon, badges, app bar actions, FAB actions) so that
/// the screen spec stays focused on content structure (sections) and identity.
@freezed
abstract class ScreenChrome with _$ScreenChrome {
  const factory ScreenChrome({
    /// Icon for display in navigation.
    String? iconName,

    /// Badge configuration for navigation display.
    @Default(BadgeConfig.fromFirstSection()) BadgeConfig badgeConfig,

    /// FAB operations available on this screen.
    @Default(<FabOperation>[]) List<FabOperation> fabOperations,

    /// AppBar actions available on this screen.
    @Default(<AppBarAction>[]) List<AppBarAction> appBarActions,

    /// Route for settings link action (when appBarActions contains settingsLink).
    String? settingsRoute,
  }) = _ScreenChrome;

  const ScreenChrome._();

  factory ScreenChrome.fromJson(Map<String, dynamic> json) =>
      _$ScreenChromeFromJson(json);

  static const empty = ScreenChrome();
}
