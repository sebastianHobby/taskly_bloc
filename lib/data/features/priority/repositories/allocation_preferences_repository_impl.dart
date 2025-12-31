import 'package:drift/drift.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart' as db;
import 'package:taskly_bloc/data/drift/features/priority_tables.drift.dart'
    as db_priority;
import 'package:taskly_bloc/domain/models/priority/allocation_preference.dart'
    as model;
import 'package:taskly_bloc/domain/interfaces/allocation_preferences_repository_contract.dart';
import 'package:uuid/uuid.dart';

/// Drift implementation of allocation preferences repository
class AllocationPreferencesRepositoryImpl
    implements AllocationPreferencesRepositoryContract {
  AllocationPreferencesRepositoryImpl(this._db);

  final db.AppDatabase _db;
  final _uuid = const Uuid();

  @override
  Stream<model.AllocationPreference?> watchPreferences() {
    // Use watch() instead of watchSingleOrNull() to handle multiple rows gracefully
    return _db.select(_db.allocationPreferences).watch().map(
      (prefs) {
        if (prefs.isEmpty) return null;
        // Take first if multiple exist (cleanup happens in getPreferences)
        final pref = prefs.first;
        return model.AllocationPreference(
          id: pref.id,
          userId: pref.userId ?? '',
          createdAt: pref.createdAt,
          updatedAt: pref.updatedAt,
          strategyType: _mapStrategyType(pref.strategyType),
          urgencyInfluence: pref.urgencyInfluence,
          minimumTasksPerCategory: pref.minimumTasksPerCategory,
          topNCategories: pref.topNCategories,
          dailyTaskLimit: pref.dailyTaskLimit,
          showExcludedUrgentWarning: pref.showExcludedUrgentWarning == 1,
        );
      },
    );
  }

  @override
  Future<model.AllocationPreference?> getPreferences() async {
    // Use get() instead of getSingleOrNull() to handle multiple rows gracefully
    final prefs = await _db.select(_db.allocationPreferences).get();
    if (prefs.isEmpty) return null;

    // If there are duplicates, clean them up (keep only the first one)
    if (prefs.length > 1) {
      await _cleanupDuplicatePreferences(prefs);
    }

    final pref = prefs.first;
    return model.AllocationPreference(
      id: pref.id,
      userId: pref.userId ?? '',
      createdAt: pref.createdAt,
      updatedAt: pref.updatedAt,
      strategyType: _mapStrategyType(pref.strategyType),
      urgencyInfluence: pref.urgencyInfluence,
      minimumTasksPerCategory: pref.minimumTasksPerCategory,
      topNCategories: pref.topNCategories,
      dailyTaskLimit: pref.dailyTaskLimit,
      showExcludedUrgentWarning: pref.showExcludedUrgentWarning == 1,
    );
  }

  /// Removes duplicate preference rows, keeping only the first one.
  Future<void> _cleanupDuplicatePreferences(
    List<db.AllocationPreferenceEntity> prefs,
  ) async {
    // Keep the first, delete the rest
    final idsToDelete = prefs.skip(1).map((p) => p.id).toList();
    if (idsToDelete.isNotEmpty) {
      await (_db.delete(
        _db.allocationPreferences,
      )..where((t) => t.id.isIn(idsToDelete))).go();
    }
  }

  @override
  Future<void> savePreferences({
    required model.AllocationStrategyType strategyType,
    double? urgencyInfluence,
    int? minimumTasksPerCategory,
    int? topNCategories,
    int? dailyTaskLimit,
    bool? showExcludedUrgentWarning,
    int? urgencyThresholdDays,
  }) async {
    final now = DateTime.now();
    // Use get() to handle multiple rows gracefully
    final allPrefs = await _db.select(_db.allocationPreferences).get();
    final existing = allPrefs.isNotEmpty ? allPrefs.first : null;

    // Clean up duplicates if any
    if (allPrefs.length > 1) {
      await _cleanupDuplicatePreferences(allPrefs);
    }

    final resolvedUrgencyInfluence =
        urgencyInfluence ?? existing?.urgencyInfluence ?? 0.4;
    final resolvedMinimumTasksPerCategory =
        minimumTasksPerCategory ?? existing?.minimumTasksPerCategory ?? 1;
    final resolvedTopNCategories =
        topNCategories ?? existing?.topNCategories ?? 3;
    final resolvedDailyTaskLimit =
        dailyTaskLimit ?? existing?.dailyTaskLimit ?? 10;
    final resolvedShowExcludedUrgentWarning =
        showExcludedUrgentWarning ??
        ((existing?.showExcludedUrgentWarning ?? 1) == 1);

    if (existing == null) {
      // Create new
      await _db
          .into(_db.allocationPreferences)
          .insert(
            db.AllocationPreferencesCompanion.insert(
              id: Value(_uuid.v4()),
              strategyType: Value(_mapStrategyTypeToDrift(strategyType)),
              urgencyInfluence: Value(resolvedUrgencyInfluence),
              minimumTasksPerCategory: Value(resolvedMinimumTasksPerCategory),
              topNCategories: Value(resolvedTopNCategories),
              dailyTaskLimit: Value(resolvedDailyTaskLimit),
              showExcludedUrgentWarning: Value(
                resolvedShowExcludedUrgentWarning ? 1 : 0,
              ),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
    } else {
      // Update existing
      await (_db.update(
        _db.allocationPreferences,
      )..where((t) => t.id.equals(existing.id))).write(
        db.AllocationPreferencesCompanion(
          strategyType: Value(_mapStrategyTypeToDrift(strategyType)),
          urgencyInfluence: Value(resolvedUrgencyInfluence),
          minimumTasksPerCategory: Value(resolvedMinimumTasksPerCategory),
          topNCategories: Value(resolvedTopNCategories),
          dailyTaskLimit: Value(resolvedDailyTaskLimit),
          showExcludedUrgentWarning: Value(
            resolvedShowExcludedUrgentWarning ? 1 : 0,
          ),
          updatedAt: Value(now),
        ),
      );
    }
  }

  @override
  Future<void> resetToDefaults() async {
    // Use get() to handle multiple rows gracefully
    final allPrefs = await _db.select(_db.allocationPreferences).get();
    if (allPrefs.isEmpty) return;

    final existing = allPrefs.first;

    // Clean up duplicates if any
    if (allPrefs.length > 1) {
      await _cleanupDuplicatePreferences(allPrefs);
    }

    await (_db.update(
      _db.allocationPreferences,
    )..where((t) => t.id.equals(existing.id))).write(
      db.AllocationPreferencesCompanion(
        strategyType: const Value(db_priority.AllocationStrategy.proportional),
        urgencyInfluence: const Value(0.4),
        minimumTasksPerCategory: const Value(1),
        topNCategories: const Value(3),
        dailyTaskLimit: const Value(10),
        showExcludedUrgentWarning: const Value(1),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // Mapping helpers
  model.AllocationStrategyType _mapStrategyType(
    db_priority.AllocationStrategy type,
  ) {
    switch (type) {
      case db_priority.AllocationStrategy.proportional:
        return model.AllocationStrategyType.proportional;
      case db_priority.AllocationStrategy.urgencyWeighted:
        return model.AllocationStrategyType.urgencyWeighted;
      case db_priority.AllocationStrategy.roundRobin:
        return model.AllocationStrategyType.roundRobin;
      case db_priority.AllocationStrategy.minimumViable:
        return model.AllocationStrategyType.minimumViable;
      case db_priority.AllocationStrategy.dynamic:
        return model.AllocationStrategyType.dynamic;
      case db_priority.AllocationStrategy.topCategories:
        return model.AllocationStrategyType.topCategories;
    }
  }

  db_priority.AllocationStrategy _mapStrategyTypeToDrift(
    model.AllocationStrategyType type,
  ) {
    switch (type) {
      case model.AllocationStrategyType.proportional:
        return db_priority.AllocationStrategy.proportional;
      case model.AllocationStrategyType.urgencyWeighted:
        return db_priority.AllocationStrategy.urgencyWeighted;
      case model.AllocationStrategyType.roundRobin:
        return db_priority.AllocationStrategy.roundRobin;
      case model.AllocationStrategyType.minimumViable:
        return db_priority.AllocationStrategy.minimumViable;
      case model.AllocationStrategyType.dynamic:
        return db_priority.AllocationStrategy.dynamic;
      case model.AllocationStrategyType.topCategories:
        return db_priority.AllocationStrategy.topCategories;
    }
  }
}
