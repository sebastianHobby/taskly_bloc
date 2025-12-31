import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';

/// Repository contract for managing screen definitions
abstract class ScreenDefinitionsRepositoryContract {
  /// Watch all active screen definitions
  Stream<List<ScreenDefinition>> watchAllScreens();

  /// Watch all system screens
  Stream<List<ScreenDefinition>> watchSystemScreens();

  /// Watch all user-created screens
  Stream<List<ScreenDefinition>> watchUserScreens();

  /// Watch a specific screen by ID
  Stream<ScreenDefinition?> watchScreen(String id);

  /// Watch a specific screen by screenId (e.g., 'today', 'inbox')
  Stream<ScreenDefinition?> watchScreenByScreenId(String screenId);

  /// Create a new screen definition
  Future<String> createScreen(ScreenDefinition screen);

  /// Update an existing screen definition
  Future<void> updateScreen(ScreenDefinition screen);

  /// Delete a screen definition
  Future<void> deleteScreen(String id);

  /// Activate/deactivate a screen
  Future<void> setScreenActive(String id, bool isActive);

  /// Reorder screens
  Future<void> reorderScreens(List<String> orderedIds);
}
