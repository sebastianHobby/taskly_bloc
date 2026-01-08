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
/// ## Architecture Change (2026-01)
///
/// System screens are now **seeded to the database** via [ScreenSeeder],
/// matching the pattern used by [AttentionSeeder]. This enables:
///
/// 1. **Unified cleanup**: [SystemDataCleanupService] can delete orphaned
///    system screens when templates are renamed/removed.
///
/// 2. **Consistent architecture**: Screens and attention rules follow
///    the same seed → read from DB → cleanup pattern.
///
/// 3. **PowerSync sync**: All screens flow through normal sync.
///
/// This interface now provides **validation and lookup only**:
/// - Check if a screenKey is a system screen
/// - Get template data for seeding
///
/// Runtime screen data comes from the database, not this provider.
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
