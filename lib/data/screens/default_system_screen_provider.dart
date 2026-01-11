import 'package:taskly_bloc/domain/interfaces/system_screen_provider.dart';
import 'package:taskly_bloc/domain/screens/catalog/system_screens/system_screen_definitions.dart';

/// Default implementation of [SystemScreenProvider].
///
/// Provides validation and lookup for system screen keys.
/// Delegates to [SystemScreenDefinitions] for all operations.
///
/// ## Architecture Change (2026-01)
///
/// This provider is now **simplified** - it only validates screen keys.
/// Runtime screen data comes from the database (seeded by [ScreenSeeder]).
class DefaultSystemScreenProvider implements SystemScreenProvider {
  /// Const constructor - this class has no mutable state.
  const DefaultSystemScreenProvider();

  @override
  bool isSystemScreen(String screenKey) {
    return SystemScreenDefinitions.isSystemScreen(screenKey);
  }

  @override
  List<String> get allSystemScreenKeys => SystemScreenDefinitions.allKeys;
}
