import 'package:taskly_bloc/domain/screens/catalog/model/screen_preferences.dart';
import 'package:taskly_bloc/domain/screens/catalog/system_screens/system_screen_specs.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_spec.dart';

/// A screen spec combined with user preferences.
class ScreenWithPreferences {
  const ScreenWithPreferences({
    required this.screen,
    this.preferences = const ScreenPreferences(),
  });

  final ScreenSpec screen;
  final ScreenPreferences preferences;

  int get effectiveSortOrder =>
      preferences.sortOrder ??
      SystemScreenSpecs.getDefaultSortOrder(screen.screenKey);

  bool get isActive => preferences.isActive;
}

/// Repository contract for system screen catalog + user preferences.
///
/// ## Architecture
///
/// - Screen specs are code-based via [SystemScreenSpecs].
/// - User preferences (`sortOrder`, `isActive`) are stored in `screen_preferences`.
abstract class ScreenCatalogRepositoryContract {
  /// Watch all active screens (system), sorted by effective sortOrder.
  Stream<List<ScreenWithPreferences>> watchAllScreens();

  /// Watch all system screens with preferences applied.
  Stream<List<ScreenWithPreferences>> watchSystemScreens();

  /// Watch a specific screen by screenKey.
  ///
  /// Returns system screen from code (or null if unknown).
  Stream<ScreenWithPreferences?> watchScreen(String screenKey);

  /// Update preferences for a system screen.
  Future<void> updateScreenPreferences(
    String screenKey,
    ScreenPreferences preferences,
  );

  /// Reorder screens by updating their sortOrder preferences.
  Future<void> reorderScreens(List<String> orderedScreenKeys);
}
