import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/screens/app_bar_action.dart';
import 'package:taskly_bloc/domain/models/screens/fab_operation.dart';

part 'actions_config.freezed.dart';
part 'actions_config.g.dart';

/// Actions configuration for screens.
///
/// Combines FAB operations, AppBar actions, and related settings
/// into a single JSON blob for efficient PowerSync sync.
/// This structure is stored in the `actions_config` column.
@freezed
abstract class ActionsConfig with _$ActionsConfig {
  const factory ActionsConfig({
    /// FAB operations available on this screen.
    @Default([]) List<FabOperation> fabOperations,

    /// AppBar actions available on this screen.
    @Default([]) List<AppBarAction> appBarActions,

    /// Route for settings link action (when appBarActions contains settingsLink).
    String? settingsRoute,
  }) = _ActionsConfig;
  const ActionsConfig._();

  factory ActionsConfig.fromJson(Map<String, dynamic> json) =>
      _$ActionsConfigFromJson(json);

  /// Empty actions config (no FAB, no AppBar actions).
  static const empty = ActionsConfig();

  /// Convenience check if this config has any actions defined.
  bool get hasActions => fabOperations.isNotEmpty || appBarActions.isNotEmpty;
}
