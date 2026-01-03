import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
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
  int get effectiveSortOrder => preferences.sortOrder ?? _defaultSortOrder;

  /// Whether the screen is visible in navigation.
  bool get isActive => preferences.isActive;

  /// Default sort order based on screen type.
  int get _defaultSortOrder {
    // Import would create circular dependency, so hardcode default
    return 999;
  }
}

/// Interface for providing system screen definitions.
///
/// System screens are built-in screens that come from code templates,
/// not from the database. This interface abstracts how system screens
/// are created and identified.
///
/// ## Design Rationale
///
/// System screens are generated from code (via [SystemScreenDefinitions])
/// rather than stored in the database because:
///
/// 1. **No sync conflicts**: Code-based screens don't create PowerSync
///    V5 CONFLICT errors during seeding.
///
/// 2. **Guaranteed availability**: System screens are always available
///    even before sync completes.
///
/// 3. **Template updates**: New versions of system screen templates
///    are picked up automatically without migration.
///
/// 4. **Clean separation**: Screen "definitions" (name, icon, sections)
///    are separate from "preferences" (sortOrder, isActive).
///
/// User preferences for system screens are stored in
/// `AppSettings.screenPreferences` keyed by screenKey.
abstract interface class SystemScreenProvider {
  /// Returns all system screen definitions.
  ///
  /// Each screen will have a deterministic v5 UUID based on screenKey.
  List<ScreenDefinition> getSystemScreens();

  /// Returns a specific system screen by screenKey.
  ///
  /// Returns null if the screenKey is not a system screen.
  ScreenDefinition? getSystemScreen(String screenKey);

  /// Returns true if the given screenKey is a system screen.
  bool isSystemScreen(String screenKey);

  /// Returns all system screen keys.
  List<String> get allSystemScreenKeys;

  /// Returns the default sort order for a screen key.
  ///
  /// Returns 999 for unknown keys (sorts them last).
  int getDefaultSortOrder(String screenKey);
}
