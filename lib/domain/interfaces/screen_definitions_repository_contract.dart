import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';

/// Repository contract for managing screen definitions
///
/// System screens are seeded to the database on user login with deterministic
/// UUIDs. User preferences for screens (sortOrder, isActive) are stored
/// alongside the screen definition. Custom user screens are also stored in
/// the database.
abstract class ScreenDefinitionsRepositoryContract {
  /// Watch all active screen definitions (system + custom screens).
  Stream<List<ScreenDefinition>> watchAllScreens();

  /// Watch all system screens.
  Stream<List<ScreenDefinition>> watchSystemScreens();

  /// Watch all user-created screens.
  Stream<List<ScreenDefinition>> watchUserScreens();

  /// Watch a specific screen by ID.
  Stream<ScreenDefinition?> watchScreen(String id);

  /// Watch a specific screen by screenKey (e.g., 'today', 'inbox').
  ///
  /// Works for both system screens and custom screens.
  Stream<ScreenDefinition?> watchScreenByScreenKey(String screenKey);

  /// Seed system screens for a user.
  ///
  /// Uses INSERT OR IGNORE so duplicate screens are safely skipped.
  /// This is called on every login to ensure system screens exist.
  Future<void> seedSystemScreens(List<ScreenDefinition> screens);

  /// Create a new custom screen definition.
  ///
  /// Cannot create system screens - they are seeded via [seedSystemScreens].
  Future<String> createScreen(ScreenDefinition screen);

  /// Update an existing screen definition.
  Future<void> updateScreen(ScreenDefinition screen);

  /// Delete a screen definition.
  ///
  /// Cannot delete system screens.
  Future<void> deleteScreen(String id);

  /// Activate/deactivate a screen.
  Future<void> setScreenActive(String screenKey, bool isActive);

  /// Reorder screens by screen keys.
  Future<void> reorderScreens(List<String> orderedScreenKeys);
}
