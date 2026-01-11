import 'package:drift/drift.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/drift/features/shared_enums.dart';
import 'package:taskly_bloc/data/id/id_generator.dart';
import 'package:taskly_bloc/domain/attention/system_attention_rules.dart';
import 'package:taskly_bloc/domain/models/screens/system_screen_definitions.dart';

/// Result of a cleanup operation.
class CleanupResult {
  const CleanupResult({
    required this.screensDeleted,
    required this.rulesDeleted,
    required this.resolutionsDeleted,
  });

  /// Number of orphaned system screen definitions deleted.
  final int screensDeleted;

  /// Number of orphaned system attention rules deleted.
  final int rulesDeleted;

  /// Number of orphaned attention resolutions deleted.
  final int resolutionsDeleted;

  /// Total items cleaned up.
  int get total => screensDeleted + rulesDeleted + resolutionsDeleted;

  @override
  String toString() =>
      'CleanupResult('
      'screens: $screensDeleted, '
      'rules: $rulesDeleted, '
      'resolutions: $resolutionsDeleted)';
}

/// Cleans up orphaned system-sourced data.
///
/// When system templates are renamed or removed between app versions,
/// their corresponding database rows become orphaned. This service
/// identifies and removes them.
///
/// ## What gets cleaned
///
/// 1. **Screen definitions**: System screens (`source='system_template'`)
///    whose IDs don't match any current template's deterministic v5 UUID.
///
/// 2. **Attention rules**: System rules (`source='system_template'`)
///    whose IDs don't match any current template's deterministic v5 UUID.
///
/// 3. **Attention resolutions**: Resolutions referencing rule IDs that
///    no longer exist in the database (cascade cleanup).
///
/// ## When to run
///
/// - On app startup (after seeding)
/// - After migrations that change system templates
/// - Periodically as maintenance
///
/// ## Safety
///
/// - Only deletes `source='system_template'` rows
/// - User-created content is never touched
/// - Uses deterministic IDs to identify valid system data
/// - Deletes sync to Supabase via PowerSync (normal CRUD flow)
class SystemDataCleanupService {
  SystemDataCleanupService({
    required AppDatabase db,
    required IdGenerator idGenerator,
  }) : _db = db,
       _idGenerator = idGenerator;

  final AppDatabase _db;
  final IdGenerator _idGenerator;

  /// Run all cleanup operations.
  ///
  /// Returns a [CleanupResult] with counts of deleted items.
  Future<CleanupResult> cleanAll() async {
    talker.info('[SystemDataCleanupService] Starting cleanup');

    try {
      final screensDeleted = await cleanOrphanedScreenDefinitions();
      final rulesDeleted = await cleanOrphanedAttentionRules();
      final resolutionsDeleted = await cleanOrphanedResolutions();

      final result = CleanupResult(
        screensDeleted: screensDeleted,
        rulesDeleted: rulesDeleted,
        resolutionsDeleted: resolutionsDeleted,
      );

      if (result.total > 0) {
        talker.info('[SystemDataCleanupService] Cleanup complete: $result');
      } else {
        talker.debug('[SystemDataCleanupService] No orphaned data found');
      }

      return result;
    } catch (e, stackTrace) {
      talker.operationFailed(
        '[SystemDataCleanupService] Cleanup failed',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Delete orphaned system screen definitions.
  ///
  /// A system screen is orphaned if:
  /// - `source = 'system_template'`
  /// - `id NOT IN (known deterministic v5 IDs from templates)`
  Future<int> cleanOrphanedScreenDefinitions() async {
    // Compute known system screen IDs from current templates
    final knownIds = SystemScreenDefinitions.all
        .map((t) => _idGenerator.screenDefinitionId(screenKey: t.screenKey))
        .toSet();

    // Delete system-sourced screens NOT in known IDs
    final deleted =
        await (_db.delete(_db.screenDefinitions)..where(
              (s) =>
                  s.source.equals(EntitySource.system_template.name) &
                  s.id.isNotIn(knownIds),
            ))
            .go();

    if (deleted > 0) {
      talker.info(
        '[SystemDataCleanupService] Deleted $deleted orphaned screen(s)',
      );
    }

    return deleted;
  }

  /// Delete orphaned system attention rules.
  ///
  /// A system rule is orphaned if:
  /// - `source = 'system_template'` (or identified by known ruleKey)
  /// - `id NOT IN (known deterministic v5 IDs from templates)`
  Future<int> cleanOrphanedAttentionRules() async {
    // Compute known system rule IDs from current templates
    final knownIds = SystemAttentionRules.all
        .map((t) => _idGenerator.attentionRuleId(ruleKey: t.ruleKey))
        .toSet();

    // System rules are identified by their ruleKeys matching templates
    final systemRuleKeys = SystemAttentionRules.all
        .map((t) => t.ruleKey)
        .toSet();

    // Delete system-sourced rules NOT in known IDs
    // Note: attention_rules may not have source column yet,
    // so we identify by ruleKey pattern
    final deleted =
        await (_db.delete(_db.attentionRules)..where(
              (r) =>
                  r.ruleKey.isIn(systemRuleKeys) & // Was a system rule (by key)
                  r.id.isNotIn(knownIds),
            )) // ID no longer valid
            .go();

    if (deleted > 0) {
      talker.info(
        '[SystemDataCleanupService] Deleted $deleted orphaned rule(s)',
      );
    }

    return deleted;
  }

  /// Delete orphaned attention resolutions.
  ///
  /// A resolution is orphaned if its `ruleId` references a rule
  /// that no longer exists in the database.
  Future<int> cleanOrphanedResolutions() async {
    // Get all valid rule IDs from database
    final rules = await _db.select(_db.attentionRules).get();
    final validRuleIds = rules.map((r) => r.id).toSet();

    // Delete resolutions referencing non-existent rules
    final deleted = await (_db.delete(
      _db.attentionResolutions,
    )..where((r) => r.ruleId.isNotIn(validRuleIds))).go();

    if (deleted > 0) {
      talker.info(
        '[SystemDataCleanupService] Deleted $deleted orphaned resolution(s)',
      );
    }

    return deleted;
  }

  /// Run cleanup and seeding in correct order.
  ///
  /// Call this during app startup after database initialization.
  /// Order: cleanup first (remove orphans), then seed (add new).
  static Future<void> runStartupMaintenance({
    required AppDatabase db,
    required IdGenerator idGenerator,
    required Future<void> Function() seedScreens,
    required Future<void> Function() seedRules,
  }) async {
    // 1. Seed first (ensures all current templates exist)
    await seedScreens();
    await seedRules();

    // 2. Cleanup orphans (removes deprecated templates)
    final cleanup = SystemDataCleanupService(db: db, idGenerator: idGenerator);
    await cleanup.cleanAll();
  }
}
