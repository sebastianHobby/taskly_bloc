import 'package:taskly_bloc/domain/models/priority/allocation_preference.dart';

/// Repository interface for managing user allocation preferences
abstract class AllocationPreferencesRepository {
  /// Watch the current user's allocation preferences
  Stream<AllocationPreference?> watchPreferences();

  /// Get the current user's allocation preferences (one-time fetch)
  Future<AllocationPreference?> getPreferences();

  /// Create or update allocation preferences
  Future<void> savePreferences({
    required AllocationStrategyType strategyType,
    double? urgencyInfluence,
    int? minimumTasksPerCategory,
    int? topNCategories,
  });

  /// Reset preferences to defaults
  Future<void> resetToDefaults();
}
