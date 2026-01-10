import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/screens/system_screen_definitions.dart';
import 'package:taskly_bloc/domain/models/settings/screen_preferences.dart';

/// A screen with its associated user preferences.
///
/// Combines a [ScreenDefinition] (the template) with [ScreenPreferences]
/// (user customizations like sortOrder and isActive).
class ScreenWithPreferences {
  const ScreenWithPreferences({
    required this.screen,
    this.preferences = const ScreenPreferences(),
  });

  /// The screen definition (template data).
  final ScreenDefinition screen;

  /// User preferences for this screen (sortOrder, isActive).
  final ScreenPreferences preferences;

  /// Effective sort order (user preference or default).
  int get effectiveSortOrder =>
      preferences.sortOrder ??
      SystemScreenDefinitions.getDefaultSortOrder(screen.screenKey);

  /// Whether the screen is visible in navigation.
  bool get isActive => preferences.isActive;
}

/// Interface for validating and looking up system screen definitions.
///
/// ## Architecture (Option B)
///
/// System screen *definitions* are authored in code via
/// [SystemScreenDefinitions].
///
/// The database stores:
/// - Custom screen definitions (`screen_definitions` rows with
///   `source='user_created'`)
/// - User preferences for system and custom screens (`screen_preferences`)
/// - Legacy system preference fallback (older `screen_definitions` rows with
///   `source='system_template'` that only contribute `isActive/sortOrder`)
///
/// [ScreenSeeder] may exist for migration/backward-compatibility, but runtime
/// system screen definitions do not depend on seeded DB rows.
///
/// This interface provides **validation and lookup only**:
/// - Check if a `screenKey` is reserved for a system screen
/// - Provide the canonical list of system screen keys
abstract interface class SystemScreenProvider {
  /// Returns true if the given screenKey is a system screen.
  ///
  /// Used to prevent users from creating custom screens with system keys.
  bool isSystemScreen(String screenKey);

  /// Returns all system screen keys.
  ///
  /// Used by [SystemDataCleanupService] to identify orphaned screens.
  List<String> get allSystemScreenKeys;
}
