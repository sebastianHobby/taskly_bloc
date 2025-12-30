import 'package:drift/drift.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart' as db;
import 'package:taskly_bloc/data/drift/features/priority_tables.drift.dart'
    as db_priority;
import 'package:taskly_bloc/domain/models/priority/allocation_preference.dart'
    as model;
import 'package:taskly_bloc/domain/repositories/allocation_preferences_repository.dart';
import 'package:uuid/uuid.dart';

/// Drift implementation of allocation preferences repository
class AllocationPreferencesRepositoryImpl
    implements AllocationPreferencesRepository {
  AllocationPreferencesRepositoryImpl(this._db);

  final db.AppDatabase _db;
  final _uuid = const Uuid();

  @override
  Stream<model.AllocationPreference?> watchPreferences() {
    return _db.select(_db.allocationPreferences).watchSingleOrNull().map(
      (pref) {
        if (pref == null) return null;
        return model.AllocationPreference(
          id: pref.id,
          userId: pref.userId ?? '',
          createdAt: pref.createdAt,
          updatedAt: pref.updatedAt,
          strategyType: _mapStrategyType(pref.strategyType),
          urgencyInfluence: pref.urgencyInfluence,
          minimumTasksPerCategory: pref.minimumTasksPerCategory,
          topNCategories: pref.topNCategories,
        );
      },
    );
  }

  @override
  Future<model.AllocationPreference?> getPreferences() async {
    final pref = await _db.select(_db.allocationPreferences).getSingleOrNull();
    if (pref == null) return null;

    return model.AllocationPreference(
      id: pref.id,
      userId: pref.userId ?? '',
      createdAt: pref.createdAt,
      updatedAt: pref.updatedAt,
      strategyType: _mapStrategyType(pref.strategyType),
      urgencyInfluence: pref.urgencyInfluence,
      minimumTasksPerCategory: pref.minimumTasksPerCategory,
      topNCategories: pref.topNCategories,
    );
  }

  @override
  Future<void> savePreferences({
    required model.AllocationStrategyType strategyType,
    double? urgencyInfluence,
    int? minimumTasksPerCategory,
    int? topNCategories,
  }) async {
    final now = DateTime.now();
    final existing = await _db
        .select(_db.allocationPreferences)
        .getSingleOrNull();

    final resolvedUrgencyInfluence =
        urgencyInfluence ?? existing?.urgencyInfluence ?? 0.4;
    final resolvedMinimumTasksPerCategory =
        minimumTasksPerCategory ?? existing?.minimumTasksPerCategory ?? 1;
    final resolvedTopNCategories =
        topNCategories ?? existing?.topNCategories ?? 3;

    if (existing == null) {
      // Create new
      await _db
          .into(_db.allocationPreferences)
          .insert(
            db.AllocationPreferencesCompanion.insert(
              id: Value(_uuid.v4()),
              userId: const Value(''), // server-side trigger will set
              strategyType: Value(_mapStrategyTypeToDrift(strategyType)),
              urgencyInfluence: Value(resolvedUrgencyInfluence),
              minimumTasksPerCategory: Value(resolvedMinimumTasksPerCategory),
              topNCategories: Value(resolvedTopNCategories),
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
          updatedAt: Value(now),
        ),
      );
    }
  }

  @override
  Future<void> resetToDefaults() async {
    final existing = await _db
        .select(_db.allocationPreferences)
        .getSingleOrNull();
    if (existing == null) return;

    await (_db.update(
      _db.allocationPreferences,
    )..where((t) => t.id.equals(existing.id))).write(
      db.AllocationPreferencesCompanion(
        strategyType: const Value(db_priority.AllocationStrategy.proportional),
        urgencyInfluence: const Value(0.4),
        minimumTasksPerCategory: const Value(1),
        topNCategories: const Value(3),
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
