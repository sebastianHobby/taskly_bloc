import 'package:taskly_bloc/domain/interfaces/system_screen_provider.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_definition.dart';
import 'package:taskly_bloc/presentation/shared/models/screen_preferences.dart';

/// Repository contract for managing screen definitions.
///
/// ## Architecture
///
/// Screens come from two sources:
/// 1. **System screens**: Generated from code via [SystemScreenProvider].
///    These are always available and don't require database storage.
/// 2. **Custom screens**: User-created screens stored in the database.
///
/// User preferences (sortOrder, isActive) for ALL screens are stored in
/// Preferences are stored directly in `screen_definitions`.
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
  /// Combines system screens from [SystemScreenProvider] with custom screens
  /// from the database, then applies preferences to determine visibility
  /// and sort order.
  Stream<List<ScreenWithPreferences>> watchAllScreens();

  /// Watch all system screens with preferences applied.
  Stream<List<ScreenWithPreferences>> watchSystemScreens();

  /// Watch all user-created (custom) screens from the database.
  Stream<List<ScreenDefinition>> watchCustomScreens();

  /// Watch a specific screen by screenKey.
  ///
  /// Returns system screen from code or custom screen from database.
  Stream<ScreenWithPreferences?> watchScreen(String screenKey);

  /// Create a new custom screen.
  ///
  /// Check if a screenKey already exists (system or custom).
  ///
  /// Use this to validate before creating a custom screen.
  Future<bool> screenKeyExists(String screenKey);

  /// Cannot create system screens - they come from [SystemScreenProvider].
  Future<String> createCustomScreen(ScreenDefinition screen);

  /// Update an existing custom screen.
  ///
  /// Cannot update system screens - their definitions come from code.
  Future<void> updateCustomScreen(ScreenDefinition screen);

  /// Delete a custom screen.
  ///
  /// Cannot delete system screens.
  Future<void> deleteCustomScreen(String screenKey);

  /// Update preferences for any screen (system or custom).
  ///
  /// Preferences are stored directly in `screen_definitions`.
  Future<void> updateScreenPreferences(
    String screenKey,
    ScreenPreferences preferences,
  );

  /// Reorder screens by updating their sortOrder preferences.
  Future<void> reorderScreens(List<String> orderedScreenKeys);
}
