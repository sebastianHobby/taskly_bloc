import 'package:taskly_bloc/domain/screens/language/models/screen_definition.dart';
import 'package:taskly_bloc/domain/screens/catalog/system_screens/system_screen_definitions.dart';
import 'package:taskly_bloc/presentation/shared/models/screen_preferences.dart';

/// A screen definition combined with user preferences.
class ScreenWithPreferences {
  const ScreenWithPreferences({
    required this.screen,
    this.preferences = const ScreenPreferences(),
  });

  final ScreenDefinition screen;
  final ScreenPreferences preferences;

  int get effectiveSortOrder =>
      preferences.sortOrder ??
      SystemScreenDefinitions.getDefaultSortOrder(screen.screenKey);

  bool get isActive => preferences.isActive;
}

/// Repository contract for managing screen definitions.
///
/// ## Architecture
///
/// Screens come from code via `SystemScreenDefinitions`.
///
/// User preferences (sortOrder, isActive) for system screens are stored in
/// `screen_preferences`.
///
/// ## Why System Screens Are Code-Based
///
/// System screens are generated from code rather than stored in the database
/// to avoid PowerSync sync conflicts. This ensures:
/// - No V5 CONFLICT errors during seeding
/// - System screens available immediately on app start
/// - Template updates applied automatically
abstract class ScreenDefinitionsRepositoryContract {
  /// Watch all active screens (system + custom), sorted by effective sortOrder.
  ///
  /// Applies preferences to determine visibility and sort order.
  Stream<List<ScreenWithPreferences>> watchAllScreens();

  /// Watch all system screens with preferences applied.
  Stream<List<ScreenWithPreferences>> watchSystemScreens();

  /// Watch a specific screen by screenKey.
  ///
  /// Returns system screen from code.
  Stream<ScreenWithPreferences?> watchScreen(String screenKey);

  /// Update preferences for any screen (system or custom).
  ///
  /// Preferences are stored in `screen_preferences`.
  Future<void> updateScreenPreferences(
    String screenKey,
    ScreenPreferences preferences,
  );

  /// Reorder screens by updating their sortOrder preferences.
  Future<void> reorderScreens(List<String> orderedScreenKeys);
}
